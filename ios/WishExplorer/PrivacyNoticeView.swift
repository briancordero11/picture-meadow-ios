import SwiftUI

/// Readable without an adult gate; only leaving the app requires a separate gate.
struct PrivacyNoticeView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss
    @State private var externalDestination: ExternalDestination?
    @State private var confirmingForget = false

    var body: some View {
        NavigationStack {
            List {
                Section("Your wish works offline") {
                    Text("The pictures, talking board, speech, and wish drawing work on this iPad. No account, child's name, photograph, medical information, camera, or microphone is requested. This prototype has no advertising or analytics.")
                }
                Section("Choices and settings on this iPad") {
                    Text("The current interest, park, color, and animal choices stay in memory while the app runs. Remember choices is off by default. A grown-up can opt in to save those choices in the app's local device settings. Device backups may include app settings under the device owner's backup settings.")
                    Text("The read-choice-labels setting can also be saved locally. The talking-board sentence is never written to storage or sent online. It clears when you finish, reset, or the app becomes inactive.")
                    Text("Start a fresh wish clears the current and saved wish. Turn Remember choices off to remove the saved copy while keeping the current picture on screen. Forget choices below turns retention off and clears the wish, talking-board sentence, and read-aloud setting. It works without an internet connection.")
                    Button("Forget choices on this iPad", role: .destructive) { confirmingForget = true }
                }
                Section("Optional online descriptions") {
                    Text("Online descriptions are disabled in the default build. If the operator enables a service, a grown-up must pass the reading check and confirm each individual request. Only the wish verb, park, roller-coaster color, and animal ideas shown in that confirmation are sent. No talking-board sentence or child identity is included.")
                    Text("The service and hosting provider also receive an IP address, request time, and usual connection and request-header information. Hosting logs may retain that technical information. Check the published policy for the operator's retention period and contact details. Clearing this iPad does not erase information already received by a service or its hosting provider.")
                    Text("Description requests do not save website cookies or browsing history in this app. Requests stop when you leave grown-up settings or switch away from the app.")
                    if store.configuration.onlinePreviewAvailable, let host = store.configuration.apiBaseURL?.host {
                        Text("Configured service: \(host)")
                    } else {
                        Text("Online descriptions are unavailable in this build.").foregroundStyle(.secondary)
                    }
                }
                Section("Publisher and help") {
                    if let name = store.configuration.publisherName { Text(verbatim: name) }
                    else { Text("Publisher details are not configured in this prototype.").foregroundStyle(.secondary) }
                    if let email = store.configuration.supportEmail { Text(verbatim: email).textSelection(.enabled) }
                    if let url = store.configuration.privacyPolicyURL {
                        Button("Read the public privacy policy") {
                            externalDestination = ExternalDestination(title: "the public privacy policy", url: url)
                        }
                    } else {
                        Text("The public privacy policy link is not configured in this prototype.").foregroundStyle(.secondary)
                    }
                    if let url = store.configuration.supportURL {
                        Button("Open support website") {
                            externalDestination = ExternalDestination(title: "the support website", url: url)
                        }
                    }
                    Text("A grown-up reading check is required before an external website opens. This check does not verify identity or establish legal parental consent.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Privacy")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(item: $externalDestination) { destination in ExternalLinkGate(destination: destination) }
            .confirmationDialog("Forget choices on this iPad?", isPresented: $confirmingForget, titleVisibility: .visible) {
                Button("Forget and start again", role: .destructive) { store.forgetAllChoices() }
                Button("Keep my choices", role: .cancel) { }
            } message: { Text("This clears local choices and settings and turns Remember choices off. It does not contact a server.") }
        }
    }
}

struct OnlinePreviewConsentView: View {
    let disclosure: OnlinePreviewDisclosure
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Send these four choices once") {
                    LabeledContent("Wish verb", value: disclosure.category)
                    LabeledContent("Park", value: disclosure.destination)
                    LabeledContent("Color", value: disclosure.color)
                    LabeledContent("Animal ideas", value: disclosure.animals)
                }
                Section("Where it goes") {
                    Text("These choices will be sent to \(disclosure.serviceHost) to refresh the wish description. The service and hosting provider also receive the IP address, request time, and usual connection and request-header information.")
                    Text("The talking-board sentence, child's identity, photos, and medical information are not sent. This does not submit, book, or approve a wish. This permission applies only to this request.")
                }
                Section {
                    Button("Send these choices once") {
                        _ = store.confirmOnlinePreview(disclosure.id)
                        dismiss()
                    }
                    Button("Keep using offline", role: .cancel) { store.cancelOnlineConfirmation(disclosure.id); dismiss() }
                }
            }
            .navigationTitle("One online request")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { store.cancelOnlineConfirmation(disclosure.id); dismiss() } } }
            .onDisappear { store.cancelOnlineConfirmation(disclosure.id) }
        }
    }
}
