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

    func testVocabularySplits20InterestsAnd34CoreWithoutDuplicatingTopics() {
        XCTAssertEqual(CommunicationWord.all.count, 34)
        XCTAssertEqual(Set(CommunicationWord.all.map(\.id)).count, 34)
        XCTAssertEqual(InterestChoice.allCases.count, 20)
        let core = Set(CommunicationWord.all.map { PictureCatalog.normalized($0.label) })
        let interests = Set(InterestChoice.allCases.map { PictureCatalog.normalized($0.label) })
        XCTAssertTrue(core.isDisjoint(with: interests))
        XCTAssertEqual(core.union(interests).count, 54)
        for concept in ["Watch", "Wish", "More", "Wet", "Dry", "I need time to think", "I need a break", "Thank you!", "Finished"] {
            XCTAssertTrue(CommunicationWord.all.contains { $0.label == concept })
        }
    }

    func testCoreRowsKeepPronounsActionsAndQuestionsInFamiliarColumns() {
        let expected = [
            ["I", "Want", "See", "Wet", "More"],
            ["You", "Go", "Help", "Dry", "Where"],
            ["We", "Stop", "Act", "Hot", "What"],
            ["Watch", "Like", "Give", "Cold", "When"],
            ["Wish", "Eat", "Meet", "Tired", "Who"],
            ["Yes", "No / don't", "Finished", "Happy", "Why"]
        ]
        XCTAssertEqual(CommunicationWord.mainRows.map { $0.map(\.label) }, expected)
        XCTAssertEqual(CommunicationWord.mainRows.prefix(3).map { $0.first?.label }, ["I", "You", "We"])
        XCTAssertTrue(CommunicationWord.mainRows.allSatisfy { $0.count == 5 })
    }

    func testAgencyPhraseFooterHasFourAdjacentDistinctChoices() {
        XCTAssertEqual(CommunicationWord.phraseWords.map(\.label), ["This is fun!", "Thank you!", "I need time to think", "I need a break"])
        XCTAssertEqual(CommunicationWord.all.count, 34)
        XCTAssertEqual(Set(CommunicationWord.all.map(\.id)).count, 34)
        XCTAssertTrue(Set(CommunicationWord.mainRows.flatMap { $0 }.map(\.id))
            .isDisjoint(with: Set(CommunicationWord.phraseWords.map(\.id))))
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
    func testChoosingAnotherInterestClearsParkChoicesAndOpensItsJourney() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.readChoicesAloud = false
        store.draft = WishDraft(category: .go, interestID: "amusement-park", coasterColor: .blue)
        store.chooseInterest(.art)
        XCTAssertNil(store.draft.category)
        XCTAssertNil(store.draft.coasterColor)
        XCTAssertEqual(store.draft.interest, .art)
        XCTAssertEqual(store.step, .journey)
        XCTAssertFalse(store.boardExpanded)
    }

    @MainActor
    func testAmusementParkPictureOpensActionJourneyAndPreservesGoAPIContract() throws {
        let suite = "WishExplorerTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults)
        store.readChoicesAloud = false
        store.chooseInterest(.amusementPark)
        XCTAssertEqual(store.draft.category, .go)
        XCTAssertEqual(store.draft.interest, .amusementPark)
        XCTAssertEqual(store.step, .journey)
    }

    func testEveryPictureHasTheOriginalBundledSymbol() {
        XCTAssertEqual(PictureCatalog.shared.items.count, 54)
        for interest in InterestChoice.allCases {
            XCTAssertNotNil(PictureCatalog.shared.image(label: interest.label), interest.label)
        }
        for word in CommunicationWord.all {
            XCTAssertNotNil(PictureCatalog.shared.image(label: word.label), word.label)
        }
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
