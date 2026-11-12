import SwiftUI

/// Data controls and the privacy notice stay inside the grown-up settings.
struct PrivacySettingsView: View {
    @EnvironmentObject private var store: WishStore
    @State private var showingNotice = false
    @State private var confirmingForget = false

    var body: some View {
        WishSettingsPage(title: "Privacy & Data") {
            WishSettingsSection("Choices on this iPad") {
                Toggle("Remember choices on this iPad", isOn: $store.rememberChoices)
                    .toggleStyle(WishSettingsToggleStyle())
                Text("Off by default. When on, the app saves the chosen topic, actions, setting, favorites, and most-important choice in this iPad's app settings. Older park choices can also be saved. No name, birth date, photograph, or medical information is requested.")
                Text("The talking-board sentence is never saved. AI pictures stay in memory and are not saved to Photos or a cloud gallery. Device backups may include saved app settings; this app cannot erase older device backups.").font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
            }
            WishSettingsSection("AI picture permissions") {
                LabeledContent("Picture service", value: serviceStatus)
                LabeledContent("Permission", value: "Asked for every picture")
                Text("A grown-up sees the exact chosen concepts and provider, confirms one request, and reviews the result before it appears with the wish. There is no always-allow permission. Leaving grown-up settings or switching away cancels pending permission and requests.")
                if let provider = store.configuration.aiProviderName { LabeledContent("Selected provider", value: provider) }
                if let host = store.configuration.apiBaseURL?.host { LabeledContent("Service host", value: host) }
                if store.isGeneratingScene { Button("Cancel picture making", role: .cancel) { store.cancelSceneGeneration() } }
                if store.pendingGeneratedScene != nil || store.generatedScene != nil {
                    Button("Remove AI picture", role: .destructive) { store.discardGeneratedScene() }
                }
                if store.sceneAccessConfigured {
                    Button("Remove AI service access", role: .destructive) { store.removeSceneAccess() }
                    Text("Removes the service access code from this iPad's Keychain and stops current requests. An already approved picture remains until you remove or forget it.").font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
                }
            }
            DataStorageSections()
            WishSettingsSection("Your data controls") {
                Button("Read privacy notice") { showingNotice = true }
                Button("Forget choices on this iPad", role: .destructive) { confirmingForget = true }
                Text("Forget turns remembering off and clears local choices, the talking-board sentence, AI pictures, narration and voice preferences, and the service access code. It also closes grown-up settings. It works offline.")
                Text("This app creates no user accounts. There is no account record to delete. Clearing this iPad does not recall information a provider already processed or erase earlier backups.").font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
                NavigationLink("Privacy request or report an AI picture") { ReportAIConcernView() }
            }
        }
        .sheet(isPresented: $showingNotice) { PrivacyNoticeView() }
        .confirmationDialog("Forget choices on this iPad?", isPresented: $confirmingForget, titleVisibility: .visible) {
            Button("Forget and start again", role: .destructive) { store.forgetAllChoices() }
            Button("Keep my choices", role: .cancel) { }
        } message: {
            Text("This removes local choices, words, pictures, settings, and the service access code. It does not send a deletion request to a server or image provider.")
        }
    }

    private var serviceStatus: String {
        if !store.configuration.sceneGenerationAvailable { return "Off in this build" }
        return store.sceneAccessConfigured ? "Set up on this iPad" : "Access code needed"
    }
}

struct DataStorageSections: View {
    var body: some View {
        WishSettingsSection("Where data goes") {
            VStack(alignment: .leading, spacing: 6) {
                Text("This iPad")
                    .font(WishTheme.bodyFont(size: 18, weight: .bold))
                Text("Current choices, words, and pictures are held in memory. Remember choices optionally saves a draft in app settings. A service access code, when entered, is stored persistently in Keychain and can be read only while the iPad is unlocked; it is not synchronized to other devices.")
            }.padding(.vertical, 5)
            VStack(alignment: .leading, spacing: 6) {
                Text("Our picture service")
                    .font(WishTheme.bodyFont(size: 18, weight: .bold))
                Text("When enabled, the service receives selected catalog IDs and builds an image prompt. It processes the prompt and picture temporarily in memory. There is no wish database or saved image library. Temporary connection counters and separate hosting logs can include technical information such as IP address and request time.")
            }.padding(.vertical, 5)
            VStack(alignment: .leading, spacing: 6) {
                Text("The image provider")
                    .font(WishTheme.bodyFont(size: 18, weight: .bold))
                Text("When enabled, OpenAI receives the authored image prompt and creates the picture. Your talking-board sentence, source picture files, intake documents, identity, and medical details are not sent. Provider retention depends on the actual account: standard abuse-monitoring records can ordinarily be kept for up to 30 days. Zero Data Retention needs provider approval and account configuration.")
            }.padding(.vertical, 5)
            Text("The published privacy policy must explain the operator's actual hosting and provider settings. Local deletion cannot erase information already retained by an external service.").font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
        }
    }
}
