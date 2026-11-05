# Wish Explorer

A native iPad prototype for helping a child explore and communicate a wish, at their own pace.

This project starts from the recovered project brief and the supplied wish-discovery materials. The first complete path explores an amusement park, a rollercoaster color, and animals, then creates a personalized illustrated wish card. The communication board remains accessible throughout.

## Project status

- **Native app:** SwiftUI iPad app source, offline wish journey, speech, communication board, local draft, and caregiver controls.
- **Backend:** dependency-free Node service with a catalog and illustrated wish-preview endpoint; Docker packaging and automated API tests.
- **Image preview:** original illustrations assembled from selected choices. These are illustrative, not photographs, AI-generated images, bookings, or wish approvals.
- **Distribution:** Xcode project generation, simulator checks, and a TestFlight release checklist. Native compilation, signing, device testing, and submission require a Mac and Apple developer access and have not been completed on this Windows computer.

The working name is **Wish Explorer**. This is an independent development prototype; the supplied organization materials inform the experience. Branding and publication details can be finalized with the project owner before release.

## Run the backend on this computer

Install Node.js 22 or later, then from the project folder:

```powershell
cd backend
npm test
npm start
```

The service listens on `http://127.0.0.1:8787` by default. See [backend/README.md](backend/README.md) for host/port configuration and the API contract.

## Run the iPad app on a Mac

Follow [ios/README.md](ios/README.md). Generate the project using XcodeGen, select a simulator, then build and test with Xcode 26 or later. The app's default experience works without a server.

## Project map

| Location | Purpose |
| --- | --- |
| `ios/` | SwiftUI app, assets, native model tests, project specification |
| `backend/` | Stateless API, illustrated preview generation, server tests, container |
| `docs/original-brief.txt` | Recovered request, preserved verbatim |
| `docs/product-brief.md` | First-version behavior and scope |
| `docs/reference-map.md` | Source mapping and design decisions |
| `docs/architecture.md` | Data flow and boundaries |
| `docs/release-checklist.md` | Work required for TestFlight and public release |
| `scripts/check-contracts.cjs` | Check native/server choice IDs and source-board vocabulary together |

Run `node scripts/check-contracts.cjs` from the project folder to check that the native app and backend use matching selections and that the source board's 54 concepts are retained. This does not compile or test SwiftUI.

Source PDFs remain in the user's Downloads folder. They are not copied into the Git repository.
