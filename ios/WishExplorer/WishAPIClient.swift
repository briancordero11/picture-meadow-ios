import Foundation

struct WishPreviewResponse: Decodable {
    struct ImagePayload: Decodable { let mimeType: String; let data: String }
    let id: String
    let title: String
    let description: String
    let image: ImagePayload
    let provider: String
}

struct WishAPIClient {
    enum ClientError: Error { case unavailable, invalidConfiguration, invalidResponse }
    private struct Request: Encodable {
        let categoryId: String
        let destinationId: String
        let coasterColor: String
        let animalIds: [String]
    }

    static var isConfigured: Bool { configuredBaseURL != nil }
    private static var configuredBaseURL: URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "WishAPIBaseURL") as? String,
              !value.isEmpty, !value.hasPrefix("$("),
              let url = URL(string: value), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil else { return nil }
        return url
    }

    func createPreview(for draft: WishDraft) async throws -> WishPreviewResponse {
        guard let baseURL = Self.configuredBaseURL else { throw ClientError.invalidConfiguration }
        guard let destination = draft.destinationID, let color = draft.coasterColor else { throw ClientError.unavailable }
        let url = baseURL.appendingPathComponent("v1/wish-preview")
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Request(
            categoryId: "go", destinationId: destination, coasterColor: color.rawValue,
            animalIds: draft.animals.map(\.rawValue)
        ))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw ClientError.invalidResponse }
        guard data.count < 500_000 else { throw ClientError.invalidResponse }
        return try JSONDecoder().decode(WishPreviewResponse.self, from: data)
    }
}
