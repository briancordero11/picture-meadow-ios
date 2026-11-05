# Wish Explorer preview API

A small, dependency-free Node service for the native app prototype. The complete preview works without storing a wish, opening an account, or sending a child's name, photo, location, or health information. The provider is `illustrated-demo`: it draws a deterministic SVG postcard from fixed choices. It does not call a generative AI service or verify a park's attractions.

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

The service binds only to `http://127.0.0.1:8787` by default. Run `npm test` for API/validation tests and `npm run check` for syntax checks. There are no packages to install. `npm ci` is supported for CI consistency using the included lockfile.

The native app can use an HTTPS deployment URL later. A device cannot reach the computer's loopback address. Use the app's local illustrated postcard for the first demo; do not weaken App Transport Security to make an unencrypted production connection work.

## Contract

`GET /health` returns `{ "status": "ok", "service": "wish-explorer", "version": "0.1.0" }`.

`GET /v1/catalog` returns supported API choices and the earlier five-verb taxonomy plus the `explore` helper. That response is retained for client compatibility; it is **not the current 20-tile home-screen definition**. `explore` / **Help me choose** is navigation, not another official wish category. The current `amusement-park` picture tile enters the existing `go` demo path. Only `go` supports this API's preview. Destination choices are examples of interests and do not establish availability or eligibility. Animal choices express imagination, not a claim that a specific animal lives at a selected park.

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

Requests without an `Origin` header, including native URLSession requests, are allowed. CORS is browser policy, not authentication. No cookies or credentials are needed for these public, fixed-choice endpoints. The API intentionally provides no accounts, database, uploads, or personal-data endpoints.

## Deployment preparation

```powershell
docker build -t wish-explorer-api .
docker run --rm -p 127.0.0.1:8787:8787 wish-explorer-api
```

The image runs as the `node` user and has a health check. Keep a reverse proxy or managed ingress in front of any hosted deployment, terminate HTTPS there, set the intended browser origins, and set request/body/rate limits at ingress. The process handles SIGINT/SIGTERM and closes idle connections. Its local rate limit uses the actual socket address and deliberately ignores `X-Forwarded-For`; behind a proxy, callers may share one bucket. Configure trusted proxy-aware limits at ingress before public use. In-memory limits reset on restart and do not coordinate across replicas.

No wish payloads are written to disk or application request logs. The limiter retains connection addresses and counts only in process memory until expiry. A hosting provider/reverse proxy can log addresses, paths, and headers independently: configure retention and redact logs before a real pilot. Health checks do not consume rate limits. Public usage still needs ingress abuse protection, monitoring, dependency/image updates, organizational approval, accessibility testing with users, a privacy review, and an operational owner. Nothing here is a booking, medical, eligibility, or Make-A-Wish submission service.

The supplied Make-A-Wish guides inform the prototype. Source picture artwork may be reused in the current local prototype at the user's direction. This API still draws its own SVG postcard and does not serve the original PDFs or a source-art asset endpoint. The prototype is not affiliated with, approved by, or a fulfillment promise from Make-A-Wish.
