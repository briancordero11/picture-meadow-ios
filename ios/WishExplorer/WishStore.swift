import SwiftUI
import AVFoundation

@MainActor
final class WishStore: ObservableObject {
    @Published var draft: WishDraft { didSet { saveDraft() } }
    @Published var step: WishStep = .welcome
    @Published var boardExpanded = false
    @Published var phrase: [String] = []
    @Published var isPaused = false
    @Published var caregiverPresented = false
    @Published var privacyPresented = false
    @Published private(set) var adultSessionActive = false
    @Published var readChoicesAloud: Bool {
        didSet { defaults.set(readChoicesAloud, forKey: Self.speechKey) }
    }
    @Published var rememberChoices: Bool {
        didSet {
            defaults.set(rememberChoices, forKey: Self.rememberKey)
            if rememberChoices { saveDraft() } else { defaults.removeObject(forKey: Self.draftKey) }
        }
    }
    @Published var remoteDescription: String?
    @Published var remoteStatus: String?
    @Published var isLoadingPreview = false

    let configuration: WishBuildConfiguration
    private let previewService: any WishPreviewServicing
    private var pendingOnlineDisclosure: OnlinePreviewDisclosure?
    private var onlineTask: Task<Void, Never>?
    private var activeOnlineRequestID: UUID?
    private var authorizationEpoch = UUID()
    private var sceneIsActive = true

    private let defaults: UserDefaults
    private let synthesizer = AVSpeechSynthesizer()
    private static let draftKey = "wish-explorer.preferences.v1"
    private static let speechKey = "wish-explorer.speech.v1"
    private static let rememberKey = "wish-explorer.remember.v1"

    init(defaults: UserDefaults = .standard,
         configuration: WishBuildConfiguration = .current,
         previewService: (any WishPreviewServicing)? = nil) {
        self.defaults = defaults
        self.configuration = configuration
        self.previewService = previewService ?? WishAPIClient(configuration: configuration)
        readChoicesAloud = defaults.object(forKey: Self.speechKey) as? Bool ?? true
        let shouldRemember = defaults.bool(forKey: Self.rememberKey)
        rememberChoices = shouldRemember
        if shouldRemember, let data = defaults.data(forKey: Self.draftKey),
           let saved = try? JSONDecoder().decode(WishDraft.self, from: data) {
            draft = saved
        } else { draft = WishDraft() }
    }

