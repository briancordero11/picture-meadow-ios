import CryptoKit
import UIKit
import XCTest
@testable import WishExplorer

final class VisualAssetsTests: XCTestCase {
    @MainActor
    func testFixedArtworkManifestCoversEveryJourneyChoice() throws {
        let journeys = try JourneyCatalog.load()
        let choices = journeys.interests.flatMap { $0.actions + $0.settings } + journeys.favoriteOptions
        let artwork = JourneyArtworkCatalog.shared
        XCTAssertEqual(choices.count, 216)
        XCTAssertEqual(artwork.symbols.count, 106)
        XCTAssertEqual(artwork.choices.count, choices.count)
        XCTAssertEqual(Set(artwork.choices.keys), Set(choices.map(\.id)))
        XCTAssertEqual(Set(artwork.symbols.keys), Set(choices.map(\.symbol)))
        XCTAssertEqual(Set(artwork.symbols.values.map(\.file)).count, 106)
        for choice in choices {
            XCTAssertEqual(artwork.choices[choice.id], choice.symbol, choice.id)
            let entry = try XCTUnwrap(artwork.symbols[choice.symbol], choice.id)
            XCTAssertEqual(URL(fileURLWithPath: entry.file).pathExtension, "png", choice.id)
            XCTAssertEqual(try XCTUnwrap(entry.sha256).count, 64, choice.id)
        }
    }

    @MainActor
    func testEveryFixedSymbolIsAnIntactBundledImageIncludingFavoritesIntake() throws {
        let artwork = JourneyArtworkCatalog.shared
        for symbol in ["🌈", "🍓", "🐾", "🎵", "🎮", "🗺️"] {
            XCTAssertNotNil(artwork.symbols[symbol], "Missing favorites intake artwork: \(symbol)")
        }
        XCTAssertFalse(artwork.symbols.isEmpty)
        for (symbol, entry) in artwork.symbols {
            let data = try Data(contentsOf: bundledURL(entry.file))
            XCTAssertEqual(digest(data), entry.sha256, symbol)
            let image = try XCTUnwrap(UIImage(data: data), symbol)
            XCTAssertGreaterThan(image.size.width, 0, symbol)
            XCTAssertGreaterThan(image.size.height, 0, symbol)
        }
    }

    @MainActor
    func testAllFourSharedFontsAreRegisteredWithoutSystemFallback() throws {
        let fontNames = ["ComicNeue-Regular", "ComicNeue-Bold", "WishBody-Regular", "WishBody-Bold"]
        let registeredFiles = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "UIAppFonts") as? [String])
        XCTAssertEqual(Set(registeredFiles), Set(fontNames.map { $0 + ".ttf" }))
        for name in fontNames {
            XCTAssertTrue(FileManager.default.fileExists(atPath: try bundledURL(name + ".ttf").path), name)
            let font = try XCTUnwrap(UIFont(name: name, size: 16), "Font was not registered: \(name)")
            XCTAssertEqual(font.fontName, name)
        }
    }

    @MainActor
    func testAllFiftyFourSourcePicturesKeepTheirOriginalBundledAtlasesAndFrames() throws {
        let manifest = try JSONDecoder().decode(SourcePictureManifest.self,
                                                from: Data(contentsOf: bundledURL("picture-catalog.json")))
        XCTAssertEqual(manifest.items.count, 54)
        XCTAssertEqual(manifest.items.filter { $0.kind == "interest" }.count, 20)
        XCTAssertEqual(manifest.items.filter { $0.kind == "core" }.count, 34)
        XCTAssertEqual(Set(manifest.items.map(\.id)).count, 54)
        XCTAssertEqual(manifest.atlases.count, 29)
        for atlas in manifest.atlases.values {
            let data = try Data(contentsOf: bundledURL(atlas.file))
            XCTAssertEqual(digest(data), atlas.sha256, atlas.file)
            let image = try XCTUnwrap(UIImage(data: data)?.cgImage, atlas.file)
            XCTAssertEqual(image.width, atlas.width, atlas.file)
            XCTAssertEqual(image.height, atlas.height, atlas.file)
        }
        for item in manifest.items {
            let atlas = try XCTUnwrap(manifest.atlases[item.atlas], item.id)
            XCTAssertGreaterThanOrEqual(item.frame.x, 0, item.id)
            XCTAssertGreaterThanOrEqual(item.frame.y, 0, item.id)
            XCTAssertGreaterThan(item.frame.width, 0, item.id)
            XCTAssertGreaterThan(item.frame.height, 0, item.id)
            XCTAssertLessThanOrEqual(item.frame.x + item.frame.width, Double(atlas.width), item.id)
            XCTAssertLessThanOrEqual(item.frame.y + item.frame.height, Double(atlas.height), item.id)
            XCTAssertNotNil(PictureCatalog.shared.image(label: item.label), item.id)
        }
    }

    private func bundledURL(_ filename: String) throws -> URL {
        let file = URL(fileURLWithPath: filename)
        return try XCTUnwrap(Bundle.main.url(forResource: file.deletingPathExtension().lastPathComponent,
                                            withExtension: file.pathExtension), "Missing bundled resource: \(filename)")
    }

    private func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

private struct SourcePictureManifest: Decodable {
    struct Atlas: Decodable {
        let file: String
        let width: Int
        let height: Int
        let sha256: String
    }
    struct Frame: Decodable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }
    struct Item: Decodable {
        let id: String
        let label: String
        let kind: String
        let atlas: String
        let frame: Frame
    }
    let atlases: [String: Atlas]
    let items: [Item]
}
