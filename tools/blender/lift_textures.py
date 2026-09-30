"""Textures for Missile Silo 00's freight lift cage and gates (tools/blender/props/silo_lift_cab.py, silo_lift_gate.py).
Opaque art laid on the cage's inside as quads with their own 0..1 UVs (node silo_lift_cab_art): obsidian steel with worn
amber paint left in the middle of the panels, diamond tread floor, ceiling with a scorched lamp ring and hatch; plus one
tileable hazard stripe for the gates' kick plates and the cage sills (a normal world-projected material).
Same art rules as the rest of the silo (matte purple-black steel, colour only from amber and rust, 200 years unattended)
but drawn at 128 px per metre with anti-aliased shapes and soft wear, so nothing reads as single bright pixels.
The control panel face and the capacity plate are in lift_fixtures.py.
Run: python tools/blender/lift_textures.py   -> models/generated/tex/lift_wall_a/b.png, lift_floor.png, lift_ceiling.png,
lift_hazard.png
"""
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from textures import _fbm, _font, _noise, _save, _scratches, _streaks

PPM = 128
SS = 3                                       # supersampling for drawn shapes
AMBER = np.array([0.150, 0.088, 0.020])      # worn amber paint
RUST = np.array([0.085, 0.036, 0.012])
HAZ_AMBER = np.array([0.20, 0.125, 0.018])
HAZ_BLACK = np.array([0.030, 0.027, 0.032])


def crop(a, h, w):
    return a[:h, :w]


def blur(a, r):
    im = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(r)), dtype=np.float32) / 255


def draw(w, h, fn):
    """Run fn(d, k) on a k-times canvas and average down: anti-aliased shapes as a 0..1 field."""
    im = Image.new("L", (w * SS, h * SS), 0)
    fn(ImageDraw.Draw(im), SS)
    return np.asarray(im.resize((w, h), Image.BOX), dtype=np.float32) / 255


def steel(h, w, rng, lum=0.10):
    """Purple-black painted steel: broad tone, a faint grain like the world's plates."""
    tone = crop(_fbm(max(h, w), rng, ((3, 0.4), (6, 0.3), (12, 0.2), (24, 0.1))), h, w)
    v = lum * (0.75 + 0.5 * tone) + rng.random((h, w)) * 0.005
    return np.stack([v, v * 0.92, v * 1.08], -1)


def wear_paint(img, rng, cover):
    """Amber paint that survived in patches, edges soft: cover = share of the field still painted."""
    h, w = img.shape[:2]
    m = crop(_fbm(max(h, w), rng, ((3, 0.35), (6, 0.3), (12, 0.2), (24, 0.15))), h, w)
    a = np.clip((m - (1 - cover)) * 5, 0, 1)[..., None]
    img[:] = img * (1 - a) + AMBER * (0.7 + 0.6 * m[..., None]) * a


def corners(img, edges=(True, True, True, True), depth=0.14):
    """Contact shading where surfaces meet (no baked AO on the cage): edges = (left, right, top, bottom)."""
    h, w = img.shape[:2]
    x, y = np.arange(w, dtype=np.float32), np.arange(h, dtype=np.float32)
    k = depth * PPM
    ao = np.ones((h, w), dtype=np.float32)
    for on, dist, axis in ((edges[0], x, 1), (edges[1], x[::-1], 1), (edges[2], y, 0), (edges[3], y[::-1], 0)):
        if on:
            f = 0.62 + 0.38 * np.clip(dist / k, 0, 1) ** 0.7
            ao *= f[None, :] if axis == 1 else f[:, None]
    img *= ao[..., None]


