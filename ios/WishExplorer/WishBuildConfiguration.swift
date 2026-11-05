import Foundation

struct WishBuildConfiguration {
    let publisherName: String?
    let supportEmail: String?
    let privacyPolicyURL: URL?
    let supportURL: URL?
    let apiBaseURL: URL?
    let onlinePreviewEnabled: Bool

    static var current: Self { Self(values: Bundle.main.infoDictionary ?? [:]) }
    var onlinePreviewAvailable: Bool { onlinePreviewEnabled && apiBaseURL != nil }

    init(values: [String: Any]) {
        publisherName = Self.publicText(values["WishPublisherName"])
        supportEmail = Self.validEmail(values["WishSupportEmail"])
        privacyPolicyURL = Self.httpsURL(values["WishPrivacyPolicyURL"])
        supportURL = Self.httpsURL(values["WishSupportURL"])
        apiBaseURL = Self.apiOriginURL(values["WishAPIBaseURL"])
        if let flag = values["WishOnlinePreviewEnabled"] as? String {
            onlinePreviewEnabled = flag.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "YES"
        } else {
            onlinePreviewEnabled = (values["WishOnlinePreviewEnabled"] as? Bool) == true
        }
    }

    static func publicText(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains("$("), !text.contains("${") else { return nil }
        return text
    }

    static func httpsURL(_ value: Any?) -> URL? {
        guard let text = publicText(value),
              let decoded = text.removingPercentEncoding,
              !decoded.contains("$("), !decoded.contains("${"),
              let parts = URLComponents(string: text), parts.scheme?.lowercased() == "https",
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil,
              parts.query == nil, parts.fragment == nil,
              parts.port == nil || (1...65535).contains(parts.port!),
              let url = parts.url else { return nil }
        return url
    }

    static func validEmail(_ value: Any?) -> String? {
        guard let text = publicText(value), !text.contains(where: { $0.isWhitespace }),
              text.range(of: #"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil else { return nil }
        return text
    }

    static func apiOriginURL(_ value: Any?) -> URL? {
        guard let url = httpsURL(value), url.path.isEmpty || url.path == "/" else { return nil }
        return url
    }

    static func permitsRedirect(from origin: URL, to destination: URL) -> Bool {
        guard let source = httpsURL(origin.absoluteString), let target = httpsURL(destination.absoluteString) else { return false }
        return source.host?.lowercased() == target.host?.lowercased()
            && (source.port ?? 443) == (target.port ?? 443)
    }
}
