import SwiftUI

struct FavoritesIntakeView: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeading(
                eyebrow: "Things I love",
                title: "What are your favorites?",
                subtitle: "Choose up to ten pictures across all the groups. Every choice is optional."
            )
            FavoriteChoicesView()
            PrimaryWishButton(title: "Choose a wish picture", symbol: "arrow.right") {
                store.finishFavoritesIntake()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
}

struct FavoriteChoicesView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 14), count: sizeClass == .compact ? 2 : 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(JourneyCatalog.shared.favorites) { group in
                VStack(alignment: .leading, spacing: 14) {
                    Text(group.label)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(WishTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(group.options) { choice in
                            JourneyChoiceTile(choice: choice, selected: store.draft.favoriteIDs.contains(choice.id)) {
                                store.toggleFavorite(choice.id)
                            }
                            .accessibilityHint("Choose or remove this favorite")
                        }
                    }
                }
            }
        }
    }
}

struct FavoritesIntakeCard: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        Button(action: store.openFavoritesIntake) {
            HStack(spacing: 18) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.pink)
                    .frame(width: 64, height: 64)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are your favorites?")
                        .font(.title2.weight(.bold))
                    Text("Begin with colors, food, music and things you love")
                        .font(.body)
                    if !store.draft.favoriteIDs.isEmpty {
                        Text("\(store.draft.favoriteIDs.count) selected")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WishTheme.blue)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(WishTheme.ink)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WishTheme.lavender, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(WishTheme.blue.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("What are your favorites?")
        .accessibilityValue("\(store.draft.favoriteIDs.count) favorites selected")
        .accessibilityHint("Begin with colors, food, music and things you love")
    }
}
