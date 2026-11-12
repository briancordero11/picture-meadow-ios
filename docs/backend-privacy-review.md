# Backend and native data-flow review

Reviewed November 11, 2026 against current source. This engineering audit describes the offline app, legacy description endpoint, direct OpenAI image endpoint, and current settings update. Actual hosting logs, provider account controls, and App Store privacy answers remain to be verified for the shipping configuration.

The latest verified native baseline is commit c54f7a3, with 70 unit tests and two UI tests passing on an iPad mini (A17 Pro) simulator with iOS 26.5. Physical-device review remains pending. [Baseline CI evidence](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43163020697).

## Local processing and retention

The default app has an empty API origin and both online flags disabled in ios/project.yml. All twenty picture journeys, the communication board, system speech, and local picture composition work without the operator's service. The yellow favorites-intake card appears above the topics. Save favorites returns to the topics with the current preferences, including across topic changes. It does not enable disk retention. Preferences persist across launches only when a grown-up has enabled Remember choices.

| Item | Actual storage and lifetime | User control or limit |
| --- | --- | --- |
| Active choices | WishDraft in memory, including topic, actions, setting, favorites, essential choice, and compatible older park fields. | Changing interest resets unrelated choices. Finish returns home and retains the current wish. |
| Saved draft | UserDefaults only when Remember choices is enabled, which defaults to off. | Turning remembering off removes the saved copy. Start a fresh wish clears the current/saved draft but preserves the remembering preference. Backups can include app settings. |
| Narration, voice style, and remembering preferences | UserDefaults independently of draft opt-in. The voice preset is Boy, Girl, Man, or Woman; no voice recording is stored. | Forget removes their keys and restores defaults. Starting a new wish preserves these preferences. |
| Talking-board sentence | Memory only. | Cleared on Finish, reset, and scene inactivity. Excluded from service requests. |
| Adult challenge and request permission | View/store memory only. | One-use confirmation, exact-draft binding, and revocation on adult-session exit or inactivity. |
| Pending AI picture | Image Data and review metadata in memory. | Requires adult approval before display with the wish. Adult-session exit clears pending review. |
| Approved AI picture and description | Memory only. No Photos export, gallery, image file, or UserDefaults image storage. | Can survive Finish/backgrounding in the current process. Discard, changed choices, reset, Forget, or process termination clears it. |
| Service access code | Persistent Keychain item using WhenUnlockedThisDeviceOnly. | Accessible while unlocked, with no synchronization requested. Remove AI service access and Forget remove it. Reset or disabling draft remembering does not. |
| Provider API key | Server environment only. | Never bundled in the app or included in its JSON body. |

The journey has no child identity, contact, medical-record, photograph, account-creation, or audio-recording fields. No advertising or analytics SDK is present. AVSpeechSynthesizer supplies system speech using available Apple English voices, ranked by requested gender, quality, and locale. Custom-provider, personal, and novelty voices are excluded using an Apple identifier compatibility allowlist and voice traits. Boy/Girl slightly increase an adult base voice's pitch. A fixed preview requires adult access; selection does not autoplay. There is no custom speech-upload endpoint, microphone capture, or app-requested voice download. Separate OS voice downloads/service behavior are outside this source audit.

## Grown-up controls and support correspondence

Privacy & Data, the privacy notice, and AI controls are accessible only inside grown-up Settings after the four-digit reading check. There is no privacy shortcut on the main header, pause screen, or code-entry screen. External links use grown-up controls. The reading task verifies no age, identity, guardianship, or legal consent.

Report AI Concern offers five fixed categories, including a privacy concern. With a validated support email and active adult session, it prepares a system mail draft containing the concern and app version/build. It attaches no picture, chosen wish, sentence, access code, or child information. The grown-up controls sending and added details in their mail app. There is no report endpoint, account record, report database, or automatic submission.

Sent mail can disclose the sender/reply address and voluntary details to the publisher/email provider. App-information help/privacy drafts have the same boundary. The completed policy needs the support purpose, retention, access, deletion, and response procedures. No real support address is configured, so monitored reporting remains a release gap.

## Legacy optional description request

The legacy client requires enabled configuration, adult access, and an exact-choice confirmation. POST /v1/wish-preview contains four fields:

~~~json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe", "tiger"]
}
~~~

It returns a deterministic choice-derived ID, title, description, SVG source, and illustrated-demo label. The native client uses the description with its local drawing. This client sends no bearer service code, and this route makes no AI-provider call.

## Optional direct AI image request

POST /v1/wish-scene uses a five-field contract:

~~~json
{
  "interestId": "art",
  "actionIds": ["art-paint"],
  "settingId": "art-art-studio",
  "favoriteIds": ["favorite-color-blue"],
  "essentialChoiceId": "art-paint"
}
~~~

