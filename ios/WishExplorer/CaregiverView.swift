import SwiftUI

struct CaregiverView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false
    @State private var onlineDisclosure: OnlinePreviewDisclosure?
    @State private var privacyPresented = false
    @State private var settingsPath: [GrownUpPage] = []

    var body: some View {
        NavigationStack(path: $settingsPath) {
            Form {
                Section("Privacy and app information") {
                    NavigationLink(value: GrownUpPage.privacy) {
                        Label("Privacy & Data", systemImage: "hand.raised.fill")
                    }.accessibilityIdentifier("grownup-privacy-data")
                    NavigationLink(value: GrownUpPage.information) {
                        Label("App Information & Help", systemImage: "info.circle")
                    }.accessibilityIdentifier("grownup-app-information")
                    NavigationLink(value: GrownUpPage.report) {
                        Label("Report an AI picture or privacy concern", systemImage: "exclamationmark.bubble")
                    }.accessibilityIdentifier("grownup-report-concern")
                }
                Section("Explore at their pace") {
                    Text("Follow your Super Star's lead. Every step can be skipped, changed, or paused. A tap is an expression to explore together; it is not an eligibility decision or a final wish approval.")
                    Toggle("Read choice labels aloud", isOn: $store.readChoicesAloud)
                    Text("The talking board and Read my wish always speak when tapped, even with choice narration off.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Current wish") {
                    Text("Saving, AI permissions, and forgetting choices are in Privacy & Data. Start a fresh wish clears the current and saved wish while keeping the remembering preference and service access code.")
                    Button("Start a fresh wish", role: .destructive) { confirmingReset = true }
                }
                SceneGenerationSettingsView()
                if store.onlinePreviewAvailable { Section("Optional online description") {
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
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Online descriptions are disabled or unconfigured in this build. The wish picture works offline.").foregroundStyle(.secondary)
                    }
                    if let status = store.remoteStatus { Text(status) }
                }
                }
                Section("Privacy") {
                    Button("Read privacy notice") { privacyPresented = true }
                    Text("Grown-up access lasts only while these settings are open and the app stays active. Each online request needs its own confirmation.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("About this prototype") {
                    Text("Wish Explorer is an independent exploration prototype inspired by the reference wish materials. It is not an official Make-A-Wish app and does not submit a wish, determine eligibility, promise a trip, or arrange care.")
                    Text("All 20 interest pictures lead to actions, broad settings, favorites, and the most-important idea. The drawer holds 34 communication pictures. Tap its center tab or drag it up or down. Stop, break, and finished remain in the drawer. Scenes are imagined ideas; they are not attraction listings, product availability, sponsor offers, or approval decisions. Communication support needs review with Super Stars, caregivers, and an AAC professional before real-world use.")
                }
            }
            .navigationTitle("For grown-ups")
            .navigationDestination(for: GrownUpPage.self) { page in
                switch page {
                case .privacy: PrivacySettingsView()
                case .information: AppInformationView()
                case .report: ReportAIConcernView()
                }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $onlineDisclosure) { disclosure in OnlinePreviewConsentView(disclosure: disclosure) }
            .sheet(isPresented: $privacyPresented) { PrivacyNoticeView() }
            .confirmationDialog("Start a fresh wish?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Clear choices and start again", role: .destructive) { store.reset(); dismiss() }
                Button("Keep my choices", role: .cancel) { }
            } message: {
                Text("This clears the choices saved on this iPad and the current talking-board sentence.")
            }
            .onAppear { openRequestedReport() }
            .onChange(of: store.aiReportRequested) { _, _ in openRequestedReport() }
        }
    }

    private func openRequestedReport() {
        guard store.adultSessionActive, store.aiReportRequested else { return }
        store.aiReportRequested = false
        settingsPath.append(.report)
    }
}

private enum GrownUpPage: Hashable { case privacy, information, report }
