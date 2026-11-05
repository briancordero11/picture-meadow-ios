import SwiftUI

@main
@MainActor
struct WishExplorerApp: App {
    @StateObject private var store = WishStore()

    var body: some Scene {
        WindowGroup {
            WishRootView()
                .environmentObject(store)
                .tint(WishTheme.blue)
                .preferredColorScheme(.light)
        }
    }
}
