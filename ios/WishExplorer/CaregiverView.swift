import SwiftUI

struct CaregiverView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Explore at their pace") {
                    Text("Follow the child's lead. Every step can be skipped, changed, or paused. A tap is an expression to explore together; it is not an eligibility decision or a final wish approval.")
                    Toggle("Read choice labels aloud", isOn: $store.readChoicesAloud)
                    Text("The talking board and Read my wish always speak when tapped, even with choice narration off.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Choices on this iPad") {
                    Toggle("Remember choices on this iPad", isOn: $store.rememberChoices)
                    Text("Off by default. This saves only the chosen interest picture, park, color, and animal ideas. Names, photographs, contact details, and medical information are not requested. The talking-board sentence is not saved.")
                    Button("Start a fresh wish", role: .destructive) { confirmingReset = true }
                }
                Section("Optional online description") {
                    Text("Your wish picture already works offline. Refreshing the description sends only park, color, and animal ideas to the configured service. It does not send the talking-board sentence or a child's identity. The picture continues to be drawn on this iPad.")
                    if WishAPIClient.isConfigured {
                        Button {
                            Task { await store.requestRemotePreview() }
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
                        Text("This prototype is in offline mode.").foregroundStyle(.secondary)
                    }
                    if let status = store.remoteStatus { Text(status) }
                }
                Section("About this prototype") {
                    Text("Wish Explorer is an independent exploration prototype inspired by the reference wish materials. It is not an official Make-A-Wish app and does not submit a wish, determine eligibility, promise a trip, or arrange care.")
                    Text("The amusement park journey is the complete demo. The other interest pictures open an exploration conversation. The main screen holds 20 interest pictures; the drawer holds the other 34 communication pictures. Open or close it using the small center tab, or drag the tab up or down. Stop, break, and finished remain inside the drawer. Park pictures are imaginary illustrations, not attraction listings. Communication support needs review with children, caregivers, and an AAC professional before real-world use.")
                }
            }
            .navigationTitle("For grown-ups")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Start a fresh wish?", isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Clear choices and start again", role: .destructive) { store.reset(); dismiss() }
                Button("Keep my choices", role: .cancel) { }
            } message: {
                Text("This clears the choices saved on this iPad and the current talking-board sentence.")
            }
        }
    }
}
