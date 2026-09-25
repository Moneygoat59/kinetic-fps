"""Procedural pixel-art textures for the PS1 look (small, seamless, no external assets except the project's own fonts).
Run: python tools/blender/textures.py   -> models/generated/tex/*.png
Theme: an abandoned amber-extraction well, decades (100+ years) derelict. Obsidian-black concrete: dirt shows up PALE (dust, salt
bloom, dust-filled cracks) and glassy glints; rust and dried amber crust are the only colour.
Surfaces: concrete, concrete_top, floor, metal, plate.   Decals (RGBA): streaks, stencil, hazard, warning, stain, notes, dust, cobweb,
papers, amber_crust, crack, drips_amber.   Liquid: liquid_flow (emission, scrolled), liquid_pool (RGBA).
Screens (emission): screen_term_a/b, screen_scan_a/b, screen_static, screen_map_a/b, screen_gen_a/b (a/b flipped at runtime).
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "models", "generated", "tex")
FONTS = os.path.join(ROOT, "fonts")
OBSIDIAN = (0.97, 0.99, 1.07)      # cool, glassy black


# ------------------------------------------------------------------ helpers
def _noise(n, k, rng):
    """Seamless value noise: random k x k grid, tiled 3x, bicubic-upsampled, centre crop."""
    g = rng.random((k, k)).astype(np.float32)
    big = np.tile(g, (3, 3))
    im = Image.fromarray((big * 255).astype(np.uint8)).resize((3 * n, 3 * n), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32)[n:2 * n, n:2 * n] / 255.0


def _fbm(n, rng, octaves=((4, 0.25), (8, 0.3), (16, 0.3), (32, 0.15))):
    a = sum(_noise(n, k, rng) * w for k, w in octaves)
    return (a - a.min()) / (a.max() - a.min())


def _save(name, arr):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, name))
    print("TEX", name)


def _save_img(name, im):
    os.makedirs(OUT, exist_ok=True)
    im.save(os.path.join(OUT, name))
    print("TEX", name)


def _tint(lum, r, g, b):
    return np.stack([lum * r, lum * g, lum * b], -1)


def _font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def _rgba(color, alpha):
    a = np.zeros(alpha.shape + (4,), dtype=np.float32)
    a[..., 0], a[..., 1], a[..., 2], a[..., 3] = color[0], color[1], color[2], alpha
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")


def _scratches(n, rng, count, minlen, maxlen, lo=0.05, hi=0.14, width=1):
    """Seamless field of thin scratches (0..1). Lines are drawn at 9 wrap offsets so tiles repeat cleanly."""
    layer = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        x, y = rng.random() * n, rng.random() * n
        a = rng.random() * math.pi
        ln = rng.uniform(minlen, maxlen)
        dx, dy = math.cos(a) * ln, math.sin(a) * ln
        v = int(rng.uniform(lo, hi) * 255)
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.line([(x + ox, y + oy), (x + ox + dx, y + oy + dy)], fill=v, width=width)
    return np.asarray(layer, dtype=np.float32) / 255.0


def _arcs(n, rng, count, rmin, rmax, lo, hi):
    """Conchoidal (shell-shaped) fracture arcs like broken volcanic glass; seamless via wrap offsets."""
    layer = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(layer)
    for _ in range(count):
        cx, cy, r = rng.random() * n, rng.random() * n, rng.uniform(rmin, rmax)
        a0 = rng.uniform(0, 360)
        span = rng.uniform(40, 130)
        v = int(rng.uniform(lo, hi) * 255)
        for ox in (-n, 0, n):
            for oy in (-n, 0, n):
                d.arc([cx - r + ox, cy - r + oy, cx + r + ox, cy + r + oy], a0, a0 + span, fill=v, width=1)
    return np.asarray(layer, dtype=np.float32) / 255.0


def _streaks(lum, rng, count, minlen, maxlen, lo, hi, wmax=3):
    """Vertical streaks. Positive strength darkens, negative brightens (pale efflorescence on black)."""
    n = lum.shape[0]
    for _ in range(count):
        x, w = int(rng.integers(0, n)), int(rng.integers(1, wmax + 1))
        ln, y0 = int(rng.integers(minlen, maxlen)), int(rng.integers(0, n))
        s = rng.uniform(min(lo, hi), max(lo, hi))
        for yy in range(ln):
            lum[(y0 + yy) % n, [(x + k) % n for k in range(w)]] -= s * (1 - yy / ln)


def _cracks(lum, rng, count, minlen, maxlen, depth=0.09):
    n = lum.shape[0]
    for _ in range(count):
        x, y = int(rng.integers(0, n)), int(rng.integers(0, n))
        for _s in range(int(rng.integers(minlen, maxlen))):
            lum[y % n, x % n] -= depth
            x += int(rng.integers(-1, 2))
            y += int(rng.integers(0, 2)) if rng.random() < 0.7 else int(rng.integers(-1, 2))


def _amber(img, mask, strength=0.9):
    """Tint masked areas toward dried-amber orange (multiplicative, keeps the dark value)."""
    img[..., 0] *= 1 + mask * strength * 0.9
    img[..., 1] *= 1 + mask * strength * 0.28
    return img


# ------------------------------------------------------------------ surfaces
def concrete(n=256, seed=1):
    """Obsidian-black board-formed concrete: glassy glints and fracture arcs, pale dust-filled cracks, salt streaks, amber stains."""
    rng = np.random.default_rng(seed)
    lum = 0.05 + _fbm(n, rng) * 0.045 + rng.random((n, n)) * 0.012 + (_noise(n, 5, rng) - 0.5) * 0.025
    lum += _arcs(n, rng, 16, 18, 80, 0.10, 0.22) * 0.16                          # conchoidal fracture
    lum += np.repeat(rng.random((n, 1)), n, axis=1) * 0.008
    for b in range(n // 32):
        lum[b * 32:(b + 1) * 32, :] += rng.uniform(-0.006, 0.006)               # board tone
        lum[b * 32:b * 32 + 2, :] += 0.022                                        # dust in the board seam
    _streaks(lum, rng, 40, 60, 220, -0.03, -0.085)                               # pale salt / ash streaks
    for x in (64, 192):
        for y in (48, 176):                                                      # tie-holes: dark, pale rim
            lum[y - 3:y + 4, x - 3:x + 4] += 0.03
            lum[y - 1:y + 2, x - 1:x + 2] -= 0.04
    lum[rng.random((n, n)) > 0.985] += 0.09                                      # spalled aggregate
    lum[rng.random((n, n)) > 0.996] += 0.24                                      # glassy glints
    _cracks(lum, rng, 5, 40, 120, -0.08)                                         # dust-filled cracks read pale
    lum += _scratches(n, rng, 26, 8, 40) * 0.5
    img = _tint(lum, *OBSIDIAN)
    _save("concrete.png", _amber(img, (_noise(n, 10, rng) > 0.8) * (0.4 + 0.6 * _noise(n, 16, rng)), 0.7))


def concrete_top(n=128, seed=4):
    """Cornice / plinth / frames: dustier, water-stained, cracked."""
    rng = np.random.default_rng(seed)
    lum = 0.06 + _fbm(n, rng, ((8, 0.4), (16, 0.4), (32, 0.2))) * 0.04 + rng.random((n, n)) * 0.012
    lum += _arcs(n, rng, 8, 14, 50, 0.10, 0.20) * 0.14
    lum += (_noise(n, 3, rng) > 0.68) * 0.03                                     # dust drifts
    _streaks(lum, rng, 14, 30, 100, -0.03, -0.07)
    _cracks(lum, rng, 3, 20, 70, -0.08)
    lum[rng.random((n, n)) > 0.996] += 0.2
    lum += _scratches(n, rng, 10, 6, 30) * 0.4
    lum[n // 2, :] += 0.02
    img = _tint(lum, *OBSIDIAN)
    _save("concrete_top.png", _amber(img, (_noise(n, 8, rng) > 0.82) * 0.5, 0.7))


def floor(n=128, seed=2):
    """Black slab under decades of dust, amber seepage stains, cracks and grit."""
    rng = np.random.default_rng(seed)
    lum = 0.045 + _fbm(n, rng) * 0.04 + rng.random((n, n)) * 0.012
    lum += (_fbm(n, rng, ((6, 0.5), (12, 0.5))) > 0.58) * 0.025                   # dust drifts
    lum[::32, :] += 0.02
    lum[:, ::32] += 0.02                                                         # dust-filled slab joints
    _cracks(lum, rng, 4, 30, 90, -0.07)
    lum[rng.random((n, n)) > 0.985] += 0.07                                      # grit
    lum += _scratches(n, rng, 34, 6, 30, 0.03, 0.08) * 0.6
    img = _tint(lum, *OBSIDIAN)
    _save("floor.png", _amber(img, (_noise(n, 8, rng) > 0.74) * (0.4 + 0.6 * _noise(n, 14, rng)), 0.8))


def metal(n=128, seed=3):
    """Century-old painted steel: heavy rust, rust drips, dried amber crust, peeling paint, scratches."""
    rng = np.random.default_rng(seed)
    lum = 0.07 + _fbm(n, rng, ((4, 0.6), (8, 0.4))) * 0.05 + rng.random((n, n)) * 0.015
    lum += np.repeat(rng.random((n, 1)), n, axis=1) * 0.012
    lum += _scratches(n, rng, 26, 6, 32, 0.04, 0.10) * 0.7
    lum[rng.random((n, n)) > 0.99] += 0.10                                       # paint flakes
    img = _tint(lum, 1.02, 0.99, 1.0)
    for x in (10, n - 11):
        for y in (10, n - 11):
            img[y - 1:y + 1, x - 1:x + 1] *= 1.8                                 # rivets
    rust = _noise(n, 12, rng)
    drips = np.zeros((n, n), dtype=np.float32)
    _streaks(drips, rng, 12, 30, 110, -0.5, -1.0, 2)                             # drips add positive mask
    rmask = np.clip((rust > 0.8) * 0.8 + drips * 0.6, 0, 1)[..., None]
    img = np.where(rmask > 0, img * (1 - 0.5 * rmask) + np.array([0.13, 0.055, 0.02]) * rmask * (0.6 + 0.6 * rust[..., None]), img)
    amber = (_noise(n, 9, rng) > 0.9)[..., None]                                # dried amber crust
    img = np.where(amber, img * 0.4 + np.array([0.15, 0.07, 0.012]), img)
    img *= (0.8 + 0.2 * np.linspace(0, 1, n))[:, None, None]
    img[0, :] *= 0.5
    img[:, 0] *= 0.5
    _save("metal.png", img)


def plate(n=128, seed=5):
    """Interior wall plating: dark panels, seam grooves, bolts, peeling paint, rust bloom and drips at the seams, grime."""
    rng = np.random.default_rng(seed)
    lum = 0.065 + _fbm(n, rng, ((4, 0.5), (8, 0.5))) * 0.05 + rng.random((n, n)) * 0.012
    lum += (_noise(n, 5, rng) > 0.8) * 0.035                                     # peeling-paint patches
    for k in (0, 64):
        lum[k:k + 2, :] -= 0.03
        lum[:, k:k + 2] -= 0.03
    img = _tint(lum, 1.03, 1.0, 1.0)
    drips = np.zeros((n, n), dtype=np.float32)
    for k in (0, 64):
        _streaks(drips, rng, 3, 24, 70, -0.5, -1.0, 2)
    rust = np.clip((_noise(n, 10, rng) > 0.82) * 0.7 + drips * 0.6, 0, 1)[..., None]
    img = img * (1 - 0.5 * rust) + np.array([0.12, 0.05, 0.02]) * rust
    for i in range(8, n, 16):
        for k in (5, 69):
            img[k, i] *= 1.8
    img += _scratches(n, rng, 24, 8, 40, 0.04, 0.10)[..., None] * 0.6
    img *= (0.75 + 0.25 * np.linspace(0, 1, n))[:, None, None]
    _save("plate.png", img)


# ------------------------------------------------------------------ decals (RGBA)
def decal_streaks(w=128, h=256, seed=11):
    """Pale efflorescence / rain streaks running down black concrete."""
    rng = np.random.default_rng(seed)
    a = np.zeros((h, w), dtype=np.float32)
    for _ in range(16):
        x, ww = int(rng.integers(0, w - 8)), int(rng.integers(2, 8))
        ln = int(rng.integers(60, h))
        s = rng.uniform(0.10, 0.34)
        for yy in range(ln):
            a[yy, x:x + ww] = np.maximum(a[yy, x:x + ww], s * (1 - yy / ln) ** 0.8 * (0.7 + 0.3 * rng.random()))
    a[:20, :] *= np.linspace(0.4, 1, 20)[:, None]
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)), dtype=np.float32) / 255
    _save_img("decal_streaks.png", _rgba((0.34, 0.32, 0.29), a))


def decal_stencil(w=128, h=192, seed=12):
    """Century-faded stencil lettering: small 'OUTPOST', big '73', small 'EXTRACTION'; mostly flaked away."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 14), "OUTPOST", font=_font("Oxanium-SemiBold.ttf", 22), fill=255, anchor="mt")
    d.text((w // 2, 108), "73", font=_font("Oxanium-SemiBold.ttf", 120), fill=255, anchor="mm")
    d.text((w // 2, 178), "EXTRACTION", font=_font("Oxanium-SemiBold.ttf", 16), fill=255, anchor="mm")
    for y in (114, 146):                                                         # stencil bridges
        d.rectangle([0, y, w, y + 3], fill=0)
    d.rectangle([w // 2 - 2, 60, w // 2 + 2, h], fill=0)
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.2 + 1.5 * np.resize(_noise(max(w, h), 6, rng), (h, w)), 0, 1)
    a = a * wear * (rng.random((h, w)) > 0.3)                                    # heavily flaked
    _save_img("decal_stencil.png", _rgba((0.46, 0.44, 0.40), a * 0.75))


def decal_hazard(w=256, h=32, seed=13):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w]
    stripe = (((xx + yy) // 16) % 2 == 0)
    col = np.where(stripe[..., None], np.array([0.42, 0.30, 0.03]), np.array([0.02, 0.02, 0.02]))
    a = np.clip(0.3 + 1.1 * np.resize(_noise(max(w, h), 5, rng), (h, w)) - 0.5, 0, 1) * (rng.random((h, w)) > 0.18)
    im = np.dstack([col, a * 0.85]).astype(np.float32)
    _save_img("decal_hazard.png", Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8), "RGBA"))


def decal_warning(w=96, h=128, seed=14):
    """Radiation warning sign, badly corroded."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([2, 2, w - 3, h - 3], 6, fill=(130, 100, 14, 255), outline=(12, 12, 12, 255), width=3)
    cx, cy, r = w // 2, 50, 30
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(12, 12, 12, 255))
    for a0 in (30, 150, 270):
        d.pieslice([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4], a0, a0 + 60, fill=(130, 100, 14, 255))
    d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(130, 100, 14, 255))
    d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(12, 12, 12, 255))
    d.text((w // 2, 100), "RADIATION", font=_font("Silkscreen-Regular.ttf", 12), fill=(12, 12, 12, 255), anchor="mm")
    d.text((w // 2, 115), "AREA", font=_font("Silkscreen-Regular.ttf", 10), fill=(12, 12, 12, 255), anchor="mm")
    arr = np.asarray(im, dtype=np.float32) / 255
    rot = np.resize(_noise(128, 6, rng), (h, w))
    arr[..., :3] *= (0.45 + 0.4 * rot)[..., None]                                 # grime
    arr[..., 0] *= 1 + (rot > 0.6) * 0.5                                          # rust bloom
    arr[..., 3] *= (rng.random((h, w)) > 0.14) * (0.6 + 0.4 * (rot < 0.75))       # corroded holes
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_warning.png"))
    print("TEX decal_warning.png")


def decal_stain(n=128, seed=15):
    """Dark amber-oil seepage stain."""
    rng = np.random.default_rng(seed)
    f = _fbm(n, rng, ((3, 0.5), (6, 0.3), (12, 0.2)))
    yy, xx = np.mgrid[0:n, 0:n]
    fall = np.clip(1 - np.hypot(xx - n / 2, yy - n / 2) / (n * 0.48), 0, 1)
    a = np.clip((f * fall - 0.28) * 2.2, 0, 0.6)
    _save_img("decal_stain.png", _rgba((0.20, 0.08, 0.01), a))


def decal_notes(w=256, h=128, seed=16):
    """Pinned paper notes gone brown with age."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sheets = [((6, 4), (80, 118), -3, ["SHIFT LOG", "D38 flow +4%", "D39 flow +9%", "D40 hum in", "the pipes", "D41 pumps run", "w/o power"], "Caveat-Regular.ttf", 12),
              ((90, 14), (76, 60), 2, ["HUB SAYS", "KEEP PUMPING", "(3rd order)"], "ReenieBeanie.ttf", 13),
              ((170, 6), (84, 112), -1, ["DO NOT", "OPEN AFTER", "DARK", "", "keys in the", "tracker.", "take it &", "GO. NOW."], "PermanentMarker.ttf", 9)]
    for (x, y), (sw, sh), rot, lines, fnt, fsz in sheets:
        p = Image.new("RGBA", (sw, sh), (150, 132, 96, 255))
        pd = ImageDraw.Draw(p)
        pd.rectangle([0, 0, sw - 1, sh - 1], outline=(80, 66, 46, 255))
        pd.ellipse([sw // 2 - 3, 2, sw // 2 + 3, 8], fill=(110, 26, 18, 255))
        for i, ln in enumerate(lines):
            pd.text((6, 12 + i * (fsz + 2)), ln, font=_font(fnt, fsz), fill=(24, 20, 16, 255))
        p = p.rotate(rot, expand=True, resample=Image.BICUBIC)
        im.alpha_composite(p, (x, y))
    arr = np.asarray(im, dtype=np.float32) / 255
    stain = np.resize(_noise(256, 8, rng), (h, w))
    arr[..., :3] *= (0.4 + 0.45 * stain)[..., None]
    arr[..., 0] *= 1 + (stain < 0.35) * 0.35                                      # water / amber staining
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_notes.png"))
    print("TEX decal_notes.png")


def decal_dust(n=128, seed=41):
    """Soft drifts of settled dust for floors and ledges."""
    rng = np.random.default_rng(seed)
    f = _fbm(n, rng, ((3, 0.5), (6, 0.3), (12, 0.2)))
    yy, xx = np.mgrid[0:n, 0:n]
    fall = np.clip(1 - np.hypot(xx - n / 2, yy - n / 2) / (n * 0.5), 0, 1) ** 0.6
    a = np.clip((f - 0.42) * 1.8, 0, 0.6) * fall
    _save_img("decal_dust.png", _rgba((0.36, 0.34, 0.31), a))


def decal_cobweb(n=128, seed=42):
    """Quarter cobweb anchored at the (0,0) corner of the texture."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    col = (200, 198, 190)
    angs = np.linspace(0.0, math.pi / 2, 8)
    for a in angs:
        d.line([(0, 0), (n * math.cos(a), n * math.sin(a))], fill=col + (120,), width=1)
    for r in range(14, n, 15):
        for i in range(len(angs) - 1):
            if rng.random() < 0.22:
                continue
            a0, a1 = angs[i], angs[i + 1]
            am = (a0 + a1) / 2
            p0, p1 = (r * math.cos(a0), r * math.sin(a0)), (r * math.cos(a1), r * math.sin(a1))
            pm = (r * 0.9 * math.cos(am), r * 0.9 * math.sin(am))
            d.line([p0, pm, p1], fill=col + (90,), width=1)
    a = np.asarray(im, dtype=np.float32) / 255
    a[..., 3] *= (rng.random((n, n)) > 0.1)
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_cobweb.png"))
    print("TEX decal_cobweb.png")


def decal_papers(n=128, seed=43):
    """Scattered loose papers on the floor."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    for (x, y), rot in (((10, 12), 18), ((60, 8), -25), ((30, 64), 40), ((78, 70), -8)):
        p = Image.new("RGBA", (44, 56), (140, 124, 92, 255))
        pd = ImageDraw.Draw(p)
        pd.rectangle([0, 0, 43, 55], outline=(70, 58, 40, 255))
        for i in range(8):
            pd.rectangle([5, 7 + i * 6, 5 + int(rng.integers(14, 34)), 8 + i * 6], fill=(30, 26, 20, 255))
        im.alpha_composite(p.rotate(rot, expand=True, resample=Image.BICUBIC), (x, y))
    a = np.asarray(im, dtype=np.float32) / 255
    a[..., :3] *= (0.4 + 0.45 * np.resize(_noise(128, 6, rng), (n, n)))[..., None]
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_papers.png"))
    print("TEX decal_papers.png")


def decal_amber_crust(n=128, seed=44):
    """Patches of dried, dull-amber resin crust."""
    rng = np.random.default_rng(seed)
    f = _fbm(n, rng, ((3, 0.4), (6, 0.35), (12, 0.25)))
    yy, xx = np.mgrid[0:n, 0:n]
    fall = np.clip(1 - np.hypot(xx - n / 2, yy - n / 2) / (n * 0.5), 0, 1)
    m = np.clip((f * 0.7 + fall * 0.7 - 0.5) * 3.0, 0, 1)
    shade = 0.55 + 0.45 * _noise(n, 8, rng)
    rgb = np.stack([0.48 * shade, 0.20 * shade, 0.025 * shade], -1)
    rgb *= (1 - 0.5 * (m < 0.5))[..., None]
    _save_img("decal_amber_crust.png", Image.fromarray((np.clip(np.dstack([rgb, m * 0.9]), 0, 1) * 255).astype(np.uint8), "RGBA"))


def decal_crack(w=128, h=256, seed=45):
    """A large branching structural crack (dark core, pale dust edge)."""
    rng = np.random.default_rng(seed)
    core = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(core)

    def walk(x, y, steps, wdt):
        for _ in range(steps):
            nx, ny = x + rng.integers(-4, 5), y + rng.integers(2, 6)
            d.line([(x, y), (nx, ny)], fill=255, width=wdt)
            x, y = nx, ny
            if rng.random() < 0.07 and wdt > 1:
                walk(x, y, int(steps * 0.4), 1)
            if not (0 <= x < w and 0 <= y < h):
                break
    walk(w * 0.5, 0, 90, 2)
    walk(w * 0.3, 40, 30, 1)
    c = np.asarray(core, dtype=np.float32) / 255
    edge = np.asarray(core.filter(ImageFilter.MaxFilter(5)), dtype=np.float32) / 255
    rgb = np.zeros((h, w, 3), dtype=np.float32) + 0.36
    rgb[c > 0.5] = 0.0
    a = np.clip(edge * 0.45 + c * 0.55, 0, 1)
    _save_img("decal_crack.png", Image.fromarray((np.clip(np.dstack([rgb, a]), 0, 1) * 255).astype(np.uint8), "RGBA"))


# ------------------------------------------------------------------ amber liquid
def liquid_flow(n=64, seed=31):
    """Seamless amber liquid for pipe sight-glasses / well surface (emission). Scrolled along V at runtime."""
    rng = np.random.default_rng(seed)
    b = 0.55 + 0.45 * _noise(n, 5, rng)
    b *= 0.75 + 0.25 * np.repeat(_noise(n, 8, rng)[:1, :], n, axis=0)
    b[rng.random((n, n)) > 0.985] = 1.0
    _save("liquid_flow.png", np.stack([b * 1.0, b * 0.5, b * 0.07], -1))


def liquid_pool(n=128, seed=32):
    """Glowing amber puddle (RGBA): swirly liquid inside an organic, soft-edged blob."""
    rng = np.random.default_rng(seed)
    f = _fbm(n, rng, ((3, 0.5), (6, 0.3), (12, 0.2)))
    yy, xx = np.mgrid[0:n, 0:n]
    fall = np.clip(1 - np.hypot(xx - n / 2, yy - n / 2) / (n * 0.5), 0, 1)
    mask = np.clip((f * 0.6 + fall * 0.9 - 0.42) * 2.6, 0, 1)
    swirl = 0.55 + 0.45 * _noise(n, 7, rng)
    a = np.dstack([np.stack([swirl, swirl * 0.5, swirl * 0.07], -1), mask]).astype(np.float32)
    _save_img("liquid_pool.png", Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA"))


def decal_drips_amber(w=128, h=256, seed=33):
    """Amber leak / drip streaks running down a wall."""
    rng = np.random.default_rng(seed)
    a = np.zeros((h, w), dtype=np.float32)
    for _ in range(9):
        x, ww = int(rng.integers(0, w - 6)), int(rng.integers(2, 6))
        ln = int(rng.integers(80, h))
        s = rng.uniform(0.25, 0.6)
        for yy in range(ln):
            a[yy, x:x + ww] = np.maximum(a[yy, x:x + ww], s * (1 - yy / ln) ** 0.6)
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)), dtype=np.float32) / 255
    _save_img("decal_drips_amber.png", _rgba((0.55, 0.24, 0.03), a))


# ------------------------------------------------------------------ screens (emission): a machine that kept running alone
def _crt(im, vignette=0.55, bloom=1.6, glitch_seed=None):
    """Phosphor look: bloom, scanlines, vignette, noise; optional horizontal glitch bands (decayed signal)."""
    a = np.asarray(im.convert("RGB"), dtype=np.float32) / 255
    if glitch_seed is not None:
        r = np.random.default_rng(glitch_seed)
        for _ in range(3):
            y0 = int(r.integers(0, a.shape[0] - 8))
            a[y0:y0 + int(r.integers(2, 7))] = np.roll(a[y0:y0 + 1], int(r.integers(-9, 10)), axis=1)
    glow = np.asarray(im.convert("RGB").filter(ImageFilter.GaussianBlur(bloom)), dtype=np.float32) / 255
    a = np.clip(a + glow * 0.6, 0, 1)
    a[::2, :, :] *= 0.72
    h, w = a.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w]
    v = 1 - vignette * (((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2) / 2
    a *= np.clip(v, 0.25, 1)[..., None]
    a += np.random.default_rng(3).random(a.shape) * 0.02
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGB")


def _text_screen(lines, size, color, w=256, h=192, cursor=None, font="VT323-Regular.ttf", x0=8, y0=6, step=None):
    im = Image.new("RGB", (w, h), (4, 3, 1))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f = _font(font, size)
    step = step or int(size * 0.9)
    for i, ln in enumerate(lines):
        d.text((x0, y0 + i * step), ln, font=f, fill=color)
    if cursor:
        cx, cy = cursor
        d.rectangle([cx, cy, cx + int(size * 0.42), cy + int(size * 0.7)], fill=color)
    return im


def screens():
    amber = (255, 150, 30)
    lines = ["WELL 73 // AMBER EXTRACTION", "-" * 30, "AUTO MODE ....... ENGAGED", "UPTIME ...... 41,882 DAYS",
             "FLOW ............ 41 L/MIN", "RESERVOIR ....... 84%", "LAST OPERATOR .. 41,880 D", "MAINTENANCE .... OVERDUE",
             "> LINE 2: UNKNOWN LOAD", "> AWAITING OPERATOR"]
    for tag, cur, gl in (("a", (8 + int(20 * 0.4) * 19, 6 + 9 * 18 + 3), None), ("b", None, 7)):
        _save_img(f"screen_term_{tag}.png", _crt(_text_screen(lines, 20, amber, cursor=cur), glitch_seed=gl))

    green = (90, 255, 120)
    rng = np.random.default_rng(21)
    for tag, val, seed in (("a", "41.2", 1), ("b", "43.0", 2)):
        r = np.random.default_rng(seed)
        im = Image.new("RGB", (256, 160), (1, 4, 2))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 4), "AMBER FLOW // W-73", font=_font("VT323-Regular.ttf", 18), fill=green)
        d.text((8, 22), val, font=_font("VT323-Regular.ttf", 50), fill=green)
        d.text((112, 50), "L/min", font=_font("VT323-Regular.ttf", 20), fill=green)
        for i in range(16):                                                        # pump pulse bars
            bh = int(6 + 34 * r.random() * (0.4 + i / 26))
            d.rectangle([120 + i * 8, 46 - bh, 125 + i * 8, 46], fill=green)
        pts = [(8 + i * 4, 110 + int(16 * math.sin(i * 0.35 + seed) + r.uniform(-5, 5))) for i in range(62)]
        d.line(pts, fill=green, width=1)
        d.line([(8, 110), (248, 110)], fill=(30, 90, 40))
        d.text((8, 138), "PURITY 97%   PRESSURE OK", font=_font("VT323-Regular.ttf", 16), fill=green)
        _save_img(f"screen_scan_{tag}.png", _crt(im, glitch_seed=None if tag == "a" else 9))

    n = rng.random((256, 256)) ** 1.6                                              # rolling static, cracked glass, NO SIGNAL card
    for y in range(256):
        if rng.random() < 0.06:
            n[y, :] = np.roll(n[y, :], int(rng.integers(0, 256)))
    im = Image.fromarray((n * 255).astype(np.uint8), "L").convert("RGB")
    d = ImageDraw.Draw(im)
    d.rectangle([28, 96, 228, 160], fill=(6, 8, 10))
    d.fontmode = "1"
    d.text((128, 116), "NO SIGNAL", font=_font("PressStart2P-Regular.ttf", 16), fill=(200, 210, 220), anchor="mm")
    d.text((128, 142), "CH 03 // CHECK ANTENNA", font=_font("VT323-Regular.ttf", 16), fill=(120, 130, 140), anchor="mm")
    for pts in ([(0, 30), (60, 70), (90, 110), (150, 140), (210, 200), (256, 226)], [(90, 110), (120, 60), (170, 20)]):
        d.line(pts, fill=(10, 10, 12), width=2)                                     # glass crack
    _save_img("screen_static.png", _crt(im, vignette=0.4, bloom=1.0))

    for tag in ("a", "b"):                                                          # pipeline map; the W-73 beacon blinks
        im = Image.new("RGB", (256, 160), (4, 3, 1))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 4), "PIPELINE MAP // SECTOR 04", font=_font("VT323-Regular.ttf", 18), fill=amber)
        nodes = {"HUB": (120, 84), "WELL-02": (186, 44), "WELL-03": (192, 118), "SILO": (56, 128)}
        me = (40, 56)
        for k, p in nodes.items():
            d.line([me if k == "HUB" else nodes["HUB"], p], fill=(120, 70, 15), width=1)
        for k, p in nodes.items():
            col = (255, 60, 40) if k == "SILO" else amber
            d.rectangle([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], outline=col)
            d.text((p[0] + 8, p[1] - 8), k, font=_font("VT323-Regular.ttf", 15), fill=col)
        d.ellipse([me[0] - 3, me[1] - 3, me[0] + 3, me[1] + 3], fill=(120, 255, 140) if tag == "a" else (10, 40, 15))
        d.text((me[0] - 10, me[1] + 6), "W-73", font=_font("VT323-Regular.ttf", 14), fill=(120, 255, 140))
        _save_img(f"screen_map_{tag}.png", _crt(im))

    for tag, out in (("a", "88%"), ("b", "91%")):                                   # pump controller LCD
        im = Image.new("RGB", (128, 64), (2, 6, 6))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((6, 4), "PUMP-02  RUN", font=_font("VT323-Regular.ttf", 20), fill=(90, 230, 210))
        d.text((6, 26), f"OUT {out}  T 61C", font=_font("VT323-Regular.ttf", 20), fill=(90, 230, 210))
        d.text((6, 46), "FUEL: AMBER (SELF)", font=_font("VT323-Regular.ttf", 14), fill=(255, 150, 30))
        _save_img(f"screen_gen_{tag}.png", _crt(im, vignette=0.3, bloom=0.8))


if __name__ == "__main__":
    concrete()
    concrete_top()
    floor()
    metal()
    plate()
    decal_streaks()
    decal_stencil()
    decal_hazard()
    decal_warning()
    decal_stain()
    decal_notes()
    decal_dust()
    decal_cobweb()
    decal_papers()
    decal_amber_crust()
    decal_crack()
    liquid_flow()
    liquid_pool()
    decal_drips_amber()
    screens()
