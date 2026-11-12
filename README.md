# Wish Explorer

A native iPad prototype for helping a child explore and communicate a wish, at their own pace.

The home screen retains the 20 illustrated topic pictures from the supplied reference. Every picture now opens an action-led journey with broad settings or objects, shared favorites, and a most-important choice. The selected cards form an offline wish collage. Core communication words sit in a pull-up drawer opened by its centered tab.

## Project status

- **Native app:** SwiftUI iPad source with 20 journeys, 100 actions, 80 settings, 36 shared favorites, an offline collage, speech, a 34-concept communication drawer, opt-in local drafts, and caregiver controls. Older saved drafts decode with the new choices unanswered.
- **Backend:** Node service with a shared journey catalog and authenticated AI scene endpoint, plus the compatible legacy park-description API. Container/deployment files and automated API tests are included. The selected scene provider is direct OpenAI Images API access with target model `gpt-image-2.5-flare`.
- **Optional AI picture:** a grown-up confirms sending selected concept IDs, reviews the generated scene, and decides whether to show it. Original photos and source PDFs are not uploaded. The app defaults to offline with an empty API origin and scene generation disabled. Direct OpenAI credentials remain unconfigured and a successful production image request remains unverified.
- **Drawer:** its height follows a finger drag and springs to open or closed, with tap and accessibility alternatives and Reduce Motion support. Physical iPad interaction validation remains pending.
- **Verification and distribution:** source commit `11506bd` built successfully on the Mac runner. All 58 native unit tests, the real tap-and-drag UI test, and 36 backend tests passed. The simulator was iPad mini (A17 Pro), iOS 26.5. Physical-device testing, signing, and TestFlight submission remain pending. [Successful native and backend run](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43152713228)

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

The default app build is offline. Privacy features include a native notice, adult gates, local forget controls, one-request online confirmations, and grown-up AI-image review and cancellation. A service access token is held in the device Keychain when configured. Child identity, medical fields, photographs, accounts, advertising, and analytics are outside the current flow. The owner confirmed a U.S. launch under a separate LLC and stated ages **2–17+**, with no upper cap recorded. Publisher/contact details, public policy/support pages, age-category decisions, distribution rights, signing, and physical-device verification remain open. See the release checklist for submission work.