def grime(img, rng, low=0.55, drips=8):
    """Dirt pooling low, soft drip streaks from the top."""
    h, w = img.shape[:2]
    n = max(h, w)
    img *= (low + (1 - low) * (1 - np.linspace(0, 1, h)) ** 1.6)[:, None, None]
    d = np.zeros((n, n), dtype=np.float32)
    _streaks(d, rng, drips, h // 4, h // 2, -0.5, -0.9, 3)
    img *= (1 - 0.45 * blur(crop(d, h, w), 2.0))[..., None]
    img *= (0.88 + 0.24 * crop(_fbm(n, rng, ((6, 0.5), (12, 0.3), (24, 0.2))), h, w))[..., None]


def scuff(img, rng, count, hi=0.05):
    h, w = img.shape[:2]
    s = crop(_scratches(max(h, w), rng, count, 10, 60, hi * 0.4, hi), h, w)
    img += blur(s, 0.5)[..., None] * np.array([1.0, 0.86, 0.72])


def bolts(img, pts, r=2.6):
    """Bolt heads: a dark washer ring, a lit crown, a soft rust tear below. pts = [(x, y)] in pixels."""
    h, w = img.shape[:2]

    def ring(d, k):
        for x, y in pts:
            d.ellipse([(x - r) * k, (y - r) * k, (x + r) * k, (y + r) * k], fill=255)

    def crown(d, k):
        for x, y in pts:
            d.ellipse([(x - r * 0.55 - 0.5) * k, (y - r * 0.55 - 0.5) * k, (x + r * 0.55 - 0.5) * k, (y + r * 0.55 - 0.5) * k], fill=255)

    def tear(d, k):
        for x, y in pts:
            d.line([(x * k, (y + r) * k), (x * k, (y + r + 9) * k)], fill=150, width=int(1.6 * k))

    ringm, crownm, tearm = draw(w, h, ring), draw(w, h, crown), blur(draw(w, h, tear), 0.8)
    img *= (1 - 0.55 * ringm)[..., None]
    img += crownm[..., None] * np.array([0.05, 0.042, 0.038])
    img[:] = img * (1 - 0.5 * tearm[..., None]) + RUST * tearm[..., None] * 0.6


def seams(img, xs=(), ys=()):
    """Panel joints: a dark groove with a pale lip beside it, anti-aliased."""
    h, w = img.shape[:2]

    def groove(d, k):
        for x in xs:
            d.line([(x * k, 0), (x * k, h * k)], fill=255, width=int(2.5 * k))
        for y in ys:
            d.line([(0, y * k), (w * k, y * k)], fill=255, width=int(2.5 * k))

    def lip(d, k):
        for x in xs:
            d.line([((x - 3) * k, 0), ((x - 3) * k, h * k)], fill=255, width=int(1.2 * k))
        for y in ys:
            d.line([(0, (y - 3) * k), (w * k, (y - 3) * k)], fill=255, width=int(1.2 * k))

    img *= (1 - 0.7 * draw(w, h, groove))[..., None]
    img += draw(w, h, lip)[..., None] * np.array([0.03, 0.026, 0.024])


def stripes(shape, period, soft=1.6):
    """Diagonal hazard stripes as a 0..1 mask, soft edges (period in px along x)."""
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]]
    s = np.abs(((xx + yy) % period) - period / 2)
    return np.clip((period / 4 - s) / soft + 0.5, 0, 1)


def hazard(h, w, rng, period=32):
    """Dulled amber/black stripes with the paint mostly rubbed dirty: returns an (h, w, 3) field."""
    m = stripes((h, w), period)[..., None]
    img = HAZ_BLACK * (1 - m) + HAZ_AMBER * m
    dirt = crop(_fbm(max(h, w), rng, ((4, 0.4), (8, 0.3), (16, 0.2), (32, 0.1))), h, w)
    img *= (0.55 + 0.7 * dirt)[..., None]
    return img


def stencil(img, rng, text, size, x, y, colour=(0.34, 0.29, 0.22)):
    """Faded stencil lettering with soft flaking."""
    h, w = img.shape[:2]

    def glyphs(d, k):
        d.text((x * k, y * k), text, font=_font("Oxanium-SemiBold.ttf", size * k), fill=255, anchor="mm")

    a = draw(w, h, glyphs)
    flake = np.clip((crop(_fbm(max(h, w), rng, ((5, 0.4), (10, 0.3), (20, 0.3))), h, w) - 0.12) * 3, 0, 1)
    a = a * flake * 0.8
    img[:] = img * (1 - a[..., None]) + np.array(colour) * a[..., None]


