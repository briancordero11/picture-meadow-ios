# Wish Explorer for iPad

Native SwiftUI prototype, iPadOS 17 and later. The complete demo is: welcome → five wish verbs and a sixth **Help me choose** navigation card → amusement park → optional park, coaster color, and animal preferences → an original illustrated wish postcard. Other wish verbs start a supported conversation with the talking board.

The 54 communication concepts from the supplied board are organized into People, Actions, Wish ideas, Feelings & needs, and Questions. **No, Stop, Think, Break, and Finished** remain outside the expandable board. Speech uses the system speech synthesizer. No microphone permission, account, child name, photograph, health information, advertising, or analytics is requested.

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

**Native compilation, simulator tests, speech, VoiceOver, Switch Control, portrait/landscape layouts, and on-device behavior have not been verified in the Windows workspace.** The repository includes unit tests for skipped choices, preserving a wish when asking for help, 54 source concepts, persistence opt-in, and resetting unrelated choices. Run them on a Mac before device testing.

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

- Preferences are kept in memory unless a grown-up enables **Remember choices on this iPad**. Only non-identifying category, park, color, and animal selections are stored in UserDefaults; the talking-board sentence is not saved.
- Turn the switch off to erase the stored preference copy, or use **Start a fresh wish** to clear the current choices and saved draft. Finishing a session returns home and keeps the in-memory wish so the child can continue later.
- Large labeled controls, selected-state semantics, system Dynamic Type, VoiceOver labels, spoken AAC responses, static imagery, and Reduce Motion-aware drawer animation are included. These are implementation features, not a completed accessibility audit. Work with AAC users and professionals to evaluate vocabulary grouping and symbol comprehension.
- Stop/Break present a quiet pause screen; Think speaks a request for time without moving the child. No timer, forced completion, eligibility judgment, or destination booking is built into the journey.

## Before TestFlight

The project is a starting point, not a submitted or approved build. Root release documentation tracks the remaining product review, real-device accessibility checks, privacy disclosures, brand/asset permission, deployment, signing, App Store Connect record, and TestFlight review steps. This independent prototype uses its own star mark and illustrations. It does not use the Make-A-Wish logo or copy PDF artwork.

Verified Apple references, 2026-11-05: [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight setup](https://developer.apple.com/testflight/), and [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion).
