import SwiftUI

@main
@MainActor
struct WishExplorerApp: App {
    @StateObject private var store = WishStore()

    var body: some Scene {
        WindowGroup {
            WishLaunchContainer()
                .environmentObject(store)
                .tint(WishTheme.blue)
                .preferredColorScheme(.light)
        }
    }
}

@MainActor
private struct WishLaunchContainer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var introVisible = true
    @State private var introOpacity = 1.0

    var body: some View {
        ZStack {
            WishRootView()
                .allowsHitTesting(!introVisible)
                .accessibilityHidden(introVisible)
            if introVisible {
                LaunchIntroView()
                    .opacity(introOpacity)
                    .zIndex(1)
            }
        }
        .task {
            guard introVisible else { return }
            do {
                try await Task.sleep(for: .milliseconds(750))
                if !reduceMotion {
                    withAnimation(.easeOut(duration: 0.35)) { introOpacity = 0 }
                    try await Task.sleep(for: .milliseconds(350))
                }
                introVisible = false
            } catch {
                // A canceled launch must never leave the app behind its overlay.
                introVisible = false
            }
        }
    }
}
