import Foundation

enum WishCategory: String, CaseIterable, Codable, Identifiable {
    case go, be, meet, have, give
    case helpChoose = "explore"
    var id: String { rawValue }
    var title: String { self == .helpChoose ? "Help me choose" : "I wish to \(rawValue)" }
    var symbol: String {
        switch self {
        case .go: "airplane"
        case .be: "theatermasks.fill"
        case .meet: "person.2.fill"
        case .have: "gift.fill"
        case .give: "heart.fill"
        case .helpChoose: "questionmark.bubble.fill"
        }
    }
    var subtitle: String {
        switch self {
        case .go: "An amazing adventure"
        case .be: "Try something wonderful"
        case .meet: "Someone special"
        case .have: "Something just for me"
        case .give: "Make someone smile"
        case .helpChoose: "Let's explore together"
        }
    }
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
    var destinationID: String? = nil
    var coasterColor: CoasterColor? = nil
    var animals: [WishAnimal] = []
    var wantsAnimals: Bool? = nil

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

    mutating func toggleAnimal(_ animal: WishAnimal) {
        if animals.contains(animal) { animals.removeAll { $0 == animal } }
        else { animals.append(animal) }
    }
}

enum WishStep: Int, CaseIterable {
    case welcome, categories, destination, color, animals, postcard, otherWish
    var progress: Double {
        switch self {
        case .welcome, .categories, .otherWish: 0
        case .destination: 0.25
        case .color: 0.5
        case .animals: 0.75
        case .postcard: 1
        }
    }
    var previous: Self {
        switch self {
        case .welcome, .categories: .welcome
        case .destination, .otherWish: .categories
        case .color: .destination
        case .animals: .color
        case .postcard: .animals
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
        case people = "People", actions = "Actions", wishes = "Wish ideas", feelings = "Feelings & needs", questions = "Questions"
        var id: String { rawValue }
    }
    static let all: [Self] = [
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
        .init(label: "Amusement park", speech: "an amusement park", symbol: "sparkles", group: .wishes),
        .init(label: "Animals", speech: "animals", symbol: "pawprint.fill", group: .wishes),
        .init(label: "Music", speech: "music", symbol: "music.note", group: .wishes),
        .init(label: "Art", speech: "art", symbol: "paintpalette.fill", group: .wishes),
        .init(label: "Waterpark", speech: "a waterpark", symbol: "water.waves", group: .wishes),
        .init(label: "Sensory room", speech: "a sensory room", symbol: "lightbulb.fill", group: .wishes),
        .init(label: "Sporting event", speech: "a sporting event", symbol: "sportscourt.fill", group: .wishes),
        .init(label: "Camp", speech: "camp", symbol: "tent.fill", group: .wishes),
        .init(label: "Athlete", speech: "an athlete", symbol: "figure.run", group: .wishes),
        .init(label: "VR equipment", speech: "VR equipment", symbol: "visionpro.fill", group: .wishes),
        .init(label: "School", speech: "school", symbol: "building.2.fill", group: .wishes),
        .init(label: "Celebrity", speech: "a celebrity", symbol: "star.circle.fill", group: .wishes),
        .init(label: "Home", speech: "home", symbol: "house.fill", group: .wishes),
        .init(label: "Bike", speech: "a bike", symbol: "bicycle", group: .wishes),
        .init(label: "Hospital", speech: "hospital", symbol: "cross.case.fill", group: .wishes),
        .init(label: "Party", speech: "a party", symbol: "party.popper.fill", group: .wishes),
        .init(label: "Gift", speech: "a gift", symbol: "gift.fill", group: .wishes),
        .init(label: "Train", speech: "a train", symbol: "tram.fill", group: .wishes),
        .init(label: "Playground", speech: "a playground", symbol: "figure.play", group: .wishes),
        .init(label: "Fishing", speech: "fishing", symbol: "fish.fill", group: .wishes),
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
}
