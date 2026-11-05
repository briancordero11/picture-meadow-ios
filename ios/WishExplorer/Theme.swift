import SwiftUI

enum WishTheme {
    static let ink = Color(red: 0.09, green: 0.18, blue: 0.31)
    static let blue = Color(red: 0.03, green: 0.34, blue: 0.75)
    static let sky = Color(red: 0.91, green: 0.96, blue: 1)
    static let lavender = Color(red: 0.94, green: 0.92, blue: 1)
    static let mint = Color(red: 0.90, green: 0.97, blue: 0.93)
    static let peach = Color(red: 1, green: 0.94, blue: 0.87)
    static let yellow = Color(red: 1, green: 0.80, blue: 0.25)
    static let background = Color(red: 0.97, green: 0.98, blue: 1)
    static let secondary = Color(red: 0.30, green: 0.37, blue: 0.47)

    static func color(for choice: CoasterColor) -> Color {
        switch choice {
        case .blue: blue
        case .pink: Color(red: 0.81, green: 0.23, blue: 0.50)
        case .purple: Color(red: 0.46, green: 0.25, blue: 0.75)
        case .green: Color(red: 0.12, green: 0.48, blue: 0.30)
        }
    }

    static func categoryColor(_ category: WishCategory) -> Color {
        switch category {
        case .go: sky
        case .be: lavender
        case .meet: peach
        case .have: mint
        case .give: Color(red: 1, green: 0.91, blue: 0.94)
        case .helpChoose: Color(red: 1, green: 0.97, blue: 0.85)
        }
    }
}

struct PrimaryWishButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.title3.weight(.bold))
                .padding(.horizontal, 26).padding(.vertical, 18)
                .frame(minHeight: 64)
                .foregroundStyle(.white)
                .background(WishTheme.blue, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(.plain)
    }
}

struct ChoiceCard<Content: View>: View {
    let selected: Bool
    let background: Color
    var action: () -> Void
    @ViewBuilder var content: () -> Content
    var body: some View {
        Button(action: action) {
            content()
                .padding(22)
                .frame(maxWidth: .infinity, minHeight: 180)
                .background(background, in: RoundedRectangle(cornerRadius: 28))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2).foregroundStyle(WishTheme.blue, .white).padding(14)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(selected ? WishTheme.blue : .clear, lineWidth: 4))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct WishStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        return Path { path in
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let length = index.isMultiple(of: 2) ? radius : radius * 0.46
                let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}

struct ScreenHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow.uppercased()).font(.subheadline.weight(.bold)).tracking(2).foregroundStyle(WishTheme.blue)
            Text(title).font(.largeTitle.weight(.bold)).foregroundStyle(WishTheme.ink).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.title3).foregroundStyle(WishTheme.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
