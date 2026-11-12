import SwiftUI

struct ReportAIConcernView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.openURL) private var openURL
    @State private var topic: AIConcernTopic = .unsuitable
    @State private var contactMessage: String?

    var body: some View {
        Form {
            Section("Tell the publisher about a concern") {
                Text("If an AI picture feels unsuitable, discard it and keep using your chosen pictures offline. A grown-up can prepare an email to the publisher here.")
                Picker("Concern", selection: $topic) {
                    ForEach(AIConcernTopic.allCases) { item in Text(item.rawValue).tag(item) }
                }
                Text("This draft includes only the selected concern and the app version. No picture, wish choices, child's identity, medical information, service access code, or talking-board sentence is attached or shared automatically.")
                    .font(.footnote)
            }
            Section("Contact the publisher") {
                if let email = store.configuration.supportEmail {
                    Text(verbatim: email).textSelection(.enabled)
                    Button("Prepare an email report") { prepareReport(to: email) }
                        .disabled(!store.adultSessionActive)
                    Text("Your email app opens a draft. Review it and choose whether to send it. Your email app may include your email address. Please leave out private information about your Super Star.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if !store.adultSessionActive {
                        Text("Open grown-up settings before preparing a report.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Reporting by email is not connected in this prototype. The publisher's support address has not been configured, so this app cannot prepare or send a report yet.")
                        .foregroundStyle(.secondary)
                    Text("You can still discard the AI picture and continue with the offline picture board.")
                }
                Text("The publisher is responsible for reviewing reports and responding to concerns in a timely way. This screen does not send the concern to the AI provider.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let message = contactMessage {
                    Text(message).accessibilityAddTraits(.updatesFrequently)
                }
            }
        }
        .navigationTitle(topic == .privacy ? "Privacy question" : "Report an AI picture")
    }

    private func prepareReport(to email: String) {
        let body = "I would like help with a concern about this app.\n\nConcern: \(topic.rawValue)\n\(AppSupportContext.versionSummary)\n\nNo picture, wish choices, talking-board sentence, or child's information has been included automatically. Please describe what follow-up information is needed without requesting a child's identity or medical details."
        guard store.adultSessionActive,
              let url = AppSupportContext.emailURL(to: email, subject: topic == .privacy ? "Privacy or deletion question" : "AI picture concern", body: body) else {
            contactMessage = "A grown-up can copy the support address above to contact the publisher."
            return
        }
        openURL(url) { accepted in
            contactMessage = accepted
                ? "Your email app handles the report draft. Nothing is sent automatically by this app."
                : "An email app could not open. Copy the support address above and contact the publisher using your preferred email service."
        }
    }
}

enum AIConcernTopic: String, CaseIterable, Identifiable, Hashable {
    case unsuitable = "The picture feels unsafe or unsuitable"
    case choices = "The picture does not follow the chosen ideas"
    case likeness = "The picture includes a brand or an identifiable person"
    case privacy = "A privacy or deletion question"
    case other = "Another concern about the picture"
    var id: String { rawValue }
}
