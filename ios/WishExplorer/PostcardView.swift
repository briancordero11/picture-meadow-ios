import SwiftUI

struct PostcardView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 26) {
            ScreenHeading(eyebrow: "Made from your ideas", title: "My wish picture", subtitle: "Your actions. Your favorites. Your imagination.")
            VStack(spacing: 22) {
                if let scene = store.generatedScene, let image = UIImage(data: scene.imageData) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .accessibilityLabel("AI illustration of my chosen wish ideas")
                    Text("AI imagined picture").font(.headline).foregroundStyle(WishTheme.secondary)
                    Button("Remove AI picture") { store.discardGeneratedScene() }.frame(minHeight: 44)
                    Button("Report this AI picture") { store.requestAIReport() }.frame(minHeight: 44)
                }
                if let interest = store.draft.interest {
                    PictureSymbol(label: interest.label).frame(height: 110).accessibilityLabel(interest.label)
                    Text("My \(interest.label) idea").font(.largeTitle.weight(.bold)).multilineTextAlignment(.center)
                    SceneChoiceCollage(draft: store.draft)
                    Text(store.draft.sceneDescription).font(.title3).multilineTextAlignment(.center).foregroundStyle(WishTheme.secondary)
                    if store.draft.sceneChoices.isEmpty {
                        Text("There is time to find what you like. You can add pictures whenever you are ready.").multilineTextAlignment(.center)
                    }
                } else if store.draft.category == .go {
                    ParkIllustration(color: store.draft.coasterColor.map { WishTheme.color(for: $0) } ?? WishTheme.blue).frame(height: 260)
                    Text(store.remoteDescription ?? store.draft.postcardDescription).font(.title3).multilineTextAlignment(.center)
                }
            }.padding(28).frame(maxWidth: .infinity).foregroundStyle(WishTheme.ink)
                .background(.white, in: RoundedRectangle(cornerRadius: 34))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) { actions }
                VStack(spacing: 16) { actions }
            }
            Text("A grown-up can open Settings to make an optional AI picture from these ideas.")
                .font(.body).foregroundStyle(WishTheme.secondary).multilineTextAlignment(.center)
            Text("An idea to explore together. Availability and approval are decided separately.")
                .font(.body).foregroundStyle(WishTheme.secondary).multilineTextAlignment(.center)
        }
    }
    @ViewBuilder private var actions: some View {
        PrimaryWishButton(title: "Read my wish", symbol: "speaker.wave.2.fill") {
            store.say(store.draft.interest != nil ? store.draft.sceneDescription : store.draft.postcardDescription, explicit: true)
        }
        Button { store.stopSpeaking() } label: {
            Label("Stop speaking", systemImage: "speaker.slash.fill").font(.headline).padding(18).frame(minWidth: 44, minHeight: 44)
        }
        Button("Change my choices") { store.editJourney() }.font(.headline).padding(18)
        Button("Choose another wish") { store.step = .interests }.font(.headline).padding(18)
    }
}

struct SceneChoiceCollage: View {
    let draft: WishDraft
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 125), spacing: 12)], spacing: 12) {
            ForEach(draft.sceneChoices) { choice in
                VStack(spacing: 8) {
                    Text(choice.symbol).font(.system(size: 48)).accessibilityHidden(true)
                    Text(choice.label).font(.headline).multilineTextAlignment(.center)
                    if draft.essentialChoiceID == choice.id {
                        Label("Most important", systemImage: "heart.fill").font(.caption.weight(.semibold))
                    }
                }.frame(maxWidth: .infinity, minHeight: 125).padding(10)
                    .background(WishTheme.sky, in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityElement(children: .combine)
            }
        }
    }
}
