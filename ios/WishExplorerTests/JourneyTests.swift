import XCTest
@testable import WishExplorer

final class JourneyTests: XCTestCase {
    func testBundledCatalogHasCompleteDistinctChoicesForAllTwentyInterests() throws {
        let catalog = try JourneyCatalog.load()
        XCTAssertEqual(catalog.version, 1)
        XCTAssertEqual(catalog.interests.count, 20)
        XCTAssertEqual(Set(catalog.interests.map(\.id)), Set(InterestChoice.allCases.map(\.id)))
        var identifiers = Set<String>()
        for topic in catalog.interests {
            XCTAssertGreaterThan(topic.actions.count, 3, topic.id)
            XCTAssertFalse(topic.settings.isEmpty, topic.id)
            for choice in topic.actions + topic.settings {
                XCTAssertTrue(identifiers.insert(choice.id).inserted, choice.id)
                XCTAssertFalse(choice.label.isEmpty, choice.id)
                XCTAssertFalse(choice.symbol.isEmpty, choice.id)
                XCTAssertFalse(choice.prompt.isEmpty, choice.id)
            }
        }
        XCTAssertGreaterThan(catalog.favoriteOptions.count, 10)
        for choice in catalog.favoriteOptions {
            XCTAssertTrue(identifiers.insert(choice.id).inserted, choice.id)
            XCTAssertFalse(choice.label.isEmpty, choice.id)
            XCTAssertFalse(choice.symbol.isEmpty, choice.id)
            XCTAssertFalse(choice.prompt.isEmpty, choice.id)
        }
    }

