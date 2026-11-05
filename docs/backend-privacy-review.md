# Backend and native data-flow review

Reviewed 2026-11-05, then updated after the backend retention and native privacy changes. This is a source-code audit of the prototype, not a deployed-infrastructure audit or an App Store privacy-label determination. Native compilation and runtime behavior still need verification on a Mac/iPad.

## What runs without a server

`ios/project.yml` sets `WISH_API_BASE_URL` to an empty string and `WISH_ONLINE_PREVIEW_ENABLED` to `NO`. The native picture board, selections, system text-to-speech, and locally drawn postcard work without an app-operated service. Online functionality requires both an explicit enabled flag and a valid HTTPS API origin.

`WishStore` keeps the active draft and talking-board phrase in memory. **Remember choices on this iPad** is off by default. If enabled, the app writes only its fixed-choice draft to `UserDefaults`: internal wish category, interest ID, destination ID, coaster color, animal choices, and the optional animals flag. The phrase is not saved or included in an API request, and now clears on finish/reset/inactivity. Narration and remembering preferences are locally persisted even when draft remembering is off. Reset removes the saved draft; the new **Forget choices** action also turns remembering off and removes those preference keys. Device/system backup behavior remains a separate review.

The inspected native code does not request a child's identity, contacts, photograph, microphone recording, health record, account, payment details, advertising ID, or device identifier. No third-party analytics or advertising SDK was found. The app uses `AVSpeechSynthesizer` for speech and contains no custom cloud-speech endpoint; OS-level service behavior is outside this source audit.

## Exact optional request

