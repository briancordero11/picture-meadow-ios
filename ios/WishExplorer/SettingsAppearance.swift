import SwiftUI

enum WishSettingsAppearance {
    static let paper = Color(red: 1, green: 251 / 255, blue: 242 / 255)
    static let ink = Color(red: 33 / 255, green: 28 / 255, blue: 24 / 255)
    static let secondary = Color(red: 101 / 255, green: 87 / 255, blue: 72 / 255)
    static let outline = Color(red: 212 / 255, green: 190 / 255, blue: 164 / 255)
    static let cream = Color(red: 1, green: 240 / 255, blue: 206 / 255)
    static let green = Color(red: 188 / 255, green: 227 / 255, blue: 161 / 255)
    static let yellow = Color(red: 1, green: 218 / 255, blue: 69 / 255)
}

private struct WishSettingsDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var wishSettingsDismiss: (() -> Void)? {
        get { self[WishSettingsDismissKey.self] }
        set { self[WishSettingsDismissKey.self] = newValue }
    }
}

/// The same trailing paper panel as the approved picture-board preview.
struct WishSettingsPanel<Content: View>: View {
    let onClose: () -> Void
    @ViewBuilder var content: () -> Content
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let panelWidth = min(410, max(0, geometry.size.width - 24))
            let availableHeight = max(0, geometry.size.height - 32)
            let panelHeight = min(availableHeight, contentHeight > 0 ? contentHeight : availableHeight)
            ZStack(alignment: .topLeading) {
                Color(red: 51 / 255, green: 37 / 255, blue: 27 / 255).opacity(0.33)
                    .ignoresSafeArea().contentShape(Rectangle()).onTapGesture { }
                    .accessibilityHidden(true)
                content()
                    .environment(\.wishSettingsDismiss, onClose)
                    .environment(\.colorScheme, .light)
                    .frame(width: panelWidth, height: panelHeight)
                    .background(WishSettingsAppearance.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 180 / 255, green: 156 / 255, blue: 125 / 255), lineWidth: 1))
                    .shadow(color: WishSettingsAppearance.ink.opacity(0.19), radius: 20, x: 0, y: 12)
                    .accessibilityAddTraits(.isModal)
                    .accessibilityAction(.escape, onClose)
                    .position(x: geometry.size.width - 12 - panelWidth / 2,
                              y: 16 + panelHeight / 2)
            }
            .onPreferenceChange(WishSettingsContentHeightKey.self) { height in
                if height > 0 { contentHeight = ceil(height) }
            }
        }
    }
}

/// A vertical ScrollView proposes unbounded content height, so this reports the
/// natural page height even while the panel is capped to its available space.
private struct WishSettingsContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct WishSettingsPage<Content: View>: View {
    let title: String
    var showsBack = true
    var showsDone = true
    var backTitle = "Back to settings"
    var onClose: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @Environment(\.wishSettingsDismiss) private var dismissSettings
    @State private var isPageVisible = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    Text(title)
                        .font(WishTheme.bodyFont(size: 23, weight: .bold, relativeTo: .title2))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier(title == "For grown-ups" ? "grownup-settings-title" : "grownup-page-title")
                    Button(action: close) { WishUIIcon(name: "x", size: 22).frame(width: 44, height: 44) }
                        .buttonStyle(.plain)
                        .background(WishSettingsAppearance.cream, in: RoundedRectangle(cornerRadius: 13))
                        .accessibilityLabel("Close settings")
                }
                content()
                if showsBack || showsDone {
                    VStack(spacing: 12) {
                        if showsBack {
                            Button { dismiss() } label: {
                                HStack(spacing: 8) { WishUIIcon(name: "arrow-left", size: 18); Text(backTitle) }
                            }
                        }
                        if showsDone { Button("Done", action: close) }
                    }.padding(.top, 6)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(key: WishSettingsContentHeightKey.self,
                                           value: isPageVisible ? geometry.size.height : 0)
                }
            }
        }
        .background(WishSettingsAppearance.paper)
        .font(WishTheme.bodyFont(size: 16))
        .foregroundStyle(WishSettingsAppearance.ink)
        .tint(WishSettingsAppearance.ink)
        .buttonStyle(WishSettingsActionStyle())
        .labeledContentStyle(WishSettingsLabeledContentStyle())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { isPageVisible = true }
        .onDisappear { isPageVisible = false }
    }

    private func close() {
        if let onClose { onClose() }
        else if let dismissSettings { dismissSettings() }
        else { dismiss() }
    }
}

struct WishSettingsSection<Content: View>: View {
    private let title: String?
    private let content: Content
    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title).font(WishTheme.bodyFont(size: 18, weight: .bold, relativeTo: .headline))
                    .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, title == nil ? 0 : 4)
    }
}

struct WishSettingsActionStyle: ButtonStyle {
    enum Kind { case standard, primary, destructive, save }
    var kind: Kind = .standard
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let actionKind: Kind = configuration.role == .destructive ? .destructive : kind
        return configuration.label
            .font(WishTheme.bodyFont(size: 16, weight: .bold))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(foreground(for: actionKind))
            .background(background(for: actionKind), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(border(for: actionKind), lineWidth: 1.5))
            .contentShape(RoundedRectangle(cornerRadius: 13))
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
    }
    private func background(for actionKind: Kind) -> Color {
        guard isEnabled else { return Color(red: 233 / 255, green: 224 / 255, blue: 212 / 255) }
        switch actionKind {
        case .standard: return WishSettingsAppearance.cream
        case .primary: return WishSettingsAppearance.green
        case .save: return WishSettingsAppearance.yellow
        case .destructive: return Color(red: 1, green: 240 / 255, blue: 235 / 255)
        }
    }
    private func foreground(for actionKind: Kind) -> Color {
        guard isEnabled else { return Color(red: 98 / 255, green: 86 / 255, blue: 72 / 255) }
        return actionKind == .destructive ? Color(red: 141 / 255, green: 45 / 255, blue: 38 / 255) : WishTheme.line
    }
    private func border(for actionKind: Kind) -> Color {
        actionKind == .destructive && isEnabled ? Color(red: 180 / 255, green: 97 / 255, blue: 81 / 255) : WishTheme.line
    }
}

struct WishSettingsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .center, spacing: 16) {
                configuration.label.frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isOn ? WishTheme.blue : .white)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(configuration.isOn ? WishTheme.blue : WishSettingsAppearance.outline, lineWidth: 1.5))
                    .overlay {
                        if configuration.isOn {
                            Color.white.frame(width: 18, height: 18)
                                .mask(WishUIIcon(name: "check", size: 18))
                        }
                    }
                    .frame(width: 24, height: 24)
            }.frame(minHeight: 56).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: Binding(get: { configuration.isOn }, set: { configuration.isOn = $0 })) {
                configuration.label
            }.toggleStyle(.switch)
        }
    }
}

struct WishSettingsTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(WishTheme.bodyFont(size: 18))
            .padding(10).frame(minHeight: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WishSettingsAppearance.outline, lineWidth: 1))
    }
}

private struct WishSettingsLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            configuration.label.font(WishTheme.bodyFont(size: 16, weight: .bold))
            configuration.content.foregroundStyle(WishSettingsAppearance.secondary)
        }.accessibilityElement(children: .combine)
    }
}
