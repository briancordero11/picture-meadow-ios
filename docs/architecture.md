# Architecture

## Native app

SwiftUI renders the child journey and communication board. The app draws an original wish postcard on device and uses system text-to-speech for selected words. Only non-identifying wish selections are stored in the local draft; reset clears those selections. There are no user accounts, medical intake fields, advertising identifiers, analytics SDKs, camera uploads, or remote child profiles in the starter.

“Local” does not mean encrypted or excluded from every device backup. Draft retention and shared-device behavior must be validated before real family use. Communication transcripts should remain transient.

## Optional service

The app can request an illustrated preview description from a configured HTTPS backend. The request contains only catalog enum IDs:

```json
{
  "categoryId": "go",
  "destinationId": "six-flags-great-america",
  "coasterColor": "blue",
  "animalIds": ["giraffe"]
}
```

The backend returns a title, description, SVG illustration, ID, and `illustrated-demo` provider label. The native app draws its own postcard instead of trying to render untrusted SVG markup. Requests and responses are transient; the service has no database and does not persist wish payloads.

The API accepts only known fields and allowed values. Body-size limits and per-process rate limits bound routine resource use. CORS is an explicit browser-origin allowlist; it is not authentication. Infrastructure access logs may still record transport metadata, so production hosting requires a separate logging and retention review.

## Deployment boundary

The container is a deployment artifact, not a deployed service. A production host must provide HTTPS, request deadlines, resource limits, process health monitoring, and rate limiting appropriate to the number of instances. No secrets belong in the iPad bundle. Do not expose provider credentials or rely on a client-shipped token for authentication.

No AI image vendor is connected. The deterministic illustration path keeps development usable offline and avoids sending child information to an external image provider. A future provider should receive an approved, non-identifying scene prompt generated from catalog selections, through the server only, with a clear caregiver-controlled workflow.

## Verification boundary

Server tests can run on Windows. SwiftUI and Apple signing require the Apple toolchain. CI is supplied as a future verification route once the local repository is connected to a private remote; a workflow file is not evidence that CI has run.
