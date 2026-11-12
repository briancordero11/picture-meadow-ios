import SwiftUI

/// An ephemeral reading check. It does not establish legal parental consent or identity.
struct AdultGateChallenge: Equatable {
    private var digits: [Int]
    private static let words = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
    var prompt: String { digits.map { Self.words[$0] }.joined(separator: " · ") }

    init() { digits = (0..<4).map { _ in Int.random(in: 0...9) } }
    init(digits: [Int]) {
        precondition(digits.count == 4 && digits.allSatisfy { (0...9).contains($0) })
        self.digits = digits
    }

    mutating func submit(_ answer: String) -> Bool {
        let expected = digits.map(String.init).joined()
        let accepted = answer.count == 4 && answer == expected
        renew()
        return accepted
    }

    mutating func renew() {
        let previous = digits
        repeat { digits = (0..<4).map { _ in Int.random(in: 0...9) } } while digits == previous
    }
}

struct AdultGateView: View {
    let purpose: String
    let showsPrivacyNotice: Bool
    var onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var challenge = AdultGateChallenge()
    @State private var answer = ""
    @State private var incorrect = false
    @State private var privacyPresented = false
    @FocusState private var answerIsFocused: Bool

    init(purpose: String, showsPrivacyNotice: Bool = false, onSuccess: @escaping () -> Void) {
        self.purpose = purpose
        self.showsPrivacyNotice = showsPrivacyNotice
        self.onSuccess = onSuccess
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Ask a grown-up").font(.largeTitle.weight(.bold)).accessibilityAddTraits(.isHeader)
                    Text(purpose).font(.title3)
                    Text("A grown-up can enter these four digits:")
                    Text(challenge.prompt).font(.title2.weight(.semibold))
                        .accessibilityLabel("Code in words: \(challenge.prompt)")
                    TextField("Four-digit code", text: $answer)
                        .focused($answerIsFocused)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder).font(.title2)
                        .accessibilityLabel("Enter the four-digit code")
                        .privacySensitive()
                        .onChange(of: answer) { _, value in
                            answer = String(value.filter { $0 >= "0" && $0 <= "9" }.prefix(4))
                            if answer.count == 4 { answerIsFocused = false }
                        }
                    if incorrect {
                        Text("Let's try the new code shown above.")
                            .foregroundStyle(.red).accessibilityAddTraits(.updatesFrequently)
                    }
                    PrimaryWishButton(title: "Continue", symbol: "arrow.right", action: submitCode)
                        .disabled(answer.count != 4)
                    Text("This reading check keeps grown-up tasks separate. It does not verify identity or provide permission to share information.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if showsPrivacyNotice {
                        Button("Read privacy notice") { privacyPresented = true }
                            .font(.headline).frame(minHeight: 44)
                    }
                }.padding(28)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { clear(); dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done entering code") { answerIsFocused = false }
                }
            }
            .onDisappear { clear() }
            .sheet(isPresented: $privacyPresented) { PrivacyNoticeView() }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { clear(); dismiss() }
            }
        }
    }

    private func submitCode() {
        guard answer.count == 4 else { return }
        answerIsFocused = false
        let passed = challenge.submit(answer)
        answer = ""
        if passed { incorrect = false; onSuccess() }
        else { incorrect = true }
    }

    private func clear() { answerIsFocused = false; answer = ""; challenge.renew(); incorrect = false }
}

struct AdultSettingsPortal: View {
    @EnvironmentObject private var store: WishStore
    var body: some View {
        ZStack {
            if store.adultSessionActive { CaregiverView() }
            else {
                AdultGateView(purpose: "Open the grown-up settings.", showsPrivacyNotice: true) { store.beginAdultSession() }
            }
        }
        .onDisappear { store.endAdultSession() }
    }
}

struct ExternalDestination: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
}

struct ExternalLinkGate: View {
    let destination: ExternalDestination
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        AdultGateView(purpose: "Open \(destination.title) in the browser at \(destination.url.host ?? "the configured website").") {
            openURL(destination.url)
            dismiss()
        }
    }
}
