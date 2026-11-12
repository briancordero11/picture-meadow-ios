import SwiftUI

struct CaregiverView: View {
    @EnvironmentObject private var store: WishStore
    @State private var confirmingReset = false
    @State private var onlineDisclosure: OnlinePreviewDisclosure?
    @State private var privacyPresented = false
    @State private var settingsPath: [GrownUpPage] = []

    var body: some View {
        NavigationStack(path: $settingsPath) {
            WishSettingsPage(title: "For grown-ups", showsBack: false, showsDone: false) {
                WishSettingsSection {
                    NavigationLink(value: GrownUpPage.voice) { Text("Voice preference") }
                        .accessibilityIdentifier("grownup-voice-preference")
                    NavigationLink(value: GrownUpPage.image) {
                        Text("AI picture generation")
                    }.accessibilityIdentifier("grownup-ai-generation")
                    NavigationLink(value: GrownUpPage.privacy) {
                        Text("Privacy & Data")
                    }.accessibilityIdentifier("grownup-privacy-data")
                    NavigationLink(value: GrownUpPage.information) {
                        Text("App Information & Help")
                    }.accessibilityIdentifier("grownup-app-information")
                    NavigationLink(value: GrownUpPage.report) {
                        Text("Report an AI picture or privacy concern")
                    }.accessibilityIdentifier("grownup-report-concern")
                    Button("Start a new wish") { confirmingReset = true }
                    Button("Done", action: close)
                }
                WishSettingsSection("Explore at their pace") {
                    Text("Follow your Super Star's lead. Every question is optional: Next can leave it unanswered, Back revisits it, and Home returns to the wish pictures while keeping choices. You can pause at any time. A tap is an expression to explore together; it is not an eligibility decision or a final wish approval.")
                    Toggle("Read choice labels aloud", isOn: $store.readChoicesAloud)
                        .toggleStyle(WishSettingsToggleStyle())
                    Text("The talking board and Read my wish always speak when tapped, even with choice narration off.")
                        .font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
                }
                WishSettingsSection("Current wish") {
                    Text("Saving, AI permissions, and forgetting choices are in Privacy & Data. Start a fresh wish clears the current and saved wish while keeping the remembering preference and service access code.")
                }
                if store.onlinePreviewAvailable { WishSettingsSection("Optional online description") {
                    Text("Your wish picture already works offline. Refreshing the description sends only park, color, and animal ideas to the configured service. It does not send the talking-board sentence or a child's identity. The picture continues to be drawn on this iPad.")
                    if store.onlinePreviewAvailable {
                        Button {
                            onlineDisclosure = store.prepareOnlinePreview()
                        } label: {
                            HStack {
                                Text(store.isLoadingPreview ? "Refreshing description…" : "Refresh this wish's description")
                                if store.isLoadingPreview { ProgressView() }
                            }
                        }.disabled(!store.draft.canRequestRemotePreview || store.isLoadingPreview)
                        if !store.draft.canRequestRemotePreview {
                            Text("Choose an amusement park and a color to try the optional description service.")
                                .font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
                        }
                    } else {
                        Text("Online descriptions are disabled or unconfigured in this build. The wish picture works offline.").foregroundStyle(WishSettingsAppearance.secondary)
                    }
                    if let status = store.remoteStatus { Text(status) }
                }
                }
                WishSettingsSection("Privacy") {
                    Button("Read privacy notice") { privacyPresented = true }
                    Text("Grown-up access lasts only while these settings are open and the app stays active. Each online request needs its own confirmation.")
                        .font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
                }
                WishSettingsSection("About this prototype") {
                    Text("Wish Explorer is an independent exploration prototype inspired by the reference wish materials. It is not an official Make-A-Wish app and does not submit a wish, determine eligibility, promise a trip, or arrange care.")
                    Text("All 20 interest pictures lead to actions, broad settings, and the most-important idea. Favorites from the dedicated home section carry into each wish automatically. The drawer holds 34 communication pictures. Tap its center tab or drag it up or down. Stop, break, and finished remain in the drawer. Scenes are imagined ideas; they are not attraction listings, product availability, sponsor offers, or approval decisions. Communication support needs review with Super Stars, caregivers, and an AAC professional before real-world use.")
                }
            }
            .navigationDestination(for: GrownUpPage.self) { page in
                switch page {
                case .voice: WishSettingsPage(title: "Voice preference") { SpeechVoicePreferenceSection() }
                case .image: WishSettingsPage(title: "AI picture generation") { SceneGenerationSettingsView() }
                case .privacy: PrivacySettingsView()
                case .information: AppInformationView()
                case .report: ReportAIConcernView()
                }
            }
            .sheet(item: $onlineDisclosure) { disclosure in OnlinePreviewConsentView(disclosure: disclosure) }
            .sheet(isPresented: $privacyPresented) { PrivacyNoticeView() }
            .confirmationDialog("Start a new wish?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Clear choices and start again", role: .destructive) { store.reset(); close() }
                Button("Keep my choices", role: .cancel) { }
            } message: {
                Text("This clears the choices saved on this iPad and the current talking-board sentence.")
            }
            .onAppear { openRequestedPage() }
            .onChange(of: store.aiReportRequested) { _, _ in openRequestedPage() }
            .onChange(of: store.aiGenerationRequested) { _, _ in openRequestedPage() }
        }
    }

    private func close() { store.endAdultSession(); store.clearSettingsRequests(); store.caregiverPresented = false }

    private func openRequestedPage() {
        guard store.adultSessionActive else { return }
        if store.aiReportRequested {
            store.clearSettingsRequests()
            settingsPath.append(.report)
        } else if store.aiGenerationRequested {
            store.clearSettingsRequests()
            settingsPath.append(.image)
        }
    }
}

private enum GrownUpPage: Hashable { case privacy, information, report, image, voice }
