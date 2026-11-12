import SwiftUI
import AVFoundation

@MainActor
final class WishStore: ObservableObject {
    @Published var draft: WishDraft { didSet { saveDraft() } }
    @Published var step: WishStep = .welcome
    @Published var journeyStage = 0
    @Published var boardExpanded = false
    @Published var phrase: [String] = []
    @Published var isPaused = false
    @Published var caregiverPresented = false
    @Published var privacyPresented = false
    @Published var aiReportRequested = false
    @Published var aiGenerationRequested = false
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
    @Published private(set) var isGeneratingScene = false
    @Published private(set) var sceneAccessConfigured = false
    @Published private(set) var pendingGeneratedScene: GeneratedWishScene?
    @Published private(set) var generatedScene: GeneratedWishScene?
    @Published private(set) var sceneStatus: String?

    let configuration: WishBuildConfiguration
    private let previewService: any WishPreviewServicing
    private let sceneService: any WishSceneServicing
    private var sceneAccessToken: String?
    private var pendingSceneDisclosure: SceneGenerationDisclosure?
    private var generatedSceneDraft: WishDraft?
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
         previewService: (any WishPreviewServicing)? = nil,
         sceneService: (any WishSceneServicing)? = nil,
         sceneAccessToken: String? = SceneAccessKeychain.read()) {
        self.defaults = defaults
        self.configuration = configuration
        self.previewService = previewService ?? WishAPIClient(configuration: configuration)
        self.sceneService = sceneService ?? WishSceneClient(configuration: configuration)
        self.sceneAccessToken = sceneAccessToken
        sceneAccessConfigured = sceneAccessToken != nil
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
        journeyStage = 0
        step = .journey
    }

    func goBack() {
        stopSpeaking()
        if step == .journey, journeyStage > 0 { journeyStage -= 1 }
        else if step == .postcard, draft.interest != nil { journeyStage = 3; step = .journey }
        else { step = step.previous }
    }

    func toggleJourneyAction(_ id: String) {
        guard let topic = JourneyCatalog.shared.interest(id: draft.interestID), topic.actions.contains(where: { $0.id == id }) else { return }
        if draft.selectedActionIDs.contains(id) { draft.selectedActionIDs.removeAll { $0 == id } }
        else if draft.selectedActionIDs.count < 3 { draft.selectedActionIDs.append(id) }
        else { say("Choose up to three, or remove one first"); return }
        sanitizeEssential(); invalidatePreview(); say(JourneyCatalog.shared.choice(id: id)?.label ?? "")
    }
    func selectJourneySetting(_ id: String) {
        guard let topic = JourneyCatalog.shared.interest(id: draft.interestID), topic.settings.contains(where: { $0.id == id }) else { return }
        draft.selectedSettingID = draft.selectedSettingID == id ? nil : id
        sanitizeEssential(); invalidatePreview(); say(JourneyCatalog.shared.choice(id: id)?.label ?? "")
    }
    func toggleFavorite(_ id: String) {
        guard JourneyCatalog.shared.favoriteOptions.contains(where: { $0.id == id }) else { return }
        if draft.favoriteIDs.contains(id) { draft.favoriteIDs.removeAll { $0 == id } }
        else if draft.favoriteIDs.count < 10 { draft.favoriteIDs.append(id) }
        else { say("Choose up to ten favorites, or remove one first"); return }
        sanitizeEssential(); invalidatePreview(); say(JourneyCatalog.shared.choice(id: id)?.label ?? "")
    }
    func selectEssential(_ id: String) {
        guard draft.sceneChoices.contains(where: { $0.id == id }) else { return }
        draft.essentialChoiceID = draft.essentialChoiceID == id ? nil : id
        invalidatePreview(); say(JourneyCatalog.shared.choice(id: id)?.label ?? "")
    }
    private func sanitizeEssential() {
        if let id = draft.essentialChoiceID, !draft.sceneChoices.contains(where: { $0.id == id }) { draft.essentialChoiceID = nil }
    }
    func advanceJourney() {
        stopSpeaking()
        if journeyStage < 3 { journeyStage += 1 } else { step = .postcard }
    }
    func skipJourneyStage() {
        switch journeyStage {
        case 0: draft.selectedActionIDs = []
        case 1: draft.selectedSettingID = nil
        case 2: draft.favoriteIDs = []
        default: draft.essentialChoiceID = nil
        }
        sanitizeEssential(); invalidatePreview(); advanceJourney()
    }
    func editJourney() {
        journeyStage = 0
        step = draft.interest != nil ? .journey : (draft.category == .go ? .destination : .interests)
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
        journeyStage = 0
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
        clearSettingsRequests()
        journeyStage = 0
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
        pendingGeneratedScene = nil
        generatedScene = nil
        generatedSceneDraft = nil
        sceneStatus = nil
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
        pendingGeneratedScene = nil
    }

    func handleSceneActivity(_ isActive: Bool) {
        sceneIsActive = isActive
        if !isActive {
            clearSettingsRequests()
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
        SceneAccessKeychain.remove()
        sceneAccessToken = nil
        sceneAccessConfigured = false
        endAdultSession()
        caregiverPresented = false
    }

    var onlinePreviewAvailable: Bool { configuration.onlinePreviewAvailable }

    func prepareOnlinePreview() -> OnlinePreviewDisclosure? {
        guard adultSessionActive, sceneIsActive, configuration.onlinePreviewAvailable,
              draft.canRequestRemotePreview, !isLoadingPreview, !isGeneratingScene,
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
              !isLoadingPreview, !isGeneratingScene, let disclosure = pendingOnlineDisclosure,
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
        pendingSceneDisclosure = nil
        onlineTask?.cancel()
        onlineTask = nil
        activeOnlineRequestID = nil
        isLoadingPreview = false
        isGeneratingScene = false
    }

    var sceneGenerationAvailable: Bool { configuration.sceneGenerationAvailable && sceneAccessConfigured }

    @discardableResult func saveSceneAccess(_ token: String) -> Bool {
        guard adultSessionActive, sceneIsActive, SceneAccessKeychain.save(token) else { return false }
        cancelNetworkWork(); sceneAccessToken = token; sceneAccessConfigured = true
        return true
    }
    func removeSceneAccess() {
        guard adultSessionActive else { return }
        cancelNetworkWork(); SceneAccessKeychain.remove(); sceneAccessToken = nil; sceneAccessConfigured = false
    }
    func prepareSceneGeneration() -> SceneGenerationDisclosure? {
        guard adultSessionActive, sceneIsActive, sceneGenerationAvailable, draft.canRequestScene,
              !isGeneratingScene, !isLoadingPreview, let host = configuration.apiBaseURL?.host,
              let provider = configuration.aiProviderName else { return nil }
        let disclosure = SceneGenerationDisclosure(id: UUID(), draft: draft, serviceHost: host, providerName: provider)
        pendingSceneDisclosure = disclosure
        return disclosure
    }
    func cancelSceneConfirmation(_ id: UUID) {
        if pendingSceneDisclosure?.id == id { pendingSceneDisclosure = nil }
    }
    @discardableResult func confirmSceneGeneration(_ id: UUID) -> Bool {
        guard adultSessionActive, sceneIsActive, sceneGenerationAvailable, !isGeneratingScene, !isLoadingPreview,
              let disclosure = pendingSceneDisclosure, disclosure.id == id, disclosure.draft == draft,
              let token = sceneAccessToken else { return false }
        pendingSceneDisclosure = nil; pendingGeneratedScene = nil; generatedSceneDraft = nil
        activeOnlineRequestID = id; isGeneratingScene = true
        sceneStatus = "Making a picture. You can cancel and keep your picture board."
        let epoch = authorizationEpoch
        onlineTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.activeOnlineRequestID == id { self.activeOnlineRequestID = nil; self.isGeneratingScene = false; self.onlineTask = nil }
            }
            guard !Task.isCancelled, self.adultSessionActive, self.sceneIsActive,
                  self.authorizationEpoch == epoch, self.activeOnlineRequestID == id, self.draft == disclosure.draft else { return }
            do {
                let scene = try await self.sceneService.generateScene(for: disclosure.draft, accessToken: token)
                guard !Task.isCancelled, self.adultSessionActive, self.sceneIsActive,
                      self.authorizationEpoch == epoch, self.activeOnlineRequestID == id, self.draft == disclosure.draft else { return }
                self.pendingGeneratedScene = scene; self.generatedSceneDraft = disclosure.draft
                self.sceneStatus = "Review the picture before showing it to your Super Star."
            } catch {
                guard !Task.isCancelled, self.adultSessionActive, self.sceneIsActive,
                      self.authorizationEpoch == epoch, self.activeOnlineRequestID == id, self.draft == disclosure.draft else { return }
                self.sceneStatus = "We couldn't make this picture. Your picture board is still here. Try again with a new confirmation, or keep exploring offline."
            }
        }
        return true
    }
    func cancelSceneGeneration() {
        cancelNetworkWork(); sceneStatus = "Picture making stopped. Your picture board is still here."
    }
    func approveGeneratedScene() {
        guard adultSessionActive, generatedSceneDraft == draft, let scene = pendingGeneratedScene else { return }
        generatedScene = scene; pendingGeneratedScene = nil
        sceneStatus = "AI picture added to this wish. You can remove it at any time."
    }
    func discardGeneratedScene() {
        pendingGeneratedScene = nil; generatedScene = nil; generatedSceneDraft = nil
        sceneStatus = "AI picture removed. Your chosen pictures are still here."
    }

    func requestAIReport() {
        stopSpeaking()
        aiGenerationRequested = false
        aiReportRequested = true
        caregiverPresented = true
    }

    func requestAIPicture() {
        stopSpeaking()
        aiReportRequested = false
        aiGenerationRequested = true
        caregiverPresented = true
    }

    func clearSettingsRequests() {
        aiReportRequested = false
        aiGenerationRequested = false
    }

    private func saveDraft() {
        guard rememberChoices, let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: Self.draftKey)
    }
}
