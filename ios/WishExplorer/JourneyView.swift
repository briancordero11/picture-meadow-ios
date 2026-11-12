import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let catalog = JourneyCatalog.shared

    private var journey: JourneyInterest? { catalog.interest(id: store.draft.interestID) }
    private var stage: Int { min(max(store.journeyStage, 0), 2) }
    private var progress: Double { Double(stage + 1) / 3 }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: sizeClass == .compact ? 2 : 4)
    }
    private var heading: String {
        switch stage {
        case 0: "What would you like to do?"
        case 1: "Choose a place or thing"
        default: "What matters most?"
        }
    }
    private var guidance: String {
        switch stage {
        case 0: "Choose up to three pictures."
        case 1: "Choose a place or thing for your wish."
        default: "Pick the picture that is most important to you."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(WishTheme.progressTrack)
                    Capsule().fill(WishTheme.blue)
                        .frame(width: geometry.size.width * CGFloat(progress))
                }
                .animation(reduceMotion ? nil : .smooth(duration: 0.32), value: stage)
            }
            .frame(height: 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Wish progress")
            .accessibilityValue("\(Int((progress * 100).rounded())) percent")
            .padding(.bottom, 26)
            ScreenHeading(
                eyebrow: store.draft.interest?.label ?? "My wish",
                title: heading,
                subtitle: guidance
            )
            .padding(.bottom, 23)
            if let journey {
                stageChoices(journey)
                actions
            } else {
                Text("Choose a wish picture to start exploring.")
                    .font(WishTheme.bodyFont(size: 16, weight: .regular, relativeTo: .body))
                    .foregroundStyle(WishTheme.secondary)
            }
        }
    }

    @ViewBuilder private func stageChoices(_ journey: JourneyInterest) -> some View {
        switch stage {
        case 0:
            choiceGrid(journey.actions, selected: store.draft.selectedActionIDs) { store.toggleJourneyAction($0) }
        case 1:
            choiceGrid(journey.settings, selected: [store.draft.selectedSettingID].compactMap { $0 }) {
                store.selectJourneySetting($0)
            }
        default:
            let selectedChoices = catalog.choices(for: store.draft)
            if selectedChoices.isEmpty {
                Text("You can make a wish picture now, or go back to choose some pictures.")
                    .font(WishTheme.bodyFont(size: 16, weight: .regular, relativeTo: .body))
                    .foregroundStyle(WishTheme.secondary)
                    .multilineTextAlignment(.center)
            } else {
                choiceGrid(selectedChoices, selected: [store.draft.essentialChoiceID].compactMap { $0 }) {
                    store.selectEssential($0)
                }
            }
        }
    }

    private func choiceGrid(_ choices: [JourneyChoice], selected: [String], action: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(choices) { choice in
                JourneyChoiceTile(choice: choice, selected: selected.contains(choice.id)) { action(choice.id) }
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { WishBackButton(); nextButton }
            VStack(spacing: 12) { WishBackButton(); nextButton }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 25)
        .padding(.bottom, 8)
    }

    private var nextButton: some View {
        PrimaryWishButton(title: stage == 2 ? "See my wish picture" : "Next", symbol: stage == 2 ? "photo" : "arrow.right") {
            store.advanceJourney()
        }
    }
}

struct JourneyChoiceTile: View {
    let choice: JourneyChoice
    var selected = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(choice.label)
                    .font(WishTheme.cardFont(size: 16, weight: .bold, relativeTo: .headline))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 38)
                JourneyArtwork(choice: choice)
                    .frame(width: 58, height: 58)
                    .padding(.vertical, 4)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(WishTheme.ink)
            .padding(.horizontal, 6).padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 154)
            .background(WishTheme.picturePeach, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? WishTheme.blue : WishTheme.line, lineWidth: selected ? 4 : 1.5))
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                        .foregroundStyle(WishTheme.blue, .white).padding(6).accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.label)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
