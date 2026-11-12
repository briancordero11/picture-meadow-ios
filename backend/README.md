# Wish Explorer preview and image API

A stateless Node service with two separate routes: the existing deterministic SVG preview and optional authenticated AI scene generation. Neither route stores wishes or images, opens an account, or accepts a child's name, photo, precise location, or health information. Connection metadata, including an IP address, is temporarily retained for rate limiting; hosting and AI services have their own processing and retention settings described below.

The new action-led journey supports all 20 interests. Picture choices represent concepts: the app sends their catalog IDs, and the server combines the corresponding reviewed descriptions into one scene prompt. This is not pixel blending or an upload of the original pictograms. Source guides/PDFs, typed communication-board phrases, names, private notes, and the device photo library are never sent to this endpoint.

The current child-facing design starts with **20 picture tiles for interests** and a centered bottom drawer containing **34 core communication concepts**. The earlier six-panel verb menu is archived documentation, not the current home screen. See [UX components and design history](docs/ux-components.md) for the picture-tile layout, drawer behavior, reusable components, and archived screenshot. There is no separate “My voice” quick toolbar or duplicate category menu in the revised design.

## Archived six-panel idea

The original six-panel concept is retained here as design history. The current app uses the illustrated picture board documented above.

![Archived six-panel concept](docs/six-panel-concept.png)

The revised picture board and its open drawer:

![Current picture board concept with centered drawer tab](docs/picture-board-home.png)

![Current core communication drawer concept](docs/picture-board-open.png)

These screenshots show the interactive browser concept. They do not represent a verified native iPad build.

## Run locally

Requires Node 22 or newer. From this folder:

```powershell
npm start
```

The service uses Node's built-in APIs and has no external runtime dependencies. `npm ci` verifies the lockfile for CI/deployment. The service binds only to `http://127.0.0.1:8787` by default. Run `npm test` for API/validation tests and `npm run check` for syntax checks. From a repository checkout, `npm run catalog:check` verifies the deployable catalog mirror; after editing shared `assets/journey-catalog.json`, run `npm run catalog:sync`.

## Optional combined AI scene

`GET /v1/scene-capabilities` returns nonsecret availability information. `enabled: false` and `mode: "offline-only"` mean the app should retain its local picture collage. A successful health check does not establish that generation, billing, or data handling has been verified.

`POST /v1/wish-scene` requires `Content-Type: application/json`, `Authorization: Bearer <grown-up access code>`, and exactly these five fields:

```json
{
  "interestId": "camp",
  "actionIds": ["camp-explore", "camp-stars"],
  "settingId": "camp-yosemite",
  "favoriteIds": [],
  "essentialChoiceId": "camp-stars"
}
```

Use IDs from the shared journey catalog. Actions must belong to the selected topic (maximum three); setting is one of that topic's settings or `null`. Favorites are up to ten distinct supported IDs. `essentialChoiceId` must identify an already-selected action, setting, or favorite, or be `null`. Unknown fields, free text, mixed-topic choices, duplicates, and unselected essentials are rejected before an AI call. All choices may be skipped; the selected topic still supplies the scene idea.

Success has the same five outer keys as the legacy response: `id`, `title`, `description`, `image`, and `provider`. The direct provider returns `image.mimeType: "image/jpeg"` and **`image.data` is base64 raster data**, unlike the legacy route's SVG source. Provider is `OpenAI (direct)`. The title and description are assembled from the reviewed catalog, not arbitrary AI text. Each result has a fresh random ID unrelated to a user. Images are limited to 2.8 MiB before base64 encoding, keeping the response below Vercel's 4.5 MB body limit. Images are held only while returning the response; there is no image URL, storage bucket, database, or server history.

The adapter calls the fixed official `https://api.openai.com/v1/images/generations` endpoint with Node `fetch`. It allows `gpt-image-2.5-flare` and its `2026-09-08` snapshot, explicitly requests one 1536×1024 JPEG at medium quality/compression 80, and keeps moderation at `auto`. Redirects and automatic retries are disabled. The response stream is capped at 4,000,000 bytes before decoding and image bytes are checked separately. The provider's documented `moderation_blocked` refusal becomes a generic actionable message. Prompts describe one child-appropriate illustrated scene without identifiable people, brands, sponsor commitments, or unsafe behavior. There is no router, arbitrary provider URL, or client-side provider key.

Generation is **off by default**. To activate, an operator must supply all of:

