# Wish Explorer for iPad

Native SwiftUI prototype, iPadOS 17 and later. The main screen presents **20 picture interests** in the supplied source order, with peach tiles, dark outlines, black labels above the unchanged colorful pictograms. It uses four columns on a full iPad layout and two columns in a compact layout. The complete demo is: welcome → amusement park picture → optional park, coaster color, and animal preferences → an original illustrated wish postcard. The other 19 interest pictures open a supported exploration conversation; they do not imply a completed destination-specific journey.

The source's other **34 core communication pictures** live entirely inside the pull-up drawer. The collapsed drawer leaves only a small centered rounded tab with a grabber and chevron. Tap the tab, drag it up/down, or use its accessible button action to open and close it. There is no My Voice section or quick-response toolbar. Interest nouns are not duplicated in the drawer. Stop, break, finished, and time-to-think remain available inside it. Speech uses the system speech synthesizer. No microphone permission, account, child name, photograph, health information, advertising, or analytics is requested.

The compact drawer uses five stable columns and six rows, followed by four adjacent phrase tiles. I/You/We stay vertically aligned in the first column, and the original action, descriptor, and question columns remain alongside each other after removing the interest topics. Tiles have no gutters, thin dividers, 5-point internal padding, and a 96-point minimum height; text wraps with Dynamic Type and the drawer scrolls when necessary. The drawer can occupy up to 82% of the available app height. `CommunicationWord.mainRows` and `phraseWords` define the spatial arrangement and have ordering tests.

`WishWordmark` supplies the blue Georgia regular **Create your wish** heading with an original drawn arch and star over “wish.” It scales with Dynamic Type, wraps to a stacked heading on narrow layouts, and has one accessible heading label. It is typeset native text and shape code, not a bitmap or the official logo. Main picture-tile type remains unchanged.

`PictureTile` and `PictureSymbol` are reused on the main board and inside the drawer. `Resources/Pictures` bundles the supplied source PNG objects unchanged and the shared `picture-catalog.json`; native runtime viewports select each pictogram from its atlas. Labels are rendered outside the image. No recolored, generated, or authored cropped replacement of those supplied pictograms is included.

## Open and run on a Mac

1. Install Xcode 26 or later, select its command-line tools, and install an iPad simulator. Apple's current upload requirements specify Xcode 26+ for iOS app builds. This repository's deployment target remains iPadOS 17.
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.
3. From this folder: `xcodegen generate --spec project.yml`.
4. Open `WishExplorer.xcodeproj`, choose the **WishExplorer** scheme, choose an iPad simulator, and Run.
5. For device signing, set your own development team and a unique bundle identifier in Xcode or `project.yml`. No team, signing certificate, or Apple account is embedded.

The generated Xcode project is a build artifact; `project.yml` is the source of truth.

## Verify

```bash
bash scripts/verify.sh
```

The script checks macOS and Xcode 26+, generates the project, validates property lists, and runs the native unit tests. It selects an available iPad simulator by UDID, preferring the newest installed iOS runtime. To select a specific simulator yourself:

```bash
WISH_TEST_DESTINATION='platform=iOS Simulator,name=iPad Pro 13-inch (M4)' bash scripts/verify.sh
```

**Native compilation, simulator tests, speech, VoiceOver, Switch Control, portrait/landscape layouts, and on-device behavior have not been verified in the Windows workspace.** The repository includes unit tests for skipped choices, the 20-interest/34-core split, bundled source imagery, interest routing, persistence opt-in, and resetting unrelated choices. Run them on a Mac before device testing. `python3 scripts/check_resources.py` performs portable property-list, image, catalog-boundary, and unchanged-source-byte checks; it does not compile Swift.

## Backend connection

Offline mode is the default; the native postcard requires no server. To enable the optional **Grown-ups → Refresh this wish's description** action, set `WISH_API_BASE_URL` in `project.yml` to your HTTPS service origin, regenerate, and rebuild. Keep it empty for the offline demo. Production endpoints must use HTTPS; there is no arbitrary network transport exception.

The optional request is sent only when the caregiver taps that action and a park/color are selected:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe"]
}
```

`POST /v1/wish-preview` returns `id`, `title`, `description`, `image: { mimeType, data }`, and `provider`. The client uses the returned description and continues to render the original native drawing. It does not render the returned SVG. This service is a deterministic illustrated demo, not generative AI. No talking-board sentence is sent. Local development server instructions are in the root/backend documentation; the native client requires an HTTPS deployment or HTTPS development tunnel.

## Retention and accessibility

- Preferences are kept in memory unless a grown-up enables **Remember choices on this iPad**. Only non-identifying interest, park, color, and animal selections (plus the internal wish verb used by the park API) are stored in UserDefaults; the talking-board sentence is not saved.
- Turn the switch off to erase the stored preference copy, or use **Start a fresh wish** to clear the current choices and saved draft. Finishing a session returns home and keeps the in-memory wish so the child can continue later.
- Large labeled controls, selected-state semantics, system Dynamic Type, VoiceOver labels, spoken AAC responses, static imagery, and Reduce Motion-aware drawer animation are included. These are implementation features, not a completed accessibility audit. Work with AAC users and professionals to evaluate vocabulary grouping and symbol comprehension.
- Stop/Break present a quiet pause screen; Think speaks a request for time without moving the child. No timer, forced completion, eligibility judgment, or destination booking is built into the journey.

## Before TestFlight

The project is a starting point, not a submitted or approved build. Root release documentation tracks the remaining product review, real-device accessibility checks, privacy disclosures, brand/asset permission, deployment, signing, App Store Connect record, and TestFlight review steps. This independent prototype uses its own star mark and park illustrations, and reuses the supplied pictograms unchanged at the user's request. It does not use the Make-A-Wish logo. Confirm rights to distribute the supplied pictograms before a public release.

Verified Apple references, 2026-11-05: [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight setup](https://developer.apple.com/testflight/), and [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion).
