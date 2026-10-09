#!/usr/bin/env python3
import math
import os
import struct
import subprocess
import zlib


ROOT = os.path.dirname(__file__)
ICONSET = os.path.join(ROOT, "Resources", "AppIcon.iconset")
ICNS = os.path.join(ROOT, "Resources", "AppIcon.icns")


def clamp(value, low=0, high=255):
    return max(low, min(high, int(round(value))))


class Canvas:
    def __init__(self, size):
        self.size = size
        self.pixels = bytearray([0, 0, 0, 0] * size * size)

    def blend_pixel(self, x, y, rgba):
        if x < 0 or y < 0 or x >= self.size or y >= self.size:
            return
        i = (y * self.size + x) * 4
        sr, sg, sb, sa = rgba
        a = sa / 255.0
        ia = 1.0 - a
        da = self.pixels[i + 3] / 255.0
        out_a = a + da * ia
        if out_a <= 0:
            return
        self.pixels[i] = clamp((sr * a + self.pixels[i] * da * ia) / out_a)
        self.pixels[i + 1] = clamp((sg * a + self.pixels[i + 1] * da * ia) / out_a)
        self.pixels[i + 2] = clamp((sb * a + self.pixels[i + 2] * da * ia) / out_a)
        self.pixels[i + 3] = clamp(out_a * 255)

    def fill_rect_gradient(self, x0, y0, x1, y1, radius, top, bottom):
        for y in range(max(0, y0), min(self.size, y1)):
            t = (y - y0) / max(1, (y1 - y0))
            r = top[0] * (1 - t) + bottom[0] * t
            g = top[1] * (1 - t) + bottom[1] * t
            b = top[2] * (1 - t) + bottom[2] * t
            for x in range(max(0, x0), min(self.size, x1)):
                dx = max(x0 + radius - x, 0, x - (x1 - radius), 0)
                dy = max(y0 + radius - y, 0, y - (y1 - radius), 0)
                if dx * dx + dy * dy <= radius * radius:
                    self.blend_pixel(x, y, (r, g, b, 255))

    def fill_ellipse(self, cx, cy, rx, ry, rgba):
        x0 = int(cx - rx)
        x1 = int(cx + rx)
        y0 = int(cy - ry)
        y1 = int(cy + ry)
        for y in range(max(0, y0), min(self.size, y1)):
            yy = ((y + 0.5 - cy) / ry) ** 2
            if yy > 1:
                continue
            for x in range(max(0, x0), min(self.size, x1)):
                if ((x + 0.5 - cx) / rx) ** 2 + yy <= 1:
                    self.blend_pixel(x, y, rgba)

    def fill_round_rect(self, x0, y0, x1, y1, radius, rgba):
        for y in range(max(0, y0), min(self.size, y1)):
            for x in range(max(0, x0), min(self.size, x1)):
                dx = max(x0 + radius - x, 0, x - (x1 - radius), 0)
                dy = max(y0 + radius - y, 0, y - (y1 - radius), 0)
                if dx * dx + dy * dy <= radius * radius:
                    self.blend_pixel(x, y, rgba)

    def fill_polygon(self, points, rgba):
        min_y = max(0, int(min(p[1] for p in points)))
        max_y = min(self.size - 1, int(max(p[1] for p in points)))
        for y in range(min_y, max_y + 1):
            intersections = []
            for i, (x1, y1) in enumerate(points):
                x2, y2 = points[(i + 1) % len(points)]
                if (y1 <= y < y2) or (y2 <= y < y1):
                    t = (y - y1) / (y2 - y1)
                    intersections.append(x1 + t * (x2 - x1))
            intersections.sort()
            for a, b in zip(intersections[0::2], intersections[1::2]):
                for x in range(max(0, int(a)), min(self.size, int(b) + 1)):
                    self.blend_pixel(x, y, rgba)

    def stroke_arc(self, cx, cy, radius, start, end, width, rgba):
        steps = int(abs(end - start) * radius / 8)
        last = None
        for i in range(steps + 1):
            t = start + (end - start) * i / max(1, steps)
            point = (cx + math.cos(t) * radius, cy + math.sin(t) * radius)
            if last:
                self.stroke_line(last[0], last[1], point[0], point[1], width, rgba)
            last = point

    def stroke_line(self, x0, y0, x1, y1, width, rgba):
        length = max(1, int(math.hypot(x1 - x0, y1 - y0)))
        for i in range(length + 1):
            t = i / length
            x = x0 * (1 - t) + x1 * t
            y = y0 * (1 - t) + y1 * t
            self.fill_ellipse(x, y, width / 2, width / 2, rgba)


