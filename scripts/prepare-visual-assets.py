"""Fetch pinned, redistributable visual sources; rendering is a separate Node step.

Run manually when updating the art. Normal app builds use the checked-in outputs.
"""
import concurrent.futures
import hashlib
import json
import re
from pathlib import Path
import sys
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
NOTO = "99701e07d3d1fe1bdbcdb14964547f0fd592966f"
FONTS = "c30b221beb0c1da59d563feb91ec8656a1fa972a"
OUT = ROOT / "assets/visual"
SVG = OUT / "svg"
FONT = OUT / "fonts"
for directory in [SVG, FONT, OUT / "licenses"]:
    directory.mkdir(parents=True, exist_ok=True)

def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "WishExplorer-asset-build"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read()

catalog = json.loads((ROOT / "assets/journey-catalog.json").read_text(encoding="utf-8"))
choices = [choice for topic in catalog["interests"] for choice in topic["actions"] + topic["settings"]]
choices += [choice for group in catalog["favorites"] for choice in group["options"]]
symbols = sorted({choice["symbol"] for choice in choices} | {"🌈", "🍓", "🐾", "🎵", "🎮", "🗺️"})

def load_symbol(symbol):
    code = "_".join(f"{ord(c):04x}" for c in symbol if ord(c) != 0xfe0f)
    filename = "journey-" + code
    url = f"https://raw.githubusercontent.com/googlefonts/noto-emoji/{NOTO}/2D/svg/emoji_u{code}.svg"
    target = SVG / (filename + ".svg")
    # Rendering replaces these six with project color swatches. Restore the
    # pinned upstream source before calculating its provenance digest.
    if not target.exists() or symbol in {"🔵", "🩷", "🟣", "🟢", "🔴", "🟡"}:
        target.write_bytes(fetch(url))
    raw = target.read_bytes()
    assert b"<script" not in raw.lower() and not re.search(rb'''(?:href|src)\s*=\s*["']https?://''', raw)
    return symbol, {"file": filename + ".png", "source": url, "sourceSHA256": hashlib.sha256(raw).hexdigest()}

with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
    artwork = dict(pool.map(load_symbol, symbols))

for filename in ["ComicNeue-Regular.ttf", "ComicNeue-Bold.ttf"]:
    (FONT / filename).write_bytes(fetch(f"https://raw.githubusercontent.com/google/fonts/{FONTS}/ofl/comicneue/{filename}"))
(OUT / "licenses/ComicNeue-OFL.txt").write_bytes(fetch(f"https://raw.githubusercontent.com/google/fonts/{FONTS}/ofl/comicneue/OFL.txt"))
(OUT / "licenses/NunitoSans-OFL.txt").write_bytes(fetch(f"https://raw.githubusercontent.com/google/fonts/{FONTS}/ofl/nunitosans/OFL.txt"))
(OUT / "licenses/NotoEmoji-Apache.txt").write_bytes(fetch(f"https://raw.githubusercontent.com/googlefonts/noto-emoji/{NOTO}/2D/svg/LICENSE"))

# Produce ordinary static fonts with a distinct family name for the modified instances.
sys.path.insert(0, str(ROOT / "work/visual-tools"))
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
import io
variable = fetch(f"https://raw.githubusercontent.com/google/fonts/{FONTS}/ofl/nunitosans/NunitoSans%5BYTLC,opsz,wdth,wght%5D.ttf")
for weight, style in [(400, "Regular"), (700, "Bold")]:
    font = TTFont(io.BytesIO(variable))
    axes = {axis.axisTag: axis.defaultValue for axis in font["fvar"].axes}
    axes["wght"] = weight
    font = instantiateVariableFont(font, axes, inplace=True)
    for name_id, value in [(1, "Wish Body"), (2, style), (4, "Wish Body " + style), (6, "WishBody-" + style), (16, "Wish Body"), (17, style)]:
        for platform, encoding, language in [(3, 1, 0x409), (1, 0, 0)]:
            font["name"].setName(value, name_id, platform, encoding, language)
    font.save(FONT / ("WishBody-" + style + ".ttf"))

manifest = {"version": 1, "notoCommit": NOTO, "fontsCommit": FONTS, "symbols": artwork,
            "choices": {choice["id"]: choice["symbol"] for choice in choices}}
(OUT / "journey-artwork.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"fixedSymbols": len(artwork), "mappedChoices": len(choices), "fonts": 4}))