- `SCENE_GENERATION_ENABLED=true`.
- `SCENE_PROVIDER_REVIEWED=true`, recording the operator's review of the intended audience, provider terms, actual account/project data controls, and privacy disclosures. This is an attestation, **not** a technical control that enables Zero Data Retention.
- `SCENE_ACCESS_TOKEN`, a securely generated 32–256 character non-whitespace ASCII access code (the server and app enforce 32–256 UTF-8 bytes). Configure it as a sensitive server variable and enter it through grown-up app Settings; never embed it in source or the app bundle. This access code protects one service, not an individual child account. Replace it if disclosed.
- `OPENAI_IMAGE_MODEL=gpt-image-2.5-flare` (or the allowlisted dated snapshot).
- Server-only `OPENAI_API_KEY`, including when hosted on Vercel. Store it as a sensitive hosting variable, never in the app, repository, request body, logs, or chat. The app receives no provider credential.

Before activation, verify provider access, actual credentials and credits, enforceable account/project spending limits, and live generation. OpenAI documents image-generation ZDR eligibility for these selected models, but ZDR requires separate approval and enabled account/project settings. No environment flag or request parameter here can grant that approval. Its under-18 guidance calls for added safeguards and requires ZDR before processing personal data of children under 13 or the applicable digital-consent age. Keep generation disabled until the operator has verified the actual data flow and required controls. This repository does not purchase credits, configure billing/ZDR, or include a working key. See [provider review notes](../docs/provider-review-notes.md).

The native app must show the exact selected concepts and provider to a grown-up and obtain permission for **each** call. Closing that flow, editing selections, leaving the app, or cancelling invalidates it. The direct provider has a 90-second deadline; the service aborts work on client disconnect or its 95-second outer deadline and discards late results. An in-process generation bucket permits three authorized requests per minute, with at most two simultaneous jobs. These limits reset on restart and do not coordinate between replicas: configure ingress limits and a provider spending limit before public activation. They are not a financial spending cap.

Controlled errors include `unauthorized` (401), `invalid_choices` (400), `generation_busy` (429), `generation_refused` (422), `generation_unavailable` (503), `generation_timeout` (504), and `generation_failed`/`image_too_large` (502). Provider authentication failure maps to `generation_not_authorized`, missing credits/allowance to `generation_budget_unavailable`, and provider access refusal to `generation_access_denied`; these three return 503 with fixed operator guidance. Errors never return provider exceptions, tokens, prompts, response bodies, or model text. A retry must be a new explicit grown-up action, not an automatic background request.

For Vercel use **`backend` as the project root**, Framework `Other`, and the included `vercel.json`. It installs with `npm ci`, bundles the catalog mirror, and rewrites `/health` and `/v1/*` to one Node function with cancellation support and a 120-second maximum. After deploying, verify the actual rewritten paths, disabled capabilities, unauthorized requests, approved generation, cancellation, and logging/budget configuration. No live image call is part of automated tests.

Privacy and release review must include the app → operator backend (Vercel when deployed there) → OpenAI data flow, connection metadata, host logging, provider/account controls, grown-up permission, output review, and subsequent sharing. Hosting on Vercel does not require Vercel AI Gateway. The local collage remains usable when online generation is unavailable or refused. Neither a successful API call nor an operator attestation establishes legal eligibility or App Store approval.