def downsample(src, new_size):
    old = src.size
    scale = old // new_size
    out = Canvas(new_size)
    for y in range(new_size):
        for x in range(new_size):
            totals = [0, 0, 0, 0]
            for yy in range(scale):
                for xx in range(scale):
                    i = ((y * scale + yy) * old + (x * scale + xx)) * 4
                    for c in range(4):
                        totals[c] += src.pixels[i + c]
            area = scale * scale
            j = (y * new_size + x) * 4
            for c in range(4):
                out.pixels[j + c] = totals[c] // area
    return out


def write_png(path, canvas):
    size = canvas.size
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        start = y * size * 4
        raw.extend(canvas.pixels[start:start + size * 4])

    def chunk(kind, data):
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    data += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)


def draw_icon():
    c = Canvas(1024)

    # macOS-style rounded square, with space for shadow/transparency around it.
    c.fill_round_rect(86, 88, 938, 940, 190, (7, 26, 37, 62))
    c.fill_rect_gradient(74, 70, 950, 946, 205, (31, 186, 195), (14, 111, 151))

    # Soft inner glow.
    for r, alpha in [(390, 32), (300, 24), (220, 18)]:
        c.fill_ellipse(512, 370, r, r * 0.62, (118, 241, 230, alpha))

    # Drive body.
    c.fill_round_rect(245, 315, 779, 690, 64, (8, 56, 75, 85))
    c.fill_round_rect(230, 290, 794, 663, 60, (242, 250, 252, 255))
    c.fill_round_rect(275, 346, 749, 565, 28, (210, 232, 236, 255))

    # Lower lip and status light.
    c.fill_round_rect(295, 588, 729, 626, 19, (172, 205, 213, 255))
    c.fill_ellipse(688, 606, 20, 20, (42, 199, 143, 255))

    # Scan sweep.
    c.stroke_arc(512, 510, 270, math.radians(205), math.radians(338), 42, (255, 255, 255, 220))
    c.stroke_arc(512, 510, 212, math.radians(214), math.radians(329), 20, (74, 224, 214, 210))
    c.stroke_line(612, 616, 783, 445, 34, (255, 255, 255, 240))

    # Sparkles for clean result.
    c.fill_polygon([(775, 245), (800, 300), (855, 326), (800, 352), (775, 407), (750, 352), (695, 326), (750, 300)], (255, 255, 255, 238))
    c.fill_polygon([(690, 205), (705, 237), (737, 252), (705, 267), (690, 299), (675, 267), (643, 252), (675, 237)], (150, 250, 229, 226))
    c.fill_polygon([(335, 230), (349, 260), (379, 274), (349, 288), (335, 318), (321, 288), (291, 274), (321, 260)], (255, 255, 255, 200))

    return c


def main():
    os.makedirs(ICONSET, exist_ok=True)
    master = draw_icon()
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
        canvas = master if size == 1024 else downsample(master, size)
        write_png(os.path.join(ICONSET, name), canvas)

    subprocess.run(["iconutil", "-c", "icns", ICONSET, "-o", ICNS], check=True)
    print(ICNS)


if __name__ == "__main__":
    main()
