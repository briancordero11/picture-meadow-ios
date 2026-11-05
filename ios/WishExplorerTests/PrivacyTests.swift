import XCTest
@testable import WishExplorer

final class PrivacyTests: XCTestCase {
    private var enabledConfiguration: WishBuildConfiguration {
        WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test", "WishOnlinePreviewEnabled": "YES"])
    }
    private var parkDraft: WishDraft {
        WishDraft(category: .go, interestID: "amusement-park", destinationID: "disney-world", coasterColor: .blue, animals: [.tiger], wantsAnimals: true)
    }

    func testMissingMetadataDoesNotInventPublisherOrBrokenLinks() {
        let config = WishBuildConfiguration(values: [:])
        XCTAssertNil(config.publisherName)
        XCTAssertNil(config.supportEmail)
        XCTAssertNil(config.privacyPolicyURL)
        XCTAssertNil(config.supportURL)
        XCTAssertFalse(config.onlinePreviewAvailable)
    }

    func testURLsRejectNonHTTPSCredentialsQueriesFragmentsAndBuildPlaceholders() {
        let invalid = ["http://service.test", "https://user@service.test", "https://user:password@service.test",
                       "https://service.test?tracking=1", "https://service.test#section", "https://service.test?", "https://service.test#",
                       "$(WISH_PRIVACY_POLICY_URL)", "https://service.test/$(UNRESOLVED)", "https://service.test/%24%28UNRESOLVED%29"]
        for url in invalid { XCTAssertNil(WishBuildConfiguration.httpsURL(url), url) }
        XCTAssertNotNil(WishBuildConfiguration.httpsURL("https://service.test/privacy"))
    }

