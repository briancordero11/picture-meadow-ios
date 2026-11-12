import Foundation

/// Internal park API verb and compatibility values for previously saved drafts.
/// Child-facing navigation uses the 20 InterestChoice pictures instead.
enum WishCategory: String, Codable {
    case go, be, meet, have, give
    case helpChoose = "explore"
}

enum CoasterColor: String, CaseIterable, Codable, Identifiable {
    case blue, pink, purple, green
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum WishAnimal: String, CaseIterable, Codable, Identifiable {
    case giraffe, dolphin, tiger
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self { case .giraffe: "leaf.fill"; case .dolphin: "water.waves"; case .tiger: "pawprint.fill" }
    }
    var emoji: String {
        switch self { case .giraffe: "🦒"; case .dolphin: "🐬"; case .tiger: "🐯" }
    }
}

struct WishDestination: Identifiable, Equatable {
    let id: String
    let name: String
    let location: String
    let symbol: String
    static let all: [Self] = [
        .init(id: "six-flags-great-america", name: "Six Flags Great America", location: "Illinois", symbol: "sparkles"),
        .init(id: "disney-world", name: "Walt Disney World", location: "Florida", symbol: "building.2.crop.circle.fill"),
        .init(id: "universal-orlando", name: "Universal Orlando", location: "Florida", symbol: "globe.americas.fill")
    ]
}

/// Preference exploration only. No identity, contact details, eligibility, or clinical fields.
struct WishDraft: Codable, Equatable {
    var category: WishCategory? = nil
    var interestID: String? = nil
    var destinationID: String? = nil
    var coasterColor: CoasterColor? = nil
    var animals: [WishAnimal] = []
    var wantsAnimals: Bool? = nil
    var selectedActionIDs: [String] = []
    var selectedSettingID: String? = nil
    var favoriteIDs: [String] = []
    var essentialChoiceID: String? = nil

    // Older saved drafts predate the action journey. Missing choices remain unanswered.
    private enum CodingKeys: String, CodingKey {
        case category, interestID, destinationID, coasterColor, animals, wantsAnimals
        case selectedActionIDs, selectedSettingID, favoriteIDs, essentialChoiceID
    }
    init(category: WishCategory? = nil, interestID: String? = nil, destinationID: String? = nil,
         coasterColor: CoasterColor? = nil, animals: [WishAnimal] = [], wantsAnimals: Bool? = nil,
         selectedActionIDs: [String] = [], selectedSettingID: String? = nil,
         favoriteIDs: [String] = [], essentialChoiceID: String? = nil) {
        self.category = category; self.interestID = interestID; self.destinationID = destinationID
        self.coasterColor = coasterColor; self.animals = animals; self.wantsAnimals = wantsAnimals
        self.selectedActionIDs = selectedActionIDs; self.selectedSettingID = selectedSettingID
        self.favoriteIDs = favoriteIDs; self.essentialChoiceID = essentialChoiceID
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        category = try values.decodeIfPresent(WishCategory.self, forKey: .category)
        interestID = try values.decodeIfPresent(String.self, forKey: .interestID)
        destinationID = try values.decodeIfPresent(String.self, forKey: .destinationID)
        coasterColor = try values.decodeIfPresent(CoasterColor.self, forKey: .coasterColor)
        animals = try values.decodeIfPresent([WishAnimal].self, forKey: .animals) ?? []
        wantsAnimals = try values.decodeIfPresent(Bool.self, forKey: .wantsAnimals)
        selectedActionIDs = try values.decodeIfPresent([String].self, forKey: .selectedActionIDs) ?? []
        selectedSettingID = try values.decodeIfPresent(String.self, forKey: .selectedSettingID)
        favoriteIDs = try values.decodeIfPresent([String].self, forKey: .favoriteIDs) ?? []
        essentialChoiceID = try values.decodeIfPresent(String.self, forKey: .essentialChoiceID)
    }

