# Wish Explorer

A native iPad prototype for helping a child explore and communicate a wish, at their own pace.

The home screen starts with a full-width yellow **What are your favorites?** card above the 20 illustrated topic pictures from the supplied reference. This dedicated intake is the only place to edit favorites. Its optional six groups are followed by one yellow **Save favorites** button at the bottom. Saving keeps the choices with the current session. A grown-up can enable **Remember choices** in Settings to retain them on the iPad. Every topic opens a three-part journey: actions, a broad setting or object, and a most-important choice. Saved favorites carry into the selected cards and offline wish collage automatically. Core communication words sit in a pull-up drawer opened by its centered tab.

The client-demo opening shows the supplied Make-A-Wish logo in white on blue `#0057B8`, holds briefly, then fades into the app. The demo treatment does not establish endorsement or public distribution rights. Main picture cards, communication-board tiles, and primary controls use rounded shapes.

Grown-up Settings offers Boy, Girl, Man, and Woman speaking styles with explicit preview and stop controls. The native app prefers available premium/enhanced English voices of the requested gender, excludes custom-provider, personal, and novelty voices, and explains fallbacks. Boy and Girl slightly raise an adult voice's pitch. Voice preferences are saved locally and reset by Forget choices. Back uses a short incoming fade/slide, and a rounded progress bar animates through the journey. Reduce Motion skips these animations.

The header's top-left house icon returns to the wish grid while keeping choices. Back sits beside Next at the bottom of each journey page, and is also available beside Save favorites and on the final picture. There is no Skip control; Next can still leave a question unanswered.

SwiftUI and the portable browser preview share fixed PNG artwork, four bundled fonts, and the warm cream/peach/yellow palette. Journey pictures load from 106 checked-in illustrations rather than a device's emoji font. The original 29 source picture files remain unchanged. Grown-up pages use the same custom cream panel and rounded controls instead of default platform forms. See [shared visuals](assets/visual/README.md) and [browser preview](preview/README.md).

## Project status

- **Native app:** SwiftUI iPad source with 20 journeys, 100 actions, 80 settings, 36 shared favorites, an offline collage, speech, a 34-concept communication drawer, opt-in local drafts, and caregiver controls. Older saved drafts decode with the new choices unanswered.
- **Backend:** Node service with a shared journey catalog and authenticated AI scene endpoint, plus the compatible legacy park-description API. Container/deployment files and automated API tests are included. The selected scene provider is direct OpenAI Images API access with target model `gpt-image-2.5-flare`.
- **Optional AI picture:** a grown-up confirms sending selected concept IDs, reviews the generated scene, and decides whether to show it. Original photos and source PDFs are not uploaded. The app defaults to offline with an empty API origin and scene generation disabled. Direct OpenAI credentials remain unconfigured and a successful production image request remains unverified.
- **Drawer:** its height follows a finger drag and springs to open or closed, with tap and accessibility alternatives and Reduce Motion support. Physical iPad interaction validation remains pending.
- **Verification and distribution:** the latest verified baseline, source commit `9b00e20`, passed 73 native unit tests and two UI tests on the Mac runner, with backend checks also passing. Physical-device testing, signing, and TestFlight submission remain pending. [Verified baseline run](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43169927668)

The working name is **Wish Explorer**. This is an independent development prototype; the supplied organization materials inform the experience. Branding and publication details can be finalized with the project owner before release.

## Run the backend on this computer

Install Node.js 22 or later, then from the project folder:

```powershell
cd backend
npm ci
npm test
npm start
```

The local service listens on `http://127.0.0.1:8787` by default. The deployed API origin is [picture-meadow-scene-api.vercel.app](https://picture-meadow-scene-api.vercel.app). Direct OpenAI credentials and a production image-generation result remain outstanding. Provider account access and data-handling terms require review for the intended deployment. See [backend/README.md](backend/README.md) for configuration and API details.

## Run the iPad app on a Mac

Follow [ios/README.md](ios/README.md). Generate the project using XcodeGen, select a simulator, then build and test with Xcode 26 or later. The app's default experience works without a server.

## Project map

| Location | Purpose |
| --- | --- |
| `ios/` | SwiftUI app, assets, native model tests, project specification |
| `backend/` | Stateless API, illustrated preview generation, server tests, container |
| `docs/original-brief.txt` | Recovered request, preserved verbatim |
| `docs/product-brief.md` | First-version behavior and scope |
| `docs/action-journey-design.md` | Current twenty-journey behavior, shared favorites, source-page mapping, and optional scene generation |
| `docs/reference-map.md` | Source mapping and design decisions |
| `docs/architecture.md` | Data flow and boundaries |
| `docs/release-checklist.md` | Work required for TestFlight and public release |
| `docs/ios-readiness-benchmark.md` | Evidence from the November 8 audit and pass/fail gates for native and release readiness |
| `scripts/check-contracts.cjs` | Check native/server choice IDs and source-board vocabulary together |
| `assets/` | Original source picture assets and the reusable picture catalog |
| `backend/docs/ux-components.md` | Current components and the archived six-panel concept with screenshot |
| `docs/apple-requirements-review.md` | Current Apple privacy/submission review and remaining release decisions |
| `docs/white-label-distribution.md` | Business-published first release and options for later client distribution |
| `config/release-metadata.example.json` | U.S. launch and stated ages 2–17+ recorded; publisher, privacy, and Kids Category decisions remain unset |

Run `node scripts/check-contracts.cjs` to check matching native/backend selections, the 54 source-board concepts, and all 216 action, setting, and favorite choices. Native compilation is checked separately on a Mac.

Source PDFs remain in the user's Downloads folder. They are not copied into the Git repository.

The default app build is offline. **Privacy & Data**, the native privacy notice, app information, and AI-concern reporting are reached through grown-up Settings after its code check. There is no privacy link on the child-facing header, pause screen, or code screen. Other privacy features include local forget controls, one-request online confirmations, and grown-up AI-image review and cancellation. A service access token is held in the device Keychain when configured. Child identity, medical fields, photographs, accounts, advertising, and analytics are outside the current journey. The owner confirmed a U.S. launch under a separate LLC and stated ages **2–17+**, with no upper cap recorded. Publisher/contact details, public policy/support pages, age-category decisions, distribution rights, signing, and physical-device verification remain open. See the release checklist for submission work.
