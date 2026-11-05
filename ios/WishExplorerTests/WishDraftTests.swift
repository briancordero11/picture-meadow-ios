import XCTest
@testable import WishExplorer

final class WishDraftTests: XCTestCase {
    func testChildCanPreviewWithoutChoosingPersonalization() {
        let draft = WishDraft(category: .go)
        XCTAssertTrue(draft.canPreview)
        XCTAssertFalse(draft.canRequestRemotePreview)
        XCTAssertEqual(draft.postcardDescription, "I wish to go to an amusement park.")
    }

    func testChangingWishCategoryRemovesUnrelatedParkChoices() {
        var draft = WishDraft(category: .go, destinationID: "disney-world", coasterColor: .pink, animals: [.tiger], wantsAnimals: true)
        draft.selectCategory(.meet)
        XCTAssertEqual(draft, WishDraft(category: .meet))
    }

    func testRechoosingSameCategoryKeepsChoices() {
        var draft = WishDraft(category: .go, coasterColor: .green)
        draft.selectCategory(.go)
        XCTAssertEqual(draft.coasterColor, .green)
    }

    func testAnimalChoiceTogglesWithoutDuplicates() {
        var draft = WishDraft()
        draft.toggleAnimal(.dolphin)
        draft.toggleAnimal(.tiger)
        draft.toggleAnimal(.dolphin)
        XCTAssertEqual(draft.animals, [.tiger])
    }

    func testSavedPreferencesRoundTrip() throws {
        let draft = WishDraft(category: .go, destinationID: "universal-orlando", coasterColor: .purple, animals: [.giraffe], wantsAnimals: true)
        XCTAssertEqual(try JSONDecoder().decode(WishDraft.self, from: JSONEncoder().encode(draft)), draft)
    }

    func testSummaryDoesNotInventUnchosenColor() {
        let draft = WishDraft(category: .go, destinationID: "disney-world")
        XCTAssertEqual(draft.postcardDescription, "I wish to go to Walt Disney World.")
        XCTAssertFalse(draft.postcardDescription.contains("roller coaster"))
    }

    func testOnlineDescriptionRequiresRecognizedParkColorAndGoCategory() {
        XCTAssertFalse(WishDraft(category: .meet).canPreview)
        XCTAssertFalse(WishDraft(category: .go, destinationID: "unknown-park", coasterColor: .pink).canRequestRemotePreview)
        XCTAssertFalse(WishDraft(category: .go, destinationID: "disney-world").canRequestRemotePreview)
        XCTAssertTrue(WishDraft(category: .go, destinationID: "disney-world", coasterColor: .blue).canRequestRemotePreview)
    }

    func testVocabularyRetainsAll54SourceConceptsWithoutDuplicateLabels() {
        XCTAssertEqual(CommunicationWord.all.count, 54)
        XCTAssertEqual(Set(CommunicationWord.all.map(\.id)).count, 54)
        for concept in ["Watch", "Wish", "More", "Wet", "Dry", "I need time to think", "I need a break", "Thank you!", "Finished"] {
            XCTAssertTrue(CommunicationWord.all.contains { $0.label == concept })
        }
    }

    @MainActor
    func testPreferencesAreNotRetainedUnlessCaregiverOptsIn() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.draft = WishDraft(category: .go, coasterColor: .blue)
        XCTAssertNil(defaults.data(forKey: "wish-explorer.preferences.v1"))
        store.rememberChoices = true
        XCTAssertNotNil(defaults.data(forKey: "wish-explorer.preferences.v1"))
        store.rememberChoices = false
        XCTAssertNil(defaults.data(forKey: "wish-explorer.preferences.v1"))
    }

    @MainActor
    func testSkipsClearPreviousAnswersRatherThanSilentlyKeepingThem() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.draft = WishDraft(category: .go, destinationID: "disney-world", coasterColor: .pink, animals: [.tiger], wantsAnimals: true)
        store.skipDestination()
        store.skipColor()
        store.skipAnimals()
        XCTAssertNil(store.draft.destinationID)
        XCTAssertNil(store.draft.coasterColor)
        XCTAssertNil(store.draft.wantsAnimals)
        XCTAssertTrue(store.draft.animals.isEmpty)
        XCTAssertEqual(store.step, .postcard)
    }

    @MainActor
    func testHelpMeChooseDoesNotReplaceAnExistingWish() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.readChoicesAloud = false
        store.draft = WishDraft(category: .go, coasterColor: .blue)
        store.choose(.helpChoose)
        XCTAssertEqual(store.draft.category, .go)
        XCTAssertEqual(store.draft.coasterColor, .blue)
        XCTAssertTrue(store.boardExpanded)
    }

    @MainActor
    func testOptedInDraftRestoresAndResetErasesStoredChoices() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = WishStore(defaults: defaults)
        original.rememberChoices = true
        original.draft = WishDraft(category: .go, destinationID: "disney-world", coasterColor: .green)
        original.phrase = ["I", "want"]
        let restored = WishStore(defaults: defaults)
        XCTAssertEqual(restored.draft, original.draft)
        XCTAssertTrue(restored.phrase.isEmpty)
        restored.reset()
        XCTAssertEqual(restored.draft, WishDraft())
        XCTAssertNil(defaults.data(forKey: "wish-explorer.preferences.v1"))
    }

    @MainActor
    func testFinishedReturnsHomeAndKeepsWishForLater() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.draft = WishDraft(category: .go, coasterColor: .blue)
        store.boardExpanded = true
        store.step = .animals
        store.finishSession()
        XCTAssertEqual(store.step, .welcome)
        XCTAssertEqual(store.draft.coasterColor, .blue)
        XCTAssertFalse(store.boardExpanded)
    }
}
