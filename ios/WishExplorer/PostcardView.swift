import SwiftUI

struct PostcardView: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        VStack(spacing: 15) {
            Text("My wish picture")
                .font(WishTheme.cardFont(size: 26, weight: .bold, relativeTo: .title))
                .foregroundStyle(WishTheme.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 8)
            VStack(spacing: 22) {
                if let scene = store.generatedScene, let image = UIImage(data: scene.imageData) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .accessibilityLabel("AI illustration of my chosen wish ideas")
                    Text("AI imagined picture")
                        .font(WishTheme.cardFont(size: 16, weight: .bold, relativeTo: .headline))
                        .foregroundStyle(WishTheme.secondary)
                    PostcardActionLayout(spacing: 12) {
                        control("Remove AI picture") { store.discardGeneratedScene() }
                        control("Report this AI picture") { store.requestAIReport() }
                    }
                }
                if let interest = store.draft.interest {
                    PictureSymbol(label: interest.label)
                        .frame(maxWidth: 270).frame(height: 200)
                        .accessibilityLabel(interest.label)
                    SceneChoiceCollage(draft: store.draft)
                    Text(store.draft.sceneDescription)
                        .font(WishTheme.bodyFont(size: 16, relativeTo: .body))
                        .lineSpacing(4)
                        .foregroundStyle(WishTheme.secondary)
                    if store.draft.sceneChoices.isEmpty {
                        Text("There is time to find what you like. You can add pictures whenever you are ready.")
                            .font(WishTheme.bodyFont(size: 16, relativeTo: .body))
                            .foregroundStyle(WishTheme.secondary)
                    }
                } else if store.draft.category == .go {
                    ParkIllustration(color: store.draft.coasterColor.map { WishTheme.color(for: $0) } ?? WishTheme.blue)
                        .frame(height: 260)
                    Text(store.remoteDescription ?? store.draft.postcardDescription)
                        .font(WishTheme.bodyFont(size: 16, relativeTo: .body))
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .foregroundStyle(WishTheme.ink)
            .background(WishTheme.peach, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))

            Text("Your picture board works offline. An optional AI picture needs a connected service and a grown-up's permission.")
                .font(WishTheme.bodyFont(size: 13, relativeTo: .footnote))
                .foregroundStyle(WishTheme.secondary)
                .lineSpacing(3)

            PostcardActionLayout(spacing: 12) {
                WishBackButton()
                control(store.generatedScene == nil ? "Make an AI picture" : "Make another AI picture", primary: true) {
                    store.requestAIPicture()
                }
                .accessibilityHint("A grown-up reviews the chosen concepts and gives permission")
                control("Read my wish") {
                    store.say(store.draft.interest != nil ? store.draft.sceneDescription : store.draft.postcardDescription, explicit: true)
                }
                Button { store.stopSpeaking() } label: {
                    WishUIIcon(name: "volume-off", size: 20)
                        .padding(.horizontal, 20).padding(.vertical, 13)
                        .frame(minWidth: 50, minHeight: 50)
                        .background(WishTheme.control, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop speaking")
                control("Change my choices") { store.editJourney() }
                control("Choose another wish") { store.goHome() }
            }
            .foregroundStyle(WishTheme.line)
            .padding(.top, 10)
        }
        .multilineTextAlignment(.center)
    }

    private func control(_ title: String, primary: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(WishTheme.cardFont(size: 16, weight: .bold, relativeTo: .headline))
                .padding(.horizontal, 20).padding(.vertical, 13)
                .frame(minHeight: 50)
                .background(primary ? WishTheme.mint : WishTheme.control, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct SceneChoiceCollage: View {
    let draft: WishDraft
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: sizeClass == .compact ? 2 : 3)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(draft.sceneChoices) { choice in
                VStack(spacing: 8) {
                    Text(choice.label)
                        .font(WishTheme.cardFont(size: 15, weight: .bold, relativeTo: .headline))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    JourneyArtwork(choice: choice).frame(width: 46, height: 46).accessibilityHidden(true)
                    if draft.essentialChoiceID == choice.id {
                        Text("♥ Most important")
                            .font(WishTheme.bodyFont(size: 12, weight: .bold, relativeTo: .caption))
                            .foregroundStyle(WishTheme.mostImportant)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 130)
                .background(WishTheme.collage, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.collageLine, lineWidth: 1))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

/// Wraps the existing controls into centered rows without changing their reading order.
private struct PostcardActionLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let naturalWidth = subviews.reduce(CGFloat.zero) { $0 + $1.sizeThatFits(.unspecified).width }
            + CGFloat(max(0, subviews.count - 1)) * spacing
        let width = proposal.width ?? naturalWidth
        let rows = rows(for: subviews, width: width)
        return CGSize(width: width, height: rows.reduce(CGFloat.zero) { $0 + $1.height }
                      + CGFloat(max(0, rows.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(for: subviews, width: bounds.width) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                                          anchor: .topLeading,
                                          proposal: ProposedViewSize(width: item.size.width, height: item.size.height))
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [Row] {
        var result: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let naturalSize = subviews[index].sizeThatFits(.unspecified)
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: min(max(0, width), naturalSize.width), height: nil))
            if !row.items.isEmpty && row.width + spacing + size.width > width {
                result.append(row)
                row = Row()
            }
            if !row.items.isEmpty { row.width += spacing }
            row.items.append((index, size))
            row.width += size.width
            row.height = max(row.height, size.height)
        }
        if !row.items.isEmpty { result.append(row) }
        return result
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}
