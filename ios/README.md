# Wish Explorer for iPad

Native SwiftUI prototype, iPadOS 17 and later. The main screen presents **20 picture interests** in the supplied source order, with peach tiles, dark outlines, black labels above the unchanged colorful pictograms. It uses four columns on a full iPad layout and two columns in a compact layout. The complete demo is: welcome → amusement park picture → optional park, coaster color, and animal preferences → an original illustrated wish postcard. The other 19 interest pictures open a supported exploration conversation; they do not imply a completed destination-specific journey.

The source's other **34 core communication pictures** live entirely inside the pull-up drawer. The collapsed drawer leaves only a small centered rounded tab with a grabber and chevron. Tap the tab, drag it up/down, or use its accessible button action to open and close it. There is no My Voice section or quick-response toolbar. Interest nouns are not duplicated in the drawer. Stop, break, finished, and time-to-think remain available inside it. Speech uses the system speech synthesizer. No microphone permission, account, child name, photograph, health information, advertising, or analytics is requested.

The compact drawer uses five stable columns and six rows, followed by four adjacent phrase tiles. I/You/We stay vertically aligned in the first column, and the original action, descriptor, and question columns remain alongside each other after removing the interest topics. Tiles have no gutters, thin dividers, 5-point internal padding, and a 96-point minimum height; text wraps with Dynamic Type and the drawer scrolls when necessary. The drawer can occupy up to 82% of the available app height. `CommunicationWord.mainRows` and `phraseWords` define the spatial arrangement and have ordering tests.

`WishWordmark` supplies the blue Georgia Bold **Create your wish** heading with an original drawn arch and star over “wish.” It scales with Dynamic Type, wraps to a stacked heading on narrow layouts, and has one accessible heading label. It is typeset native text and shape code, not a bitmap or the official logo. Main picture-tile type remains unchanged.

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

**Native compilation and all 30 unit tests passed on November 11, 2026 in [GitHub Actions](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43135189389)** for source commit `bbf5ed5`, with Xcode 26.6, scheme `WishExplorer`, and the iPad mini (A17 Pro) simulator on iOS 26.5. The build was unsigned. Speech, VoiceOver, Switch Control, portrait/landscape layouts, and physical-device behavior still need hands-on iPad verification. The repository includes unit tests for skipped choices, the 20-interest/34-core split, bundled source imagery, interest routing, persistence opt-in, and resetting unrelated choices. Re-run them on a Mac when changing native behavior. `python3 scripts/check_resources.py` performs portable property-list, image, catalog-boundary, and unchanged-source-byte checks; it does not compile Swift.

## Backend connection

Offline mode is the default; the native postcard requires no server. The optional **Grown-ups → Refresh this wish's description** action requires both `WISH_ONLINE_PREVIEW_ENABLED: "YES"` and a valid `WISH_API_BASE_URL` HTTPS origin with no path other than `/`. Defaults are `"NO"` and empty respectively. Regenerate and rebuild after changes. Production endpoints must use HTTPS; there is no arbitrary network transport exception. API, policy, and support URLs reject user information, queries, fragments, and unresolved build placeholders; policy/support URLs may have paths.

