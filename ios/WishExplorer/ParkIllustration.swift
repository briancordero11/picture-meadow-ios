import SwiftUI

/// Original vector drawing. It represents an imagined park, not any destination's attractions.
struct ParkIllustration: View {
    let color: Color
    var compact = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 20 : 30).fill(WishTheme.sky)
                Canvas { context, size in
                    let w = size.width
                    let h = size.height
                    let baseline = h * 0.82
                    var ground = Path()
                    ground.move(to: CGPoint(x: 0, y: baseline))
                    ground.addQuadCurve(to: CGPoint(x: w, y: baseline), control: CGPoint(x: w * 0.5, y: h * 0.67))
                    ground.addLine(to: CGPoint(x: w, y: h))
                    ground.addLine(to: CGPoint(x: 0, y: h))
                    ground.closeSubpath()
                    context.fill(ground, with: .color(WishTheme.mint))
                    let wheelCenter = CGPoint(x: w * 0.73, y: h * 0.40)
                    let wheelRadius = min(w * 0.20, h * 0.30)
                    let wheelRect = CGRect(x: wheelCenter.x - wheelRadius, y: wheelCenter.y - wheelRadius, width: wheelRadius * 2, height: wheelRadius * 2)
                    context.stroke(Path(ellipseIn: wheelRect), with: .color(WishTheme.blue.opacity(0.65)), lineWidth: 4)
                    for index in 0..<8 {
                        let angle = CGFloat(index) * .pi / 4
                        let endpoint = CGPoint(x: wheelCenter.x + cos(angle) * wheelRadius, y: wheelCenter.y + sin(angle) * wheelRadius)
                        var spoke = Path()
                        spoke.move(to: wheelCenter)
                        spoke.addLine(to: endpoint)
                        context.stroke(spoke, with: .color(WishTheme.blue.opacity(0.45)), lineWidth: 2)
                        context.fill(Path(roundedRect: CGRect(x: endpoint.x - 5, y: endpoint.y - 5, width: 10, height: 12), cornerRadius: 3), with: .color(WishTheme.yellow))
                    }
                    var stand = Path()
                    stand.move(to: CGPoint(x: wheelCenter.x - wheelRadius * 0.5, y: baseline))
                    stand.addLine(to: wheelCenter)
                    stand.addLine(to: CGPoint(x: wheelCenter.x + wheelRadius * 0.5, y: baseline))
                    context.stroke(stand, with: .color(WishTheme.blue.opacity(0.6)), lineWidth: 4)
                    var track = Path()
                    track.move(to: CGPoint(x: w * 0.05, y: h * 0.77))
                    track.addCurve(to: CGPoint(x: w * 0.48, y: h * 0.66), control1: CGPoint(x: w * 0.12, y: -h * 0.03), control2: CGPoint(x: w * 0.27, y: h * 0.06))
                    track.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.68), control1: CGPoint(x: w * 0.64, y: h * 0.95), control2: CGPoint(x: w * 0.70, y: h * 0.28))
                    for fraction in [0.12, 0.26, 0.4] {
                        var support = Path()
                        support.move(to: CGPoint(x: w * fraction, y: h * (fraction == 0.26 ? 0.25 : 0.55)))
                        support.addLine(to: CGPoint(x: w * fraction, y: baseline))
                        context.stroke(support, with: .color(color.opacity(0.3)), lineWidth: 4)
                    }
                    context.stroke(track, with: .color(.white), style: StrokeStyle(lineWidth: compact ? 12 : 18, lineCap: .round))
                    context.stroke(track, with: .color(color), style: StrokeStyle(lineWidth: compact ? 6 : 10, lineCap: .round))
                    context.fill(Path(ellipseIn: CGRect(x: w * 0.1, y: h * 0.09, width: h * 0.12, height: h * 0.12)), with: .color(WishTheme.yellow))
                }.clipShape(RoundedRectangle(cornerRadius: compact ? 20 : 30))
                if !compact {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 6).fill(color).frame(width: width * 0.045, height: height * 0.07)
                                .overlay(alignment: .bottom) {
                                    HStack { Circle().fill(WishTheme.ink); Circle().fill(WishTheme.ink) }.frame(height: 5).offset(y: 3)
                                }
                        }
                    }.rotationEffect(.degrees(-15)).position(x: width * 0.26, y: height * 0.27)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("An imagined amusement park with a roller coaster and Ferris wheel")
    }
}