    var sceneChoices: [JourneyChoice] { JourneyCatalog.shared.choices(for: self) }
    var canRequestScene: Bool { interest != nil && !sceneChoices.isEmpty }
    var sceneDescription: String {
        var parts = ["My \(interest?.label ?? "wish") idea."]
        if !selectedActionIDs.isEmpty {
            let actions = selectedActionIDs.compactMap { JourneyCatalog.shared.choice(id: $0)?.label.lowercased() }
            if !actions.isEmpty { parts.append("I want to \(actions.joined(separator: ", ")).") }
        }
        if let setting = selectedSettingID.flatMap({ JourneyCatalog.shared.choice(id: $0) }) {
            parts.append("I imagine \(setting.label.lowercased()).")
        }
        let favorites = favoriteIDs.compactMap { JourneyCatalog.shared.choice(id: $0)?.label.lowercased() }
        if !favorites.isEmpty { parts.append("I like \(favorites.joined(separator: ", ")).") }
        if let essential = essentialChoiceID.flatMap({ JourneyCatalog.shared.choice(id: $0) }) {
            parts.append("\(essential.label) matters most to me.")
        }
        return parts.joined(separator: " ")
    }

    var destination: WishDestination? { WishDestination.all.first { $0.id == destinationID } }
    var canPreview: Bool { category == .go }
    var canRequestRemotePreview: Bool { category == .go && destination != nil && coasterColor != nil }

    var postcardDescription: String {
        let park = destination?.name ?? "an amusement park"
        var text = "I wish to go to \(park)."
        if let color = coasterColor { text += " I like the \(color.label.lowercased()) roller coaster." }
        if wantsAnimals == true && !animals.isEmpty {
            text += " I would also like to explore \(animals.map { $0.label.lowercased() }.joined(separator: ", ")) ideas."
        }
        return text
    }

    mutating func selectCategory(_ category: WishCategory) {
        if self.category != category { self = WishDraft(category: category) }
    }

    mutating func selectInterest(_ interest: InterestChoice) {
        if interestID != interest.id {
            self = WishDraft(category: interest == .amusementPark ? .go : nil, interestID: interest.id)
        }
    }

    var interest: InterestChoice? { interestID.flatMap(InterestChoice.init(rawValue:)) }

    mutating func toggleAnimal(_ animal: WishAnimal) {
        if animals.contains(animal) { animals.removeAll { $0 == animal } }
        else { animals.append(animal) }
    }
}

enum WishStep: Int, CaseIterable {
    case welcome, interests, destination, color, animals, postcard, otherWish, journey
    var progress: Double {
        switch self {
        case .welcome, .interests, .otherWish: 0
        case .journey: 0.25
        case .destination: 0.25
        case .color: 0.5
        case .animals: 0.75
        case .postcard: 1
        }
    }
    var previous: Self {
        switch self {
        case .welcome, .interests: .welcome
        case .destination, .otherWish, .journey: .interests
        case .color: .destination
        case .animals: .color
        case .postcard: .animals
        }
    }
}

enum InterestChoice: String, CaseIterable, Codable, Identifiable {
    case sportingEvent = "sporting-event", camp, athlete
    case vrEquipment = "vr-equipment", amusementPark = "amusement-park"
    case school, celebrity, art, home, waterpark, animals, bike, hospital, party, gift, train, playground, music
    case sensoryRoom = "sensory-room", fishing
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sportingEvent: "sporting event"
        case .vrEquipment: "VR equipment"
        case .amusementPark: "amusement park"
        case .sensoryRoom: "sensory room"
        default: rawValue
        }
    }
}

