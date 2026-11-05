"""Portable resource checks. This does not compile Swift or replace native tests."""
import json
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
assert len(labels) == len(set(labels)) == 54, "Communication concepts must be complete and unique"
test_count = len(re.findall(r"func test", (root / "WishExplorerTests/WishDraftTests.swift").read_text()))
print(json.dumps({"valid_plists": len(plists), "valid_asset_catalog_files": len(assets),
                  "opaque_icon": "1024x1024", "communication_concepts": len(labels),
                  "native_tests_written_not_run": test_count, "swift_compiled": False}))
