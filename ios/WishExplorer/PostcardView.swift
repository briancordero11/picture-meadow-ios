import SwiftUI

struct PostcardView: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        VStack(spacing: 26) {
            ScreenHeading(eyebrow: "Made from your ideas", title: "My wish picture", subtitle: "This is a picture from your imagination. You can change anything.")
            VStack(spacing: 22) {
                if store.draft.category == .go {
                    ParkIllustration(color: store.draft.coasterColor.map { WishTheme.color(for: $0) } ?? WishTheme.blue)
                        .frame(height: 280)
                    Text(store.draft.destination?.name ?? "An amusement park adventure")
                        .font(.largeTitle.weight(.bold)).multilineTextAlignment(.center).foregroundStyle(WishTheme.ink)
                    Text(store.remoteDescription ?? store.draft.postcardDescription)
                        .font(.title3).multilineTextAlignment(.center).foregroundStyle(WishTheme.secondary)
                    if !store.draft.animals.isEmpty {
                        HStack(spacing: 20) {
                            ForEach(store.draft.animals) { animal in
                                VStack {
                                    Text(animal.emoji).font(.system(size: 46)).accessibilityHidden(true)
                                    Text(animal.label).font(.headline)
                                }
                            }
                        }.foregroundStyle(WishTheme.ink)
                        Text("I also like these animals. They may be part of a different adventure.")
                            .font(.body).foregroundStyle(WishTheme.secondary).multilineTextAlignment(.center)
                    }
                } else {
                    if let interest = store.draft.interest {
                        PictureSymbol(label: interest.label).frame(height: 200).accessibilityLabel(interest.label)
                    }
                    Text(store.draft.interest?.label.capitalized ?? "There is time to find my wish")
                        .font(.largeTitle.weight(.bold)).foregroundStyle(WishTheme.ink)
                    Text("A grown-up can help explore your ideas using the talking board.")
                        .font(.title3).foregroundStyle(WishTheme.secondary)
                }
            }.padding(28).frame(maxWidth: .infinity)
                .background(.white, in: RoundedRectangle(cornerRadius: 34))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { actions }
                VStack(spacing: 16) { actions }
            }
            if let status = store.remoteStatus {
                Text(status).font(.body).foregroundStyle(WishTheme.secondary).accessibilityAddTraits(.updatesFrequently)
            }
            Text("A wish idea to talk about together. It is not a booking or an approved wish.")
                .font(.body).foregroundStyle(WishTheme.secondary).multilineTextAlignment(.center)
        }
    }

    @ViewBuilder private var actions: some View {
        PrimaryWishButton(title: "Read my wish", symbol: "speaker.wave.2.fill") {
            store.say(store.draft.category == .go ? (store.remoteDescription ?? store.draft.postcardDescription) : (store.draft.interest?.label ?? "I am still thinking"), explicit: true)
        }
        Button { store.stopSpeaking() } label: {
            Label("Stop speaking", systemImage: "speaker.slash.fill")
                .font(.headline).padding(18)
                .frame(minWidth: 44, minHeight: 44)
        }
        Button("Change my choices") { store.step = store.draft.category == .go ? .destination : .interests }
            .font(.headline).padding(18)
        Button("Choose another wish") { store.step = .interests }.font(.headline).padding(18)
    }
}
