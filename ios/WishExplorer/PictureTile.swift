import SwiftUI
import UIKit

struct PictureTile: View {
    let label: String
    var selected = false
    var compact = false
    var backgroundColor: Color? = nil
    var action: () -> Void

    private var phraseTile: Bool {
        CommunicationWord.phraseWords.contains { $0.label == label }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 3 : 9) {
                Text(PictureCatalog.shared.item(label: label)?.label ?? label)
                    .font(WishTheme.cardFont(size: compact ? 13 : 16, weight: .bold, relativeTo: compact ? .caption : .headline))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(WishTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: compact ? (phraseTile ? 34 : 20) : 35)
                PictureSymbol(label: label)
                    .frame(maxWidth: compact ? 75 : 104)
                    .frame(height: compact ? 51 : 82)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, compact ? 3 : 5.5)
            .padding(.top, compact ? 3 : 8.5)
            .padding(.bottom, compact ? 3 : 10.5)
            .frame(maxWidth: .infinity, minHeight: compact ? (phraseTile ? 98 : 84) : 146)
            .background(backgroundColor ?? WishTheme.picturePeach, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(selected ? WishTheme.blue : WishTheme.line, lineWidth: selected ? 4 : compact ? 1 : 1.5))
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 22))
                        .foregroundStyle(WishTheme.blue, .white).padding(6).accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(PictureCatalog.shared.item(label: label)?.label ?? label)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// Shows an unchanged source picture through its atlas viewport at runtime.
/// The original atlas bytes are bundled intact; no recolored or edited icon is authored.
struct PictureSymbol: View {
    let label: String
    var body: some View {
        Group {
            if let image = PictureCatalog.shared.image(label: label) {
                Image(uiImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Text("Picture unavailable").font(.caption).foregroundStyle(.black)
            }
        }
    }
}

struct PictureCatalog {
    struct Atlas: Decodable {
        let file: String
        let width: Int
        let height: Int
    }
    struct Frame: Decodable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
        var rect: CGRect { CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height)) }
    }
    struct Item: Decodable {
        let id: String
        let label: String
        let kind: String
        let atlas: String
        let frame: Frame
        let speech: String
    }
    private struct Manifest: Decodable {
        let version: Int
        let atlases: [String: Atlas]
        let items: [Item]
    }

    static let shared = PictureCatalog()
    let items: [Item]
    private let images: [String: UIImage]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "picture-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data), manifest.version == 1 else {
            items = []; images = [:]; return
        }
        items = manifest.items
        var sourceImages: [String: CGImage] = [:]
        for (key, atlas) in manifest.atlases {
            let filename = URL(fileURLWithPath: atlas.file).lastPathComponent
            let stem = (filename as NSString).deletingPathExtension
            let fileExtension = (filename as NSString).pathExtension
            if let url = bundle.url(forResource: stem, withExtension: fileExtension),
               let source = UIImage(contentsOfFile: url.path)?.cgImage {
                sourceImages[key] = source
            }
        }
        var pictures: [String: UIImage] = [:]
        for entry in manifest.items {
            if let source = sourceImages[entry.atlas], let viewport = source.cropping(to: entry.frame.rect) {
                pictures[Self.normalized(entry.label)] = UIImage(cgImage: viewport)
            }
        }
        images = pictures
    }

    func item(label: String) -> Item? {
        items.first { Self.normalized($0.label) == Self.normalized(label) }
    }
    func image(label: String) -> UIImage? { images[Self.normalized(label)] }
    static func normalized(_ text: String) -> String {
        text.lowercased().unicodeScalars.filter(CharacterSet.alphanumerics.contains).map(String.init).joined()
    }
}
