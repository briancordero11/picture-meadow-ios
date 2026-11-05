import SwiftUI
import AVFoundation

@MainActor
final class WishStore: ObservableObject {
    @Published var draft: WishDraft { didSet { saveDraft() } }
    @Published var step: WishStep = .welcome
    @Published var boardExpanded = false
    @Published var boardGroup: CommunicationWord.Group = .people
    @Published var phrase: [String] = []
    @Published var isPaused = false
    @Published var caregiverPresented = false
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

    private let defaults: UserDefaults
    private let synthesizer = AVSpeechSynthesizer()
    private static let draftKey = "wish-explorer.preferences.v1"
    private static let speechKey = "wish-explorer.speech.v1"
    private static let rememberKey = "wish-explorer.remember.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

    func choose(_ category: WishCategory) {
        if category == .helpChoose {
            boardExpanded = true
            boardGroup = .wishes
            say("Let's explore together")
            return
        }
        draft.selectCategory(category)
        invalidatePreview()
        say(category.title)
        if category == .go { step = .destination }
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

    func quickMessage(_ message: String) {
        say(message, explicit: true)
        if message == "I need a break" || message == "Stop" { isPaused = true }
    }

    func finishSession() {
        say("I am finished", explicit: true)
        boardExpanded = false
        isPaused = false
        step = .welcome
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
        remoteDescription = nil
        remoteStatus = nil
    }

    func requestRemotePreview() async {
        guard draft.canRequestRemotePreview, !isLoadingPreview else { return }
        let snapshot = draft
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        do {
            let preview = try await WishAPIClient().createPreview(for: snapshot)
            guard draft == snapshot else { return }
            remoteDescription = preview.description
            remoteStatus = "Wish description refreshed. Your picture stays on this iPad."
        } catch {
            guard draft == snapshot else { return }
            remoteStatus = "Your wish is still here. The online description is unavailable; your picture works offline."
        }
    }

    private func saveDraft() {
        guard rememberChoices, let data = try? JSONEncoder().encode(draft) else { return }
        defaults.set(data, forKey: Self.draftKey)
    }
}
