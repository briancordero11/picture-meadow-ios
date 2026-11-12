import SwiftUI

struct SceneGenerationSettingsView: View {
    @EnvironmentObject private var store: WishStore
    @State private var accessCode = ""
    @State private var accessMessage: String?
    @State private var disclosure: SceneGenerationDisclosure?
    var body: some View {
        Section("Make one picture from these ideas") {
            Text("The picture board already works offline. AI can combine the selected picture concepts into one imagined scene. It does not receive picture files or the talking-board sentence.")
            if store.configuration.sceneGenerationAvailable {
                if !store.sceneAccessConfigured {
                    SecureField("Service access code from your operator", text: $accessCode)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Save service access") {
                        accessMessage = store.saveSceneAccess(accessCode) ? "Access saved securely on this iPad." : "The access code could not be saved. Check the code with your operator."
                        accessCode = ""
                    }.disabled(accessCode.isEmpty)
                } else {
                    Button("Remove service access", role: .destructive) { store.removeSceneAccess() }
                }
                if let message = accessMessage { Text(message).font(.footnote) }
                Button { disclosure = store.prepareSceneGeneration() } label: {
                    HStack {
                        Text(store.isGeneratingScene ? "Making your picture…" : "Review choices and make a picture")
                        if store.isGeneratingScene { ProgressView() }
                    }
                }.disabled(!store.sceneGenerationAvailable || !store.draft.canRequestScene || store.isGeneratingScene || store.isLoadingPreview)
                if !store.draft.canRequestScene { Text("Choose an action, a setting, or a favorite first.").font(.footnote) }
                if store.isGeneratingScene { Button("Cancel picture making", role: .cancel) { store.cancelSceneGeneration() } }
            } else {
                Text("AI picture making is not connected in this build. All 20 journeys and the picture board work offline.").foregroundStyle(.secondary)
            }
            if let status = store.sceneStatus { Text(status).accessibilityAddTraits(.updatesFrequently) }
            if let scene = store.pendingGeneratedScene, let image = UIImage(data: scene.imageData) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 360).accessibilityLabel("AI picture for grown-up review")
                Text("Check that this AI picture is appropriate and follows the Super Star's choices. AI can make mistakes. It is an imagined scene, not a confirmed plan.")
                Button("Show this picture with the wish") { store.approveGeneratedScene() }
                Button("Discard this picture", role: .destructive) { store.discardGeneratedScene() }
                Text("For an unsuitable result, discard it and contact the publisher through the help details in Privacy. Please describe the issue without a child's identity or medical information.").font(.footnote)
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
            List {
                Section("Send these chosen concepts once") {
                    Text(disclosure.draft.interest?.label ?? "Wish idea").font(.headline)
                    ForEach(disclosure.choices) { choice in
                        LabeledContent(choice.label, value: disclosure.draft.essentialChoiceID == choice.id ? "Most important" : "Selected")
                    }
                    Text("Only these catalog IDs, their topic, and the most-important choice are sent. Colors guide the illustration; they do not select real rides or products.").font(.footnote)
                }
                Section("Where it goes") {
                    Text("Service: \(disclosure.serviceHost)")
                    Text("Image provider: \(disclosure.providerName)")
                    Text("The service turns the chosen concepts into an image prompt. The service, hosting provider, AI gateway, and image provider process this request. Connection information such as IP address and request time can be received by the service and hosting provider.")
                    Text("Names, photographs, medical details, saved talking-board sentences, and the intake documents are not sent. The generated picture stays in app memory and is cleared when the wish changes or is forgotten. Clearing this iPad cannot recall information already processed by an external service.")
                    Text("A grown-up will review the result before showing it. This permission covers one request. It does not submit or approve a wish.")
                }
                Section {
                    Button("Allow these choices to be sent and generate once") { _ = store.confirmSceneGeneration(disclosure.id); dismiss() }
                    Button("Keep using my offline picture board", role: .cancel) { cancel() }
                }
            }.navigationTitle("Permission for one AI picture")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } } }
                .onDisappear { store.cancelSceneConfirmation(disclosure.id) }
        }
    }
    private func cancel() { store.cancelSceneConfirmation(disclosure.id); dismiss() }
}
