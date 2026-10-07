#!/usr/bin/env python3
"""Generate the Wesal app icon at high resolution.

Rebuilds the brand mark (gold location-pin + white plane/road on a dark
teal-green squircle) as clean, anti-aliased vector-style geometry, so the icon
is crisp at every size instead of an upscaled low-res JPEG.

Outputs (1024x1024):
  assets/icon/wesal_icon.png             full-bleed (iOS + legacy Android)
  assets/icon/wesal_icon_foreground.png  transparent mark only (Android adaptive)

Colors sampled from the supplied brand icon.
Run:  python3 tool/generate_icon.py
"""
import math
import os

from PIL import Image, ImageDraw

S = 4                      # supersample factor for anti-aliasing
BASE = 1024
SIZE = BASE * S

# Brand palette (sampled from the source icon).
GREEN_TOP = (22, 66, 60)
GREEN_BOT = (11, 38, 35)
GOLD_TOP = (242, 203, 94)
GOLD_BOT = (201, 148, 32)
CREAM = (244, 244, 239)


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vgradient(size, top, bot):
    """Vertical gradient image."""
    img = Image.new("RGB", (1, size))
    px = img.load()
    for y in range(size):
        px[0, y] = lerp(top, bot, y / (size - 1))
    return img.resize((size, size))


def teardrop_points(cx, cy, r, tip_y, n=160):
    """Map-pin / teardrop outline: a circle (center cx,cy r) tapering to a
    point at (cx, tip_y) below it. Returns a closed polygon point list."""
    d = tip_y - cy
    if d <= r:
        d = r * 1.08
        tip_y = cy + d
    a = math.acos(max(-1.0, min(1.0, r / d)))  # half tangent angle
    base = math.pi / 2  # center -> tip direction (down, +y)
    a1 = base - a
    a2 = base + a
    pts = [(cx, tip_y)]
    # major arc over the top, from a1 around (decreasing) to a2 - 2pi
    steps = n
    start = a1
    end = a2 - 2 * math.pi
    for i in range(steps + 1):
        ang = start + (end - start) * i / steps
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


def rotate(points, cx, cy, deg):
    rad = math.radians(deg)
    ca, sa = math.cos(rad), math.sin(rad)
    out = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        out.append((cx + dx * ca - dy * sa, cy + dx * sa + dy * ca))
    return out


def quad_ribbon(p0, p1, p2, w0, w1, n=60):
    """Variable-width ribbon along a quadratic bezier (p0->p2, control p1).
    Width tapers from w0 (start) to w1 (end)."""
    left, right = [], []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        x = mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0]
        y = mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1]
        # derivative for normal
        dx = 2 * mt * (p1[0] - p0[0]) + 2 * t * (p2[0] - p1[0])
        dy = 2 * mt * (p1[1] - p0[1]) + 2 * t * (p2[1] - p1[1])
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        w = (w0 + (w1 - w0) * t) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def draw_mark(size, with_bg):
    """Draw the mark on a (size,size) RGBA image. If with_bg, fills the dark
    green squircle; otherwise background stays transparent (adaptive fg)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    sc = size / BASE  # scale from base coords

    def P(x, y):
        return (x * sc, y * sc)

    def PL(pts):
        return [P(x, y) for x, y in pts]

    if with_bg:
        bg = vgradient(size, GREEN_TOP, GREEN_BOT).convert("RGBA")
        mask = Image.new("L", (size, size), 0)
        md = ImageDraw.Draw(mask)
        radius = int(220 * sc)
        md.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
        img.paste(bg, (0, 0), mask)

    # Mark is slightly scaled down for adaptive safe-zone when no bg.
    pad = 1.0 if with_bg else 0.78
    cxb, cyb = BASE / 2, BASE / 2

    def scale_about(pts, f):
        return [(cxb + (x - cxb) * f, cyb + (y - cyb) * f) for x, y in pts]

    gold = vgradient(size, GOLD_TOP, GOLD_BOT).convert("RGBA")

    # --- Gold location-pin ring (outer teardrop minus inner teardrop) ---
    cx, cy = 512, 452
    outer = teardrop_points(cx, cy, 250, 812)
    inner = teardrop_points(cx, cy, 150, past(cy, 150))

    outer = scale_about(outer, pad)
    inner = scale_about(inner, pad)

    gold_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gold_layer)
    gd.polygon(PL(outer), fill=(255, 255, 255, 255))
    gd.polygon(PL(inner), fill=(0, 0, 0, 0))  # punch the hole
    # apply gold gradient through the ring mask
    ring_mask = gold_layer.split()[3]
    img.paste(gold, (0, 0), ring_mask)

    # --- White paper plane + swoosh inside the ring ---
    white_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    wd = ImageDraw.Draw(white_layer)

    # Swoosh / road: sweeps from lower-left up toward the plane, tapering.
    swoosh = quad_ribbon((372, 590), (470, 560), (560, 452), 10, 70)
    swoosh = scale_about(swoosh, pad)
    wd.polygon(PL(swoosh), fill=CREAM + (255,))

    # Paper plane (origami) pointing up-left.
    plane = [
        (512, 300),   # nose
        (598, 500),   # right tail
        (512, 452),   # center fold (back)
        (470, 520),   # left tail lower
        (452, 452),   # left mid
    ]
    plane = rotate(plane, 512, 420, -12)
    plane = scale_about(plane, pad)
    wd.polygon(PL(plane), fill=CREAM + (255,))

    img = Image.alpha_composite(img, white_layer)
    return img


def past(cy, r):
    """Inner teardrop tip y (shorter than outer)."""
    return cy + r * 1.75


def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
    out_dir = os.path.abspath(out_dir)
    os.makedirs(out_dir, exist_ok=True)

    full = draw_mark(SIZE, with_bg=True).resize((BASE, BASE), Image.LANCZOS)
    fg = draw_mark(SIZE, with_bg=False).resize((BASE, BASE), Image.LANCZOS)

    full_path = os.path.join(out_dir, "wesal_icon.png")
    fg_path = os.path.join(out_dir, "wesal_icon_foreground.png")
    full.convert("RGB").save(full_path)
    fg.save(fg_path)
    print("wrote", full_path)
    print("wrote", fg_path)


if __name__ == "__main__":
    main()
