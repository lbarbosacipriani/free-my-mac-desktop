#!/usr/bin/env python3
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ICONSET = ROOT / "desktop-mac" / "Resources" / "AppIcon.iconset"
ICNS = ROOT / "desktop-mac" / "Resources" / "AppIcon.icns"


def write_png(path: Path, width: int, height: int, pixels: list[tuple[int, int, int, int]]) -> None:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixels[y * width + x])

    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def rounded_rect_alpha(x: int, y: int, size: int, inset: int, radius: int) -> bool:
    left = inset
    top = inset
    right = size - inset - 1
    bottom = size - inset - 1
    if left + radius <= x <= right - radius and top <= y <= bottom:
        return True
    if left <= x <= right and top + radius <= y <= bottom - radius:
        return True
    centers = [
        (left + radius, top + radius),
        (right - radius, top + radius),
        (left + radius, bottom - radius),
        (right - radius, bottom - radius),
    ]
    return any((x - cx) ** 2 + (y - cy) ** 2 <= radius**2 for cx, cy in centers)


def draw_icon(size: int) -> list[tuple[int, int, int, int]]:
    pixels: list[tuple[int, int, int, int]] = []
    center = (size - 1) / 2
    max_dist = math.sqrt(2 * center * center)

    for y in range(size):
        for x in range(size):
            if not rounded_rect_alpha(x, y, size, max(1, size // 16), max(4, size // 5)):
                pixels.append((0, 0, 0, 0))
                continue

            dist = math.sqrt((x - center) ** 2 + (y - center) ** 2) / max_dist
            r = int(20 + 18 * (1 - dist))
            g = int(105 + 62 * (1 - dist))
            b = int(126 + 52 * (1 - dist))
            pixels.append((r, g, b, 255))

    def set_px(x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if 0 <= x < size and 0 <= y < size:
            pixels[y * size + x] = color

    def rect(x0: int, y0: int, x1: int, y1: int, color: tuple[int, int, int, int]) -> None:
        for yy in range(y0, y1):
            for xx in range(x0, x1):
                set_px(xx, yy, color)

    white = (245, 250, 252, 255)
    pale = (187, 231, 229, 255)
    accent = (255, 255, 255, 255)

    rect(size // 4, size // 4, size * 3 // 4, size * 11 // 16, white)
    rect(size // 4 + size // 24, size // 4 + size // 14, size * 3 // 4 - size // 24, size * 11 // 16 - size // 20, pale)
    rect(size // 4, size // 4, size * 3 // 4, size // 4 + max(2, size // 18), accent)

    # Simple sparkle/check mark.
    stroke = max(2, size // 24)
    points = [
        (size * 7 // 20, size * 14 // 20),
        (size * 9 // 20, size * 16 // 20),
        (size * 14 // 20, size * 11 // 20),
    ]
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            x = x0 + (x1 - x0) * i // steps
            y = y0 + (y1 - y0) * i // steps
            rect(x - stroke // 2, y - stroke // 2, x + stroke, y + stroke, accent)

    return pixels


def main() -> int:
    ICONSET.mkdir(parents=True, exist_ok=True)
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, size in sizes.items():
        write_png(ICONSET / name, size, size, draw_icon(size))

    icns_items = [
        (b"icp4", ICONSET / "icon_16x16.png"),
        (b"icp5", ICONSET / "icon_32x32.png"),
        (b"icp6", ICONSET / "icon_32x32@2x.png"),
        (b"ic07", ICONSET / "icon_128x128.png"),
        (b"ic08", ICONSET / "icon_256x256.png"),
        (b"ic09", ICONSET / "icon_512x512.png"),
        (b"ic10", ICONSET / "icon_512x512@2x.png"),
    ]
    chunks = []
    for code, path in icns_items:
        data = path.read_bytes()
        chunks.append(code + struct.pack(">I", len(data) + 8) + data)

    body = b"".join(chunks)
    ICNS.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
