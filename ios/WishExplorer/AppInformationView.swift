import SwiftUI

struct AppInformationView: View {
    @EnvironmentObject private var store: WishStore
    @Environment(\.openURL) private var openURL
    @State private var privacyPresented = false
    @State private var externalDestination: ExternalDestination?
    @State private var contactMessage: String?

    var body: some View {
        Form {
            Section("About this app") {
                Text("Explore ideas with your Super Star through pictures, actions, and favorites. A wish picture is an idea to discuss together; it does not confirm an event, item, or trip.")
                LabeledContent("App", value: AppSupportContext.appName)
                LabeledContent("Version", value: AppSupportContext.version)
                LabeledContent("Build", value: AppSupportContext.build)
            }
            Section("Publisher and help") {
                if let publisher = store.configuration.publisherName {
                    Text(verbatim: publisher)
                } else {
                    Text("Publisher details are not configured in this prototype.")
                        .foregroundStyle(.secondary)
                }
                if let email = store.configuration.supportEmail {
                    Text(verbatim: email).textSelection(.enabled)
                    Button("Prepare an email to support") {
                        prepareEmail(to: email, subject: "App support", body: "I have a question about this app.\n\n\(AppSupportContext.versionSummary)\n\nPlease leave out a child's name, photographs, medical information, and talking-board sentence.")
                    }.disabled(!store.adultSessionActive)
                } else {
                    Text("Support email is not connected in this prototype. An email cannot be prepared here yet.")
                        .foregroundStyle(.secondary)
                }
                if let url = store.configuration.supportURL {
                    Button("Open the support website") { openWebsite(url, title: "the support website") }
                }
                NavigationLink("Report an unsuitable AI picture") { ReportAIConcernView() }
                Text("A grown-up chooses whether to send an email. The email app may include the sender's email address.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Privacy and your information") {
                Button("Privacy and data on this iPad") { privacyPresented = true }
                if let url = store.configuration.privacyPolicyURL {
                    Button("Read the public privacy policy") { openWebsite(url, title: "the public privacy policy") }
                } else {
                    Text("The public privacy policy link is not configured in this prototype.")
                        .foregroundStyle(.secondary)
                }
                if let email = store.configuration.supportEmail {
                    Button("Prepare a privacy or deletion question") {
                        prepareEmail(to: email, subject: "Privacy or deletion question", body: "I have a question about privacy or deleting information associated with this app.\n\n\(AppSupportContext.versionSummary)\n\nPlease explain what information you need to help. This draft does not include wish choices, pictures, a child's identity, or medical information.")
                    }.disabled(!store.adultSessionActive)
                }
                Text("This app does not create an account. Privacy includes a control to forget choices on this iPad. Clearing this iPad cannot recall information already processed by an online service.")
                if !store.adultSessionActive {
                    Text("Open grown-up settings to prepare an email. External websites require a grown-up reading check.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let message = contactMessage {
                Section { Text(message).accessibilityAddTraits(.updatesFrequently) }
            }
        }
        .navigationTitle("App information and help")
        .sheet(isPresented: $privacyPresented) { PrivacyNoticeView() }
        .sheet(item: $externalDestination) { ExternalLinkGate(destination: $0) }
    }

    private func openWebsite(_ url: URL, title: String) {
        guard store.adultSessionActive else {
            externalDestination = ExternalDestination(title: title, url: url)
            return
        }
        openURL(url) { accepted in
            if !accepted { contactMessage = "The website could not open. You can find the publisher's contact details above." }
        }
    }

    private func prepareEmail(to email: String, subject: String, body: String) {
        guard store.adultSessionActive,
              let url = AppSupportContext.emailURL(to: email, subject: subject, body: body) else {
            contactMessage = "A grown-up can use the support email shown above to get in touch."
            return
        }
        openURL(url) { accepted in
            contactMessage = accepted
                ? "Your email app handles the draft. Nothing is sent automatically by this app."
                : "An email app could not open. Copy the support address above and contact the publisher using your preferred email service."
        }
    }
}

enum AppSupportContext {
    static var appName: String {
        WishBuildConfiguration.publicText(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName"))
            ?? WishBuildConfiguration.publicText(Bundle.main.object(forInfoDictionaryKey: "CFBundleName"))
            ?? "Wish Explorer"
    }
    static var version: String {
        WishBuildConfiguration.publicText(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")) ?? "Prototype"
    }
    static var build: String {
        WishBuildConfiguration.publicText(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")) ?? "Not specified"
    }
    static var versionSummary: String { "\(appName) — version \(version), build \(build)" }

    static func emailURL(to email: String, subject: String, body: String) -> URL? {
        guard WishBuildConfiguration.validEmail(email) != nil else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [URLQueryItem(name: "subject", value: subject), URLQueryItem(name: "body", value: body)]
        return components.url
    }
}
