"""Portable resource checks. This does not compile Swift or replace native tests."""
import json
import hashlib
import plistlib
import re
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
plists = [root / "WishExplorer/Info.plist", root / "WishExplorer/PrivacyInfo.xcprivacy"]
for file in plists:
    plistlib.loads(file.read_bytes())
assets = list((root / "WishExplorer/Assets.xcassets").rglob("Contents.json"))
for file in assets:
    metadata = json.loads(file.read_text())
    for image in metadata.get("images", []):
        assert (file.parent / image["filename"]).is_file(), image["filename"]
icon = root / "WishExplorer/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
raw = icon.read_bytes()
assert raw[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", raw[16:24]) == (1024, 1024)
assert raw[25] == 2, "App icon must be opaque RGB"
models = (root / "WishExplorer/Models.swift").read_text(encoding="utf-8")
labels = re.findall(r'\.init\(label: "([^"]+)"', models)
assert len(labels) == len(set(labels)) == 34, "Core communication concepts must be complete and unique"
rows_match = re.search(r"let labels = (\[.*?\n        \])", models, re.S)
assert rows_match, "Core row declaration missing"
core_rows = json.loads(rows_match.group(1))
assert len(core_rows) == 6 and all(len(row) == 5 for row in core_rows)
assert [row[0] for row in core_rows[:3]] == ["I", "You", "We"]
phrase_match = re.search(r"static let phraseWords: \[Self\] = (\[[^\n]+\])", models)
assert phrase_match, "Core phrase footer missing"
core_phrases = json.loads(phrase_match.group(1))
assert core_phrases == ["This is fun!", "Thank you!", "I need time to think", "I need a break"]
packed_labels = [label for row in core_rows for label in row] + core_phrases
assert len(packed_labels) == len(set(packed_labels)) == 34
assert set(packed_labels) == set(labels)
pictures = root / "WishExplorer/Resources/Pictures"
manifest_path = pictures / "picture-catalog.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
assert len(manifest["items"]) == 54
assert sum(item["kind"] == "interest" for item in manifest["items"]) == 20
assert sum(item["kind"] == "core" for item in manifest["items"]) == 34
normalize = lambda label: "".join(character for character in label.lower() if character.isalnum())
assert {normalize(label) for label in labels} == {normalize(item["label"]) for item in manifest["items"] if item["kind"] == "core"}
canonical_manifest = root.parent / "assets/picture-catalog.json"
if canonical_manifest.exists():
    assert manifest_path.read_bytes() == canonical_manifest.read_bytes(), "Re-copy the latest canonical picture catalog"
for atlas in manifest["atlases"].values():
    source = pictures / Path(atlas["file"]).name
    original = source.read_bytes()
    assert hashlib.sha256(original).hexdigest() == atlas["sha256"], "Supplied picture bytes changed: " + source.name
    assert struct.unpack(">II", original[16:24]) == (atlas["width"], atlas["height"])
for item in manifest["items"]:
    atlas, frame = manifest["atlases"][item["atlas"]], item["frame"]
    assert min(frame.values()) >= 0 and frame["width"] > 0 and frame["height"] > 0
    assert frame["x"] + frame["width"] <= atlas["width"] and frame["y"] + frame["height"] <= atlas["height"]

visuals = root / "WishExplorer/Resources/Visual"
artwork_path = visuals / "journey-artwork.json"
artwork = json.loads(artwork_path.read_text(encoding="utf-8"))
journey_path = root / "WishExplorer/Resources/journey-catalog.json"
journeys = json.loads(journey_path.read_text(encoding="utf-8"))
choices = [choice for interest in journeys["interests"] for choice in interest["actions"] + interest["settings"]]
choices += [choice for group in journeys["favorites"] for choice in group["options"]]
assert len(choices) == len(artwork["choices"]) == 216
assert artwork["choices"] == {choice["id"]: choice["symbol"] for choice in choices}
assert len(artwork["symbols"]) == 106
assert set(artwork["symbols"]) == {choice["symbol"] for choice in choices}
assert len({entry["file"] for entry in artwork["symbols"].values()}) == 106
assert all(symbol in artwork["symbols"] for symbol in ["🌈", "🍓", "🐾", "🎵", "🎮", "🗺️"])
canonical_visuals = root.parent / "assets/visual"
assert artwork_path.read_bytes() == (canonical_visuals / "journey-artwork.json").read_bytes(), "Re-copy canonical artwork manifest"
assert journey_path.read_bytes() == (root.parent / "assets/journey-catalog.json").read_bytes(), "Re-copy canonical journey catalog"
for entry in artwork["symbols"].values():
    filename = entry["file"]
    assert Path(filename).name == filename and Path(filename).suffix == ".png", filename
    data = (visuals / filename).read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", filename
    assert all(value > 0 for value in struct.unpack(">II", data[16:24])), filename
    assert hashlib.sha256(data).hexdigest() == entry["sha256"], "Shared artwork bytes changed: " + filename
    assert data == (canonical_visuals / "png" / filename).read_bytes(), "Re-copy canonical artwork: " + filename
test_files = list((root / "WishExplorerTests").glob("*Tests.swift"))
for name in ["house", "star", "x", "arrow-left", "volume-off", "volume-2", "delete", "chevron-up", "chevron-down", "check", "circle-help"]:
    filename = "ui-" + name + ".png"
    data = (visuals / filename).read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n" and struct.unpack(">II", data[16:24]) == (128, 128), filename
    assert data == (canonical_visuals / "png" / filename).read_bytes(), "Re-copy canonical control icon: " + filename
for filename in ["ComicNeue-OFL.txt", "NunitoSans-OFL.txt", "NotoEmoji-Apache.txt", "Apache-2.0.txt", "Lucide-LICENSE.txt"]:
    assert (visuals / filename).read_bytes() == (canonical_visuals / "licenses" / filename).read_bytes(), filename
test_count = sum(len(re.findall(r"func test", file.read_text(encoding="utf-8"))) for file in test_files)
info = plistlib.loads(plists[0].read_bytes())
font_names = ["ComicNeue-Regular", "ComicNeue-Bold", "WishBody-Regular", "WishBody-Bold"]
assert set(info.get("UIAppFonts", [])) == {name + ".ttf" for name in font_names}, "Register all four shared fonts in UIAppFonts"
for name in font_names:
    filename = name + ".ttf"
    data = (visuals / filename).read_bytes()
    assert data[:4] == b"\x00\x01\x00\x00", "Invalid TrueType font: " + filename
    assert data == (canonical_visuals / "fonts" / filename).read_bytes(), "Re-copy canonical font: " + filename
for info_key, build_key in {
    "WishAPIBaseURL": "WISH_API_BASE_URL", "WishOnlinePreviewEnabled": "WISH_ONLINE_PREVIEW_ENABLED",
    "WishPublisherName": "WISH_PUBLISHER_NAME", "WishSupportEmail": "WISH_SUPPORT_EMAIL",
    "WishPrivacyPolicyURL": "WISH_PRIVACY_POLICY_URL", "WishSupportURL": "WISH_SUPPORT_URL"
}.items():
    assert info[info_key] == "$(" + build_key + ")"
    assert re.search(r"^    " + build_key + r":", (root / "project.yml").read_text(), re.M)
privacy = plistlib.loads(plists[1].read_bytes())
assert privacy["NSPrivacyTracking"] is False
assert privacy["NSPrivacyCollectedDataTypes"] == []
assert privacy["NSPrivacyAccessedAPITypes"] == [{"NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults", "NSPrivacyAccessedAPITypeReasons": ["CA92.1"]}]
print(json.dumps({"valid_plists": len(plists), "valid_asset_catalog_files": len(assets),
                  "opaque_icon": "1024x1024", "interest_pictures": 20, "core_pictures": len(labels),
                  "core_grid": "5 columns x 6 rows + 4 phrase tiles",
                  "unchanged_source_picture_files": len(manifest["atlases"]),
                  "fixed_journey_symbols": len(artwork["symbols"]), "mapped_journey_choices": len(choices),
                  "bundled_shared_fonts": len(font_names),
                  "native_test_files": len(test_files), "build_metadata_bindings": 6,
                  "native_tests_written_not_run": test_count, "swift_compiled": False}))