struct CommunicationWord: Identifiable {
    let label: String
    let speech: String
    let symbol: String
    let group: Group
    var id: String { label }
    enum Group: String, CaseIterable, Identifiable {
        case people = "People", actions = "Actions", feelings = "Feelings & needs", questions = "Questions"
        var id: String { rawValue }
    }
    private static let vocabulary: [Self] = [
        .init(label: "I", speech: "I", symbol: "person.fill", group: .people),
        .init(label: "You", speech: "You", symbol: "person.crop.circle", group: .people),
        .init(label: "We", speech: "We", symbol: "person.2.fill", group: .people),
        .init(label: "Want", speech: "want", symbol: "star.fill", group: .actions),
        .init(label: "Go", speech: "go", symbol: "arrow.forward.circle.fill", group: .actions),
        .init(label: "See", speech: "see", symbol: "eye.fill", group: .actions),
        .init(label: "Like", speech: "like", symbol: "heart.fill", group: .actions),
        .init(label: "Meet", speech: "meet", symbol: "person.2.wave.2.fill", group: .actions),
        .init(label: "Eat", speech: "eat", symbol: "fork.knife", group: .actions),
        .init(label: "Give", speech: "give", symbol: "gift.fill", group: .actions),
        .init(label: "Stop", speech: "Stop", symbol: "stop.circle.fill", group: .actions),
        .init(label: "Act", speech: "act", symbol: "theatermasks.fill", group: .actions),
        .init(label: "Watch", speech: "watch", symbol: "play.rectangle.fill", group: .actions),
        .init(label: "Wish", speech: "wish", symbol: "sparkles", group: .actions),
        .init(label: "More", speech: "more", symbol: "plus.circle.fill", group: .actions),
        .init(label: "Yes", speech: "Yes", symbol: "checkmark.circle.fill", group: .feelings),
        .init(label: "No / don't", speech: "No", symbol: "xmark.circle.fill", group: .feelings),
        .init(label: "Happy", speech: "I feel happy", symbol: "face.smiling.fill", group: .feelings),
        .init(label: "Tired", speech: "I feel tired", symbol: "moon.fill", group: .feelings),
        .init(label: "Hot", speech: "I feel hot", symbol: "sun.max.fill", group: .feelings),
        .init(label: "Cold", speech: "I feel cold", symbol: "snowflake", group: .feelings),
        .init(label: "Wet", speech: "wet", symbol: "drop.fill", group: .feelings),
        .init(label: "Dry", speech: "dry", symbol: "sun.haze.fill", group: .feelings),
        .init(label: "I need time to think", speech: "I need time to think", symbol: "clock.fill", group: .feelings),
        .init(label: "I need a break", speech: "I need a break", symbol: "pause.circle.fill", group: .feelings),
        .init(label: "Finished", speech: "I am finished", symbol: "flag.checkered", group: .feelings),
        .init(label: "Help", speech: "I need help", symbol: "hand.raised.fill", group: .feelings),
        .init(label: "This is fun!", speech: "This is fun!", symbol: "face.smiling.fill", group: .feelings),
        .init(label: "Thank you!", speech: "Thank you!", symbol: "heart.circle.fill", group: .feelings),
        .init(label: "What", speech: "What?", symbol: "questionmark.circle.fill", group: .questions),
        .init(label: "Where", speech: "Where?", symbol: "mappin.circle.fill", group: .questions),
        .init(label: "Who", speech: "Who?", symbol: "person.crop.circle.badge.questionmark", group: .questions),
        .init(label: "When", speech: "When?", symbol: "calendar", group: .questions),
        .init(label: "Why", speech: "Why?", symbol: "questionmark.bubble.fill", group: .questions)
    ]
    static let mainRows: [[Self]] = {
        let labels = [
            ["I", "Want", "See", "Wet", "More"],
            ["You", "Go", "Help", "Dry", "Where"],
            ["We", "Stop", "Act", "Hot", "What"],
            ["Watch", "Like", "Give", "Cold", "When"],
            ["Wish", "Eat", "Meet", "Tired", "Who"],
            ["Yes", "No / don't", "Finished", "Happy", "Why"]
        ]
        return labels.map { row in row.compactMap { label in vocabulary.first { $0.label == label } } }
    }()
    static let phraseWords: [Self] = ["This is fun!", "Thank you!", "I need time to think", "I need a break"]
        .compactMap { label in vocabulary.first { $0.label == label } }
    static let all: [Self] = mainRows.flatMap { $0 } + phraseWords
}
