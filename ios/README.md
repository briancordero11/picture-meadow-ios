# Wish Explorer for iPad

Native SwiftUI prototype, iPadOS 17 and later. The main screen presents **20 picture interests** in the supplied source order, with peach tiles, dark outlines, and black labels above the original colorful pictograms. It uses four columns on a full iPad layout and two in a compact layout. All twenty interests follow the current journey: welcome → interest picture → up to three actions → broad setting or object → optional favorites → most-important picture → offline wish collage. Every stage can be skipped or revisited. Yosemite is a camp example, and the gift journey includes a brick creation and creative or gaming computer.

`JourneyCatalog` loads 100 action choices, 80 settings, and 36 shared favorites from the bundled JSON. New subchoices use large labeled emoji cards. The twenty home pictures and thirty-four drawer pictures retain the supplied artwork. Saved drafts from the earlier park prototype decode with the new fields unanswered. Legacy park selections remain readable, while new home selections enter the generic action journey. See [the action-journey design](../docs/action-journey-design.md) for source-page mapping and all twenty routes.

The source's other **34 core communication pictures** live in the pull-up drawer. The collapsed drawer leaves a centered rounded tab with a grabber and chevron. Its height follows finger movement, then uses the predicted release position to spring open or closed. A new drag can interrupt that snap. Tap, adjustable accessibility actions, and an explicit open/close action remain available. Reduce Motion removes the spring animation. Stop, break, finished, and time-to-think remain in the drawer. The phrase bar and postcard also have Stop speaking controls. Speech uses the system synthesizer. Finger tracking, interruptions, and assistive access still require physical iPad validation.

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

**The action journeys, scene-generation integration, migration, and new drawer behavior await a fresh Mac CI result.** An earlier unsigned build and 30 tests passed on November 11, 2026 for commit `bbf5ed5`, with Xcode 26.6 and the iPad mini (A17 Pro) simulator on iOS 26.5. That historical run predates these changes. [Earlier GitHub Actions result](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43135189389)

The native suite includes catalog/resource, migration, journey selection, persistence, and privacy behavior. Speech, VoiceOver, Switch Control, portrait/landscape, and physical-device behavior need hands-on iPad verification. `python3 scripts/check_resources.py` checks portable resources and unchanged source images. The root contract checker compares the native, authoritative, and backend journey catalogs. Neither portable checker compiles Swift.

## Backend connection

Offline mode is the default. `WISH_API_BASE_URL` is empty, `WISH_SCENE_GENERATION_ENABLED` is `"NO"`, and the collage works without a server. The deployed API origin is `https://picture-meadow-scene-api.vercel.app`. Its live provider connection and the complete native request still require verification.

Optional AI scenes require a valid HTTPS origin, `WISH_SCENE_GENERATION_ENABLED: "YES"`, and an accurate `WISH_AI_PROVIDER_NAME`. Regenerate and rebuild after changing these settings. A grown-up then supplies the service access token in Settings. `SceneAccessKeychain` stores that token with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; provider credentials stay on the server. The service also needs its generation flag, token, model, and AI Gateway credentials configured.

After a fresh adult gate, each request shows the receiving service, provider, selected concepts, and connection-metadata disclosure. Confirming authorizes one request. The native client sends fixed catalog IDs to `POST /v1/wish-scene`, for example:

```json
{
  "interestId": "camp",
  "actionIds": ["camp-explore", "camp-stars"],
  "settingId": "camp-yosemite",
  "favoriteIds": ["favorite-color-blue"],
  "essentialChoiceId": "camp-stars"
}
```

The server combines authored fragments for those IDs into one AI scene. A grown-up reviews the returned picture before displaying it, and can cancel generation, discard the result, or remove an approved picture. Changing choices, leaving adult settings, or making the app inactive revokes pending permission and cancels work. Original picture files, photographs, child identity, medical information, and the talking-board sentence are excluded from the scene payload. Generated images stay in memory and are omitted from saved drafts. Live generation success remains unverified until an actual provider request completes.

API origins allow HTTPS with an empty or `/` path. Policy/support URLs may have paths. URL validation rejects user information, queries, fragments, and unresolved build placeholders.

### Legacy description API

The older deterministic park service remains for compatibility. **Grown-ups → Refresh this wish's description** requires `WISH_ONLINE_PREVIEW_ENABLED: "YES"`, the HTTPS API origin, and compatible park/color choices. Its default is `"NO"`. New home selections follow the action-led journey, while migrated park drafts can retain their original values.

