import SwiftUI

struct FavoritesIntakeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ScreenHeading(
                eyebrow: "Things I love",
                title: "What are your favorites?",
                subtitle: "Pick any pictures you like, up to ten. Every choice is optional."
            )
            FavoriteChoicesView()
            VStack(spacing: 10) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { WishBackButton(); SaveFavoritesButton() }
                    VStack(spacing: 12) { WishBackButton(); SaveFavoritesButton() }
                }
                Text("Save keeps these favorites with your ideas. A grown-up can use Remember choices in Settings to keep them on this iPad.")
                    .font(WishTheme.bodyFont(size: 13, relativeTo: .footnote))
                    .foregroundStyle(WishTheme.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 620)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
    }
}

struct SaveFavoritesButton: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        Button(action: store.finishFavoritesIntake) {
            Text("Save favorites")
                .font(WishTheme.cardFont(size: 16, weight: .bold, relativeTo: .headline))
                .foregroundStyle(WishTheme.ink)
                .padding(.horizontal, 20).padding(.vertical, 13)
                .frame(minWidth: 210, minHeight: 50)
                .background(WishTheme.yellow, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Keep these favorites with your ideas and choose a wish picture")
    }
}

struct FavoriteChoicesView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: sizeClass == .compact ? 2 : 4)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(JourneyCatalog.shared.favorites) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(group.label)
                        .font(WishTheme.cardFont(size: 20, weight: .bold, relativeTo: .title2))
                        .foregroundStyle(WishTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: columns, spacing: 8) {
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
    private let symbols = ["🌈", "🍓", "🐾", "🎵", "🎮", "🗺️"]

    var body: some View {
        Button(action: store.openFavoritesIntake) {
            VStack(spacing: 10) {
                Text("What are your favorites?")
                    .font(WishTheme.cardFont(size: 21, weight: .bold, relativeTo: .title2))
                HStack(spacing: 8) {
                    ForEach(symbols, id: \.self) { symbol in
                        JourneyArtwork(symbol: symbol).frame(width: 28, height: 28)
                    }
                }
                .accessibilityHidden(true)
                Text("Choose colors, food, animals, music, games, and adventures.")
                    .font(WishTheme.bodyFont(size: 15, relativeTo: .body))
                    .lineSpacing(3)
            }
            .foregroundStyle(WishTheme.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14).padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 132)
            .background(WishTheme.intake, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("What are your favorites?")
        .accessibilityValue("\(store.draft.favoriteIDs.count) favorites selected")
        .accessibilityHint("Choose colors, food, animals, music, games, and adventures")
    }
}