    func say(_ text: String, explicit: Bool = false) {
        guard readChoicesAloud || explicit else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.40
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    func stopSpeaking() { synthesizer.stopSpeaking(at: .immediate) }

    func chooseInterest(_ interest: InterestChoice) {
        draft.selectInterest(interest)
        invalidatePreview()
        say(interest.label)
        if phrase.count < 12 { phrase.append(interest.label) }
        boardExpanded = false
        if interest == .amusementPark { step = .destination }
        else { step = .otherWish }
    }

    func setDestination(_ destination: WishDestination) {
        draft.destinationID = destination.id
        invalidatePreview()
        say(destination.name)
    }

    func setColor(_ color: CoasterColor) {
        draft.coasterColor = color
        invalidatePreview()
        say(color.label)
    }

    func toggleAnimal(_ animal: WishAnimal) {
        draft.wantsAnimals = true
        draft.toggleAnimal(animal)
        invalidatePreview()
        say(animal.label)
    }

    func noAnimals() {
        draft.wantsAnimals = false
        draft.animals = []
        invalidatePreview()
        say("No animals")
    }

    func addWord(_ word: CommunicationWord) {
        if phrase.count < 12 { phrase.append(word.speech) }
        if word.label == "Finished" { finishSession(); return }
        say(word.speech, explicit: true)
        if word.label == "I need a break" || word.label == "Stop" { isPaused = true }
    }

    func finishSession() {
        say("I am finished", explicit: true)
        boardExpanded = false
        isPaused = false
        step = .welcome
        phrase = []
    }

    func skipDestination() {
        draft.destinationID = nil
        invalidatePreview()
        step = .color
    }

    func skipColor() {
        draft.coasterColor = nil
        invalidatePreview()
        step = .animals
    }

    func skipAnimals() {
        draft.wantsAnimals = nil
        draft.animals = []
        invalidatePreview()
        step = .postcard
    }

    func reset() {
        cancelNetworkWork()
        stopSpeaking()
        draft = WishDraft()
        defaults.removeObject(forKey: Self.draftKey)
        phrase = []
        boardExpanded = false
        isPaused = false
        step = .welcome
        invalidatePreview()
    }

    func invalidatePreview() {
        cancelNetworkWork()
        remoteDescription = nil
        remoteStatus = nil
    }

    func beginAdultSession() {
        guard caregiverPresented, sceneIsActive else { return }
        endAdultSession()
        adultSessionActive = true
    }

    func endAdultSession() {
        adultSessionActive = false
        authorizationEpoch = UUID()
        cancelNetworkWork()
    }

    func handleSceneActivity(_ isActive: Bool) {
        sceneIsActive = isActive
        if !isActive {
            endAdultSession()
            caregiverPresented = false
            phrase = []
            stopSpeaking()
        }
    }

    func forgetAllChoices() {
        rememberChoices = false
        readChoicesAloud = true
        defaults.removeObject(forKey: Self.rememberKey)
        defaults.removeObject(forKey: Self.speechKey)
        reset()
        endAdultSession()
        caregiverPresented = false
    }

    var onlinePreviewAvailable: Bool { configuration.onlinePreviewAvailable }

    func prepareOnlinePreview() -> OnlinePreviewDisclosure? {
        guard adultSessionActive, sceneIsActive, configuration.onlinePreviewAvailable,
              draft.canRequestRemotePreview, !isLoadingPreview,
              let host = configuration.apiBaseURL?.host else { return nil }
        let disclosure = OnlinePreviewDisclosure(id: UUID(), draft: draft, serviceHost: host)
        pendingOnlineDisclosure = disclosure
        return disclosure
    }

    func cancelOnlineConfirmation(_ id: UUID) {
        if pendingOnlineDisclosure?.id == id { pendingOnlineDisclosure = nil }
    }

    @discardableResult
    func confirmOnlinePreview(_ id: UUID) -> Bool {
        guard adultSessionActive, sceneIsActive, configuration.onlinePreviewAvailable,
              !isLoadingPreview, let disclosure = pendingOnlineDisclosure,
              disclosure.id == id, disclosure.draft == draft else { return false }
        pendingOnlineDisclosure = nil
        activeOnlineRequestID = id
        isLoadingPreview = true
        let epoch = authorizationEpoch
        onlineTask = Task { [weak self] in
            guard let self else { return }
            await self.performOnlinePreview(disclosure, epoch: epoch)
        }
        return true
    }

    private func performOnlinePreview(_ disclosure: OnlinePreviewDisclosure, epoch: UUID) async {
        defer {
            if activeOnlineRequestID == disclosure.id {
                activeOnlineRequestID = nil
                isLoadingPreview = false
                onlineTask = nil
            }
        }
        guard !Task.isCancelled, adultSessionActive, sceneIsActive,
              authorizationEpoch == epoch, activeOnlineRequestID == disclosure.id,
              draft == disclosure.draft else { return }
        do {
            let preview = try await previewService.createPreview(for: disclosure.draft)
            guard !Task.isCancelled, adultSessionActive, sceneIsActive,
                  authorizationEpoch == epoch, activeOnlineRequestID == disclosure.id,
                  draft == disclosure.draft else { return }
            remoteDescription = preview.description
            remoteStatus = "Wish description refreshed. Your picture stays on this iPad."
        } catch {
            guard !Task.isCancelled, adultSessionActive, sceneIsActive,
                  authorizationEpoch == epoch, activeOnlineRequestID == disclosure.id,
                  draft == disclosure.draft else { return }
            remoteStatus = "Your wish is still here. The online description is unavailable; your picture works offline."
        }
    }

    private func cancelNetworkWork() {
        pendingOnlineDisclosure = nil
        onlineTask?.cancel()
        onlineTask = nil
        activeOnlineRequestID = nil
        isLoadingPreview = false
    }

    private func saveDraft() {
        guard rememberChoices, let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: Self.draftKey)
    }
}
