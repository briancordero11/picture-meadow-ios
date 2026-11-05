import SwiftUI

struct WishRootView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                if store.step.progress > 0 {
                    ProgressView(value: store.step.progress)
                        .tint(WishTheme.blue).padding(.horizontal, 30)
                        .accessibilityLabel("Wish journey progress")
                }
                ScrollView {
                    Group {
                        switch store.step {
                        case .welcome: WelcomeView()
                        case .categories: CategoryView()
                        case .destination: DestinationView()
                        case .color: CoasterColorView()
                        case .animals: AnimalChoiceView()
                        case .postcard: PostcardView()
                        case .otherWish: OtherWishView()
                        }
                    }
                    .padding(30)
                    .frame(maxWidth: 1100)
                    .frame(maxWidth: .infinity)
                }
            }
            .background(WishTheme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CommunicationBoardView()
                    .frame(maxHeight: store.boardExpanded ? max(280, geometry.size.height * 0.52) : nil)
            }
            .disabled(store.isPaused)
            .accessibilityHidden(store.isPaused)
            .overlay {
                if store.isPaused { PauseView() }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.boardExpanded)
            .sheet(isPresented: $store.caregiverPresented) { CaregiverView() }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            if store.step != .welcome {
                Button {
                    store.stopSpeaking()
                    store.step = store.step.previous
                } label: {
                    Label("Back", systemImage: "arrow.left").font(.headline).padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(WishTheme.blue)
                }.buttonStyle(.plain)
            }
            HStack(spacing: 9) {
                WishStar().fill(WishTheme.yellow).frame(width: 30, height: 30).accessibilityHidden(true)
                Text("wish explorer").font(.title2.weight(.heavy)).foregroundStyle(WishTheme.ink)
            }.accessibilityElement(children: .combine)
            Spacer(minLength: 4)
            Button { store.caregiverPresented = true } label: {
                Label("Grown-ups", systemImage: "person.crop.circle")
                    .font(.subheadline.weight(.semibold)).padding(14)
            }.buttonStyle(.plain).foregroundStyle(WishTheme.secondary)
        }.padding(.horizontal, 24).padding(.vertical, 16)
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle().fill(WishTheme.sky).frame(width: 200, height: 200)
                WishStar().fill(WishTheme.yellow).frame(width: 110, height: 110).rotationEffect(.degrees(-12))
                Image(systemName: "sparkle").font(.system(size: 32)).foregroundStyle(WishTheme.blue).offset(x: 90, y: -65)
            }.padding(.top, 16).accessibilityHidden(true)
            Text("Big dreams.\nYour way.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center).foregroundStyle(WishTheme.ink)
            Text("Tap a picture. Explore an idea.\nTake all the time you need.")
                .font(.title2).multilineTextAlignment(.center).foregroundStyle(WishTheme.secondary)
            PrimaryWishButton(title: "Create your wish", symbol: "sparkles") {
                store.step = .categories
                store.say("What would you like to wish for?")
            }.padding(.top, 8)
            if store.draft.category != nil {
                Button("See my choices so far") { store.step = .postcard }
                    .font(.headline).padding(16)
            }
            Label("You can tell us yes, no, or take a break anytime.", systemImage: "hand.wave.fill")
                .font(.body).foregroundStyle(WishTheme.secondary).padding(.top, 8)
        }.frame(maxWidth: .infinity).padding(.vertical, 10)
    }
}

struct CategoryView: View {
    @EnvironmentObject private var store: WishStore
    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 20)]
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "A little imagination", title: "Create your wish", subtitle: "What sounds wonderful to you?")
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(WishCategory.allCases) { category in
                    ChoiceCard(selected: store.draft.category == category, background: WishTheme.categoryColor(category)) {
                        store.choose(category)
                    } content: {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: category.symbol).font(.system(size: 43)).foregroundStyle(WishTheme.blue).accessibilityHidden(true)
                            Text(category.title).font(.title2.weight(.bold)).foregroundStyle(WishTheme.ink)
                            Text(category.subtitle).font(.body).foregroundStyle(WishTheme.secondary)
                        }.frame(maxWidth: .infinity, alignment: .leading)
                    }.accessibilityHint(category == .go ? "Explore an amusement park idea" : "Explore this wish idea with a grown-up")
                }
            }
        }
    }
}

