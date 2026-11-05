# Reference map

The six supplied files contain four unique documents. The duplicate guide and board copies have identical SHA-256 hashes. Full local extraction and rendering evidence is kept in ignored `work/reference-review/`; the repository records only the inventory and product decisions.

| Source | Evidence used | Product decision |
| --- | --- | --- |
| `WishImages.pdf`, pp. 1-2 | Same 9-column, 6-row board on both pages, with a different surround | Preserve 54 concepts across 20 illustrated topic tiles and 34 core drawer choices |
| `Super Star-Wish Guide (1).pdf`, pp. 2-3 | Relaxed exploration, family/team participation, multiple ideas, four broad interest groups | No time pressure or forced single “correct” wish; caregiver-supported exploration |
| `Super Star-Wish Guide (1).pdf`, pp. 4-8 | Sensory, movement, communication, and learning examples | Reference for future paths rather than forcing a diagnostic quiz |
| `WishIntakeform(1).pdf`, pp. 1-2 | Preferences mixed with identity and contact fields | Prototype uses fixed, non-identifying preference choices; no child identity form |
| `WishIntakeform(1).pdf`, pp. 3-5 | Multiple wish ideas, why they matter, an imagined experience; at least one local idea | Include a local park example; multiple saved ideas are a future extension |
| `WishIntakeform(1).pdf`, p. 6 | Adult provider and volunteer follow-up | Keep this outside the child's experience and outside the starter API |
| `WVC Guidance_Wish Types and Subtypes_Last Updated 2.22.2023.pdf`, pp. 1-4 | 26 adult operational classifications | Do not turn the internal classification table into 26 child-facing tiles |

The dated operational guide is evidence of the supplied 2023 workflow, not a statement of current policy. Example parks and imagined animals do not imply approval, current attractions, accessibility, or travel availability.

## Archived six-panel concept

The first prototype used the five broad wish verbs (go, have, meet, be, give) and a sixth “Help me choose” navigation tile. The user replaced that screen with illustrated topic components matching their screenshot. Preserve the previous six-panel idea and screenshot under `backend/docs/`; it is not the active child-facing screen. The backend's older wish taxonomy remains an API detail rather than the current home-screen layout.

Public context checked November 5, 2026:

- [Official wish discovery examples](https://wish.org/ncc/get-ready-discover-your-wish) show the five broad verbs.
- [Official family FAQ](https://wish.org/newyork/frequently-asked-questions) describes discovery with volunteers and subsequent staff/medical review. It is chapter-specific context, not a replacement for the Illinois process.
- The user's `https://wish.org/illinois-31` URL was inaccessible during the review. [The Illinois chapter home](https://wish.org/illinois) was accessible. No automated intake integration is claimed.

## Communication vocabulary

The canonical source order is stored in `communication-board.json`. Source wording is retained, including short fragments and phrases. App controls may use sentence capitalization, while remaining consistent in meaning and order. Stable source order supports follow-up AAC review; it is not a claim that replacing a child's established AAC system is appropriate.

The revised prototype reuses the supplied pictograms at the user's request. Original image objects are extracted unchanged and displayed through reusable picture components; source PDFs are not embedded. The working app mark remains original. Asset provenance and display rectangles are recorded in `assets/`.
