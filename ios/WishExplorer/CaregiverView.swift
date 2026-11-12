import SwiftUI

struct CaregiverView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false
    @State private var onlineDisclosure: OnlinePreviewDisclosure?
    @State private var privacyPresented = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Explore at their pace") {
                    Text("Follow your Super Star's lead. Every step can be skipped, changed, or paused. A tap is an expression to explore together; it is not an eligibility decision or a final wish approval.")
                    Toggle("Read choice labels aloud", isOn: $store.readChoicesAloud)
                    Text("The talking board and Read my wish always speak when tapped, even with choice narration off.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Choices on this iPad") {
                    Toggle("Remember choices on this iPad", isOn: $store.rememberChoices)
                    Text("Off by default. This saves the chosen topic, actions, setting, favorites, and most-important choice, including older park choices. Names, photographs, contact details, and medical information are not requested. The talking-board sentence and AI pictures are not saved.")
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
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $onlineDisclosure) { disclosure in OnlinePreviewConsentView(disclosure: disclosure) }
            .sheet(isPresented: $privacyPresented) { PrivacyNoticeView() }
            .confirmationDialog("Start a fresh wish?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Clear choices and start again", role: .destructive) { store.reset(); dismiss() }
                Button("Keep my choices", role: .cancel) { }
            } message: {
                Text("This clears the choices saved on this iPad and the current talking-board sentence.")
            }
        }
    }
}
