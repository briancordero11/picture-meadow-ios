#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RESULT_ROOT="$PROJECT_ROOT/ios/build/DerivedData/Logs/Test"
OUTPUT_ROOT="$PROJECT_ROOT/ios/build/visual-proof"
shopt -s nullglob
RESULTS=("$RESULT_ROOT"/*.xcresult)
if [[ ${#RESULTS[@]} -eq 0 ]]; then
  echo "No native test result bundle exists; there are no screenshots to export."
  exit 0
fi

# Print the installed Xcode command's supported options alongside its output.
xcrun xcresulttool export attachments --help
mkdir -p "$OUTPUT_ROOT"
for RESULT in "${RESULTS[@]}"; do
  BUNDLE_NAME="$(basename "$RESULT" .xcresult)"
  xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUTPUT_ROOT/$BUNDLE_NAME"
done

python3 - "$OUTPUT_ROOT" <<'PY'
import html
import json
import sys
from pathlib import Path
from urllib.parse import quote

root = Path(sys.argv[1])
images = sorted(path for path in root.rglob("*") if path.suffix.lower() in {".png", ".jpg", ".jpeg"})
if not images:
    raise SystemExit("The native result bundles exported no screenshot images.")

labels = {}
def inspect(value):
    if isinstance(value, dict):
        filename = value.get("exportedFileName")
        name = value.get("suggestedHumanReadableName") or value.get("name")
        if isinstance(filename, str) and isinstance(name, str):
            labels[Path(filename).name] = name
        for child in value.values():
            inspect(child)
    elif isinstance(value, list):
        for child in value:
            inspect(child)

for manifest in root.rglob("*.json"):
    try:
        inspect(json.loads(manifest.read_text()))
    except (ValueError, OSError):
        pass

cards = []
for path in images:
    title = labels.get(path.name, path.name)
    relative = path.relative_to(root).as_posix()
    cards.append(f'<figure><figcaption>{html.escape(title)}</figcaption><a href="{quote(relative)}"><img src="{quote(relative)}" alt="{html.escape(title, quote=True)}" loading="lazy"></a></figure>')
(root / "index.html").write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Native iPad visual proof</title><style>body{margin:24px;background:#eee9df;color:#211c18;font:16px system-ui}figure{margin:24px 0}figcaption{font-weight:700;margin-bottom:8px}img{display:block;max-width:100%;width:820px;height:auto;border:1px solid #c9bba7}</style><h1>Native iPad visual proof</h1><p>Actual simulator screenshots attached by the UI tests. Result manifests retain attachment and test names.</p>' + ''.join(cards) + '</html>')
print(f"Exported {len(images)} native screenshot images to {root}")
PY
