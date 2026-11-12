import SwiftUI

enum WishTheme {
    static let launchBlue = Color("LaunchBackground")
    static let ink = color(hex: 0x211c18)
    static let line = color(hex: 0x33251b)
    static let blue = color(hex: 0x1167ad)
    static let wordmarkBlue = color(hex: 0x0057b8)
    static let sky = color(hex: 0xb6dded)
    static let lavender = color(hex: 0xd9b9df)
    static let mint = color(hex: 0xbce3a1)
    static let peach = color(hex: 0xf8cea0)
    static let yellow = color(hex: 0xffda45)
    static let background = color(hex: 0xfffbf2)
    static let secondary = color(hex: 0x5a493a)
    static let picturePeach = peach
    static let boardBackground = color(hex: 0xfff2d9)
    static let control = color(hex: 0xfff0ce)
    static let homeBackground = color(hex: 0xfff6e8)
    static let homeLine = color(hex: 0xd4bea4)
    static let headerLine = color(hex: 0xe0d1bd)
    static let settingsInk = color(hex: 0x79521a)
    static let intake = color(hex: 0xfff1ba)
    static let collage = color(hex: 0xfff6e7)
    static let collageLine = color(hex: 0xd2b690)
    static let mostImportant = color(hex: 0x7d2447)
    static let progressTrack = color(hex: 0xdce6eb)
    static let outerBackground = color(hex: 0xeee9df)
    static let frameLine = color(hex: 0xc9bba7)

    private static func color(hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xff) / 255,
              green: Double((hex >> 8) & 0xff) / 255,
              blue: Double(hex & 0xff) / 255)
    }

    static func color(for choice: CoasterColor) -> Color {
        switch choice {
        case .blue: blue
        case .pink: Color(red: 0.81, green: 0.23, blue: 0.50)
        case .purple: Color(red: 0.46, green: 0.25, blue: 0.75)
        case .green: Color(red: 0.12, green: 0.48, blue: 0.30)
        }
    }

}

struct PrimaryWishButton: View {
    let title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(WishTheme.cardFont(size: 16, weight: .bold, relativeTo: .headline))
                .padding(.horizontal, 20).padding(.vertical, 13)
                .frame(minHeight: 50)
                .foregroundStyle(WishTheme.line)
                .background(WishTheme.mint, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(WishTheme.line, lineWidth: 1.5))
        }.buttonStyle(.plain)
    }
}

struct ChoiceCard<Content: View>: View {
    let selected: Bool
    let background: Color
    var action: () -> Void
    @ViewBuilder var content: () -> Content
    var body: some View {
        Button(action: action) {
            content()
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 154)
                .background(background, in: RoundedRectangle(cornerRadius: 13))
                .overlay(alignment: .topTrailing) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2).foregroundStyle(WishTheme.blue, .white).padding(14)
                            .accessibilityHidden(true)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? WishTheme.blue : WishTheme.line, lineWidth: selected ? 4 : 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct WishStar: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        return Path { path in
            for index in 0..<10 {
                let angle = CGFloat(index) * .pi / 5 - .pi / 2
                let length = index.isMultiple(of: 2) ? radius : radius * 0.46
                let point = CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}

struct ScreenHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(WishTheme.cardFont(size: 26, weight: .bold, relativeTo: .title))
                .foregroundStyle(WishTheme.ink).accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(WishTheme.bodyFont(size: 16, weight: .regular, relativeTo: .body))
                .foregroundStyle(WishTheme.secondary)
                .lineSpacing(4)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
