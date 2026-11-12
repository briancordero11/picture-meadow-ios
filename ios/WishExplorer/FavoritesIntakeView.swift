import SwiftUI

struct FavoritesIntakeView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeading(
                eyebrow: "Things I love",
                title: "What are your favorites?",
                subtitle: "Choose up to ten pictures across all the groups. Every choice is optional."
            )
            FavoriteChoicesView()
            VStack(spacing: 12) {
                SaveFavoritesButton()
                Text("Save keeps these favorites with your ideas. A grown-up can use Remember choices in Settings to keep them on this iPad.")
                    .font(.footnote)
                    .foregroundStyle(WishTheme.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        }
    }
}

struct SaveFavoritesButton: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        Button(action: store.finishFavoritesIntake) {
            Text("Save favorites")
                .font(.headline)
                .foregroundStyle(WishTheme.ink)
                .padding(.horizontal, 22).padding(.vertical, 12)
                .frame(minHeight: 52)
                .background(WishTheme.yellow, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Keep these favorites with your ideas and choose a wish picture")
    }
}

struct FavoritesSaveBar: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        HStack(spacing: 16) {
            Text("\(store.draft.favoriteIDs.count) selected")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(WishTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Favorites selected")
                .accessibilityValue("\(store.draft.favoriteIDs.count) of 10")
            SaveFavoritesButton()
        }
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(WishTheme.background)
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
            .background(WishTheme.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(WishTheme.blue.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("What are your favorites?")
        .accessibilityValue("\(store.draft.favoriteIDs.count) favorites selected")
        .accessibilityHint("Begin with colors, food, music and things you love")
    }
}
