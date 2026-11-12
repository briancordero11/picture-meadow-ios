import AVFoundation
import XCTest
@testable import WishExplorer

final class SpeechVoicePreferenceTests: XCTestCase {
    func testPresetsHaveDistinctLabelsAndBoundedNaturalSpeechSettings() {
        XCTAssertEqual(SpeechVoicePreference.allCases.map(\.label), ["Boy", "Girl", "Man", "Woman"])
        XCTAssertEqual(SpeechVoicePreference.defaultPreference, .woman)
        for preset in SpeechVoicePreference.allCases {
            XCTAssertTrue((0.5...2.0).contains(preset.pitchMultiplier))
            XCTAssertTrue((AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate).contains(preset.rate))
        }
        XCTAssertTrue((1.1...1.2).contains(SpeechVoicePreference.boy.pitchMultiplier))
        XCTAssertTrue((1.1...1.2).contains(SpeechVoicePreference.girl.pitchMultiplier))
        XCTAssertEqual(SpeechVoicePreference.man.pitchMultiplier, 1)
        XCTAssertEqual(SpeechVoicePreference.woman.pitchMultiplier, 1)
    }

    func testSelectionExcludesCustomPersonalNoveltyAndNonEnglishVoicesBeforeRanking() {
        let options = [
            option("personal", quality: .premium, traits: [.isPersonalVoice]),
            option("novelty", quality: .premium, traits: [.isNoveltyVoice]),
            option("french", language: "fr-FR", quality: .premium),
            option("custom-provider", quality: .premium, providerIdentifier: "org.example.speech.English"),
            option("eligible", quality: .default)
        ]
        XCTAssertEqual(SpeechVoicePreference.woman.preferredOption(from: options)?.name, "eligible")
        XCTAssertNil(SpeechVoicePreference.woman.preferredOption(from: Array(options.dropLast())))
    }

    func testSelectionPrioritizesGenderThenQualityThenUSLocaleAndStableIdentifier() {
        let preference = SpeechVoicePreference.man
        let femalePremium = option("female-premium", gender: .female, quality: .premium)
        let maleBasic = option("male-basic", gender: .male)
        XCTAssertEqual(preference.preferredOption(from: [femalePremium, maleBasic])?.name, "male-basic")
        let maleEnhanced = option("male-enhanced", gender: .male, quality: .enhanced)
        let malePremiumGB = option("male-premium-gb", language: "en-GB", gender: .male, quality: .premium)
        let malePremiumUSZ = option("z-us", gender: .male, quality: .premium)
        let malePremiumUSA = option("a-us", gender: .male, quality: .premium)
        let inventory = [maleBasic, maleEnhanced, malePremiumGB, malePremiumUSZ, malePremiumUSA]
        XCTAssertEqual(preference.preferredOption(from: inventory)?.name, "a-us")
        XCTAssertEqual(preference.preferredOption(from: Array(inventory.reversed()))?.name, "a-us")
        XCTAssertEqual(preference.preferredOption(from: [maleBasic, maleEnhanced, malePremiumGB])?.name, "male-premium-gb")
        XCTAssertEqual(preference.preferredOption(from: [femalePremium])?.name, "female-premium")
        XCTAssertNotNil(preference.fallbackExplanation(for: femalePremium))
        XCTAssertNotNil(preference.fallbackExplanation(for: nil))
        XCTAssertNil(preference.fallbackExplanation(for: maleBasic))
    }

    @MainActor
    func testVoicePreferencePersistsIndependentlyOfRememberingWishChoices() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = makeStore(defaults)
        XCTAssertFalse(store.rememberChoices)
        store.voicePreset = .boy
        XCTAssertEqual(defaults.string(forKey: SpeechVoicePreference.defaultsKey), "boy")
        XCTAssertEqual(makeStore(defaults).voicePreset, .boy)
        store.reset()
        XCTAssertEqual(store.voicePreset, .boy, "Starting a fresh wish keeps the local speech preference.")
    }

    @MainActor
    func testInvalidStoredPreferenceFallsBackAndForgettingRemovesVoiceSetting() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("unrecognized-voice", forKey: SpeechVoicePreference.defaultsKey)
        let store = makeStore(defaults)
        XCTAssertEqual(store.voicePreset, .woman)
        store.voicePreset = .man
        store.forgetAllChoices()
        XCTAssertEqual(store.voicePreset, .woman)
        XCTAssertNil(defaults.object(forKey: SpeechVoicePreference.defaultsKey))
        XCTAssertEqual(makeStore(defaults).voicePreset, .woman)
    }

    @MainActor
    func testVoicePreviewRequiresAnActiveGrownUpSessionWithoutStartingAudio() throws {
        let (defaults, suite) = try isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = makeStore(defaults)
        XCTAssertFalse(store.previewVoice())
        store.caregiverPresented = true
        XCTAssertFalse(store.previewVoice(), "Opening the reading check alone is not authorization.")
        store.beginAdultSession()
        store.handleSceneActivity(false)
        XCTAssertFalse(store.previewVoice(), "Backgrounding revokes permission to preview.")
    }

    private func option(_ identifier: String, language: String = "en-US", gender: AVSpeechSynthesisVoiceGender = .female,
                        quality: AVSpeechSynthesisVoiceQuality = .default, traits: AVSpeechSynthesisVoice.Traits = [],
                        providerIdentifier: String? = nil) -> SpeechVoiceOption {
        SpeechVoiceOption(identifier: providerIdentifier ?? "com.apple.test.\(identifier)", name: identifier, language: language, gender: gender, quality: quality, traits: traits)
    }

    private func isolatedDefaults() throws -> (UserDefaults, String) {
        let suite = "SpeechVoicePreferenceTests.\(UUID().uuidString)"
        return (try XCTUnwrap(UserDefaults(suiteName: suite)), suite)
    }

    @MainActor
    private func makeStore(_ defaults: UserDefaults) -> WishStore {
        WishStore(defaults: defaults, configuration: .init(values: [:]), sceneAccessToken: nil)
    }
}
