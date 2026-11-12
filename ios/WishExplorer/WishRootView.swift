import SwiftUI

@MainActor
struct WishRootView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var backTransition: BackTransition?

    private var pageLocation: PageLocation {
        PageLocation(step: store.step, journeyStage: store.journeyStage)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                header
                if store.step.progress > 0 && store.step != .journey {
                    ProgressView(value: store.step.progress)
                        .tint(WishTheme.blue).padding(.horizontal, 30)
                        .accessibilityLabel("Wish journey progress")
                }
                ScrollView {
                    TimelineView(.animation(paused: backTransition == nil)) { context in
                        let remaining = 1 - backProgress(at: context.date)
                        let easedRemaining = remaining * remaining * remaining
                        pageContent
                            .opacity(1 - 0.5 * easedRemaining)
                            .offset(x: CGFloat(-18 * easedRemaining))
                    }
                    .task(id: backTransition?.startedAt) { await finishBackTransition() }
                }
                .environment(\.wishBack, WishBackAction(perform: { navigateBack() }))
            }
            .background(WishTheme.background)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CommunicationBoardView(expandedHeight: min(geometry.size.height, max(280, geometry.size.height * 0.82)))
            }
            .disabled(store.isPaused)
            .accessibilityHidden(store.isPaused)
            .overlay {
                if store.isPaused { PauseView() }
            }
            .sheet(isPresented: $store.caregiverPresented, onDismiss: {
                store.endAdultSession()
                store.clearSettingsRequests()
            }) { AdultSettingsPortal() }
            .onChange(of: pageLocation) { _, destination in
                if let backTransition, backTransition.destination != destination { cancelBackTransition() }
            }
            .onChange(of: reduceMotion) { _, enabled in
                if enabled { cancelBackTransition() }
            }
            .onChange(of: store.caregiverPresented) { _, presented in
                if presented { cancelBackTransition() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { cancelBackTransition() }
                store.handleSceneActivity(phase == .active)
            }
            .onDisappear { cancelBackTransition() }
        }
    }

    private var pageContent: some View {
        Group {
            switch store.step {
            case .welcome: WelcomeView()
            case .interests: InterestView()
            case .destination: DestinationView()
            case .color: CoasterColorView()
            case .animals: AnimalChoiceView()
            case .postcard: PostcardView()
            case .otherWish: OtherWishView()
            case .journey: JourneyView()
            case .favoritesIntake: FavoritesIntakeView()
            }
        }
        .padding(30)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(spacing: sizeClass == .compact ? 6 : 16) {
            Button {
                cancelBackTransition()
                store.goHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .foregroundStyle(WishTheme.blue)
            .disabled(store.step == .interests)
            .opacity(store.step == .interests ? 0.45 : 1)
            .accessibilityLabel("Home")
            .accessibilityIdentifier("home-navigation")
            .accessibilityIdentifier("home-navigation")
            .accessibilityHint("Return to wish pictures and keep your choices")
            HStack(spacing: 9) {
                WishStar().fill(WishTheme.yellow).frame(width: sizeClass == .compact ? 20 : 30, height: sizeClass == .compact ? 20 : 30).accessibilityHidden(true)
                Text("wish explorer").font(sizeClass == .compact ? .headline : .title2.weight(.heavy)).foregroundStyle(WishTheme.ink)
            }.accessibilityElement(children: .combine)
            Spacer(minLength: 4)
            SettingsStarButton { store.caregiverPresented = true }
        }.padding(.horizontal, sizeClass == .compact ? 12 : 24).padding(.vertical, 16)
    }

    private func navigateBack() {
        cancelBackTransition()
        store.stopSpeaking()
        store.goBack()
        guard !reduceMotion, scenePhase == .active else { return }
        backTransition = BackTransition(destination: pageLocation, startedAt: .now)
    }

    private func backProgress(at date: Date) -> Double {
        guard let startedAt = backTransition?.startedAt else { return 1 }
        return min(1, max(0, date.timeIntervalSince(startedAt) / 0.30))
    }

    private func finishBackTransition() async {
        guard let startedAt = backTransition?.startedAt else { return }
        do { try await Task.sleep(for: .milliseconds(300)) }
        catch { return }
        guard !Task.isCancelled, backTransition?.startedAt == startedAt else { return }
        backTransition = nil
    }

    private func cancelBackTransition() {
        backTransition = nil
    }
}

