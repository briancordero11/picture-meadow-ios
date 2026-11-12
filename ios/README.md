# Wish Explorer for iPad

Native SwiftUI prototype, iPadOS 17 and later. A full-width pale-yellow **What are your favorites?** card appears above **20 picture interests** in the supplied source order. The optional intake has six groups and a maximum of ten favorites, followed by one yellow **Save favorites** button at the bottom. Its explanation makes clear that saving keeps the choices with the current session; only a grown-up's **Remember choices** opt-in persists the draft on the iPad.

The twenty topic cards have peach backgrounds, dark outlines, rounded 16-point corners, and black labels above the original pictograms. The topic grid uses four columns on a full iPad layout and two in a compact layout. A topic opens up to three actions → broad setting or object → shared favorites → most-important picture → offline wish collage. Favorites carry across topic changes and can be changed during a journey. **Keep my favorites** advances that stage without clearing them. Other optional stages can be skipped or revisited. Yosemite is a camp example, and the gift journey includes a brick creation and creative or gaming computer.

`JourneyCatalog` loads 100 action choices, 80 settings, and 36 shared favorites from the bundled JSON. New subchoices use large labeled emoji cards. The twenty home pictures and thirty-four drawer pictures retain the supplied artwork. Saved drafts from the earlier park prototype decode with the new fields unanswered. Legacy park selections remain readable, while new home selections enter the generic action journey. See [the action-journey design](../docs/action-journey-design.md) for source-page mapping and all twenty routes.

The source's other **34 core communication pictures** live in the pull-up drawer. The collapsed drawer leaves a centered rounded tab with a grabber and chevron. Its height follows finger movement, then uses the predicted release position to spring open or closed. A new drag can interrupt that snap. Tap, adjustable accessibility actions, and an explicit open/close action remain available. Reduce Motion removes the spring animation. Stop, break, finished, and time-to-think remain in the drawer. The phrase bar and postcard also have Stop speaking controls. Speech uses the system synthesizer. Finger tracking, interruptions, and assistive access still require physical iPad validation.

The compact drawer uses five stable columns and six rows, followed by four adjacent phrase tiles. I/You/We stay vertically aligned in the first column, and the original action, descriptor, and question columns remain alongside each other after removing the interest topics. Tiles have 12-point rounded corners, no added grid gutters, thin dividers, 5-point internal padding, and a 96-point minimum height. Text wraps with Dynamic Type and the drawer scrolls when necessary. The drawer can occupy up to 82% of the available app height. `CommunicationWord.mainRows` and `phraseWords` define the spatial arrangement and have ordering tests. Primary actions and the yellow Save favorites control also use rounded shapes.

The cold-launch client-demo intro displays the supplied Make-A-Wish `ClientDemoLogo` asset in white on blue `#0057B8`. The OS launch background uses the same color. The SwiftUI overlay holds for about 750 ms and fades over 350 ms, with an immediate dismissal after the hold under Reduce Motion. It keeps the app mounted underneath, cancels cleanly, and does not replay on page changes or background/foreground transitions. This client-demo branding does not establish organizational endorsement or public distribution rights.

`WishWordmark` remains the main screen's blue Georgia Bold **Create your wish** heading with its original drawn arch and star. It scales with Dynamic Type, wraps on narrow layouts, and has one accessible heading label.

Back changes page or journey stage immediately and eases the incoming content from half opacity and an 18-point offset over 300 ms. A single content tree remains interactive; the header and communication board stay fixed. An active-only animation timeline stops when navigation changes, Settings opens, the scene becomes inactive, or Reduce Motion is enabled. The 12-point rounded progress bar animates between 25/50/75/100 percent over 320 ms, with accessible progress values and no visible step counter.

Grown-up **Speaking voice** settings offers Boy, Girl, Man, and Woman presets, a fixed **Preview voice** sample, and **Stop voice**. Selection itself stays quiet and stops existing speech. `SpeechVoicePreference` ranks eligible English voices by matching gender, premium/enhanced/basic quality, U.S. English, and stable identifier. Custom-provider, personal, and novelty voices are excluded using an Apple identifier compatibility allowlist and voice traits. The UI shows the actual available voice and any fallback; Boy/Girl use adult base voices at a slightly higher pitch. No voice download or online TTS API is requested by this code. The preset is saved in UserDefaults independently of draft remembering. Starting a new wish preserves it; Forget restores Woman and removes the stored preference.

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

The script checks macOS and Xcode 26+, generates the project, validates property lists, and runs the native unit and UI tests. It selects an available iPad simulator by UDID, preferring the newest installed iOS runtime. To select a specific simulator yourself:

```bash
WISH_TEST_DESTINATION='platform=iOS Simulator,name=iPad Pro 13-inch (M4)' bash scripts/verify.sh
```

**The latest verified baseline, source commit `c54f7a3`, passed the unsigned native build, 70 unit tests, and two UI tests.** The UI tests cover drawer taps/drags and passing the displayed grown-up code to navigate Privacy & Data and App information. Favorites intake is covered by unit tests. The tests do not establish physical-device feel, frame-rate performance, or a signed release. [Verified baseline run](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43163020697)

The native suite includes catalog/resource, migration, journey selection, persistence, and privacy behavior. Speech, VoiceOver, Switch Control, portrait/landscape, and physical-device behavior need hands-on iPad verification. `python3 scripts/check_resources.py` checks portable resources and unchanged source images. The root contract checker compares the native, authoritative, and backend journey catalogs. Neither portable checker compiles Swift.