The bearer service code is an Authorization header to the operator backend. Actions must belong to the topic, with a maximum of three. Favorites have a maximum of ten. Setting and essential choice can be null. The essential must already be selected. Validation rejects unknown fields, free text, duplicates, mixed-topic actions/settings, and unsupported IDs before calling the provider.

The backend composes a prompt from catalog descriptions and calls the fixed OpenAI Images API directly using its server key. It uploads no pictogram bytes, PDF/intake document, photo, board sentence, or identity/medical field. There is no AI routing intermediary. The result contains base64 JPEG data, a random scene ID, catalog-authored title/description, and the OpenAI (direct) label. [OpenAI Images API](https://developers.openai.com/api/reference/resources/images/methods/generate).

The app requires one confirmation and adult output review. Changing choices, canceling, ending the adult session, or inactivity revokes pending permission. Cancellation and stale-result checks prevent late output being applied. They cannot recall remote processing already performed.

## Transport, server memory, and logs

| Layer | Source behavior | Unverified boundary |
| --- | --- | --- |
| Native sessions | Ephemeral URLSession with no cookie/cache/credential stores, no-store headers, and strict HTTPS origin. Legacy redirects stay on the same HTTPS host/port. Image requests reject redirects. | Inspect final archive/device traffic and OS behavior separately. |
| Requests | Default 2,048-byte body cap, strict UTF-8 JSON, fixed routes, no query or compressed bodies. | Request/header buffers exist in memory. Garbage collection does not establish secure erasure. |
| Prompt and images | Memory buffers. Provider stream capped at 4,000,000 bytes, image bytes at 2.8 MiB. Native checks type, size, and dimensions. | Limits do not configure provider retention. |
| Persistence | No wish DB, image bucket, payload logger, file writes, queue, or server history. Reads the bundled catalog. | Independent hosting logs, security records, backups, crash dumps, and monitoring require review. |
| Application logs | Startup/listening and fixed configuration/listen errors. Request errors omit input, headers, stacks, tokens, prompts, and provider bodies. | Verify deployed observability. No hosting plan, log policy, or retention period is established here. |
| Address limiter | Socket address maps to count/resetAt. Defaults to 60 seconds, 10,000 entries, and cleanup every second while the event loop progresses. Ignores forwarded address headers. | The address may be a proxy. Expiry normally takes about 60–61 seconds from the first window request. Suspension/stalls can delay it. Process disposal clears entries. |
| Scene limits | Separate constant-key bucket permits three authenticated calls per minute per process, plus two simultaneous jobs by default. | Memory-only counters. No persistent user identifier, distributed coordination, or financial cap. |
| Caching | API responses set no-store. Direct provider fetch disables cache, cookies, redirects, and automatic retries. | Does not erase host logs or alter upstream policy. |

The Node listener uses HTTP internally. A native deployment needs HTTPS ingress. Vercel is the configured backend hosting route, but actual account/plan, locations, logging, retention, and deletion procedures remain unverified. Docker defines no DB/payload volume. Neither configuration proves external infrastructure practices.

## OpenAI account and audience controls

OpenAI documents default abuse-monitoring retention of prompts and outputs for up to 30 days, with longer retention when required by law or reasonably necessary to protect its services or others from harm. Approved Zero Data Retention depends on actual organization/project configuration. No such approval or configuration is established for this deployment. [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data).

The sample environment defaults generation/review to false. Activation requires explicit flags, service access code, allowed model, and a server-only provider key. SCENE_PROVIDER_REVIEWED is operator attestation. It cannot configure or verify ZDR. Model eligibility does not establish account enrollment. Credentials, controls, credits, and an approved live generation remain separate evidence.

OpenAI's under-18 guidance addresses additional safeguards and ZDR before processing personal data of children under 13 or the applicable digital-consent age. Assess the actual data/audience without assuming fixed IDs or a reading gate settle the issue. [OpenAI under-18 guidance](https://developers.openai.com/api/docs/guides/safety-checks/under-18-api-guidance#regulatory-standards).

## Disclosure and remaining evidence

App Privacy answers need the final app, operator, host, provider, and support practices. Retained technical metadata and provider handling need review even with no wish DB. The empty collected-data array is an offline baseline, not a determination that an activated service qualifies as Data Not Collected. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

There are no user accounts. Local Forget and a configured privacy-email draft do not submit remote erasure requests. Release needs actual publisher identity, public policy/support URLs, monitored contact/response process, hosting/provider retention, audience/category decisions, and final manifest/App Store Connect review. Physical-iPad, accessibility, network, and new-settings verification remain outstanding.

Recheck WishStore/Models, SceneAccessKeychain, both clients, the privacy/settings/report views, project/manifest files, backend server/scene/preview sources, deployment entrypoints, and tests when changing this flow. The browser preview and static website have independent hosting practices and do not establish the native binary's traffic.
