# Local picture-board preview

The approved browser layout and interactions live in `template.html` and `picture-board.js`. The build uses Node built-ins and the repository's shared assets. It works on macOS, Windows, and Linux without installing packages or downloading assets.

From the repository root, with Node.js 22 or newer:

```sh
node preview/build.cjs
node preview/serve.cjs
```

Open **http://127.0.0.1:8787/**. Stop the local server with **Ctrl+C**. The server listens only on this computer and serves the ignored `preview/dist/` directory. It supplies the correct PNG, SVG, JavaScript, CSS, and font content types.

To refresh the output used by the existing local preview server:

```sh
node preview/build.cjs --out work/app-preview
```

To serve that output with the portable server:

```sh
node preview/serve.cjs --dir work/app-preview --port 8787
```

The output directory contains a complete static website: `index.html`, `app.js`, `app.css`, and local `assets/`. It can also be served by an ordinary static file server. There is no embedded-fragment size limit. Build commands write generated files without deleting unrelated files in the output directory.

## Shared artwork and typography

- `assets/picture-catalog.json` supplies all 54 topic/core pictures and their exact native viewport rectangles. The original PNG atlas/file bytes from `assets/pictures/` are copied unchanged. Browser viewports use the same crop coordinates as the iPad app, including full-image frames.
- `assets/journey-catalog.json` supplies the 20 journeys and 216 choices. `assets/visual/journey-artwork.json` resolves every choice, plus the six intake illustrations, to the same fixed PNGs bundled by the native app.
- All `ui-*.png` controls come from `assets/visual/png/`; the preview no longer depends on an installed Lucide package or platform emoji artwork.
- Comic Neue Regular/Bold and WishBody Regular/Bold come from `assets/visual/fonts/`. The original Georgia wordmark styling is retained, matching the native wordmark. Font/artwork license files are copied into the static output.
- The introductory SVG is copied from the native app's `ClientDemoLogo` asset.

Each build checks canonical PNG hashes/dimensions, all 54 frame bounds, all journey artwork mappings, required control icons, and generated script syntax. `build-manifest.json` records the generated asset sizes and SHA-256 hashes for inspection.

The page's content policy permits local scripts, images, and fonts, plus image/font data URLs; it blocks external connections. Normal builds and interactions need no external service. Choices and settings remain in page memory; reloading clears them. Speech uses an available English voice marked as local by the browser. The AI-generation button remains unconfigured. See [the iPad guide](../ios/README.md) for native builds and tests.

Edit the checked-in `preview/` source for future changes. The former ignored `work/` builders are superseded by `preview/build.cjs`.
