# First version

## Purpose

Give a child who does not rely on speech a calm, visual way to explore a wish with a parent, nurse, caregiver, or wish volunteer. Support the child's communication and preferences; do not infer consent or eligibility from tapping a tile.

## Initial journey

1. A welcoming star introduces the experience.
2. “Create your wish” shows the 20 childlike illustrated topic tiles from the user's reference, in its original row order. Labels sit above the pictures on peach tiles with dark dividers. The earlier six-verb concept is retained only as documented design history in `backend/docs/`.
3. The first detailed path explores an amusement park. Example destinations are Six Flags Great America, Walt Disney World, and Universal Orlando. These are example interests, not current travel or availability recommendations.
4. The child can choose a rollercoaster color and optional animals, change their mind, skip optional personalization, or pause.
5. A wish postcard illustrates the choices and gives a caregiver a starting point for a conversation. It does not submit a wish application.

## Communication board

Preserve all 54 labels across two surfaces: 20 topic tiles in the main screen and 34 core communication choices in the drawer. Reuse the supplied pictograms as requested, with a reusable picture component. The drawer contains pronouns, actions, feelings, questions, and agency phrases; it does not duplicate the sports, school, or other topic tiles. Offer tap-to-speak and a phrase area, with clear and speak actions.

The communication drawer is collapsed by default, with only a small centered grab tab visible at the bottom. Tapping the tab or dragging it up/down opens or closes the drawer; dragging is optional. Remove the previous “My voice” section and the permanent quick-action row. No, stop, think, break, and finished remain inside the core drawer as pictured choices. Do not require speech, timed completion, color recognition alone, or a long sentence before allowing progress. A child's “no” or request to stop should not silently become a wish selection.

## Caregiver experience

Keep configuration and reset controls away from the main child choices. Explain that this is a local exploration, and that actual wish discovery, application, approvals, and travel planning take place with the responsible organization. The prototype does not collect the medical, contact, identity, or family information found in the intake document.

## Completion criteria for this starter

- Native iPad code and a reproducible Xcode project specification exist.
- One coherent amusement-park journey reaches an illustrated result.
- Communication choices remain reachable and speakable.
- The backend validates the same selection IDs used by the app.
- The default journey works offline.
- Automated server tests pass on this computer.
- Native simulator/build verification is explicitly recorded as pending until run on macOS.

## Following increments

Complete the other wish paths, review vocabulary and motor access with AAC users and a qualified communication specialist, validate on physical iPads, finalize approved branding, and decide whether a hosted AI image provider is needed. Only then add a real wish-submission or caregiver account workflow with a separately reviewed data and consent design.
