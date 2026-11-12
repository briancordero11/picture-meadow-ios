# TestFlight and release checklist

Status: action-led development prototype with current native changes awaiting a new Mac CI result. Signing, physical-device validation, and TestFlight upload remain pending. The earlier unsigned build and 30 passing tests for commit `bbf5ed5` predate the new journeys, migration, scene service, and drawer changes. [Historical simulator run](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43135189389)

Confirmed release direction: United States, published by a **separate, independent LLC, not CanaClaw**, with future white-label versions planned. The LLC's exact legal name is unspecified, and there is no public business email or published privacy-policy URL yet. The intended audience is exactly **"2 - 17+"**; no upper age cap is inferred. This broad span crosses Kids Category bands and extends to older users, so Kids Category must be reviewed deliberately rather than selected automatically. See [white-label distribution](white-label-distribution.md) before choosing public client apps or private Custom Apps; no Apple account enrollment or App Store Connect availability has been verified.

Privacy references include the [Apple requirements review](apple-requirements-review.md), [service data-flow audit](backend-privacy-review.md), and [unfinished policy draft](privacy-policy-draft.html). Current source adds catalog-ID scene requests, grown-up confirmation and image review, cancellation, transient generated images, and service access in device Keychain. The default app keeps an empty API origin and both online flags disabled. The API is deployed at [picture-meadow-scene-api.vercel.app](https://picture-meadow-scene-api.vercel.app); live provider access and native end-to-end behavior remain under verification. Reconcile the privacy documents with the selected shipping configuration before release.

## Implemented source scope

- [x] Route all twenty original home pictures through actions, broad settings or objects, shared favorites, and a most-important choice.
- [x] Assemble selected picture concepts into an offline collage and decode older drafts with missing journey fields unanswered.
- [x] Implement the optional actual AI scene API using catalog IDs, with grown-up one-request permission, review, removal, and cancellation controls.
- [x] Preserve the legacy park-description API for compatible saved choices while new home routes use the action-led flow.
- [x] Implement finger-tracking drawer height, spring snapping, tap/accessibility alternatives, and Reduce Motion behavior.

## Mac build and device verification

- [ ] Use Xcode 26 or later with the iOS 26 SDK or later. Apple's upload minimum is distinct from this app's iOS 17 deployment target.
- [ ] Run `bash ios/scripts/verify.sh` for the current changes, retain the result bundle, and record the source commit, toolchain, simulator, and test totals.
- [ ] Verify all twenty journeys and skip/back/change paths on a physical iPad in landscape, portrait, split view, and supported text sizes.
- [ ] Review VoiceOver, Switch Control, Stop speaking, interruption handling, and every No/Stop/Think/Break/Finished control.
- [ ] Validate drawer finger tracking, interrupted spring snaps, rotation during drag, canceled gestures, tap/accessibility alternatives, and Reduce Motion on device.
- [ ] Verify offline launch, migration of older drafts, opt-in retention, favorite/essential-choice consistency, forgetting, and reset behavior.
- [ ] Validate grown-up scene confirmation, Keychain access/removal, cancellation, stale-result rejection, app inactivity, image review, and discard/removal with an actual configured service.
- [ ] Review vocabulary/symbol comprehension with AAC users, caregivers, and a communication specialist. The source board is a reference, not validation of a new AAC interface.

## Signing and TestFlight

- [ ] Choose the final app name, bundle ID, and verified Apple development team for the independent LLC; obtain its exact legal name.
- [ ] Create the corresponding App Store Connect app and signing configuration.
- [ ] Archive, validate, and upload from Xcode; complete export-compliance questions based on the final build.
- [ ] Supply beta description, review notes, feedback contact, and tester groups. Do not add external testers until the build is ready for their use and Apple's required review is complete.
- [ ] Run internal testing before an external family-facing pilot.

## Before publication or a real family pilot

- [ ] Finalize approved visual branding and a release icon; do not imply organizational endorsement without agreement.
- [ ] Publish the actual privacy policy and support contact, complete App Privacy answers against the final binary and hosting behavior, and verify the included privacy manifest.
- [ ] Decide the content age rating and Kids Category treatment for the declared **"2 - 17+"** audience. The span includes multiple Kids bands and older users; do not assign a single Kids band automatically or invent an upper age cap. Implement and validate the resulting requirements.
- [ ] Review the declared audience and resolve current U.S. state age-assurance, parental-consent, and significant-update obligations for the U.S. launch. Do not substitute the reading gate for legal parental consent or assume a low content rating resolves this. Reassess before expanding to another country.
- [ ] Confirm the shipping online configuration. Current defaults disable descriptions and scenes and leave the API origin empty. Complete provider credentials, native configuration, and a verified live request before enabling AI for users.
- [ ] Review AI provider/operator disclosures, IP retention, hosting logs, generated-content handling, rate limits, access-token operation, and App Privacy answers for the actual deployed service. Confirm the chosen operating controls on the deployed environment.
- [ ] Pilot the twenty journeys, including local and imagined ideas, with Super Stars and caregivers. Review the favorite examples, action limits, and essential-choice prompt with an AAC specialist.
- [ ] Review the implemented grown-up AI confirmation and result-review flow on device. Reassess permissions and data design if later adding accounts, sharing, photograph uploads, medical fields, or real wish submission.
- [ ] Prepare iPad screenshots from the real app, accessibility descriptions, store copy, and review instructions.

## Official references checked November 5, 2026

- [Apple upcoming requirements](https://developer.apple.com/news/upcoming-requirements/): as of April 28, 2026, uploads require Xcode 26 or later and the iOS 26 SDK or later.
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [TestFlight](https://developer.apple.com/testflight/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

Recheck these requirements before a real upload; they change independently of the source code.

## Check the release record

Copy `config/release-metadata.example.json` to ignored `config/release-metadata.local.json`, enter the real decisions, and record the reviews that have actually been completed. The example records the confirmed `US` storefront and the audience as `statedAgeRange: "2–17+"`, `minimumAge: 2`, `maximumAge: null`. Null means the upper age is explicitly open-ended, not missing or capped at 17. The Kids Category decision still needs deliberate review for this span. This file does not change App Store Connect availability. Then run:

```powershell
python scripts/check-release-metadata.py config/release-metadata.local.json --check-public-links
```

The unfilled example must fail. A passing record check does not verify the native build, compiled configuration, legal compliance, policy accuracy, or Apple approval. Copy the publisher/support/privacy values into the corresponding `WISH_*` build settings in `ios/project.yml`, and check the built archive and App Store Connect entries for consistency. The public-links option checks whether the configured pages are readable; it does not publish anything.
