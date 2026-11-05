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
test_count = len(re.findall(r"func test", (root / "WishExplorerTests/WishDraftTests.swift").read_text()))
print(json.dumps({"valid_plists": len(plists), "valid_asset_catalog_files": len(assets),
                  "opaque_icon": "1024x1024", "interest_pictures": 20, "core_pictures": len(labels),
                  "unchanged_source_picture_files": len(manifest["atlases"]),
                  "native_tests_written_not_run": test_count, "swift_compiled": False}))