Official references: [OpenAI Images API](https://developers.openai.com/api/reference/resources/images/methods/generate), [image generation](https://developers.openai.com/api/docs/guides/image-generation), [data controls](https://developers.openai.com/api/docs/guides/your-data), [under-18 guidance](https://developers.openai.com/api/docs/guides/safety-checks/under-18-api-guidance), and [Vercel function limits](https://vercel.com/docs/functions/limitations).

The native app can use an HTTPS deployment URL later. A device cannot reach the computer's loopback address. Use the app's local illustrated postcard for the first demo; do not weaken App Transport Security to make an unencrypted production connection work.

## Contract

`GET /health` returns `{ "status": "ok", "service": "wish-explorer", "version": "0.1.0" }`.

`GET /v1/catalog` returns supported choices for the legacy SVG preview API and its earlier five-verb taxonomy plus the `explore` helper. That response is retained for client compatibility; it is **not the current 20-tile home-screen or action-journey definition**. `explore` / **Help me choose** is navigation, not another official wish category. Only `go` supports the legacy `/v1/wish-preview` endpoint. The new `/v1/wish-scene` uses the separate shared journey catalog and supports all 20 interests. Legacy destination choices do not establish availability or eligibility. Animal choices express imagination, not a claim that a specific animal lives at a selected park.

`POST /v1/wish-preview` requires `Content-Type: application/json` and exactly these four fields:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe", "tiger"]
}
```

- `destinationId`: `six-flags-great-america`, `disney-world`, `universal-orlando`
- `coasterColor`: `blue`, `pink`, `purple`, `green`
- `animalIds`: zero to three distinct choices from `giraffe`, `dolphin`, `tiger`

The response is:

```json
{
  "id": "wish_<stable hash>",
  "title": "My wish: Six Flags Great America",
  "description": "I wish to go to ...",
  "image": { "mimeType": "image/svg+xml", "data": "<svg ...>...</svg>" },
  "provider": "illustrated-demo"
}
```

`image.data` contains SVG source, not a URL or base64 string. iOS does not natively load SVG into `Image`; keep the SwiftUI postcard, or add a reviewed rendering/export path later. Use the returned description for the optional API integration. The ID depends on the choices, not a user identity. Unknown fields are rejected. Do not add free text, identifiers, photos, or health fields without redesigning consent, retention, and access controls.

Errors use `{ "error": { "code": "...", "message": "..." } }`. Invalid choices or JSON return 400; oversized payloads 413; unsupported types/encodings 415; disallowed browser origins 403; excess requests 429 with `Retry-After`; incorrect methods 405. There is no query-string API.

## Configuration

Settings are environment variables; `.env` files are not read automatically. `.env.example` documents all names.

| Setting | Default | Purpose |
| --- | --- | --- |
| `HOST` | `127.0.0.1` | Interface to listen on; Docker sets `0.0.0.0` inside its container |
| `PORT` | `8787` | Listening port |
| `CORS_ALLOWED_ORIGINS` | empty | Comma-separated exact browser origins, no wildcard or trailing slash |
| `MAX_BODY_BYTES` | `2048` | Request-body limit, 128 to 65536 |
| `RATE_LIMIT_MAX` | `60` | Requests per connection address per window |
| `RATE_LIMIT_WINDOW_MS` | `60000` | Window length in milliseconds |
| `RATE_LIMIT_MAX_CLIENTS` | `10000` | Bound on temporary rate-limit entries |

Requests without an `Origin` header, including native URLSession requests, pass the origin check. CORS is browser policy, not authentication. Health, catalog, capabilities, and the legacy fixed-choice SVG preview are public; `/v1/wish-scene` separately requires the grown-up's bearer access code. No cookies are used. The API intentionally provides no accounts, database, uploads, or personal-data endpoints.

## Deployment preparation

```powershell
docker build -t wish-explorer-api .
docker run --rm -p 127.0.0.1:8787:8787 wish-explorer-api
```

The image runs as the `node` user and has a health check. Keep a reverse proxy or managed ingress in front of any hosted deployment, terminate HTTPS there, set the intended browser origins, and set request/body/rate limits at ingress. The process handles SIGINT/SIGTERM and closes idle connections. Its local rate limit uses the actual socket address and deliberately ignores `X-Forwarded-For`; behind a proxy, callers may share one bucket. Configure trusted proxy-aware limits at ingress before public use. In-memory limits reset on restart and do not coordinate across replicas.

No wish payloads are written to disk or application request logs. The limiter temporarily retains raw connection addresses, request counts, and reset times in process memory. Each entry's window starts on its first request; the default is 60 seconds. Scheduled cleanup runs every `min(RATE_LIMIT_WINDOW_MS, 1000)` milliseconds, even while the service is idle. In normal operation an expired entry is removed within one cleanup interval (at the default, about 60–61 seconds after its first request). Timer execution depends on the Node event loop, so a stalled/suspended process can delay deletion; this is not a hard wall-clock erasure guarantee. Closing the server stops the timer and clears all entries. The timer is unref'd so it cannot keep an otherwise idle Node process running.

This metadata exists beyond the individual request: the online configuration must not be described as “no data collected” solely because it has no database. A hosting provider/reverse proxy can also log addresses, paths, and headers independently. Verify its retention and logging settings, update the user-facing privacy notice, and review the actual deployed data flow before completing App Store privacy answers. Health checks do not consume rate limits. Public usage still needs ingress abuse protection, monitoring, dependency/image updates, organizational approval, accessibility testing with users, a privacy review, and an operational owner. Nothing here is a booking, medical, eligibility, or Make-A-Wish submission service.

The supplied Make-A-Wish guides inform the prototype. Source picture artwork may be reused in the current local prototype at the user's direction. The legacy API draws its own SVG postcard; the optional AI route sends only reviewed concept descriptions to its provider. Neither serves or uploads the original PDFs or source-art image files. The prototype is not affiliated with, approved by, or a fulfillment promise from Make-A-Wish.