    @MainActor
    func testEveryInterestCanReachPostcardWithoutAnsweringOptionalStages() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        for interest in InterestChoice.allCases {
            store.journeyStage = 3
            store.boardExpanded = true
            store.chooseInterest(interest)
            XCTAssertEqual(store.step, .journey, interest.id)
            XCTAssertEqual(store.journeyStage, 0, interest.id)
            XCTAssertFalse(store.boardExpanded, interest.id)
            for _ in 0..<4 { store.skipJourneyStage() }
            XCTAssertEqual(store.step, .postcard, interest.id)
            XCTAssertEqual(store.draft.interest, interest)
            XCTAssertFalse(store.draft.canRequestScene, interest.id)
        }
    }

    @MainActor
    func testOldSavedDraftMigratesWithUnansweredNewJourneyChoices() throws {
        let storage = try JourneyTestStorage()
        let data = Data(#"{"category":"go","interestID":"amusement-park","destinationID":"disney-world","coasterColor":"blue","animals":["tiger"],"wantsAnimals":true}"#.utf8)
        storage.defaults.set(true, forKey: "wish-explorer.remember.v1")
        storage.defaults.set(data, forKey: "wish-explorer.preferences.v1")
        let store = makeStore(storage)
        XCTAssertEqual(store.draft.destinationID, "disney-world")
        XCTAssertEqual(store.draft.coasterColor, .blue)
        XCTAssertEqual(store.draft.animals, [.tiger])
        XCTAssertTrue(store.draft.selectedActionIDs.isEmpty)
        XCTAssertNil(store.draft.selectedSettingID)
        XCTAssertTrue(store.draft.favoriteIDs.isEmpty)
        XCTAssertNil(store.draft.essentialChoiceID)
        XCTAssertFalse(store.draft.canRequestScene)
    }

    @MainActor
    func testActionsAreLimitedToThreeAndCanBeReplaced() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        let topic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.art.id))
        store.chooseInterest(.art)
        for choice in topic.actions { store.toggleJourneyAction(choice.id) }
        XCTAssertEqual(store.draft.selectedActionIDs, Array(topic.actions.prefix(3).map(\.id)))
        store.toggleJourneyAction(topic.actions[0].id)
        store.toggleJourneyAction(topic.actions[3].id)
        XCTAssertEqual(store.draft.selectedActionIDs, [topic.actions[1].id, topic.actions[2].id, topic.actions[3].id])
        store.toggleJourneyAction("unknown-action")
        let otherTopic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.camp.id))
        store.toggleJourneyAction(otherTopic.actions[0].id)
        XCTAssertEqual(store.draft.selectedActionIDs.count, 3)
        XCTAssertFalse(store.draft.selectedActionIDs.contains(otherTopic.actions[0].id))
    }

    @MainActor
    func testFavoritesAreLimitedToTenAndCanBeReplaced() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        store.chooseInterest(.art)
        let favorites = JourneyCatalog.shared.favoriteOptions
        for choice in favorites.prefix(11) { store.toggleFavorite(choice.id) }
        XCTAssertEqual(store.draft.favoriteIDs, Array(favorites.prefix(10).map(\.id)))
        store.toggleFavorite(favorites[0].id)
        store.toggleFavorite(favorites[10].id)
        XCTAssertEqual(store.draft.favoriteIDs.count, 10)
        XCTAssertFalse(store.draft.favoriteIDs.contains(favorites[0].id))
        XCTAssertTrue(store.draft.favoriteIDs.contains(favorites[10].id))
        store.toggleFavorite("unknown-favorite")
        XCTAssertEqual(store.draft.favoriteIDs.count, 10)
    }

    @MainActor
    func testEssentialChoiceMustBeSelectedAndClearsWhenItsChoiceIsRemoved() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        store.chooseInterest(.art)
        let topic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.art.id))
        let action = topic.actions[0].id
        let setting = topic.settings[0].id
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        store.selectEssential(action)
        XCTAssertNil(store.draft.essentialChoiceID)
        store.toggleJourneyAction(action)
        store.selectEssential(action)
        XCTAssertEqual(store.draft.essentialChoiceID, action)
        store.toggleFavorite(favorite)
        XCTAssertEqual(store.draft.essentialChoiceID, action)
        store.toggleJourneyAction(action)
        XCTAssertNil(store.draft.essentialChoiceID)
        store.selectJourneySetting(setting)
        store.selectEssential(setting)
        store.selectJourneySetting(topic.settings[1].id)
        XCTAssertNil(store.draft.essentialChoiceID)
        store.selectEssential(favorite)
        store.toggleFavorite(favorite)
        XCTAssertNil(store.draft.essentialChoiceID)
    }

    @MainActor
    func testSkippingWishQuestionsKeepsSharedIntakeFavorites() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        let topic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.art.id))
        let action = topic.actions[0].id
        let setting = topic.settings[0].id
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        let essentials = [action, setting, favorite, action]
        for stage in 0..<4 {
            store.draft = WishDraft(interestID: InterestChoice.art.id, selectedActionIDs: [action],
                                   selectedSettingID: setting, favoriteIDs: [favorite], essentialChoiceID: essentials[stage])
            store.step = .journey
            store.journeyStage = stage
            store.skipJourneyStage()
            XCTAssertEqual(store.draft.selectedActionIDs, stage == 0 ? [] : [action])
            XCTAssertEqual(store.draft.selectedSettingID, stage == 1 ? nil : setting)
            XCTAssertEqual(store.draft.favoriteIDs, [favorite])
            XCTAssertEqual(store.draft.essentialChoiceID, stage == 2 ? favorite : nil)
            XCTAssertEqual(store.step, stage == 3 ? .postcard : .journey)
            XCTAssertEqual(store.journeyStage, min(stage + 1, 3))
        }
    }

    @MainActor
    func testBackWalksJourneyStagesAndReopensPostcardAtLastStage() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        store.chooseInterest(.art)
        for expectedStage in 1...3 {
            store.advanceJourney()
            XCTAssertEqual(store.journeyStage, expectedStage)
            XCTAssertEqual(store.step, .journey)
        }
        store.advanceJourney()
        XCTAssertEqual(store.step, .postcard)
        store.goBack()
        XCTAssertEqual(store.step, .journey)
        XCTAssertEqual(store.journeyStage, 3)
        for expectedStage in stride(from: 2, through: 0, by: -1) {
            store.goBack()
            XCTAssertEqual(store.journeyStage, expectedStage)
            XCTAssertEqual(store.step, .journey)
        }
        store.goBack()
        XCTAssertEqual(store.step, .interests)
    }

    @MainActor
    func testChangingInterestClearsWishSpecificAnswersAndKeepsIntakeFavorites() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        let topic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.art.id))
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        let original = WishDraft(interestID: InterestChoice.art.id, selectedActionIDs: [topic.actions[0].id],
                                 selectedSettingID: topic.settings[0].id, favoriteIDs: [favorite], essentialChoiceID: favorite)
        store.draft = original
        store.chooseInterest(.art)
        XCTAssertEqual(store.draft, original)
        store.journeyStage = 3
        store.chooseInterest(.camp)
        XCTAssertEqual(store.draft, WishDraft(interestID: InterestChoice.camp.id, favoriteIDs: [favorite]))
        XCTAssertEqual(store.journeyStage, 0)
        XCTAssertEqual(store.step, .journey)
    }

    @MainActor
    func testOptedInJourneyAnswersRestoreIncludingEssentialChoice() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        store.rememberChoices = true
        store.chooseInterest(.art)
        let topic = try XCTUnwrap(JourneyCatalog.shared.interest(id: InterestChoice.art.id))
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        store.toggleJourneyAction(topic.actions[0].id)
        store.selectJourneySetting(topic.settings[0].id)
        store.toggleFavorite(favorite)
        store.selectEssential(favorite)
        let restored = makeStore(storage)
        XCTAssertEqual(restored.draft, store.draft)
        XCTAssertEqual(restored.draft.essentialChoiceID, favorite)
        XCTAssertTrue(restored.draft.canRequestScene)
    }

    @MainActor
    func testFavoritesIntakeWorksBeforeChoosingATopicAndCarriesIntoDifferentIdeas() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        store.boardExpanded = true
        store.openFavoritesIntake()
        XCTAssertEqual(store.step, .favoritesIntake)
        XCTAssertFalse(store.boardExpanded)
        store.toggleFavorite(favorite)
        XCTAssertNil(store.draft.interest)
        XCTAssertFalse(store.draft.canRequestScene)
        store.finishFavoritesIntake()
        XCTAssertEqual(store.step, .interests)
        store.chooseInterest(.camp)
        XCTAssertEqual(store.draft.favoriteIDs, [favorite])
        store.chooseInterest(.gift)
        XCTAssertEqual(store.draft.favoriteIDs, [favorite])
        XCTAssertTrue(store.draft.canRequestScene)
        store.reset()
        XCTAssertTrue(store.draft.favoriteIDs.isEmpty)
    }

    @MainActor
    func testAnOptedInIntakeDraftRestoresWithoutInventingAWishTopic() throws {
        let storage = try JourneyTestStorage()
        let store = makeStore(storage)
        let favorite = try XCTUnwrap(JourneyCatalog.shared.favoriteOptions.first).id
        store.rememberChoices = true
        store.openFavoritesIntake()
        store.toggleFavorite(favorite)
        let restored = makeStore(storage)
        XCTAssertNil(restored.draft.interest)
        XCTAssertEqual(restored.draft.favoriteIDs, [favorite])
        XCTAssertFalse(restored.draft.canRequestScene)
    }

    @MainActor
    private func makeStore(_ storage: JourneyTestStorage) -> WishStore {
        let store = WishStore(defaults: storage.defaults, configuration: .init(values: [:]), sceneAccessToken: nil)
        store.readChoicesAloud = false
        return store
    }
}

private final class JourneyTestStorage {
    let suite: String
    let defaults: UserDefaults

    init() throws {
        let suite = "JourneyTests.\(UUID().uuidString)"
        self.suite = suite
        defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    }

    deinit { defaults.removePersistentDomain(forName: suite) }
}