def wall(name, seed, mark=None, w=416, h=320):
    """One side wall, 3.2 x 2.5 m: four panels (the cage's pilasters stand on the joints at the quarters, its cornice
    over the top 0.16 m), obsidian steel with amber paint left mid-panel, a hazard kick band, bolt rows, hand grease at
    rail height. Image right = frame +y on the -x wall, frame -y on the +x wall."""
    rng = np.random.default_rng(seed)
    img = steel(h, w, rng)
    wear_paint(img, rng, 0.34)
    kick = int(0.3 * PPM)
    img[h - kick:] = hazard(kick, w, rng)
    top = h - kick
    seams(img, xs=(w // 4, w // 2, 3 * w // 4), ys=(top, int(0.16 * PPM)))
    pts = [(x + s, y) for x in (w // 4, w // 2, 3 * w // 4) for s in (-15, 15) for y in range(30, top - 8, 34)]
    pts += [(x, int(0.16 * PPM) + 14) for x in range(20, w, 40)]
    bolts(img, pts)
    grease = crop(_noise(max(h, w), 10, rng), h, w) * np.exp(-(((np.arange(h) - h * 0.56) / 16.0) ** 2))[:, None]
    img *= (1 - 0.5 * blur(grease, 3))[..., None]
    grime(img, rng)
    scuff(img, rng, 46)
    if mark:
        stencil(img, rng, mark, 80, w * 3 // 8, int(h * 0.36))
    corners(img, (True, True, True, False))
    _save(name, np.clip(img, 0, 1))


def tread(n, rng):
    """Diamond tread plate, 24 px cells: rounded ridges, the upper-left edge lit, a shadow falling lower-right."""
    c = 24

    def ridges(d, k):
        for j in range(n // c):
            for i in range(n // c):
                x0, y0 = i * c, j * c
                a, b = ((x0 + 5, y0 + c - 5), (x0 + c - 5, y0 + 5)) if (i + j) % 2 == 0 else ((x0 + 5, y0 + 5), (x0 + c - 5, y0 + c - 5))
                d.line([(a[0] * k, a[1] * k), (b[0] * k, b[1] * k)], fill=255, width=int(4.4 * k))
                for p in (a, b):
                    d.ellipse([(p[0] - 2.2) * k, (p[1] - 2.2) * k, (p[0] + 2.2) * k, (p[1] + 2.2) * k], fill=255)

    r = draw(n, n, ridges)
    lit = np.clip(r - np.roll(r, (2, 2), (0, 1)), 0, 1)
    shade = np.clip(np.roll(r, (2, 2), (0, 1)) - r, 0, 1)
    return r, lit, shade


def floor(n=384, seed=201):
    """The cage floor, 3 x 3 m (image up = toward level 09, right = frame +x): tread worn smooth down the walking line,
    oil stains, a bolted edge angle, a maintenance hatch and a drain grate."""
    rng = np.random.default_rng(seed)
    r, lit, shade = tread(n, rng)
    base = 0.068 * (0.8 + 0.4 * crop(_fbm(n, rng), n, n)) + rng.random((n, n)) * 0.004
    lum = base * (1 - 0.45 * shade) + r * 0.05 + lit * 0.09
    x = np.arange(n)[None, :]
    path = np.exp(-(((x - n / 2) / (0.5 * PPM)) ** 2))
    smooth = 0.085 * (0.7 + 0.6 * crop(_fbm(n, rng), n, n))
    lum = lum * (1 - 0.65 * path) + smooth * 0.65 * path
    img = np.stack([lum * 1.05, lum * 0.94, lum * 1.02], -1)
    stain = np.clip((crop(_fbm(n, rng, ((3, 0.5), (6, 0.3), (12, 0.2))), n, n) - 0.66) * 5, 0, 1)
    img *= (1 - 0.5 * stain)[..., None]
    img += np.array([0.03, 0.012, 0.002]) * stain[..., None]

    def hatch(d, k):
        d.rectangle([60 * k, 260 * k, 150 * k, 350 * k], outline=255, width=int(2.6 * k))
        d.rectangle([92 * k, 300 * k, 118 * k, 310 * k], outline=255, width=int(1.4 * k))
        for gx in range(280, 344, 9):
            d.line([(gx * k, 48 * k), (gx * k, 92 * k)], fill=255, width=int(3 * k))

    img *= (1 - 0.6 * draw(n, n, hatch))[..., None]
    img[:, :22] = img[:, :22].mean() * np.array([0.8, 0.72, 0.72])
    img[:, -22:] = img[:, -22:].mean() * np.array([0.8, 0.72, 0.72])
    bolts(img, [(x0, y) for x0 in (11, n - 12) for y in range(24, n - 10, 48)], r=3.0)
    corners(img, depth=0.08)
    _save("lift_floor.png", np.clip(img, 0, 1))


def ceiling(n=384, h=372, seed=202):
    """The roof from below, 3 x 2.9 m (image up = toward level 09, right = frame -x): four panels, bolted seams, a lamp
    ring scorched round the fixture, an inspection hatch, condensation streaks."""
    rng = np.random.default_rng(seed)
    img = steel(h, n, rng, 0.075)
    wear_paint(img, rng, 0.18)
    seams(img, xs=(n // 2,), ys=(h // 2,))
    pts = [(n // 2 + s, p) for s in (-13, 13) for p in range(24, h, 34)] + [(p, h // 2 + s) for s in (-13, 13) for p in range(24, n, 34)]
    bolts(img, pts, r=2.4)
    yy, xx = np.mgrid[0:h, 0:n]
    soot = np.clip(1 - np.hypot(xx - n / 2, (yy - h / 2) * 1.4) / (0.95 * PPM), 0, 1) ** 0.8
    img *= (1 - 0.6 * soot)[..., None]

    def hatch(d, k):
        d.rectangle([36 * k, 250 * k, 138 * k, 352 * k], outline=255, width=int(2.6 * k))

    img *= (1 - 0.6 * draw(n, h, hatch))[..., None]
    bolts(img, [(46, 260), (128, 260), (46, 342), (128, 342)], r=3.0)
    grime(img, rng, low=0.72, drips=12)
    corners(img)
    _save("lift_ceiling.png", np.clip(img, 0, 1))


def gate_hazard(n=128, seed=203):
    """Tileable hazard stripe (1 m tile) for the gates' kick plates and the cage sills."""
    rng = np.random.default_rng(seed)
    img = hazard(n, n, rng)
    img += crop(_scratches(n, rng, 20, 8, 40, 0.01, 0.04), n, n)[..., None] * np.array([1.0, 0.86, 0.72])
    _save("lift_hazard.png", np.clip(img, 0, 1))


if __name__ == "__main__":
    wall("lift_wall_a.png", 211, "09")
    wall("lift_wall_b.png", 212)
    floor()
    ceiling()
    gate_hazard()
