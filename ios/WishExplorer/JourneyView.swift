import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    private let catalog = JourneyCatalog.shared

    private var journey: JourneyInterest? { catalog.interest(id: store.draft.interestID) }
    private var stage: Int { min(max(store.journeyStage, 0), 3) }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: sizeClass == .compact ? 2 : 4)
    }
    private var heading: String {
        switch stage {
        case 0: "What would you like to do?"
        case 1: "Choose a place or thing"
        case 2: "What are your favorites?"
        default: "What matters most?"
        }
    }
    private var guidance: String {
        switch stage {
        case 0: "Choose up to three pictures."
        case 1: "Choose a place or thing for your wish."
        case 2: "Pick any pictures you like. You can skip a group."
        default: "Pick the picture that is most important to you."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeading(
                eyebrow: store.draft.interest?.label ?? "My wish",
                title: heading,
                subtitle: guidance
            )
            ProgressView(value: Double(stage + 1), total: 4)
                .tint(WishTheme.blue)
                .accessibilityLabel("Wish choices")
                .accessibilityValue("Step \(stage + 1) of 4")
            if let journey {
                stageChoices(journey)
                actions
            } else {
                Text("Choose a wish picture to start exploring.")
                    .font(.title3).foregroundStyle(WishTheme.secondary)
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
        case 2:
            ForEach(catalog.favorites) { group in
                VStack(alignment: .leading, spacing: 14) {
                    Text(group.label).font(.title2.weight(.bold)).foregroundStyle(WishTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                    choiceGrid(group.options, selected: store.draft.favoriteIDs) { store.toggleFavorite($0) }
                }
            }
        default:
            let selectedChoices = catalog.choices(for: store.draft)
            if selectedChoices.isEmpty {
                Text("You can make a wish picture now, or go back to choose some pictures.")
                    .font(.title3).foregroundStyle(WishTheme.secondary)
            } else {
                choiceGrid(selectedChoices, selected: [store.draft.essentialChoiceID].compactMap { $0 }) {
                    store.selectEssential($0)
                }
            }
        }
    }

    private func choiceGrid(_ choices: [JourneyChoice], selected: [String], action: @escaping (String) -> Void) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(choices) { choice in
                JourneyChoiceTile(choice: choice, selected: selected.contains(choice.id)) { action(choice.id) }
            }
        }
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) { skipButton; nextButton }
            VStack(spacing: 16) { nextButton; skipButton }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    private var skipButton: some View {
        Button("Skip this part", action: store.skipJourneyStage)
            .font(.headline).foregroundStyle(WishTheme.blue)
            .padding(16).frame(minHeight: 54)
    }

    private var nextButton: some View {
        PrimaryWishButton(title: stage == 3 ? "See my wish picture" : "Next", symbol: stage == 3 ? "photo" : "arrow.right") {
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
            VStack(spacing: 12) {
                Text(choice.symbol).font(.system(size: 64)).frame(height: 78).accessibilityHidden(true)
                Text(choice.label).font(.system(.title3, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(WishTheme.ink)
            .padding(.horizontal, 12).padding(.vertical, 22)
            .frame(maxWidth: .infinity, minHeight: 174)
            .background(WishTheme.peach, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? WishTheme.blue : WishTheme.secondary.opacity(0.25), lineWidth: selected ? 4 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.title2)
                        .foregroundStyle(WishTheme.blue, .white).padding(8).accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.label)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