The optional request is sent only after the grown-up reading check, a park/color selection, and a separate confirmation showing the four exact choice fields and the receiving service's IP/connection-metadata disclosure. Each confirmation authorizes one request; changing choices, dismissing the confirmation, leaving adult settings, or making the app inactive expires it. No perpetual online permission is saved:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe"]
}
```

`POST /v1/wish-preview` returns `id`, `title`, `description`, `image: { mimeType, data }`, and `provider`. The client uses the returned description and continues to render the original native drawing. It does not render the returned SVG. This service is a deterministic illustrated demo, not generative AI. No talking-board sentence is sent. Local development server instructions are in the root/backend documentation; the native client requires an HTTPS deployment or HTTPS development tunnel.

Each request creates a `URLSessionConfiguration.ephemeral` session with nil URL cache, cookie storage, and credential storage; cookie handling is disabled and cache policy bypasses local cache. The delegate accepts only HTTPS redirects to the same host and effective port, with no query, fragment, or user information. Sessions are invalidated and canceled when finished. Adult-session revocation cancels the task, and request ID/authorization-epoch checks run before service invocation and after response completion so canceled or stale work cannot send/apply a request after revocation. Technical hosting metadata and any hosting logs still require an operator-specific retention review.

## Privacy metadata and adult boundaries

`PrivacyNoticeView` is available from the child-facing header and pause screen without a gate. It describes offline retention, the ephemeral talking-board sentence, optional transmission and connection metadata, publisher/contact details, and an offline **Forget choices on this iPad** action. Missing public links are omitted rather than opened as placeholders.

Configure these public release values in `project.yml`; they intentionally default to empty and have no fabricated owner or URL:

| Build setting | Info.plist key |
| --- | --- |
| `WISH_PUBLISHER_NAME` | `WishPublisherName` |
| `WISH_SUPPORT_EMAIL` | `WishSupportEmail` |
| `WISH_PRIVACY_POLICY_URL` | `WishPrivacyPolicyURL` |
| `WISH_SUPPORT_URL` | `WishSupportURL` |
| `WISH_ONLINE_PREVIEW_ENABLED` (default `NO`) | `WishOnlinePreviewEnabled` |
| `WISH_API_BASE_URL` (default empty) | `WishAPIBaseURL` |

The yellow star at the top right opens **Settings** through the existing adult gate. It has a 48-point tap target and a spoken Settings label; the separate Privacy action stays available without that gate. Opening grown-up settings or an external policy/support website requires an ephemeral random four-digit reading check whose prompt spells out each digit. The response uses an accessible numeric keyboard. Answers are held only in view memory and renewed after submission/dismissal; they are never saved. A gate is an adult-task separation mechanism, not identity verification or legal parental consent. It does not block the child from reading the native privacy notice or continuing an offline wish.

Adult access is revoked on settings dismissal and whenever the scene is not active. Pending confirmations and active network work are canceled; re-entry requires a new gate. The default build remains offline. The planned first release is U.S.-only under a separate LLC, with stated audience ages 2–17+ and no upper cap entered. Exact legal publisher name, public contact/policy/support pages, the Kids Category approach for this broad audience, hosting retention, and the root release-record validation are still required before distribution. No claim of completed Apple/legal compliance is made. The current privacy manifest describes the offline baseline with no tracking/data-collection declarations and app-only UserDefaults reason `CA92.1`; reassess declarations before enabling a deployed online feature.

See [Apple requirements review](../docs/apple-requirements-review.md), [backend privacy review](../docs/backend-privacy-review.md), [policy draft](../docs/privacy-policy-draft.html), and [release checklist](../docs/release-checklist.md). Native privacy tests cover URL configuration, one-use confirmations, gate non-persistence, immediate authorization revocation before queued service invocation, stale-response rejection, and offline forgetting. All 30 native tests, including the privacy tests, passed in the Mac simulator run linked above.

## Retention and accessibility

- Preferences are kept in memory unless a grown-up enables **Remember choices on this iPad**. Only non-identifying interest, park, color, and animal selections (plus the internal wish verb used by the park API) are stored in UserDefaults; device backups may include these settings. The read-choice-labels setting is also local. The talking-board sentence is not saved or transmitted and clears on finish/reset/scene inactivity.
- Turn the switch off to erase the stored preference copy, or use **Start a fresh wish** to clear the current choices and saved draft. Finishing a session returns home and keeps the in-memory wish so the child can continue later. **Forget choices on this iPad** additionally turns retention off, resets the read-aloud setting, and revokes adult access; it needs no network connection.
- Large labeled controls, selected-state semantics, system Dynamic Type, VoiceOver labels, spoken AAC responses, static imagery, and Reduce Motion-aware drawer animation are included. These are implementation features, not a completed accessibility audit. Work with AAC users and professionals to evaluate vocabulary grouping and symbol comprehension.
- Stop/Break present a quiet pause screen; Think speaks a request for time without moving the child. No timer, forced completion, eligibility judgment, or destination booking is built into the journey.

## Before TestFlight

The project is a starting point, not a submitted or approved build. Root release documentation tracks the remaining product review, real-device accessibility checks, privacy disclosures, brand/asset permission, deployment, signing, App Store Connect record, and TestFlight review steps. This independent prototype uses its own star mark and park illustrations, and reuses the supplied pictograms unchanged at the user's request. It does not use the Make-A-Wish logo. Confirm rights to distribute the supplied pictograms before a public release.

Verified Apple references, 2026-11-05: [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight setup](https://developer.apple.com/testflight/), [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion), [ephemeral sessions](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral), and [redirect delegation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/urlsession(_:task:willperformhttpredirection:newrequest:completionhandler:)).
