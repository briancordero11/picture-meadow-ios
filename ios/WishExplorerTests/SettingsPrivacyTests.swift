import Foundation
import XCTest
@testable import WishExplorer

final class SettingsPrivacyTests: XCTestCase {
    func testSupportDraftEncodesReservedCharactersWithoutAddingRecipientsOrHeaders() throws {
        let recipient = "care+help@example.test"
        let subject = "Privacy & AI? #question"
        let body = "Please help.\nVersion 1 & bcc=another@example.test"
        let url = try XCTUnwrap(AppSupportContext.emailURL(to: recipient, subject: subject, body: body))
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, recipient)
        XCTAssertNil(components.host)
        XCTAssertNil(components.fragment)
        let items = try XCTUnwrap(components.queryItems)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(Set(items.map(\.name)), Set(["subject", "body"]))
        XCTAssertEqual(items.first { $0.name == "subject" }?.value, subject)
        XCTAssertEqual(items.first { $0.name == "body" }?.value, body)
    }

    func testSupportDraftRejectsMissingAddressesAndRecipientInjection() {
        for recipient in ["", "not-an-address", "support@example.test\r\nBcc:other@example.test",
                          "support@example.test?bcc=other@example.test", "support@example.test#fragment",
                          "mailto:support@example.test", "support@example.test,other@example.test"] {
            XCTAssertNil(AppSupportContext.emailURL(to: recipient, subject: "Help", body: "A support question."), recipient)
        }
    }

    @MainActor
    func testRequestingAReportOpensTheGateWithoutAuthorizationPersistenceOrAPICalls() async throws {
        let suite = "SettingsPrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let forbidden = expectation(description: "A report request never calls a wish or image API")
        forbidden.isInverted = true
        let service = SettingsForbiddenNetworkService(called: forbidden)
        let store = WishStore(defaults: defaults, configuration: enabledConfiguration,
                              previewService: service, sceneService: service,
                              sceneAccessToken: String(repeating: "a", count: 32))
        store.draft = WishDraft(interestID: "camp", selectedActionIDs: ["camp-explore"])
        store.requestAIPicture()
        XCTAssertTrue(store.aiGenerationRequested)
        XCTAssertFalse(store.aiReportRequested)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertNil(store.prepareSceneGeneration())
        store.requestAIReport()
        XCTAssertFalse(store.aiGenerationRequested)
        XCTAssertTrue(store.aiReportRequested)
        XCTAssertTrue(store.caregiverPresented)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertNil(store.prepareSceneGeneration())
        XCTAssertNil(store.prepareOnlinePreview())
        XCTAssertFalse(store.isGeneratingScene)
        XCTAssertFalse(store.isLoadingPreview)
        await fulfillment(of: [forbidden], timeout: 0.1)
        let calls = await service.calls
        XCTAssertEqual(calls, 0)
        XCTAssertTrue(defaults.persistentDomain(forName: suite)?.isEmpty ?? true)
    }

    @MainActor
    func testResetAndInactiveSceneClearPendingReportRouting() throws {
        let suite = "SettingsPrivacyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = WishStore(defaults: defaults, configuration: .init(values: [:]), sceneAccessToken: nil)
        store.requestAIReport()
        store.reset()
        XCTAssertFalse(store.aiReportRequested)
        store.requestAIPicture()
        store.reset()
        XCTAssertFalse(store.aiGenerationRequested)
        store.requestAIReport()
        store.beginAdultSession()
        XCTAssertTrue(store.adultSessionActive)
        store.handleSceneActivity(false)
        XCTAssertFalse(store.aiReportRequested)
        XCTAssertFalse(store.aiGenerationRequested)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertFalse(store.caregiverPresented)
        store.handleSceneActivity(true)
        XCTAssertFalse(store.aiReportRequested)
        XCTAssertFalse(store.adultSessionActive)
        XCTAssertTrue(defaults.persistentDomain(forName: suite)?.isEmpty ?? true)
    }

    private var enabledConfiguration: WishBuildConfiguration {
        WishBuildConfiguration(values: ["WishAPIBaseURL": "https://service.test",
                                        "WishOnlinePreviewEnabled": "YES",
                                        "WishSceneGenerationEnabled": "YES",
                                        "WishAIProviderName": "OpenAI (direct)"])
    }
}

private actor SettingsForbiddenNetworkService: WishPreviewServicing, WishSceneServicing {
    let called: XCTestExpectation
    private(set) var calls = 0
    init(called: XCTestExpectation) { self.called = called }
    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse {
        calls += 1; called.fulfill()
        throw WishAPIClient.ClientError.unavailable
    }
    func generateScene(for draft: WishDraft, accessToken: String) async throws -> GeneratedWishScene {
        calls += 1; called.fulfill()
        throw WishAPIClient.ClientError.unavailable
    }
}
