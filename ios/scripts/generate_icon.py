"""Create the original Wish Explorer icon with Python's standard library only."""
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
DESTINATION = Path(__file__).resolve().parents[1] / "WishExplorer/Assets.xcassets/AppIcon.appiconset/AppIcon.png"


def star(cx, cy, radius, inner=0.46, points=5, rotation=-math.pi / 2):
    return [(cx + math.cos(rotation + i * math.pi / points) * radius * (1 if i % 2 == 0 else inner),
             cy + math.sin(rotation + i * math.pi / points) * radius * (1 if i % 2 == 0 else inner))
            for i in range(points * 2)]


def spans(polygon, y):
    intersections = []
    for index, (x1, y1) in enumerate(polygon):
        x2, y2 = polygon[(index + 1) % len(polygon)]
        if (y1 <= y < y2) or (y2 <= y < y1):
            intersections.append(x1 + (y - y1) * (x2 - x1) / (y2 - y1))
    intersections.sort()
    return list(zip(intersections[::2], intersections[1::2]))


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)


shapes = [(star(514, 498, 276, rotation=-math.pi / 2 + 0.12), (255, 210, 70)),
          (star(792, 240, 57, inner=0.25, points=4), (255, 255, 255)),
          (star(230, 715, 42, inner=0.25, points=4), (196, 228, 255))]
rows = bytearray()
for y in range(SIZE):
    row = bytearray()
    for x in range(SIZE):
        glow = max(0.0, 1 - math.hypot(x - 310, y - 200) / 1100)
        color = [int(8 + glow * 18), int(56 + glow * 67), int(143 + glow * 72)]
        orbit = ((x - 512) / 370) ** 2 + ((y - 540) / 300) ** 2
        if 0.98 < orbit < 1.02 and (x < 400 or y > 590):
            color = [114, 183, 242]
        row.extend(color)
    for polygon, color in shapes:
        for left, right in spans(polygon, y):
            a, b = max(0, math.ceil(left)), min(SIZE, math.ceil(right))
            row[a * 3:b * 3] = bytes(color) * max(0, b - a)
    rows.append(0)
    rows.extend(row)

DESTINATION.parent.mkdir(parents=True, exist_ok=True)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b"")
DESTINATION.write_bytes(png)
print(f"Created opaque original icon: {DESTINATION} ({len(png)} bytes)")
