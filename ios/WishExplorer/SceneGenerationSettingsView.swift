import SwiftUI

struct SceneGenerationSettingsView: View {
    @EnvironmentObject private var store: WishStore
    @State private var accessCode = ""
    @State private var accessMessage: String?
    @State private var disclosure: SceneGenerationDisclosure?
    var body: some View {
        WishSettingsSection("Make one picture from these ideas") {
            Text("The picture board already works offline. AI can combine the selected picture concepts into one imagined scene. It does not receive picture files or the talking-board sentence.")
            if store.draft.interest != nil {
                Text(store.draft.sceneDescription).font(WishTheme.bodyFont(size: 16))
                if !store.draft.sceneChoices.isEmpty { SceneChoiceCollage(draft: store.draft) }
            } else {
                Text("Choose a wish picture after exploring your favorites to build an AI scene.").font(WishTheme.bodyFont(size: 14)).foregroundStyle(WishSettingsAppearance.secondary)
            }
            if store.configuration.sceneGenerationAvailable {
                if !store.sceneAccessConfigured {
                    SecureField("Service access code from your operator", text: $accessCode)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .textFieldStyle(WishSettingsTextFieldStyle())
                    Button("Save service access") {
                        accessMessage = store.saveSceneAccess(accessCode) ? "Access saved securely on this iPad." : "The access code could not be saved. Check the code with your operator."
                        accessCode = ""
                    }.buttonStyle(WishSettingsActionStyle(kind: .save)).disabled(accessCode.isEmpty)
                } else {
                    Button("Remove service access", role: .destructive) { store.removeSceneAccess() }
                }
                if let message = accessMessage { Text(message).font(WishTheme.bodyFont(size: 14)) }
                Button { disclosure = store.prepareSceneGeneration() } label: {
                    HStack {
                        Text(store.isGeneratingScene ? "Generating your picture…" : "Review choices and generate an AI picture")
                        if store.isGeneratingScene { ProgressView() }
                    }
                }.buttonStyle(WishSettingsActionStyle(kind: .primary))
                    .disabled(!store.sceneGenerationAvailable || !store.draft.canRequestScene || store.isGeneratingScene || store.isLoadingPreview)
                if !store.draft.canRequestScene { Text("Choose an action, a setting, or a favorite first.").font(WishTheme.bodyFont(size: 14)) }
                if store.isGeneratingScene { Button("Cancel picture making", role: .cancel) { store.cancelSceneGeneration() } }
            } else {
                Button("Generate AI picture") { }.disabled(true)
                Text("AI picture making is not connected in this build. All 20 journeys and the picture board work offline.").foregroundStyle(WishSettingsAppearance.secondary)
            }
            if let status = store.sceneStatus { Text(status).accessibilityAddTraits(.updatesFrequently) }
            if let scene = store.pendingGeneratedScene, let image = UIImage(data: scene.imageData) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 360).accessibilityLabel("AI picture for grown-up review")
                Text("Check that this AI picture is appropriate and follows the Super Star's choices. AI can make mistakes. It is an imagined scene, not a confirmed plan.")
                Button("Show this picture with the wish") { store.approveGeneratedScene() }
                    .buttonStyle(WishSettingsActionStyle(kind: .primary))
                Button("Discard this picture", role: .destructive) { store.discardGeneratedScene() }
                Text("For an unsuitable result, discard it and contact the publisher through the help details in Privacy. Please describe the issue without a child's identity or medical information.").font(WishTheme.bodyFont(size: 14))
            }
            if store.generatedScene != nil { Button("Remove AI picture", role: .destructive) { store.discardGeneratedScene() } }
        }
        .sheet(item: $disclosure) { SceneGenerationConsentView(disclosure: $0) }
    }
}

struct SceneGenerationConsentView: View {
    let disclosure: SceneGenerationDisclosure
    @EnvironmentObject private var store: WishStore
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            WishSettingsPage(title: "Permission for one AI picture", showsBack: false, onClose: cancel) {
                WishSettingsSection("Send these chosen concepts once") {
                    Text(disclosure.draft.interest?.label ?? "Wish idea").font(WishTheme.bodyFont(size: 18, weight: .bold))
                    ForEach(disclosure.choices) { choice in
                        LabeledContent(choice.label, value: disclosure.draft.essentialChoiceID == choice.id ? "Most important" : "Selected")
                    }
                    Text("Only these catalog IDs, their topic, and the most-important choice are sent. Colors guide the illustration; they do not select real rides or products.").font(WishTheme.bodyFont(size: 14))
                }
                WishSettingsSection("Where it goes") {
                    Text("Service: \(disclosure.serviceHost)")
                    Text("Image provider: \(disclosure.providerName)")
                    Text("The service turns the chosen concepts into an image prompt and sends it directly to the disclosed image provider. Connection information such as IP address and request time can be received by the service and hosting provider.")
                    Text("Names, photographs, medical details, saved talking-board sentences, and the intake documents are not sent. The generated picture stays in app memory and is cleared when the wish changes or is forgotten. Clearing this iPad cannot recall information already processed by an external service.")
                    Text("A grown-up will review the result before showing it. This permission covers one request. It does not submit or approve a wish.")
                }
                WishSettingsSection {
                    Button("Allow these choices to be sent and generate once") { _ = store.confirmSceneGeneration(disclosure.id); dismiss() }
                        .buttonStyle(WishSettingsActionStyle(kind: .primary))
                    Button("Keep using my offline picture board", role: .cancel) { cancel() }
                }
            }
                .onDisappear { store.cancelSceneConfirmation(disclosure.id) }
        }.environment(\.wishSettingsDismiss, nil)
    }
    private func cancel() { store.cancelSceneConfirmation(disclosure.id); dismiss() }
}