struct DestinationView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "I wish to go", title: "An amusement park adventure", subtitle: "Here are some ideas. Which one would you like to explore?")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 235), spacing: 20)], spacing: 20) {
                ForEach(WishDestination.all) { destination in
                    ChoiceCard(selected: store.draft.destinationID == destination.id, background: .white) {
                        store.setDestination(destination)
                    } content: {
                        VStack(spacing: 16) {
                            ParkIllustration(color: WishTheme.blue, compact: true).frame(height: 125).accessibilityHidden(true)
                            Text(destination.name).font(.title3.weight(.bold)).multilineTextAlignment(.center)
                            Text(destination.location).foregroundStyle(WishTheme.secondary)
                        }.foregroundStyle(WishTheme.ink)
                    }
                }
            }
            JourneyActions(next: "Let's add some color", skip: "I'm not sure yet", skipAction: store.skipDestination) { store.step = .color }
        }
    }
}

struct CoasterColorView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "Make it yours", title: "Pick a roller coaster color", subtitle: "This is your imaginary picture. Any color is okay.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 20)], spacing: 20) {
                ForEach(CoasterColor.allCases) { color in
                    ChoiceCard(selected: store.draft.coasterColor == color, background: .white) {
                        store.setColor(color)
                    } content: {
                        VStack(spacing: 18) {
                            ParkIllustration(color: WishTheme.color(for: color), compact: true).frame(height: 130).accessibilityHidden(true)
                            Text(color.label).font(.title2.weight(.bold)).foregroundStyle(WishTheme.ink)
                        }
                    }.accessibilityLabel("\(color.label) roller coaster")
                }
            }
            JourneyActions(next: "What else do you like?", skip: "Skip color for now", skipAction: store.skipColor) { store.step = .animals }
        }
    }
}

struct AnimalChoiceView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "More things I like", title: "Would you like to see animals?", subtitle: "You can choose more than one, or none at all.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 20)], spacing: 20) {
                ForEach(WishAnimal.allCases) { animal in
                    ChoiceCard(selected: store.draft.animals.contains(animal), background: .white) {
                        store.toggleAnimal(animal)
                    } content: {
                        VStack(spacing: 16) {
                            Text(animal.emoji).font(.system(size: 72)).accessibilityHidden(true)
                            Text(animal.label).font(.title2.weight(.bold)).foregroundStyle(WishTheme.ink)
                        }
                    }
                }
                ChoiceCard(selected: store.draft.wantsAnimals == false, background: WishTheme.sky) {
                    store.noAnimals()
                } content: {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised.fill").font(.system(size: 58)).foregroundStyle(WishTheme.blue).accessibilityHidden(true)
                        Text("No animals").font(.title2.weight(.bold)).foregroundStyle(WishTheme.ink)
                    }
                }
            }
            Text("Animal ideas can be a separate adventure. They might not be at the park you chose.")
                .font(.body).foregroundStyle(WishTheme.secondary)
            JourneyActions(next: "See my wish picture", skip: "Skip animals for now", skipAction: store.skipAnimals) { store.step = .postcard }
        }
    }
}

struct JourneyActions: View {
    let next: String
    let skip: String
    var skipAction: () -> Void
    var action: () -> Void
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) { buttons }
            VStack(spacing: 12) { buttons }
        }.padding(.top, 10)
    }
    @ViewBuilder private var buttons: some View {
        PrimaryWishButton(title: next, action: action)
        Button(skip, action: skipAction).font(.headline).padding(18).frame(minHeight: 64)
    }
}

struct OtherWishView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "Your idea matters", title: store.draft.category?.title ?? "My wish", subtitle: "Let's tell a grown-up more about this idea.")
            Image(systemName: store.draft.category?.symbol ?? "star.fill")
                .font(.system(size: 100)).foregroundStyle(WishTheme.blue).padding(35).accessibilityHidden(true)
            Text("Use the talking board below. You can say what you like, what you don't like, or ask for more time.")
                .font(.title2).multilineTextAlignment(.center).foregroundStyle(WishTheme.ink)
            PrimaryWishButton(title: "Open talking board", symbol: "bubble.left.and.bubble.right.fill") {
                store.boardExpanded = true
                store.boardGroup = .wishes
            }
            Button("Explore an amusement park idea") { store.choose(.go) }.font(.headline).padding(18)
        }
    }
}

struct PauseView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        ZStack {
            WishTheme.background.ignoresSafeArea()
            VStack(spacing: 28) {
                Image(systemName: "moon.stars.fill").font(.system(size: 84)).foregroundStyle(WishTheme.blue).accessibilityHidden(true)
                Text("Let's take a break").font(.largeTitle.weight(.bold)).foregroundStyle(WishTheme.ink)
                Text("There is no hurry. Your choices will be right here.")
                    .font(.title2).multilineTextAlignment(.center).foregroundStyle(WishTheme.secondary)
                PrimaryWishButton(title: "I'm ready", symbol: "play.fill") { store.isPaused = false }
                Button("Finished for now") { store.finishSession() }.font(.headline).padding(20)
            }.padding(40)
        }.accessibilityAddTraits(.isModal)
    }
}
