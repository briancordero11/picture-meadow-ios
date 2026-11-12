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
                    Text("The topic, actions, setting, favorites, and most-important choice stay in memory while the app runs. Older park, color, and animal choices may also be present. Remember choices is off by default. A grown-up can opt in to save those choices in the app's local device settings. Device backups may include app settings under the device owner's backup settings.")
                    Text("The read-choice-labels setting can also be saved locally. The talking-board sentence is never written to storage or sent online. It clears when you finish, reset, or the app becomes inactive.")
                    Text("Start a fresh wish clears the current and saved wish. Turn Remember choices off to remove the saved copy while keeping the current picture on screen. Forget choices below turns retention off and clears the wish, talking-board sentence, read-aloud setting, AI pictures, and service access code. It works without an internet connection.")
                    Button("Forget choices on this iPad", role: .destructive) { confirmingForget = true }
                }
                Section("Optional AI pictures") {
                    Text("AI picture making is disabled in the default build. When configured, a grown-up must pass the reading check, have service access, and confirm each request. Only the selected catalog topic, actions, setting, favorites, and most-important choice shown in the confirmation are sent to the service. The service composes an image prompt for the disclosed AI provider and calls it directly. No picture files, intake documents, identity, medical information, or talking-board sentence are sent.")
                    Text("The generated picture is held in memory. It needs grown-up review before appearing with the wish. You can discard it at any time; changing or forgetting the wish also clears it. AI pictures are not saved to Photos, device preferences, or a public gallery by this app. Closing settings or switching away cancels in-flight requests, although a provider may already have processed a request.")
                    Text("The service and hosting provider receive connection details including IP address and time. The image provider processes the image prompt and output. Your operator must verify the actual account's retention settings, eligibility, and safeguards for minors and publish those details before enabling it. Zero Data Retention requires the provider's approval and account configuration; an app setting cannot enable it. Forgetting choices does not recall data already processed externally.")
                    Text("A service access code, if entered, is stored persistently in this iPad's Keychain and can be read only while the iPad is unlocked. It is not synchronized to other devices. It is separate from the provider's API credentials. Remove it in grown-up settings or use Forget choices.")
                    Text("OpenAI's standard API abuse-monitoring records may ordinarily be retained for up to 30 days. Approved Zero Data Retention changes that account's treatment. This prototype has not established or enabled that approval. Hosting logs and support correspondence can have separate retention periods, which the operator must publish before launch.")
                    if let provider = store.configuration.aiProviderName, store.configuration.sceneGenerationAvailable { Text("Configured image provider: \(provider)") }
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
                Section("Support and reporting") {
                    Text("A grown-up can report an unsuitable AI picture or privacy concern from App Information & Help. Where a real support address is configured, the app prepares a generic email draft with the selected issue and app version. It does not attach the picture, choices, talking-board sentence, identity, or service code. You control any additional details and sending in your mail app. The publisher receives correspondence you choose to send, including your reply address.")
                    Text("This app creates no user accounts. Forget choices removes local app data and access; it does not send a provider-deletion request or erase older device backups.")
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