private struct PageLocation: Equatable {
    let step: WishStep
    let journeyStage: Int
}

private struct BackTransition {
    let destination: PageLocation
    let startedAt: Date
}

struct WishBackAction: Sendable {
    let perform: @MainActor @Sendable () -> Void

    @MainActor func callAsFunction() { perform() }
}

private struct WishBackActionKey: EnvironmentKey {
    static let defaultValue = WishBackAction(perform: {})
}

extension EnvironmentValues {
    var wishBack: WishBackAction {
        get { self[WishBackActionKey.self] }
        set { self[WishBackActionKey.self] = newValue }
    }
}

struct WishBackButton: View {
    @Environment(\.wishBack) private var goBack

    var body: some View {
        Button { goBack() } label: {
            Label("Back", systemImage: "arrow.left")
                .font(.headline)
                .foregroundStyle(WishTheme.blue)
                .padding(.horizontal, 20).padding(.vertical, 14)
                .frame(minHeight: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(WishTheme.blue.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsStarButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            WishStar().fill(WishTheme.yellow)
                .overlay(WishStar().stroke(WishTheme.ink, lineWidth: 1.5))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-8))
                .frame(width: 48, height: 48)
                .background(.white, in: Circle())
                .contentShape(Rectangle())
                .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
        .accessibilityHint("Open grown-up settings")
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
            WishWordmark()
            Text("Tap a picture. Explore an idea.\nTake all the time you need.")
                .font(.title2).multilineTextAlignment(.center).foregroundStyle(WishTheme.secondary)
            PrimaryWishButton(title: "Create your wish", symbol: "sparkles") {
                store.step = .interests
                store.say("What would you like to wish for?")
            }.padding(.top, 8)
            if store.draft.interest != nil || store.draft.category != nil || !store.draft.favoriteIDs.isEmpty {
                Button("See my choices so far") {
                    store.step = store.draft.interest != nil || store.draft.category == .go ? .postcard : (store.draft.category != nil ? .otherWish : .interests)
                }
                    .font(.headline).padding(16)
            }
            Label("Open the little tab to tell us something.", systemImage: "chevron.up")
                .font(.body).foregroundStyle(WishTheme.secondary).padding(.top, 8)
        }.frame(maxWidth: .infinity).padding(.vertical, 10)
    }
}

struct InterestView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 8), count: sizeClass == .compact ? 2 : 4) }
    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 9) {
                WishWordmark()
                Text("What would you like? Choose a picture.").font(.title3).foregroundStyle(WishTheme.secondary)
            }.frame(maxWidth: .infinity)
            FavoritesIntakeCard()
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(InterestChoice.allCases) { interest in
                    PictureTile(label: interest.label, selected: store.draft.interest == interest) {
                        store.chooseInterest(interest)
                    }
                    .accessibilityHint("Choose actions and favorites for this idea")
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
            JourneyActions(next: "Let's add some color") { store.step = .color }
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
            JourneyActions(next: "What else do you like?") { store.step = .animals }
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
            JourneyActions(next: "See my wish picture") { store.step = .postcard }
        }
    }
}

struct JourneyActions: View {
    let next: String
    var action: () -> Void
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 24) { buttons }
            VStack(spacing: 12) { buttons }
        }.padding(.top, 10)
    }
    @ViewBuilder private var buttons: some View {
        WishBackButton()
        PrimaryWishButton(title: next, action: action)
    }
}

struct OtherWishView: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        VStack(spacing: 28) {
            ScreenHeading(eyebrow: "Your idea matters", title: store.draft.interest?.label ?? "My wish idea", subtitle: "Let's tell a grown-up more about this picture.")
            if let interest = store.draft.interest {
                PictureSymbol(label: interest.label).frame(height: 230).accessibilityLabel(interest.label)
            }
            Text("Open the little tab below. You can say what you like, what you don't like, or ask for more time.")
                .font(.title2).multilineTextAlignment(.center).foregroundStyle(WishTheme.ink)
            Button("Choose a different picture") { store.step = .interests }.font(.headline).padding(18)
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
