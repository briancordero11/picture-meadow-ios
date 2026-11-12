import SwiftUI

struct LaunchIntroView: View {
    var body: some View {
        ZStack {
            WishTheme.launchBlue.ignoresSafeArea()
            Image("ClientDemoLogo")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(maxWidth: 460, maxHeight: 300)
                .padding(.horizontal, 36)
                .accessibilityLabel("Make-A-Wish")
        }
    }
}
