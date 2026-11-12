import Foundation

struct JourneyChoice: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let label: String
    let symbol: String
    let prompt: String
}

struct JourneyInterest: Codable, Sendable, Identifiable {
    let id: String
    let actions: [JourneyChoice]
    let settings: [JourneyChoice]
}

struct JourneyFavoriteGroup: Codable, Sendable, Identifiable {
    let id: String
    let label: String
    let options: [JourneyChoice]
}

struct JourneyCatalog: Codable, Sendable {
    let version: Int
    let interests: [JourneyInterest]
    let favorites: [JourneyFavoriteGroup]

    static let shared = (try? load()) ?? JourneyCatalog(version: 1, interests: [], favorites: [])

    static func load(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "journey-catalog", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let catalog = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        guard catalog.version == 1 else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unsupported journey catalog version."))
        }
        return catalog
    }

    var favoriteOptions: [JourneyChoice] { favorites.flatMap(\.options) }

    func interest(id: String?) -> JourneyInterest? {
        interests.first { $0.id == id }
    }

    func choice(id: String) -> JourneyChoice? {
        interests.lazy.flatMap { $0.actions + $0.settings }.first { $0.id == id }
            ?? favoriteOptions.first { $0.id == id }
    }

    func choices(for draft: WishDraft) -> [JourneyChoice] {
        let identifiers = draft.selectedActionIDs + [draft.selectedSettingID].compactMap { $0 } + draft.favoriteIDs
        var seen = Set<String>()
        return identifiers.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return choice(id: id)
        }
    }
}
