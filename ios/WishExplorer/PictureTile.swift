import SwiftUI
import UIKit

struct PictureTile: View {
    let label: String
    var selected = false
    var compact = false
    var backgroundColor: Color? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 5 : 12) {
                Text(PictureCatalog.shared.item(label: label)?.label ?? label)
                    .font(compact ? .system(.callout, design: .rounded, weight: .bold) : .system(.title3, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                PictureSymbol(label: label)
                    .frame(height: compact ? 50 : 105)
                    .accessibilityHidden(true)
            }
            .padding(compact ? 5 : 16)
            .frame(maxWidth: .infinity, minHeight: compact ? 96 : 174)
            .background(backgroundColor ?? WishTheme.picturePeach, in: RoundedRectangle(cornerRadius: compact ? 0 : 4))
            .overlay(RoundedRectangle(cornerRadius: compact ? 0 : 4).stroke(.black, lineWidth: selected ? 3 : compact ? 1 : 1.5))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.black, .white).padding(7).accessibilityHidden(true)
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
