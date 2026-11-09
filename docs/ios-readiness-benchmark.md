# iPad readiness benchmark

Reviewed November 8, 2026 against app source commit `d505167`. This audit ran on Windows. It establishes portable checks and inspected configuration; it does not establish native compilation, iPad usability, signing, or Apple approval.

**Verdict: development starter ready for Mac validation; not yet ready for TestFlight or App Store submission.** Use evidence-backed release gates rather than a readiness percentage.

## Evidence from this audit

| Check | Observed result | What it proves |
| --- | --- | --- |
| Backend automated tests | 15 passed; 0 failed | Fixed-choice API behavior, validation, request limits, CORS, and temporary rate-limiter metadata behavior covered by these tests |
| Backend syntax check | Passed | Checked JavaScript files parse |
| Cross-component contracts | Passed, including 96 choice combinations | Native/server IDs agree; backend illustrated results vary with selections |
| Picture resources | Passed | 20 topic concepts + 34 core concepts; native resources match the 29 original picture files; property lists, catalog metadata and opaque 1024px icon are valid |
| Release-validator tests | 6 passed | The validator's tested acceptance/rejection cases behave as intended |
| Actual release record | Not ready: 12 unresolved configuration/review checks | Publisher/contact/pages/category/review decisions remain incomplete; these are not 12 newly discovered code defects |
| Native tests | 30 written; not run | Test source exists. No Swift compilation or XCTest result is established |
| Git / CI | Clean committed app source; no configured remote | Workflow files exist, but this checkout supplies no hosted CI-run evidence |

The current CI tests the release validator; it does not validate a completed production release record. A future green CI run would therefore not, by itself, mean the app is release-ready. Native verification currently selects one available iPad simulator and runs unsigned tests; there is no signed archive, physical-device result, retained result bundle, UI-test target, or performance measurement in the inspected evidence.

## Pass/fail release gates

The acceptance targets below are proposed project criteria. They are not an Apple certification program or a clinical/AAC validation standard.

| Gate | Evidence required to pass | Current status |
| --- | --- | --- |
| Reproducible native build | A clean checkout generates and builds on a Mac using the required Xcode/SDK; all 30 native tests pass. Record commit, toolchain, simulator and test result bundle. | Unverified |
| Native user journeys | Every promised v1 task passes on the agreed device/OS matrix, with zero blocking defects. Include all picture routes, park choices, skip/back/change, postcard, drawer, all 34 core words, settings, pause/resume and finishing. | Unverified on iPad |
| Offline and lifecycle behavior | Airplane-mode launch, pictures and speech work; interruptions recover safely; remembering is opt-in; turning it off removes the saved wish draft; Forget and adult-session revocation behave as documented. | Source/tests exist; device proof pending |
| Accessibility and motor access | All critical tasks work with VoiceOver and Switch Control. Essential controls remain visible in portrait, landscape, split view and supported large text sizes. Drawer access does not depend on dragging. | Implementation features exist; audit pending |
| Responsiveness and stability | Measure launch, tap-to-feedback, tap-to-speech, memory and interruptions on real iPads. Establish a baseline and regression limits on the oldest intended device; no blocking crashes or hangs during the pilot. | No measurements yet |
| Child/caregiver usability | Observe representative users and caregivers with an AAC specialist; review symbol understanding, stable word positions, refusal/pause controls, and the different needs across ages 2–17+. | Pending |
| Privacy and audience | Real publisher/contact/policy/support pages, deliberate Kids Category/content-rating decision, appropriate U.S. age-assurance review, accurate App Privacy answers, and inspection of the final archive's privacy manifest. | Incomplete |
| Distribution and beta | Final bundle ID/team, signed archive validation, installation on real iPads, and a working internal TestFlight build. Then record tester feedback and resolve blocking issues before broader release. | Not configured / not verified |
| Public submission | Agreed shipping scope, distribution rights for art/branding, accurate native screenshots/store description, completed release record and final App Review submission. | Not ready |

Test an older intended physical iPad as well as a current device. Testing only the newest simulator does not cover this matrix. Accessibility support declarations must reflect actual common-task testing, rather than the presence of labels in source.

## Product scope and demo boundary

The native product includes a complete amusement-park example and supported conversations for the other 19 interest topics. Those conversation routes can be legitimate v1 functionality if that is the agreed scope and the description is accurate. This audit does not require nineteen additional detailed journeys merely because they are roadmap possibilities.

The recent logo opening, background music, and three childlike narration voices are **video production edits**. The native app still uses the system English speech synthesizer. The client video is a concept demonstration, not a recording of a verified iPad build or evidence that its narration features are implemented in the app.

The default native build is offline. A deployed backend is not required to validate that release configuration. If online descriptions are enabled, add deployed HTTPS/hosting/retention tests and disclosures. One source hardening item is to bound response bytes while downloading: the native client currently applies its 500KB response check after buffering the response.

## Repeat the portable checks

From the repository root:

```powershell
npm --prefix backend test
npm --prefix backend run check
node scripts/check-contracts.cjs
python -m unittest discover -s scripts -p test_release_metadata.py
python ios/scripts/check_resources.py
python scripts/check-release-metadata.py config/release-metadata.example.json
```

The last command is expected to fail while the example remains incomplete. It must not be treated as a completed production release record. Enter real values in the ignored local record and record only reviews actually completed.

## Next milestone

On a Mac, run `bash ios/scripts/verify.sh`. Resolve build/test failures, preserve the result bundle and exact toolchain, and then install a signed build on an iPad. Improve CI to retain test evidence and exercise the agreed minimum/current OS matrix. Keep this separate from the later signed archive and submission gate.

## Primary Apple references checked November 8, 2026

- [SDK/upload requirements](https://developer.apple.com/news/upcoming-requirements/): Xcode 26+ and iOS/iPadOS 26 SDK+ remain the upload minimum. The project's deployment target is 17; deployment and build SDK are different settings.
- [App completeness and beta distribution, guidelines 2.1–2.2](https://developer.apple.com/app-store/review/guidelines/#app-completeness): shipped behavior and metadata must be complete and accurately represented; beta distribution uses TestFlight.
- [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/): a working uploaded build and beta information are required; first external beta builds undergo review.
- [Accessibility evaluation](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/): evaluate common tasks across supported assistive features and devices before making support claims.
- [Kids Category guidance](https://developer.apple.com/kids/): age bands are 5 and under, 6–8 and 9–11. Intended audience ages 2–17+ are distinct from content age rating and do not automatically select a band.
- [App Privacy details](https://developer.apple.com/app-store/app-privacy-details/), [age-assurance guidance](https://developer.apple.com/support/age-assurance/), and [intellectual-property requirements](https://developer.apple.com/app-store/review/guidelines/#intellectual-property): apply them to the actual shipping configuration and material.
