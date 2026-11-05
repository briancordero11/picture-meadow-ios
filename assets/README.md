# Shared picture components

`picture-catalog.json` defines the 20 topic pictures and 34 core communication pictures used by the revised UI. It records each stable ID, visible label, source image, display rectangle, and source order.

`pictures/` contains 29 original PNG image objects extracted unchanged from the supplied `WishImages.pdf`. The app displays those pictures through the catalog's viewports and renders labels as accessible text. File hashes in the catalog identify the original bytes. The supplied source art is reused at the user's request; no newly generated illustration replaces these reference pictures.

The iOS resource copy is under `ios/WishExplorer/Resources/Pictures/`. `python ios/scripts/check_resources.py` verifies that its manifest and original image hashes match this canonical copy. Run that check after updating picture definitions.

`provenance/` contains reference screenshots for project context. They are not native app resources and should not be added to the app bundle. Public distribution decisions remain part of the release review.