    func testURLAloneCannotEnableOnlineFeature() {
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test"]).onlinePreviewAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test", "WishOnlinePreviewEnabled": "NO"]).onlinePreviewAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishOnlinePreviewEnabled": "YES"]).onlinePreviewAvailable)
        XCTAssertTrue(enabledConfiguration.onlinePreviewAvailable)
        XCTAssertFalse(WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test/some-path", "WishOnlinePreviewEnabled": "YES"]).onlinePreviewAvailable)
        XCTAssertNotNil(WishBuildConfiguration.httpsURL("https://service.test/privacy"))
    }

    func testRedirectsStayOnHTTPSHostAndEffectivePort() throws {
        let origin = try XCTUnwrap(URL(string: "https://service.test"))
        XCTAssertTrue(WishBuildConfiguration.permitsRedirect(from: origin, to: try XCTUnwrap(URL(string: "https://service.test:443/v1/other"))))
        for target in ["https://other.test/v1", "https://service.test:444/v1", "http://service.test/v1", "https://service.test/v1?copy=1", "https://user@service.test/v1"] {
            XCTAssertFalse(WishBuildConfiguration.permitsRedirect(from: origin, to: try XCTUnwrap(URL(string: target))), target)
        }
    }

    func testNetworkSessionDoesNotReuseCookiesCacheOrCredentials() {
        let config = WishAPIClient.sessionConfiguration()
        XCTAssertNil(config.identifier)
        XCTAssertNil(config.urlCache)
        XCTAssertNil(config.httpCookieStorage)
        XCTAssertNil(config.urlCredentialStorage)
        XCTAssertFalse(config.httpShouldSetCookies)
        XCTAssertEqual(config.httpCookieAcceptPolicy, .never)
        XCTAssertEqual(config.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRequestContainsOnlyTheFourDisclosedChoiceFields() throws {
        let request = try WishAPIClient(configuration: enabledConfiguration).makeRequest(for: parkDraft)
        let body = try XCTUnwrap(request.httpBody)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(Set(fields.keys), Set(["categoryId", "destinationId", "coasterColor", "animalIds"]))
        XCTAssertEqual(fields["categoryId"] as? String, "go")
        XCTAssertEqual(fields["animalIds"] as? [String], ["tiger"])
        XCTAssertFalse(request.httpShouldHandleCookies)
        XCTAssertThrowsError(try WishAPIClient(configuration: .init(values: [:])).makeRequest(for: parkDraft))
    }

    func testGateUsesSpelledDigitsAndRenewsAfterEitherOutcome() {
        var gate = AdultGateChallenge(digits: [1, 2, 3, 4])
        XCTAssertEqual(gate.prompt, "one · two · three · four")
        let original = gate
        XCTAssertFalse(gate.submit("0000"))
        XCTAssertNotEqual(gate, original)
        gate = AdultGateChallenge(digits: [1, 2, 3, 4])
        XCTAssertTrue(gate.submit("1234"))
        XCTAssertNotEqual(gate, original)
        XCTAssertFalse(gate.submit("1234"))
    }

    @MainActor
    func testAdultAuthorizationAndChallengesAreNotPersisted() throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration)
        store.caregiverPresented = true
        store.beginAdultSession()
        XCTAssertTrue(store.adultSessionActive)
        store.endAdultSession()
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertTrue(defaults.persistentDomain(forName: suite)?.isEmpty ?? true)
    }

    @MainActor
    func testNoNetworkRequestCanBePreparedWithoutAdultAccessOrWhenBuildDisabled() throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration)
        store.draft = parkDraft
        XCTAssertNil(store.prepareOnlinePreview())
        XCTAssertFalse(store.confirmOnlinePreview(UUID()))
        let offline = WishStore(defaults: defaults, configuration: .init(values: [:]))
        offline.draft = parkDraft
        offline.caregiverPresented = true
        offline.beginAdultSession()
        XCTAssertNil(offline.prepareOnlinePreview())
    }

    @MainActor
    func testConfirmationExpiresWhenChoicesChangeOrSceneBecomesInactive() throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration)
        store.draft = parkDraft
        store.caregiverPresented = true
        store.beginAdultSession()
        let first = try XCTUnwrap(store.prepareOnlinePreview())
        store.draft.coasterColor = .pink
        XCTAssertFalse(store.confirmOnlinePreview(first.id))
        let next = try XCTUnwrap(store.prepareOnlinePreview())
        store.phrase = ["I", "want"]
        store.handleSceneActivity(false)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertFalse(store.caregiverPresented)
        XCTAssertTrue(store.phrase.isEmpty)
        XCTAssertFalse(store.confirmOnlinePreview(next.id))
        store.handleSceneActivity(true)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertNil(store.prepareOnlinePreview())
    }

    @MainActor
    func testOneConfirmationCanStartOnlyOneRequest() async throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let started = expectation(description: "One disclosed request starts")
        let service = ControlledPreviewService(started: started)
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration, previewService: service)
        store.draft = parkDraft
        store.caregiverPresented = true
        store.beginAdultSession()
        let disclosure = try XCTUnwrap(store.prepareOnlinePreview())
        XCTAssertTrue(store.confirmOnlinePreview(disclosure.id))
        XCTAssertFalse(store.confirmOnlinePreview(disclosure.id))
        await fulfillment(of: [started], timeout: 2)
        let count = await service.requestCount
        XCTAssertEqual(count, 1)
        store.handleSceneActivity(false)
        await service.finish()
        await Task.yield()
        XCTAssertNil(store.remoteDescription)
        XCTAssertFalse(store.isLoadingPreview)
    }

    @MainActor
    func testSynchronousRevocationStopsQueuedRequestBeforeServiceIsCalled() async throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let forbidden = expectation(description: "Revoked request never reaches service")
        forbidden.isInverted = true
        let service = ImmediatePreviewService(started: forbidden)
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration, previewService: service)
        store.draft = parkDraft
        store.caregiverPresented = true
        store.beginAdultSession()
        let disclosure = try XCTUnwrap(store.prepareOnlinePreview())
        XCTAssertTrue(store.confirmOnlinePreview(disclosure.id))
        store.endAdultSession()
        await fulfillment(of: [forbidden], timeout: 0.15)
        let count = await service.requestCount
        XCTAssertEqual(count, 0)
        XCTAssertNil(store.remoteDescription)
    }

    @MainActor
    func testForgetWorksOfflineAndClearsSavedDraftSentenceSettingsAndAdultAccess() throws {
        let suite = "PrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults, configuration: .init(values: [:]))
        store.rememberChoices = true
        store.readChoicesAloud = false
        store.draft = parkDraft
        store.phrase = ["I", "want"]
        store.caregiverPresented = true
        store.beginAdultSession()
        store.forgetAllChoices()
        XCTAssertEqual(store.draft, WishDraft())
        XCTAssertTrue(store.phrase.isEmpty)
        XCTAssertFalse(store.rememberChoices)
        XCTAssertTrue(store.readChoicesAloud)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertFalse(store.caregiverPresented)
        XCTAssertTrue(defaults.persistentDomain(forName: suite)?.isEmpty ?? true)
    }
}

private actor ControlledPreviewService: WishPreviewServicing {
    let started: XCTestExpectation
    private var continuation: CheckedContinuation<WishPreviewResponse, Never>?
    private(set) var requestCount = 0
    init(started: XCTestExpectation) { self.started = started }
    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse {
        requestCount += 1
        started.fulfill()
        return await withCheckedContinuation { continuation = $0 }
    }
    func finish() {
        continuation?.resume(returning: WishPreviewResponse(id: "test", title: "Test", description: "A late response must not be applied", image: .init(mimeType: "image/svg+xml", data: "<svg/>"), provider: "illustrated-demo"))
        continuation = nil
    }
}

private actor ImmediatePreviewService: WishPreviewServicing {
    let started: XCTestExpectation
    private(set) var requestCount = 0
    init(started: XCTestExpectation) { self.started = started }
    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse {
        requestCount += 1
        started.fulfill()
        return WishPreviewResponse(id: "test", title: "Test", description: "Unexpected request", image: .init(mimeType: "image/svg+xml", data: "<svg/>"), provider: "illustrated-demo")
    }
}
