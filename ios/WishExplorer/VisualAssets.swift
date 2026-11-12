import SwiftUI
import UIKit

/// Shared PNG artwork prevents operating-system emoji/font substitutions.
struct JourneyArtwork: View {
    let symbol: String
    init(symbol: String) { self.symbol = symbol }
    init(choice: JourneyChoice) { self.symbol = choice.symbol }

    var body: some View {
        if let filename = JourneyArtworkCatalog.shared.symbols[symbol]?.file,
           let image = bundledVisualImage(filename) {
            Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
                .accessibilityHidden(true)
        } else {
            Text("Picture unavailable").font(WishTheme.bodyFont(size: 12))
        }
    }
}

struct JourneyArtworkCatalog: Decodable {
    struct Entry: Decodable { let file: String; let sha256: String? }
    let symbols: [String: Entry]
    let choices: [String: String]
    static let shared: Self = {
        guard let url = Bundle.main.url(forResource: "journey-artwork", withExtension: "json"),
              let data = try? Data(contentsOf: url), let catalog = try? JSONDecoder().decode(Self.self, from: data) else {
            return Self(symbols: [:], choices: [:])
        }
        return catalog
    }()
}

private func bundledVisualImage(_ filename: String) -> UIImage? {
    let url = URL(fileURLWithPath: filename)
    guard let source = Bundle.main.url(forResource: url.deletingPathExtension().lastPathComponent,
                                       withExtension: url.pathExtension) else { return nil }
    return UIImage(contentsOfFile: source.path)
}

struct WishUIIcon: View {
    let name: String
    var size: CGFloat = 20
    var body: some View {
        Group {
            if let image = bundledVisualImage("ui-\(name).png") {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
            } else { Color.clear }
        }
        .frame(width: size, height: size).accessibilityHidden(true)
    }
}

extension WishTheme {
    static func cardFont(size: CGFloat, weight: Font.Weight = .regular, relativeTo: Font.TextStyle = .body) -> Font {
        .custom(isBold(weight) ? "ComicNeue-Bold" : "ComicNeue-Regular", size: size, relativeTo: relativeTo)
    }
    static func bodyFont(size: CGFloat, weight: Font.Weight = .regular, relativeTo: Font.TextStyle = .body) -> Font {
        .custom(isBold(weight) ? "WishBody-Bold" : "WishBody-Regular", size: size, relativeTo: relativeTo)
    }
    private static func isBold(_ weight: Font.Weight) -> Bool {
        weight == .bold || weight == .heavy || weight == .black || weight == .semibold
    }
}
