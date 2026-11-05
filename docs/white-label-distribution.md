# White-label distribution plan

Reviewed November 5, 2026 using primary Apple sources. The user confirmed a **US product published by a separate, independent LLC, not CanaClaw**. The LLC's exact legal name is unspecified; there is no public business email or published privacy-policy URL yet. The intended audience is exactly **"2 - 17+"**, with no inferred upper age cap. That span crosses Kids Category bands and extends to older users; category/content-rating decisions require deliberate review. Final brand also remains pending. This plan is an engineering recommendation, not Apple approval or a legal determination. No additional app records, Bundle IDs, or publications have been created.

## Initial recommendation

Build **one app published by the user's independent LLC**, with configuration for organization name, approved artwork, colors, support details, and permitted wish content. Keep one product identity and one maintained codebase. If multiple organizations are later represented, use clearly identified organization profiles within that product rather than automatically producing a public app clone for each customer. This recommendation is an inference from the constraints below.

| Route | Practical constraint | Decision for this project |
| --- | --- | --- |
| One public, configurable business app | Apple 4.2.6 permits a single binary that aggregates client content through an organization/content picker. | Recommended initial route. Configuration changes presentation/content, while the publisher remains clear. |
| Separate public apps for clients | For commercial-template products, 4.2.6 requires submission directly by the content provider; 4.3 discourages the same app under multiple Bundle IDs and indistinguishable variants. | Later only when a client's distinct product/content and publishing responsibility justify it; avoid a vendor-operated clone factory. |

Source for these constraints: [App Review Guidelines 4.2.6 and 4.3](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality). Reusing a codebase does not itself establish that a particular submission will qualify.

## Later B2B option: Custom Apps

Custom Apps can be tailored for named organizations, with organization-specific appearance and workflows. The developer selects eligible Organization IDs in App Store Connect; those organizations obtain the app through Apple Business or Apple School Manager and distribute it using MDM or redemption codes. Apple still reviews the app. [Apple: Distributing Apps on Apple Business and Apple School Manager, “Making a custom app available only to specific organizations”](https://developer.apple.com/support/volume-purchase-and-custom-apps/)

Use this route later for an organization-managed deployment, such as a contracted organization equipping its own iPads. Collect the customer's Organization ID and establish who operates the service, supplies content, supports users, and owns the relevant branding rights. Custom distribution is not evidence of an exemption from template, privacy, or child-safety review.

Public distribution reaches consumers in selected storefronts; private distribution targets specified organizations. After approval, switching public to private or private to public requires a new app record and resubmission. Decide before submitting the corresponding release. [App Store Connect: Set distribution methods](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/set-distribution-methods/)

## Configuration and release boundaries

The current native app supports per-build publisher name, support email, policy/support URLs, and optional API settings. Its display name, blue wordmark, icon, and prototype Bundle ID are still fixed. Customer-specific branding, organization profiles, and separate client products are future work; this plan does not claim that a complete white-label system already exists.

The release record preserves the audience as `statedAgeRange: "2–17+"`, `minimumAge: 2`, `maximumAge: null`. The null upper bound is an explicit open-ended range; it does not select a Kids Category band or imply an age cap.

- Keep publisher identity separate from a customer's displayed brand. Do not silently replace the accountable operator with an organization profile.
- Keep the child's communication experience independent of branding. Customer configuration must not remove privacy controls, the adult gate, offline access, or essential communication words.
- Treat configured support/privacy endpoints and artwork as reviewed release inputs. Do not populate them with invented business details or imply an official Make-A-Wish affiliation.
- Preserve the first US release as a single-business product. Additional customers, custom distribution, monetization, and separate client products require their own concrete distribution decisions.

Publisher identity, privacy/data handling, artwork rights, child audience, regional age assurance, and native release validation remain tracked in the project's release review. A US-only storefront choice does not by itself settle every applicable US state requirement.