The native **Grown-ups** area is now behind an ephemeral reading gate. **Refresh this wish's description** first creates a disclosure for the exact selected choices and service host. An adult must confirm that one disclosure before the store calls the service; exit/inactivity revokes authorization and cancels work. No birthdate or identity is collected by the gate, and it is not legal parental-consent verification. With an explicitly enabled/configured service and selected park/color, the request is one JSON POST to `v1/wish-preview`:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe", "tiger"]
}
```

Those are fixed enum choices, not free text. The actual destination, color, and animal array depend on the draft. `categoryId` is always `go`. Neither `interestID`, the talking-board phrase, nor a child identity is sent. The response contains a deterministic choice-derived ID, title, description, SVG image source, and `illustrated-demo` provider label. The native client uses the description and retains the native drawing; it does not upload an image or call a generative-image vendor.

Network transport also exposes connection and request metadata to the service and any hosting infrastructure: the connection address, timing, requested path, HTTP headers, and body size. The exact automatically supplied URLSession headers must be inspected on a real device/build. There is no app-defined user/device identifier or Authorization/API-key header in this client.

## Processing, logging, caching, and retention

| Layer | Observed behavior | Limit or unresolved point |
| --- | --- | --- |
| Native endpoint configuration | Requires an HTTPS origin with no credentials, query, fragment, unresolved build placeholder, or non-root path; empty/disabled by default. Policy/support links may use paths. | Confirm the shipping archive contains the intended operator-controlled public URL; the source validator does not establish ownership or inspect infrastructure. |
| Native network session | Dedicated ephemeral session per request; cookie/cache/credential stores disabled; same-origin HTTPS redirects only. Timeouts and no-store headers are set. | Native tests and instrumented device traffic are still unrun. The OS/network/hosting layers have separate behavior. |
| Request body | Four supported fields only, fixed enum values. Unknown/personal fields are rejected. Maximum body defaults to 2,048 bytes. Malformed JSON and unsupported compression are rejected. | Request buffers exist in process memory while processing and are released through normal garbage collection, not a verified memory-erasure scheme. |
| Wish result | Computed directly from choices and returned. No database, file write, queue, account, or payload request logger is present. | No deployed provider, proxy, crash reporter, or machine-dump configuration has been inspected. |
| Error handling | Returns fixed messages. It does not reflect request text, headers, stack traces, or invalid input. | Operator configuration errors and startup/listening messages are written to stdout/stderr; these do not include wish payloads. |
| Response caching | Every API response sets `Cache-Control: no-store`. The service defines no response cache; native configuration has no URL cache and bypasses local caches. | Ingress settings, upstream vendors, and final device behavior remain unverified. |
| Cookies | The service never sets a cookie; native cookie handling/storage is disabled. | CORS is not authentication or a native-client privacy control. External policy/support websites have their own practices and open only after a separate adult gate. |
| Rate limiter | The in-process `Map` is keyed by `request.socket.remoteAddress` and stores `{ count, resetAt }`. Default window is 60,000 ms; default capacity is 10,000 addresses. It deliberately ignores `X-Forwarded-For`. The targeted fix adds scheduled cleanup every `min(windowMs, 1000)` ms, starting when the server listens. The timer is unref'd, and server close stops it and clears entries. | The IP/address and count are still retained beyond the single request. Under a progressing event loop, removal follows window expiry by at most one cleanup interval: normally about 60–61 seconds from the first request at defaults. Process suspension or an event-loop stall can delay a timer, so this is not a hard wall-clock erasure promise. Hosting retention remains separate and unverified. |
| Docker | Runs the service as nonroot `node`, with no database or payload volume. The health check only calls `/health`; health checks bypass the rate limiter. | Container stdout/stderr collection, reverse-proxy/access logs, TLS ingress, DNS, backups, crash dumps, host monitoring, and retention are operator/provider decisions that remain unverified. |

No App Transport Security exception appears in `Info.plist`. The Node listener itself uses HTTP; a hosted deployment requires an HTTPS ingress before the native client can use it. Docker's `HOST=0.0.0.0` is its internal listen setting, not proof of encrypted transport or restricted external exposure.

## Apple disclosure boundary

Apple distinguishes on-device processing from data transmitted off-device and accessible beyond real-time request handling. Optional functionality does not automatically make disclosure optional; Apple's exception has multiple conditions. Its guidance also specifically addresses retained IP addresses and says the relevant data types depend on their use. See [Apple's App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

Consequently, the offline build and an online-configured build need separate verification. The online service's retained connection-address/count metadata and any infrastructure logs must be included in that review. An empty `NSPrivacyCollectedDataTypes` array in the current privacy manifest is not, by itself, evidence that every possible service configuration qualifies for **Data Not Collected**. This audit does not assign unverified App Store data categories, linkage, tracking status, or purpose answers.

## Minimal concrete follow-up

1. Keep the empty endpoint and complete offline path as the default. Do not add names, free text, photographs, health/eligibility details, accounts, or device identifiers to this service. Keep API keys on a service only if a future provider needs one; no client secret is needed now.
2. **Native hardening implemented:** ephemeral session with no cookie/cache/credential store, same-origin HTTPS redirects, strict API-origin configuration, one-use confirmation, and cancellation when adult access expires. Verify these behaviors with the included native tests and instrumented device traffic before enabling a service.
3. **Backend fix implemented:** idle expired entries now have scheduled removal, and server close disposes the timer and retained metadata. Dedicated tests verify expiry without another request, bounded capacity/immediate disposal, and that the timer cannot keep a process alive. Keep the documented event-loop scheduling caveat and review the retained raw address/count data honestly. A keyed/hash representation could reduce raw-address exposure but would still require a linkability/retention review; do not label it anonymous without evidence. Do not remove abuse controls merely to obtain a desired label.
4. Configure the chosen ingress/provider to avoid payload logging and unnecessary cookies, analytics, persistent identifiers, or request metadata retention. Record the real vendor, logging settings, retention, backups, access, and deletion controls. Where metadata retention is operationally necessary, document it honestly and review disclosure categories with the final use in view.
5. **Native notice/confirmation implemented:** the configured service host, four selected fields, and connection metadata are explained; native policy information is readable without an adult gate, with external links separately gated. The reading check and confirmation do not establish legal guardianship or satisfy every regional consent obligation. Publisher/support/public-policy values are still unset.
6. Validate the final binary, privacy manifest, App Store Connect answers, and publicly accessible privacy policy against the actual configuration. Keep native build/TestFlight verification marked pending until run on macOS/Xcode and a device.

## Evidence inspected

- `ios/WishExplorer/WishAPIClient.swift` and `WishBuildConfiguration.swift`: URL/config validation, encoded request, ephemeral session, redirects, and returned-data limit.
- `ios/WishExplorer/WishStore.swift` and `Models.swift`: local preferences/draft, phrase behavior, explicit remote action.
- `ios/WishExplorer/CaregiverView.swift`: offline/online wording and user action.
- `ios/project.yml`, `Info.plist`, and `PrivacyInfo.xcprivacy`: empty default endpoint, transport settings, manifest declarations.
- `backend/src/server.js`: strict body handling, fixed errors, no-store headers, CORS, raw-address rate map, scheduled expiry, and server-close disposal.
- `backend/test/retention.test.js`: idle-expiry, capacity/disposal, and unref'd-process-lifetime checks for the retention fix.
- `backend/src/main.js`, `preview.js`, `package.json`, and `Dockerfile`: startup logging, deterministic result generation, no third-party packages, nonroot runtime.

The browser design-preview wrapper is not the native app binary. It can load visualization-host/CDN resources and should not be used as evidence that the released iPad app makes no requests.
