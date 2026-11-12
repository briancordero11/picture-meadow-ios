import AVFoundation
import SwiftUI

enum SpeechVoicePreference: String, CaseIterable, Identifiable {
    case boy, girl, man, woman

    static let defaultsKey = "wish-explorer.voice-preset.v1"
    static let defaultPreference: Self = .woman
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var preferredGender: AVSpeechSynthesisVoiceGender {
        switch self {
        case .boy, .man: .male
        case .girl, .woman: .female
        }
    }
    var pitchMultiplier: Float {
        switch self {
        case .boy: 1.15
        case .girl: 1.18
        case .man, .woman: 1.0
        }
    }
    var rate: Float { 0.40 }
    var styleExplanation: String {
        switch self {
        case .boy, .girl:
            "This style raises an adult voice's pitch slightly. It is not a recorded child voice."
        case .man, .woman:
            "This style uses an available adult voice at its usual pitch."
        }
    }

    /// Rank only eligible voices already returned by the device. This never requests a download.
    func preferredOption(from options: [SpeechVoiceOption]) -> SpeechVoiceOption? {
        options.filter(\.isEligible).sorted { first, second in
            let firstMatches = first.gender == preferredGender
            let secondMatches = second.gender == preferredGender
            if firstMatches != secondMatches { return firstMatches }
            if first.qualityRank != second.qualityRank { return first.qualityRank > second.qualityRank }
            let firstUS = first.language.lowercased() == "en-us"
            let secondUS = second.language.lowercased() == "en-us"
            if firstUS != secondUS { return firstUS }
            return first.identifier < second.identifier
        }.first
    }

    func availableVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        guard let option = preferredOption(from: voices.map(SpeechVoiceOption.init(voice:))) else { return nil }
        return voices.first { $0.identifier == option.identifier }
    }

    func fallbackExplanation(for option: SpeechVoiceOption?) -> String? {
        guard let option else { return "No eligible English voice is available on this iPad. Speech is unavailable until an English voice is available in iPad Settings." }
        guard option.gender != preferredGender else { return nil }
        let gender = preferredGender == .male ? "male" : "female"
        return "A matching \(gender) English voice is unavailable. This style uses \(option.name) instead."
    }
}

/// Voice metadata is separate from AVSpeechSynthesisVoice so ranking can be checked without a particular device inventory.
struct SpeechVoiceOption {
    let identifier: String
    let name: String
    let language: String
    let gender: AVSpeechSynthesisVoiceGender
    let quality: AVSpeechSynthesisVoiceQuality
    var traits: AVSpeechSynthesisVoice.Traits = []

    var isEligible: Bool {
        // Compatibility allowlist: custom speech extensions can also appear in the system inventory.
        identifier.hasPrefix("com.apple.")
            && language.split(separator: "-").first?.lowercased() == "en"
            && !traits.contains(.isNoveltyVoice) && !traits.contains(.isPersonalVoice)
    }
    var qualityRank: Int {
        switch quality {
        case .premium: 3
        case .enhanced: 2
        case .default: 1
        @unknown default: 0
        }
    }
    var qualityLabel: String {
        switch quality {
        case .premium: "Premium quality"
        case .enhanced: "Enhanced quality"
        case .default: "Basic quality"
        @unknown default: "System quality"
        }
    }
    var summary: String { "\(name) · \(language) · \(qualityLabel)" }
}

extension SpeechVoiceOption {
    init(voice: AVSpeechSynthesisVoice) {
        self.init(identifier: voice.identifier, name: voice.name, language: voice.language,
                  gender: voice.gender, quality: voice.quality, traits: voice.voiceTraits)
    }
}

struct SpeechVoicePreferenceSection: View {
    @EnvironmentObject private var store: WishStore

    var body: some View {
        let selected = store.voicePreset.availableVoice().map(SpeechVoiceOption.init(voice:))
        WishSettingsSection {
            Text("Choose how the picture board and wish ideas sound. Selection stays quiet until you tap Preview voice.")
            Text("Voice style").font(WishTheme.bodyFont(size: 16, weight: .bold))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(SpeechVoicePreference.allCases) { preference in
                    Button { store.voicePreset = preference } label: {
                        HStack(spacing: 10) {
                            Text(preference.label).frame(maxWidth: .infinity, alignment: .leading)
                            Circle().stroke(WishSettingsAppearance.ink, lineWidth: 1)
                                .overlay { if store.voicePreset == preference { Circle().fill(WishSettingsAppearance.ink).padding(5) } }
                                .frame(width: 22, height: 22)
                        }
                        .font(WishTheme.bodyFont(size: 16))
                        .padding(.horizontal, 12).frame(minHeight: 56)
                        .background(Color(red: 1, green: 246 / 255, blue: 232 / 255), in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishSettingsAppearance.outline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(preference.label) voice")
                    .accessibilityAddTraits(store.voicePreset == preference ? [.isSelected] : [])
                }
            }
            LabeledContent("Available voice", value: selected?.summary ?? "Unavailable")
            Text(store.voicePreset.styleExplanation).font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
            if let fallback = store.voicePreset.fallbackExplanation(for: selected) {
                Text(fallback).font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
            }
            Button("Preview voice") { store.previewVoice() }
                .buttonStyle(WishSettingsActionStyle(kind: .primary))
                .disabled(selected == nil || !store.adultSessionActive)
            Button { store.stopSpeaking() } label: {
                HStack(spacing: 8) { WishUIIcon(name: "volume-off", size: 20); Text("Stop speaking") }
            }.accessibilityLabel("Stop voice")
            Text("Uses Apple English voices already available on this iPad. Voice names and quality vary by device. Custom-provider, personal, and novelty voices are excluded. Choosing a style does not play audio; tap Preview voice to listen. This preference is saved on this iPad even when remembering wish choices is off.")
                .font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
        }
    }
}