## Backend connection

Offline mode is the default. `WISH_API_BASE_URL` is empty, `WISH_SCENE_GENERATION_ENABLED` is `"NO"`, and the collage works without a server. The deployed API origin is `https://picture-meadow-scene-api.vercel.app`. Direct OpenAI credentials are unconfigured, and a production image-generation request and the complete native connection remain unverified.

Optional AI scenes require a valid HTTPS origin, `WISH_SCENE_GENERATION_ENABLED: "YES"`, and an accurate `WISH_AI_PROVIDER_NAME`, currently `OpenAI (direct)`. Regenerate and rebuild after changing these settings. A grown-up then supplies the service access token in Settings. `SceneAccessKeychain` stores that token with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; the OpenAI API key stays on the server. The selected service integration calls the direct OpenAI Images API with target model `gpt-image-2.5-flare`. It requires the server generation flag, service access token, and direct provider credentials.

Provider account access, retention terms, and any required data-handling approval must be verified for the actual account. An application setting alone does not establish Zero Data Retention eligibility or approval.

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

Each request creates a `URLSessionConfiguration.ephemeral` session with nil URL cache, cookie storage, and credential storage; cookie handling is disabled and cache policy bypasses local cache. The legacy delegate permits only HTTPS redirects to the same host/effective port, with no query, fragment, or user information. The AI image client rejects redirects. Sessions are invalidated and canceled when finished. Adult-session revocation cancels the task, and request ID/authorization-epoch checks run before invocation and after response completion so canceled or stale work cannot send/apply a result after revocation. Technical hosting metadata and logs still require an operator-specific retention review.

## Privacy metadata and adult boundaries

The native privacy notice is available only inside grown-up Settings after the code check. The child-facing header, pause screen, and code screen have no privacy entry. **Privacy & Data** explains local retention, temporary board words/images, optional transmission, connection metadata, and local forgetting. App information/help and AI-concern reporting are in the same grown-up area. Publisher/contact/public-policy values remain unconfigured, and missing links are omitted.

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

The yellow star at the top right opens **Settings** through an ephemeral four-digit reading check, with a 48-point tap target and spoken Settings label. Its prompt spells out each digit, and the response uses an accessible numeric keyboard. Answers stay in view memory and renew after submission/dismissal. Passing the code opens grown-up settings, including the privacy notice and data controls. External links stay within grown-up controls. The gate separates tasks and does not verify identity, guardianship, or legal parental consent. The offline picture journey remains available without opening Settings.

Adult access is revoked on settings dismissal and whenever the scene is not active. Pending confirmations and active network work are canceled; re-entry requires a new gate. The default build remains offline. The planned first release is U.S.-only under a separate LLC, with stated audience ages 2–17+ and no upper cap entered. Exact legal publisher name, public contact/policy/support pages, the Kids Category approach for this broad audience, hosting retention, and the root release-record validation are still required before distribution. No claim of completed Apple/legal compliance is made. The current privacy manifest describes the offline baseline with no tracking/data-collection declarations and app-only UserDefaults reason `CA92.1`; reassess declarations before enabling a deployed online feature.

See [Apple requirements review](../docs/apple-requirements-review.md), [backend privacy review](../docs/backend-privacy-review.md), [policy draft](../docs/privacy-policy-draft.html), and [release checklist](../docs/release-checklist.md). The verified 70-unit baseline includes journey, intake, persistence, and request/privacy checks. The two UI tests cover the drawer and code-gated settings navigation. Combined source `c54f7a3`, including voice preferences, Back motion, and the animated progress bar, passed the native and backend workflow.

## Retention and accessibility

- Choices, including favorites retained with **Save favorites**, stay in the current session unless a grown-up enables **Remember choices on this iPad**. UserDefaults then stores topic, actions, setting, favorites, and essential choice alongside compatible older park fields. Device backups may include those preferences. The read-choice-labels setting is also local. The talking-board sentence clears on finish, reset, and inactivity. AI images stay in memory. A configured service code is stored separately in Keychain and can be removed from grown-up Settings.
- Turn the switch off to erase the stored preference copy, or use **Start a fresh wish** to clear the current choices and saved draft. Finishing a session returns home and keeps the in-memory wish so the child can continue later. **Forget choices on this iPad** additionally turns retention off, resets the read-aloud setting, and revokes adult access; it needs no network connection.
- Large labeled controls, selected states, Dynamic Type, VoiceOver labels, spoken AAC responses, and the finger-tracking, spring drawer with Reduce Motion support are implemented. Validate their behavior with real iPads, AAC users, caregivers, and communication professionals.
- Stop/Break present a quiet pause screen; Think speaks a request for time without moving the child. No timer, forced completion, eligibility judgment, or destination booking is built into the journey.

## Before TestFlight

Root release documentation tracks remaining product review, real-device accessibility checks, privacy disclosures, brand/asset permission, deployment, signing, App Store Connect record, and TestFlight work. The current client-demo opening uses the supplied Make-A-Wish logo; the main heading and illustrations retain the prototype's existing design. Supplied pictograms remain unchanged. Confirm distribution rights and approved public branding before a release. The client-demo treatment establishes no endorsement or App Store approval.

Verified Apple references, 2026-11-05: [upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/), [TestFlight setup](https://developer.apple.com/testflight/), [Reduce Motion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion), [ephemeral sessions](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/ephemeral), and [redirect delegation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/urlsession(_:task:willperformhttpredirection:newrequest:completionhandler:)).
