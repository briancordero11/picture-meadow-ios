import Foundation
import UIKit
import ImageIO

struct WishSceneRequest: Encodable, Equatable {
    let interestId: String
    let actionIds: [String]
    let settingId: String?
    let favoriteIds: [String]
    let essentialChoiceId: String?
    init(draft: WishDraft) {
        interestId = draft.interestID ?? ""
        actionIds = draft.selectedActionIDs; settingId = draft.selectedSettingID
        favoriteIds = draft.favoriteIDs; essentialChoiceId = draft.essentialChoiceID
    }
    // Explicit nulls make the wire contract independent of Swift's optional encoding.
    enum CodingKeys: CodingKey { case interestId, actionIds, settingId, favoriteIds, essentialChoiceId }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(interestId, forKey: .interestId); try values.encode(actionIds, forKey: .actionIds)
        try values.encode(settingId, forKey: .settingId); try values.encode(favoriteIds, forKey: .favoriteIds)
        try values.encode(essentialChoiceId, forKey: .essentialChoiceId)
    }
}

struct GeneratedWishScene {
    let imageData: Data
    let description: String
    let provider: String
    static func validated(_ response: WishPreviewResponse) throws -> Self {
        guard ["image/png", "image/jpeg", "image/webp"].contains(response.image.mimeType),
              let data = Data(base64Encoded: response.image.data), data.count <= 2_936_012,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int,
              width > 0, height > 0, width <= 4096, height <= 4096,
              CGImageSourceGetCount(source) == 1,
              UIImage(data: data) != nil else { throw WishAPIClient.ClientError.invalidResponse }
        return Self(imageData: data, description: response.description, provider: response.provider)
    }
}

protocol WishSceneServicing {
    func generateScene(for draft: WishDraft, accessToken: String) async throws -> GeneratedWishScene
}

struct WishSceneClient: WishSceneServicing {
    let configuration: WishBuildConfiguration
    func makeRequest(for draft: WishDraft, accessToken: String) throws -> URLRequest {
        guard configuration.sceneGenerationAvailable, let origin = configuration.apiBaseURL,
              draft.canRequestScene, accessToken.utf8.count >= 32, accessToken.utf8.count <= 256,
              !accessToken.contains(where: { $0.isWhitespace }) else { throw WishAPIClient.ClientError.unavailable }
        var request = URLRequest(url: origin.appendingPathComponent("v1/wish-scene"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 100)
        request.httpMethod = "POST"; request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(WishSceneRequest(draft: draft))
        return request
    }
    func generateScene(for draft: WishDraft, accessToken: String) async throws -> GeneratedWishScene {
        let request = try makeRequest(for: draft, accessToken: accessToken)
        let settings = WishAPIClient.sessionConfiguration()
        settings.timeoutIntervalForRequest = 100; settings.timeoutIntervalForResource = 110
        let session = URLSession(configuration: settings, delegate: NoSceneRedirects(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              http.mimeType == "application/json", response.expectedContentLength <= 4_000_000 else { throw WishAPIClient.ClientError.invalidResponse }
        var data = Data()
        for try await byte in bytes {
            guard data.count < 4_000_000 else { throw WishAPIClient.ClientError.invalidResponse }
            data.append(byte)
            if data.count % 65_536 == 0 { try Task.checkCancellation() }
        }
        try Task.checkCancellation()
        let result = try JSONDecoder().decode(WishPreviewResponse.self, from: data)
        guard result.provider == configuration.aiProviderName else { throw WishAPIClient.ClientError.invalidResponse }
        return try GeneratedWishScene.validated(result)
    }
}

private final class NoSceneRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct SceneGenerationDisclosure: Identifiable, Equatable {
    let id: UUID
    let draft: WishDraft
    let serviceHost: String
    let providerName: String
    var choices: [JourneyChoice] { JourneyCatalog.shared.choices(for: draft) }
}
