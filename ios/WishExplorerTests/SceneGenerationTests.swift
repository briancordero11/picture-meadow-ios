import XCTest
@testable import WishExplorer

final class SceneGenerationTests: XCTestCase {
    private let token = String(repeating: "a", count: 32)
    private let provider = "OpenAI (direct)"

    private var enabledConfiguration: WishBuildConfiguration {
        WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test",
                                        "WishSceneGenerationEnabled": "YES",
                                        "WishAIProviderName": provider])
    }

    private var sceneDraft: WishDraft {
        WishDraft(interestID: "art", selectedActionIDs: ["art-paint"],
                  selectedSettingID: "art-art-studio", favoriteIDs: ["favorite-color-blue"], essentialChoiceID: "art-paint")
    }

    @MainActor
    func testSceneGenerationRequiresExplicitConfigurationAndServiceAccess() throws {
        XCTAssertFalse(WishBuildConfiguration(values: [:]).sceneGenerationAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test",
                                                      "WishAIProviderName": provider]).sceneGenerationAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishSceneGenerationEnabled": "YES",
                                                      "WishAIProviderName": provider]).sceneGenerationAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test",
                                                      "WishSceneGenerationEnabled": "YES"]).sceneGenerationAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test",
                                                      "WishSceneGenerationEnabled": "YES",
                                                      "WishAIProviderName": "An undisclosed provider"]).sceneGenerationAvailable)
        XCTAssertTrue(enabledConfiguration.sceneGenerationAvailable)
        let storage = try SceneTestStorage()
        let store = makeStore(storage, accessToken: nil)
        authorize(store)
        XCTAssertFalse(store.sceneAccessConfigured)
        XCTAssertFalse(store.sceneGenerationAvailable)
        XCTAssertNil(store.prepareSceneGeneration())
    }

    func testRequestContainsOnlyFiveDisclosedChoiceFields() throws {
        var draft = sceneDraft
        draft.category = .go
        draft.destinationID = "disney-world"
        draft.coasterColor = .purple
        draft.animals = [.tiger]
        let request = try WishSceneClient(configuration: enabledConfiguration).makeRequest(for: draft, accessToken: token)
        let data = try XCTUnwrap(request.httpBody)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(fields.keys), Set(["interestId", "actionIds", "settingId", "favoriteIds", "essentialChoiceId"]))
        XCTAssertEqual(fields["interestId"] as? String, "art")
        XCTAssertEqual(fields["actionIds"] as? [String], draft.selectedActionIDs)
        XCTAssertEqual(fields["settingId"] as? String, draft.selectedSettingID)
        XCTAssertEqual(fields["favoriteIds"] as? [String], draft.favoriteIDs)
        XCTAssertEqual(fields["essentialChoiceId"] as? String, draft.essentialChoiceID)
        XCTAssertEqual(request.url?.absoluteString, "https://service.test/v1/wish-scene")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(token)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Cache-Control"), "no-store")
        XCTAssertFalse(request.httpShouldHandleCookies)
    }

    func testUnansweredSettingAndEssentialAreExplicitNullsInRequest() throws {
        let draft = WishDraft(interestID: "art", selectedActionIDs: ["art-paint"])
        let request = try WishSceneClient(configuration: enabledConfiguration).makeRequest(for: draft, accessToken: token)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any])
        XCTAssertEqual(fields.count, 5)
        XCTAssertTrue(fields["settingId"] is NSNull)
        XCTAssertTrue(fields["essentialChoiceId"] is NSNull)
        XCTAssertEqual(fields["favoriteIds"] as? [String], [])
    }

    func testInvalidAccessOrMissingChoicesCannotProduceARequest() {
        let client = WishSceneClient(configuration: enabledConfiguration)
        for invalid in ["", String(repeating: "a", count: 31), String(repeating: "a", count: 257), token + "\n", token + " "] {
            XCTAssertThrowsError(try client.makeRequest(for: sceneDraft, accessToken: invalid))
        }
        XCTAssertThrowsError(try client.makeRequest(for: WishDraft(interestID: "art"), accessToken: token))
        XCTAssertThrowsError(try WishSceneClient(configuration: .init(values: [:])).makeRequest(for: sceneDraft, accessToken: token))
    }

    func testSceneValidationAcceptsRasterFixtureAndRejectsUnsupportedOrInvalidImages() throws {
        let scene = try sceneFixture()
        XCTAssertFalse(scene.imageData.isEmpty)
        XCTAssertEqual(scene.provider, provider)
        XCTAssertThrowsError(try GeneratedWishScene.validated(response(mimeType: "image/svg+xml")))
        XCTAssertThrowsError(try GeneratedWishScene.validated(response(imageBase64: "not-base64")))
        XCTAssertThrowsError(try GeneratedWishScene.validated(response(imageBase64: Data("not an image".utf8).base64EncodedString())))
        XCTAssertThrowsError(try GeneratedWishScene.validated(response(imageBase64: Data(repeating: 0, count: 2_936_013).base64EncodedString())))
    }

    @MainActor
    func testPreparationRequiresAdultAccessAnActiveSceneAndAnEnabledBuild() throws {
        let storage = try SceneTestStorage()
        let store = makeStore(storage)
        XCTAssertNil(store.prepareSceneGeneration())
        XCTAssertFalse(store.confirmSceneGeneration(UUID()))
        store.beginAdultSession()
        XCTAssertFalse(store.adultSessionActive)
        authorize(store)
        let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertEqual(disclosure.draft, sceneDraft)
        XCTAssertEqual(disclosure.serviceHost, "service.test")
        XCTAssertEqual(disclosure.providerName, provider)
        XCTAssertEqual(Set(disclosure.choices.map(\.id)), Set(sceneDraft.sceneChoices.map(\.id)))
        store.handleSceneActivity(false)
        XCTAssertNil(store.prepareSceneGeneration())
        XCTAssertFalse(store.confirmSceneGeneration(disclosure.id))
        store.handleSceneActivity(true)
        XCTAssertNil(store.prepareSceneGeneration())
        let offline = makeStore(storage, configuration: .init(values: [:]))
        authorize(offline)
        XCTAssertNil(offline.prepareSceneGeneration())
    }

    @MainActor
    func testConfirmationIsBoundToItsDraftAndLatestUncanceledDisclosure() throws {
        let storage = try SceneTestStorage()
        let store = makeStore(storage)
        authorize(store)
        let original = try XCTUnwrap(store.prepareSceneGeneration())
        store.draft.favoriteIDs = []
        XCTAssertFalse(store.confirmSceneGeneration(original.id))
        let replaced = try XCTUnwrap(store.prepareSceneGeneration())
        let current = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertNotEqual(replaced.id, current.id)
        XCTAssertFalse(store.confirmSceneGeneration(replaced.id))
        XCTAssertFalse(store.confirmSceneGeneration(UUID()))
        store.cancelSceneConfirmation(current.id)
        XCTAssertFalse(store.confirmSceneGeneration(current.id))
        XCTAssertFalse(store.isGeneratingScene)
    }

    @MainActor
    func testOneUseConfirmationGeneratesAReviewBeforeAnyChildFacingImage() async throws {
        let storage = try SceneTestStorage()
        let started = expectation(description: "Scene request started")
        let service = ControlledSceneService(scene: try sceneFixture(), started: started)
        let store = makeStore(storage, service: service)
        authorize(store)
        let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertTrue(store.confirmSceneGeneration(disclosure.id))
        XCTAssertFalse(store.confirmSceneGeneration(disclosure.id))
        XCTAssertNil(store.prepareSceneGeneration())
        await fulfillment(of: [started], timeout: 2)
        await service.finish()
        try await waitForGenerationToFinish(store)
        let requestCount = await service.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertNotNil(store.pendingGeneratedScene)
        XCTAssertNil(store.generatedScene)
        XCTAssertFalse(store.confirmSceneGeneration(disclosure.id))
        store.approveGeneratedScene()
        XCTAssertNotNil(store.generatedScene)
        XCTAssertNil(store.pendingGeneratedScene)
        store.toggleFavorite("favorite-color-blue")
        XCTAssertNil(store.generatedScene)
        XCTAssertNil(store.pendingGeneratedScene)
    }

    @MainActor
    func testPendingImageCannotBeApprovedAfterAdultAccessEnds() async throws {
        let storage = try SceneTestStorage()
        let started = expectation(description: "Scene request started")
        let service = ControlledSceneService(scene: try sceneFixture(), started: started)
        let store = makeStore(storage, service: service)
        authorize(store)
        let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertTrue(store.confirmSceneGeneration(disclosure.id))
        await fulfillment(of: [started], timeout: 2)
        await service.finish()
        try await waitForGenerationToFinish(store)
        XCTAssertNotNil(store.pendingGeneratedScene)
        store.endAdultSession()
        store.approveGeneratedScene()
        XCTAssertNil(store.pendingGeneratedScene)
        XCTAssertNil(store.generatedScene)
    }

    @MainActor
    func testImmediateRevocationPreventsQueuedServiceInvocation() async throws {
        let storage = try SceneTestStorage()
        let forbidden = expectation(description: "Revoked request never reaches image service")
        forbidden.isInverted = true
        let service = ControlledSceneService(scene: try sceneFixture(), started: forbidden)
        let store = makeStore(storage, service: service)
        authorize(store)
        let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertTrue(store.confirmSceneGeneration(disclosure.id))
        store.endAdultSession()
        await fulfillment(of: [forbidden], timeout: 0.15)
        let requestCount = await service.requestCount
        XCTAssertEqual(requestCount, 0)
        XCTAssertFalse(store.isGeneratingScene)
        XCTAssertNil(store.pendingGeneratedScene)
        XCTAssertNil(store.generatedScene)
    }

    @MainActor
    func testLateResponsesAfterDraftChangeRevocationOrCancellationAreNotDisplayed() async throws {
        for scenario in ["draft-change", "revocation", "cancellation"] {
            let storage = try SceneTestStorage()
            let started = expectation(description: "Scene request started for \(scenario)")
            let returned = expectation(description: "Late service response returned for \(scenario)")
            let service = ControlledSceneService(scene: try sceneFixture(), started: started, returned: returned)
            let store = makeStore(storage, service: service)
            authorize(store)
            let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
            XCTAssertTrue(store.confirmSceneGeneration(disclosure.id))
            await fulfillment(of: [started], timeout: 2)
            switch scenario {
            case "draft-change": store.draft.favoriteIDs = []
            case "revocation": store.endAdultSession()
            default: store.cancelSceneGeneration()
            }
            await service.finish()
            await fulfillment(of: [returned], timeout: 2)
            try await waitForGenerationToFinish(store)
            await Task.yield()
            XCTAssertNil(store.pendingGeneratedScene, scenario)
            XCTAssertNil(store.generatedScene, scenario)
        }
    }

    @MainActor
    func testForgettingClearsSceneAccessImagesChoicesAndSavedMemory() async throws {
        let storage = try SceneTestStorage()
        let started = expectation(description: "Scene ready for adult review")
        let service = ControlledSceneService(scene: try sceneFixture(), started: started)
        let store = makeStore(storage, service: service)
        store.rememberChoices = true
        store.phrase = ["I", "want"]
        store.journeyStage = 2
        authorize(store)
        let disclosure = try XCTUnwrap(store.prepareSceneGeneration())
        XCTAssertTrue(store.confirmSceneGeneration(disclosure.id))
        await fulfillment(of: [started], timeout: 2)
        await service.finish()
        try await waitForGenerationToFinish(store)
        store.approveGeneratedScene()
        XCTAssertNotNil(store.generatedScene)
        store.forgetAllChoices()
        XCTAssertEqual(store.draft, WishDraft())
        XCTAssertTrue(store.phrase.isEmpty)
        XCTAssertNil(store.generatedScene)
        XCTAssertNil(store.pendingGeneratedScene)
        XCTAssertFalse(store.sceneAccessConfigured)
        XCTAssertFalse(store.sceneGenerationAvailable)
        XCTAssertFalse(store.isGeneratingScene)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertFalse(store.rememberChoices)
        XCTAssertEqual(store.step, .welcome)
        XCTAssertEqual(store.journeyStage, 0)
        XCTAssertTrue(storage.defaults.persistentDomain(forName: storage.suite)?.isEmpty ?? true)
    }

    @MainActor
    private func makeStore(_ storage: SceneTestStorage, configuration: WishBuildConfiguration? = nil,
                           service: (any WishSceneServicing)? = nil,
                           accessToken: String? = String(repeating: "a", count: 32)) -> WishStore {
        let store = WishStore(defaults: storage.defaults, configuration: configuration ?? enabledConfiguration,
                              sceneService: service ?? UnavailableSceneService(), sceneAccessToken: accessToken)
        store.readChoicesAloud = false
        store.draft = sceneDraft
        return store
    }

    @MainActor
    private func authorize(_ store: WishStore) {
        store.caregiverPresented = true
        store.beginAdultSession()
    }

    @MainActor
    private func waitForGenerationToFinish(_ store: WishStore) async throws {
        for _ in 0..<200 {
            if !store.isGeneratingScene { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("Scene generation did not finish")
    }

    private func sceneFixture() throws -> GeneratedWishScene {
        try GeneratedWishScene.validated(response())
    }

    private func response(mimeType: String = "image/png", imageBase64: String = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNIW9XxHwAFqgKYLi7uYwAAAABJRU5ErkJggg==") -> WishPreviewResponse {
        WishPreviewResponse(id: "scene-fixture", title: "An imagined art scene", description: "An illustration for testing adult review.",
                            image: .init(mimeType: mimeType, data: imageBase64), provider: provider)
    }
}

private final class SceneTestStorage {
    let suite: String
    let defaults: UserDefaults

    init() throws {
        let suite = "SceneGenerationTests.\(UUID().uuidString)"
        self.suite = suite
        defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
    }

    deinit { defaults.removePersistentDomain(forName: suite) }
}

private struct UnavailableSceneService: WishSceneServicing {
    func generateScene(for draft: WishDraft, accessToken: String) async throws -> GeneratedWishScene {
        throw WishAPIClient.ClientError.unavailable
    }
}

private actor ControlledSceneService: WishSceneServicing {
    let scene: GeneratedWishScene
    let started: XCTestExpectation
    let returned: XCTestExpectation?
    private var continuation: CheckedContinuation<GeneratedWishScene, Never>?
    private(set) var requestCount = 0

    init(scene: GeneratedWishScene, started: XCTestExpectation, returned: XCTestExpectation? = nil) {
        self.scene = scene
        self.started = started
        self.returned = returned
    }

    func generateScene(for draft: WishDraft, accessToken: String) async throws -> GeneratedWishScene {
        requestCount += 1
        let result: GeneratedWishScene = await withCheckedContinuation { continuation in
            self.continuation = continuation
            started.fulfill()
        }
        returned?.fulfill()
        return result
    }

    func finish() {
        continuation?.resume(returning: scene)
        continuation = nil
    }
}
