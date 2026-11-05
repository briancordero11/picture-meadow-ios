# TestFlight and release checklist

Status: development starter, not uploaded, signed, or device-validated.

## Mac build and device verification

- [ ] Use Xcode 26 or later with the iOS 26 SDK or later. Apple's upload minimum is distinct from this app's iOS 17 deployment target.
- [ ] Run `bash ios/scripts/verify.sh` and review the simulator test result.
- [ ] Open the generated project and verify every route on an actual iPad, including landscape, portrait, split view, and accessibility text sizes.
- [ ] Review VoiceOver reading order, Switch Control access, Reduce Motion, speech stopping, interruption handling, and all No/Stop/Think/Break/Finished controls.
- [ ] Verify that an offline launch works, optional network failure leaves the local postcard available, draft persistence is opt-in, and reset clears saved choices.
- [ ] Review vocabulary/symbol comprehension with AAC users, caregivers, and a communication specialist. The source board is a reference, not validation of a new AAC interface.

## Signing and TestFlight

- [ ] Choose the final app name, bundle ID, and Apple development team.
- [ ] Create the corresponding App Store Connect app and signing configuration.
- [ ] Archive, validate, and upload from Xcode; complete export-compliance questions based on the final build.
- [ ] Supply beta description, review notes, feedback contact, and tester groups. Do not add external testers until the build is ready for their use and Apple's required review is complete.
- [ ] Run internal testing before an external family-facing pilot.

## Before publication or a real family pilot

- [ ] Finalize approved visual branding and a release icon; do not imply organizational endorsement without agreement.
- [ ] Publish the actual privacy policy and support contact, complete App Privacy answers against the final binary and hosting behavior, and verify the included privacy manifest.
- [ ] Decide the appropriate age rating and whether the app will be placed in the Kids Category; implement and validate any requirements that follow from that choice.
- [ ] Complete the remaining wish routes and evaluate retaining multiple ideas, including a local idea.
- [ ] If using a hosted backend, deploy behind HTTPS with appropriate edge rate limits, restricted operational access, retention controls, and incident procedures. Confirm no wish payloads enter infrastructure logs.
- [ ] If adding AI generation, accounts, sharing, photographs, medical fields, or wish submission, review the new data flows and caregiver permissions before implementation. These features are not part of this starter.
- [ ] Prepare iPad screenshots from the real app, accessibility descriptions, store copy, and review instructions.

## Official references checked November 5, 2026

- [Apple upcoming requirements](https://developer.apple.com/news/upcoming-requirements/): as of April 28, 2026, uploads require Xcode 26 or later and the iOS 26 SDK or later.
- [Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [TestFlight](https://developer.apple.com/testflight/)
- [App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

Recheck these requirements before a real upload; they change independently of the source code.