The optional request is sent only after the grown-up reading check, a park/color selection, and a separate confirmation showing the four exact choice fields and the receiving service's IP/connection-metadata disclosure. Each confirmation authorizes one request; changing choices, dismissing the confirmation, leaving adult settings, or making the app inactive expires it. No perpetual online permission is saved:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe"]
}
```

`POST /v1/wish-preview` returns `id`, `title`, `description`, `image: { mimeType, data }`, and `provider`. The legacy client uses its description with the original native drawing and leaves the returned SVG unrendered. Its deterministic illustration implementation is separate from `POST /v1/wish-scene`. Local server instructions are in the root/backend documentation; native online requests require HTTPS.

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
| `WISH_SCENE_GENERATION_ENABLED` (default `NO`) | `WishSceneGenerationEnabled` |
| `WISH_AI_PROVIDER_NAME` | `WishAIProviderName` |
| `WISH_API_BASE_URL` (default empty) | `WishAPIBaseURL` |

The yellow star at the top right opens **Settings** through the existing adult gate. It has a 48-point tap target and a spoken Settings label; the separate Privacy action stays available without that gate. Opening grown-up settings or an external policy/support website requires an ephemeral random four-digit reading check whose prompt spells out each digit. The response uses an accessible numeric keyboard. Answers are held only in view memory and renewed after submission/dismissal; they are never saved. A gate is an adult-task separation mechanism, not identity verification or legal parental consent. It does not block the child from reading the native privacy notice or continuing an offline wish.

Adult access is revoked on settings dismissal and whenever the scene is not active. Pending confirmations and active network work are canceled; re-entry requires a new gate. The default build remains offline. The planned first release is U.S.-only under a separate LLC, with stated audience ages 2–17+ and no upper cap entered. Exact legal publisher name, public contact/policy/support pages, the Kids Category approach for this broad audience, hosting retention, and the root release-record validation are still required before distribution. No claim of completed Apple/legal compliance is made. The current privacy manifest describes the offline baseline with no tracking/data-collection declarations and app-only UserDefaults reason `CA92.1`; reassess declarations before enabling a deployed online feature.

See [Apple requirements review](../docs/apple-requirements-review.md), [backend privacy review](../docs/backend-privacy-review.md), [policy draft](../docs/privacy-policy-draft.html), and [release checklist](../docs/release-checklist.md). Privacy tests cover URL configuration, one-use confirmations, gate non-persistence, revocation before service invocation, stale responses, and offline forgetting. The earlier 30-test result is historical. Current native results must be recorded from a new run.

## Retention and accessibility

- Preferences are kept in memory unless a grown-up enables **Remember choices on this iPad**. UserDefaults then stores the topic, actions, setting, favorites, and essential choice alongside compatible older park fields. Device backups may include those preferences. The read-choice-labels setting is also local. The talking-board sentence clears on finish, reset, and scene inactivity. AI images are transient. A configured service access token is stored separately in Keychain and can be removed from grown-up Settings.
- Turn the switch off to erase the stored preference copy, or use **Start a fresh wish** to clear the current choices and saved draft. Finishing a session returns home and keeps the in-memory wish so the child can continue later. **Forget choices on this iPad** additionally turns retention off, resets the read-aloud setting, and revokes adult access; it needs no network connection.
- Large labeled controls, selected states, Dynamic Type, VoiceOver labels, spoken AAC responses, and the finger-tracking, spring drawer with Reduce Motion support are implemented. Validate their behavior with real iPads, AAC users, caregivers, and communication professionals.
- Stop/Break present a quiet pause screen; Think speaks a request for time without moving the child. No timer, forced completion, eligibility judgment, or destination booking is built into the journey.

## Before TestFlight

The project is a starting point, not a submitted or approved build. Root release documentation tracks the remaining product review, real-device accessibility checks, privacy disclosures, brand/asset permission, deployment, signing, App Store Connect record, and TestFlight review steps. This independent prototype uses its own star mark and park illustrations, and reuses the supplied pictograms unchanged at the user's request. It does not use the Make-A-Wish logo. Confirm rights to distribute the supplied pictograms before a public release.

Verified Apple references, 2026-11-05: [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight setup](https://developer.apple.com/testflight/), [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion), [ephemeral sessions](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral), and [redirect delegation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/urlsession(_:task:willperformhttpredirection:newrequest:completionhandler:)).
