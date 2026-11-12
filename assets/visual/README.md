# Shared browser and native visuals

The browser preview and SwiftUI app load the same checked-in PNGs and fonts. They do not render journey symbols with an operating-system emoji font. The 54 original picture concepts still use their original 29 source PNG atlases and catalog frames, unchanged.

- `png/`: 106 fixed journey symbols at 256 × 256, plus 11 navigation/control icons at 128 × 128, with transparent backgrounds.
- `svg/`: pinned Noto source artwork. The six favorite color symbols are replaced with project-drawn circle swatches matching the preview palette; `journey-artwork.json` records this modification and the original upstream digest.
- `fonts/`: unmodified Comic Neue Regular/Bold, and static 400/700 instances of Nunito Sans renamed **Wish Body** (PostScript names `WishBody-Regular` and `WishBody-Bold`). The latter are modified OFL fonts; all other axes use the pinned upstream defaults.
- `licenses/`: the source notices and full redistribution licenses. Noto artwork is converted from SVG to PNG. UI icons are rendered from Lucide 1.8.0; its ISC notice and Feather-derived MIT notice are retained. Color, stroke width, size, and star fill are set by the project.
- `journey-artwork.json`: pinned source revisions, original source digests, output PNG digests, and mappings for all 216 journey/favorite choices. Unicode is only a catalog lookup key, never the visible glyph.

The native copies live in `ios/WishExplorer/Resources/Visual`. Resource checks compare their bytes to this canonical directory. Normal Xcode and browser-preview builds need no download, image library, or font conversion.

## Manually regenerating assets

Only use these steps when intentionally updating the assets. Install `fonttools[woff]` for Python and `sharp` plus `lucide@1.8.0` for Node in a development environment. Optional `WISH_SHARP_MODULE` / `WISH_LUCIDE_MODULE` variables can point to installed modules outside the repository.

1. Run `python scripts/prepare-visual-assets.py` to fetch the pinned upstream SVGs/fonts and generate the renamed font instances. Python also looks in `work/visual-tools` if dependencies were installed there.
2. Run `node scripts/render-visual-assets.cjs` to create PNGs, apply the six project swatches, copy native resources, and record output digests.
3. Run `python ios/scripts/check_resources.py` and review the resulting artwork in both previews before committing.

Licenses: [Comic Neue OFL](licenses/ComicNeue-OFL.txt), [Nunito Sans OFL](licenses/NunitoSans-OFL.txt), [Noto notice](licenses/NotoEmoji-Apache.txt), [Apache 2.0](licenses/Apache-2.0.txt), [Lucide / Feather](licenses/Lucide-LICENSE.txt).
