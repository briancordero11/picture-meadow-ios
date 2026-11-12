import SwiftUI

struct CaregiverView: View {
    @EnvironmentObject private var store: WishStore
    @State private var confirmingReset = false
    @State private var onlineDisclosure: OnlinePreviewDisclosure?
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
                        Text("App information & help")
                    }.accessibilityIdentifier("grownup-app-information")
                    Button("Start a new wish") { confirmingReset = true }
                    Button("Done", action: close)
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
