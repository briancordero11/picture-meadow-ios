# Image provider review

Reviewed November 11, 2026 against public primary sources. This records the implementation choice and unresolved release evidence; it does not establish account-specific permission or App Store approval. Online generation stays disabled by default.

## Why the default is direct OpenAI

Vercel hosting and Vercel AI Gateway are separate choices. The backend can remain hosted on Vercel while calling OpenAI directly. For this single image-generation feature, the selected design avoids an additional AI routing intermediary and keeps one fixed model, endpoint, and provider disclosure. This is an architectural judgment, not a claim that a router is inherently unsuitable.

OpenAI publishes guidance for applications serving minors, with additional age-appropriate safeguards and ZDR before processing under-13 personal data. That is more directly applicable to this app than assuming an adult button makes a child-directed product eligible. [OpenAI under-18 guidance](https://developers.openai.com/api/docs/guides/safety-checks/under-18-api-guidance).

The allowlist uses `gpt-image-2.5-flare` and its dated snapshot because the current data-controls page explicitly lists their image-generation ZDR eligibility. Actual ZDR requires prior approval and enabled organization/project settings. `SCENE_PROVIDER_REVIEWED=true` only records operator review; it cannot enable ZDR. Newer 2.6 models exist, but their ZDR eligibility was not established by the reviewed page. [OpenAI data controls](https://developers.openai.com/api/docs/guides/your-data), [current image models](https://developers.openai.com/api/docs/models).

## Google Vertex restriction

Google Cloud's current Service Specific Terms section 20(d) restricts generative AI use within applications directed toward, or likely accessed by, people under 18. No exception for an adult-operated control was identified in that provision. This finding concerns Google Cloud/Vertex, rather than borrowing AI Studio's terms. The services summary expressly includes the generative API formerly named Vertex AI. [Cloud Service Specific Terms](https://cloud.google.com/terms/service-terms), [Cloud services summary](https://cloud.google.com/terms/services).

Vercel's AI Product Terms section 8 requires compliance with applicable upstream terms. Its Notices and License Information separately links **Google Vertex AI** to those Cloud Service Specific Terms. The former Vertex adapter was therefore removed from the default runtime; adult gating and data-retention controls did not resolve this audience restriction. [Vercel AI Product Terms](https://vercel.com/legal/ai-product-terms), [provider notices](https://vercel.com/legal/notices-and-license-information).

## OpenRouter remains an optional future integration

OpenRouter supports image generation and provider pinning. Its terms require service users to be 18 and preserve upstream model terms. The reviewed documents do not establish this app's eligibility merely because the account owner is an adult. [OpenRouter image API](https://openrouter.ai/docs/guides/overview/multimodal/image-generation), [OpenRouter terms](https://openrouter.ai/terms).

Its current `provider.zdr: true` follows account/guardrail settings: self-service defaults may also allow **Safety Retention**, which permits abuse-related retention and is distinct from strict ZDR. Strict use needs the separate **ZDR only** setting and endpoint verification. The reviewed OpenAI image endpoint listed first-party OpenAI; the ZDR guide says OpenAI-group enforcement excludes that provider unless an independently qualified route/key is available. No qualifying OpenRouter route was verified for this deployment. [OpenRouter ZDR controls](https://openrouter.ai/docs/guides/features/zdr).

## Evidence still required before activation

The operator must establish actual provider/account eligibility and retention settings, securely configure a server key, set enforceable spending controls, verify one live generation and cancellation, and finish the app's privacy/audience review. Controlled catalog choices, per-request grown-up permission, output review, and offline operation remain part of the design. No provider account, key, billing agreement, or ZDR approval was created by this implementation.
