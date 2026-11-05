import SwiftUI

/// A typeset heading with an original arch and star; it does not embed an official logo.
struct WishWordmark: View {
    @ScaledMetric(relativeTo: .largeTitle) private var ornamentScale: CGFloat = 40

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: ornamentScale * 0.15) {
                Text("Create your")
                wish
            }.fixedSize(horizontal: true, vertical: false)
            VStack(spacing: ornamentScale * 0.4) {
                Text("Create your")
                wish
            }.multilineTextAlignment(.center)
        }
        .font(.custom("Georgia", size: 40, relativeTo: .largeTitle))
        .foregroundStyle(WishTheme.blue)
        .padding(.top, ornamentScale * 0.35)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Create your wish")
        .accessibilityAddTraits(.isHeader)
    }

    private var wish: some View {
        Text("wish")
            .overlay(alignment: .topLeading) {
                GeometryReader { geometry in
                    WishWordmarkArch()
                        .stroke(WishTheme.blue, style: StrokeStyle(lineWidth: max(1.2, ornamentScale * 0.035), lineCap: .round))
                        .frame(width: geometry.size.width * 1.12, height: ornamentScale * 0.45)
                        .offset(x: -geometry.size.width * 0.06, y: -ornamentScale * 0.26)
                    WishStar().fill(WishTheme.blue)
                        .frame(width: ornamentScale * 0.25, height: ornamentScale * 0.25)
                        .rotationEffect(.degrees(10))
                        .position(x: geometry.size.width * 1.01, y: -ornamentScale * 0.05)
                }.accessibilityHidden(true)
            }
    }
}

private struct WishWordmarkArch: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX * 0.95, y: rect.maxY * 0.61),
                control: CGPoint(x: rect.midX * 0.94, y: -rect.height * 0.38)
            )
        }
    }
}
