import Foundation

struct WishPreviewResponse: Decodable {
    struct ImagePayload: Decodable { let mimeType: String; let data: String }
    let id: String
    let title: String
    let description: String
    let image: ImagePayload
    let provider: String
}

protocol WishPreviewServicing {
    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse
}

struct WishAPIClient: WishPreviewServicing {
    enum ClientError: Error { case unavailable, invalidConfiguration, invalidResponse }
    private struct Request: Encodable {
        let categoryId: String
        let destinationId: String
        let coasterColor: String
        let animalIds: [String]
    }
    let configuration: WishBuildConfiguration
    init(configuration: WishBuildConfiguration = .current) { self.configuration = configuration }
    static var isConfigured: Bool { WishBuildConfiguration.current.onlinePreviewAvailable }

    static func sessionConfiguration() -> URLSessionConfiguration {
        let session = URLSessionConfiguration.ephemeral
        session.urlCache = nil
        session.httpCookieStorage = nil
        session.httpShouldSetCookies = false
        session.httpCookieAcceptPolicy = .never
        session.urlCredentialStorage = nil
        session.requestCachePolicy = .reloadIgnoringLocalCacheData
        session.timeoutIntervalForRequest = 20
        session.timeoutIntervalForResource = 25
        session.httpAdditionalHeaders = ["Cache-Control": "no-store", "Pragma": "no-cache"]
        return session
    }

    func makeRequest(for draft: WishDraft) throws -> URLRequest {
        guard configuration.onlinePreviewAvailable, let baseURL = configuration.apiBaseURL else { throw ClientError.invalidConfiguration }
        guard draft.canRequestRemotePreview, let destination = draft.destinationID, let color = draft.coasterColor else { throw ClientError.unavailable }
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/wish-preview"), cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = false
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
        request.httpBody = try JSONEncoder().encode(Request(
            categoryId: "go", destinationId: destination, coasterColor: color.rawValue,
            animalIds: draft.animals.map(\.rawValue)
        ))
        return request
    }

    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse {
        let request = try makeRequest(for: draft)
        guard let origin = configuration.apiBaseURL else { throw ClientError.invalidConfiguration }
        let delegate = SameOriginHTTPSRedirects(origin: origin)
        let session = URLSession(configuration: Self.sessionConfiguration(), delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let finalURL = http.url, WishBuildConfiguration.permitsRedirect(from: origin, to: finalURL),
              data.count < 500_000 else { throw ClientError.invalidResponse }
        return try JSONDecoder().decode(WishPreviewResponse.self, from: data)
    }
}

private final class SameOriginHTTPSRedirects: NSObject, URLSessionTaskDelegate {
    let origin: URL
    init(origin: URL) { self.origin = origin }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard let target = request.url, WishBuildConfiguration.permitsRedirect(from: origin, to: target) else {
            completionHandler(nil)
            return
        }
        var cleanRequest = request
        cleanRequest.httpShouldHandleCookies = false
        cleanRequest.setValue(nil, forHTTPHeaderField: "Cookie")
        cleanRequest.setValue(nil, forHTTPHeaderField: "Authorization")
        completionHandler(cleanRequest)
    }
}

struct OnlinePreviewDisclosure: Identifiable, Equatable {
    let id: UUID
    let draft: WishDraft
    let serviceHost: String
    var category: String { "go" }
    var destination: String { draft.destination?.name ?? "" }
    var color: String { draft.coasterColor?.label ?? "" }
    var animals: String { draft.animals.isEmpty ? "None" : draft.animals.map(\.label).joined(separator: ", ") }
}
