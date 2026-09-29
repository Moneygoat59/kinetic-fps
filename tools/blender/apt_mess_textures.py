"""Textures for the apartment gone to squalor (the flat after night 4: tools/blender/apt/mess.py, scripts/apartment/apt_squalor.gd).
Run: python tools/blender/apt_mess_textures.py   -> models/generated/tex/apt_mess.png, apt_grime_*.png
  apt_mess.png      4 x 4 atlas of 128 px prints (apt_dims.MESS): pizza box lid and greasy inside, takeout carton, chip bag,
                    four soda can wraps, a flyer, a receipt, an envelope, a past-due notice, a shipping label, a crust, a
                    grease-stained card, a tissue. Generic prints only: no brands, no story.
  apt_grime_*.png   RGBA decals Godot projects at runtime (AptSqualor): spill (sticky puddle with a dried tide line), rings
                    (cup and can rings), smudge (hand-high wall grime), mould (black speckle colonies), water (ceiling leak
                    stain), dust (floor film, tiles), crumbs (debris by the sofa and the table).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "apt"))
from textures import FONTS, ROOT, _fbm, _save_img  # noqa: E402
import apt_dims as D  # noqa: E402

CELL = 128
BOLD = os.path.join(ROOT, "tools", "asset_src", "fonts", "ArchivoBlack-Regular.ttf")
CONDENSED = os.path.join(ROOT, "tools", "asset_src", "fonts", "Anton-Regular.ttf")
SANS = os.path.join(ROOT, "tools", "asset_src", "fonts", "WorkSans[wght].ttf")
MONO = os.path.join(FONTS, "ShareTechMono-Regular.ttf")


def _f(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.truetype(os.path.join(FONTS, "ShareTechMono-Regular.ttf"), size)


def _stain(n, rng, cover=0.5, scale=((3, 0.4), (6, 0.35), (12, 0.25)), soft=1.5):
    """Organic blotch mask 0..1 inside the square (fades off at the edges so it never shows a border)."""
    y, x = np.mgrid[0:n, 0:n] / (n - 1) * 2 - 1
    edge = np.clip(1.0 - np.sqrt(x * x + y * y), 0, 1) ** 0.6
    f = _fbm(n, rng, scale) * edge
    m = np.clip((f - (1 - cover) * f.max()) / (0.12 + 1e-6), 0, 1)
    return np.asarray(Image.fromarray((m * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(soft)), np.float32) / 255


def _tide(mask):
    """A dried spill's darker rim: where the mask falls from full to empty."""
    g = np.abs(np.gradient(mask)[0]) + np.abs(np.gradient(mask)[1])
    return np.clip(g * 6.0, 0, 1)


def _rgba(rgb, alpha):
    a = np.dstack([np.broadcast_to(np.asarray(rgb, np.float32), alpha.shape + (3,)), alpha])
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")


def _grease(im, box, rng, count=3, alpha=110):
    """Translucent orange-brown grease blots on a print cell."""
    x0, y0, x1, y1 = box
    for _ in range(count):
        r = int(rng.uniform(8, 22))
        m = _stain(r * 2, rng, 0.6, soft=1.0)
        blot = _rgba((0.55, 0.32, 0.1), m * alpha / 255)
        im.alpha_composite(blot, (int(rng.uniform(x0, x1 - 2 * r)), int(rng.uniform(y0, y1 - 2 * r))))


def _lines(d, x0, y0, x1, rows, step, rng, fill, gap=0.25):
    """Rows of ragged grey text lines (print you cannot read at a glance)."""
    for i in range(rows):
        y = y0 + i * step
        x = x0
        while x < x1:
            w = int(rng.uniform(6, 22))
            d.rectangle([x, y, min(x + w, x1), y + max(1, step // 3)], fill=fill)
            x += w + int(rng.uniform(3, 6))
        if rng.random() < gap:
            x1 -= int(rng.uniform(0, 20))


def mess_atlas():
    rng = np.random.default_rng(404)
    im = Image.new("RGBA", (CELL * 4, CELL * 4), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    cell = {name: ((i % 4) * CELL, (i // 4) * CELL) for i, name in enumerate(D.MESS)}

    def box(name, pad=0):
        x, y = cell[name]
        return (x + pad, y + pad, x + CELL - 1 - pad, y + CELL - 1 - pad)

    def text(name, dy, s, font, fill, dx=0):
        x, y = cell[name]
        tw = d.textlength(s, font=font)
        d.text((x + (CELL - tw) / 2 + dx, y + dy), s, font=font, fill=fill)

    # pizza lid: white board, red band, big word, a checker stripe
    d.rectangle(box("pizza_lid"), fill=(236, 230, 214))
    x, y = cell["pizza_lid"]
    d.rectangle([x, y + 30, x + CELL, y + 86], fill=(178, 34, 30))
    text("pizza_lid", 34, "PIZZA", _f(BOLD, 30), (250, 244, 228))
    text("pizza_lid", 72, "HOT  &  FRESH", _f(SANS, 10), (250, 236, 200))
    for i in range(16):
        d.rectangle([x + i * 8, y + 96, x + i * 8 + 3, y + 100], fill=(30, 110, 60) if i % 2 else (178, 34, 30))
    text("pizza_lid", 106, "SMELLS LIKE HOME", _f(SANS, 9), (120, 60, 50))
    _grease(im, box("pizza_lid"), rng, 4)
    # pizza box inside: grey-brown card, big grease rings, burnt crumbs
    card = _fbm(CELL, rng) * 0.12 + 0.62
    x, y = cell["pizza_in"]
    im.paste(Image.fromarray((np.dstack([card * 0.82, card * 0.66, card * 0.47]) * 255).astype(np.uint8)), (x, y))
    _grease(im, box("pizza_in"), rng, 7, 150)
    for _ in range(60):
        cx, cy = x + rng.uniform(10, 118), y + rng.uniform(10, 118)
        r = rng.uniform(0.6, 2.2)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(int(rng.uniform(60, 140)), 40, 20))
    # takeout carton: white with a red border and a simple mark
    d.rectangle(box("carton"), fill=(242, 240, 234))
    x, y = cell["carton"]
    d.rectangle([x + 6, y + 6, x + 121, y + 121], outline=(190, 30, 30), width=3)
    d.polygon([(x + 64, y + 26), (x + 40, y + 50), (x + 88, y + 50)], fill=(190, 30, 30))
    d.rectangle([x + 46, y + 50, x + 82, y + 76], fill=(190, 30, 30))
    d.polygon([(x + 64, y + 58), (x + 36, y + 82), (x + 92, y + 82)], fill=(190, 30, 30))
    text("carton", 92, "THANK YOU", _f(BOLD, 14), (190, 30, 30))
    # chip bag: foil gradient, burst, word
    x, y = cell["chips"]
    for i in range(CELL):
        t = i / CELL
        d.line([(x, y + i), (x + CELL, y + i)], fill=(int(230 - 60 * t), int(170 - 90 * t), int(30 + 10 * t)))
    d.ellipse([x + 20, y + 20, x + 108, y + 100], fill=(200, 30, 24))
    text("chips", 40, "CHIPS", _f(BOLD, 24), (255, 230, 120))
    text("chips", 72, "SEA SALT", _f(SANS, 10), (255, 240, 200))
    for i in range(6):
        d.line([(x, y + 110 + i * 3), (x + CELL, y + 104 + i * 3)], fill=(255, 220, 90), width=1)
    # soda can wraps: colour field, sweep, vertical word
    for name, bg, fg, word in (("can_cola", (170, 20, 22), (250, 250, 250), "COLA"), ("can_lime", (40, 140, 60), (240, 255, 220), "LIME"),
                               ("can_energy", (24, 26, 34), (120, 255, 60), "VOLT"), ("can_orange", (240, 120, 20), (255, 250, 230), "ORANGE")):
        x, y = cell[name]
        d.rectangle(box(name), fill=bg)
        for i in range(CELL):
            s = int(18 * np.sin(i / CELL * np.pi * 2))
            d.point((x + i, y + 64 + s), fill=fg)
            d.point((x + i, y + 65 + s), fill=fg)
        font = _f(CONDENSED, 30 if len(word) < 6 else 17)
        for k in range(2):                                            # the word twice round the can
            tw = d.textlength(word, font=font)
            d.text((x + k * 64 + (64 - tw) / 2, y + 20), word, font=font, fill=fg)
        d.rectangle([x, y, x + CELL, y + 5], fill=(180, 182, 188))    # the bare metal at top and bottom
        d.rectangle([x, y + CELL - 6, x + CELL, y + CELL], fill=(180, 182, 188))
    # flyer: grey newsprint columns and a headline bar
    d.rectangle(box("flyer"), fill=(214, 210, 198))
    x, y = cell["flyer"]
    d.rectangle([x + 8, y + 8, x + 119, y + 26], fill=(40, 40, 44))
    text("flyer", 9, "EVERYTHING MUST GO", _f(SANS, 10), (240, 236, 220))
    _lines(d, x + 8, y + 34, x + 60, 14, 6, rng, (110, 108, 104))
    d.rectangle([x + 66, y + 34, x + 119, y + 76], fill=(150, 146, 136))
    _lines(d, x + 66, y + 82, x + 119, 7, 6, rng, (110, 108, 104))
    # receipt: white, thermal grey lines, a total
    d.rectangle(box("receipt"), fill=(246, 244, 238))
    x, y = cell["receipt"]
    _lines(d, x + 26, y + 10, x + 100, 12, 7, rng, (130, 130, 136), 0.5)
    d.text((x + 30, y + 100), "TOTAL", font=_f(MONO, 11), fill=(60, 60, 66))
    # envelope: white, address scribble, a stamp, window
    d.rectangle(box("envelope"), fill=(240, 238, 232))
    x, y = cell["envelope"]
    d.rectangle([x + 96, y + 30, x + 118, y + 52], fill=(160, 60, 70))
    d.rectangle([x + 20, y + 62, x + 90, y + 90], fill=(226, 230, 236), outline=(190, 196, 206))
    _lines(d, x + 26, y + 68, x + 84, 3, 7, rng, (70, 70, 80), 0.6)
    d.rectangle([x, y + 22, x + CELL, y + 24], fill=(220, 218, 210))
    # past-due notice: manila, a red stamp
    d.rectangle(box("notice"), fill=(214, 186, 132))
    x, y = cell["notice"]
    _lines(d, x + 14, y + 16, x + 110, 4, 7, rng, (120, 96, 60), 0.5)
    stamp = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stamp)
    sd.rectangle([18, 52, 110, 86], outline=(180, 30, 30, 220), width=3)
    tw = sd.textlength("PAST DUE", font=_f(BOLD, 17))
    sd.text(((CELL - tw) / 2, 56), "PAST DUE", font=_f(BOLD, 17), fill=(180, 30, 30, 220))
    im.alpha_composite(stamp.rotate(-11, resample=Image.BICUBIC), (x, y))
    # shipping label: white, barcode, lines
    d.rectangle(box("ship_label"), fill=(250, 250, 246))
    x, y = cell["ship_label"]
    for i in range(70):
        if rng.random() < 0.55:
            d.rectangle([x + 20 + i, y + 16, x + 20 + i, y + 50], fill=(20, 20, 22))
    _lines(d, x + 16, y + 62, x + 110, 6, 8, rng, (60, 60, 66), 0.4)
    # crust: baked dough, darker blisters
    x, y = cell["crust"]
    f = _fbm(CELL, rng, ((6, 0.5), (16, 0.3), (32, 0.2)))
    col = np.dstack([0.78 - 0.3 * f, 0.55 - 0.3 * f, 0.28 - 0.18 * f])
    im.paste(Image.fromarray((np.clip(col, 0, 1) * 255).astype(np.uint8)), (x, y))
    # grease-stained card (box sides, lids from underneath)
    x, y = cell["stain_card"]
    card = _fbm(CELL, rng) * 0.1 + 0.6
    im.paste(Image.fromarray((np.dstack([card * 0.8, card * 0.64, card * 0.44]) * 255).astype(np.uint8)), (x, y))
    _grease(im, box("stain_card"), rng, 5, 130)
    # tissue: soft white with faint quilting
    x, y = cell["tissue"]
    q = (np.sin(np.mgrid[0:CELL, 0:CELL][0] / 3.0) * np.sin(np.mgrid[0:CELL, 0:CELL][1] / 3.0)) * 0.03 + 0.93
    im.paste(Image.fromarray((np.dstack([q, q, q * 0.98]) * 255).astype(np.uint8)), (x, y))
    _save_img("apt_mess.png", im.convert("RGB"))


def grime():
    rng = np.random.default_rng(77)
    n = 256
    # spill: a sticky dark puddle, drier towards a darker tide line
    m = _stain(n, rng, 0.55, soft=2.0)
    alpha = np.clip(m * 0.55 + _tide(m) * 0.8, 0, 0.92)
    _save_img("apt_grime_spill.png", _rgba((0.22, 0.13, 0.05), alpha))
    # rings: overlapping cup and can rings, uneven, one half-wiped
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for _ in range(9):
        cx, cy, r = rng.uniform(50, 206), rng.uniform(50, 206), rng.uniform(22, 40)
        a = int(rng.uniform(90, 170))
        d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(70, 40, 18, a), width=int(rng.uniform(2, 5)))
    _save_img("apt_grime_rings.png", im.filter(ImageFilter.GaussianBlur(1.2)))
    # smudge: hand-high greasy grey-brown cloud with finger drags
    m = _stain(n, rng, 0.45, ((2, 0.5), (5, 0.3), (14, 0.2)), soft=6.0)
    streak = np.clip(_fbm(n, rng, ((2, 0.4), (40, 0.6))) - 0.45, 0, 1) * 1.6
    _save_img("apt_grime_smudge.png", _rgba((0.2, 0.17, 0.12), np.clip(m * 0.5 + m * streak * 0.4, 0, 0.8)))
    # mould: black speckle colonies, denser at the heart, green-black
    y, x = np.mgrid[0:n, 0:n] / (n - 1) * 2 - 1
    heart = np.clip(1 - np.sqrt(x * x + y * y) * 1.1, 0, 1)
    speck = (rng.random((n, n)) < heart ** 1.5 * 0.5).astype(np.float32)
    spots = np.asarray(Image.fromarray((speck * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3)), np.float32) / 255
    cloud = _stain(n, rng, 0.5, soft=4.0) * 0.55
    _save_img("apt_grime_mould.png", _rgba((0.05, 0.07, 0.04), np.clip(spots * heart * 0.95 + cloud * heart, 0, 0.95)))
    # water: a ceiling leak stain, yellow-brown tide rings, pale middle
    m = _stain(n, rng, 0.6, ((2, 0.6), (5, 0.3), (10, 0.1)), soft=3.0)
    rings = np.zeros_like(m)
    for lvl in (0.25, 0.5, 0.75, 0.9):
        rings = np.maximum(rings, np.clip(1 - np.abs(m - lvl) * 14, 0, 1) * (1.1 - lvl))
    _save_img("apt_grime_water.png", _rgba((0.45, 0.33, 0.14), np.clip(m * 0.28 + rings * 0.7, 0, 0.85)))
    # dust: soft floor film, patchy (tiled across a room)
    f = _fbm(n, rng, ((4, 0.5), (8, 0.3), (32, 0.2)))
    _save_img("apt_grime_dust.png", _rgba((0.3, 0.27, 0.22), np.clip((f - 0.15) * 1.1, 0, 0.72)))
    # crumbs: specks and flakes over a faint grease shadow
    im = _rgba((0.3, 0.2, 0.1), _stain(n, rng, 0.5, soft=8.0) * 0.25)
    d = ImageDraw.Draw(im)
    for _ in range(420):
        cx, cy = rng.normal(128, 55), rng.normal(128, 55)
        r = rng.uniform(0.6, 2.6)
        t = rng.uniform(0.0, 1.0)                                     # crust brown to burnt, never bright
        c = (int(70 + 110 * t), int(42 + 70 * t), int(18 + 34 * t), 255)
        d.ellipse([cx - r, cy - r * rng.uniform(0.5, 1), cx + r, cy + r], fill=c)
    _save_img("apt_grime_crumbs.png", im)
    # streaks: something that ran down a wall and dried (condensation under a sill, grease behind the hob, the bath wall):
    # a stained band at the top, drips of every length below it, thinning and fading as they go
    alpha = np.zeros((n, n), np.float32)
    top = _stain(n, rng, 0.55, ((3, 0.5), (8, 0.5)), soft=5.0) * np.clip(1.3 - np.mgrid[0:n, 0:n][0] / (n * 0.3), 0, 1)
    alpha += top * 0.75
    centres = rng.uniform(0.2, 0.8, 3) * n                              # drips run in a few clusters, not a comb
    for _ in range(38):
        x = int(np.clip(rng.normal(rng.choice(centres), n * 0.09), 6, n - 6))
        y0 = int(rng.uniform(n * 0.1, n * 0.28))
        ln = int(rng.uniform(n * 0.12, n * 0.7) * rng.uniform(0.4, 1.0))
        w0 = rng.uniform(0.8, 1.8)
        for y in range(y0, min(n - 4, y0 + ln)):
            k = 1.0 - (y - y0) / ln
            w = w0 * (0.35 + 0.65 * k)                                # thins as it runs
            xs = x + np.sin(y * 0.04 + x) * 1.5
            lo, hi = max(0, int(xs - w)), min(n, int(xs + w) + 1)
            alpha[y, lo:hi] = np.maximum(alpha[y, lo:hi], (0.18 + 0.36 * k) * rng.uniform(0.85, 1.0))
    alpha = np.asarray(Image.fromarray((np.clip(alpha, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.0)),
                       np.float32) / 255
    _save_img("apt_grime_streaks.png", _rgba((0.26, 0.2, 0.12), alpha))


if __name__ == "__main__":
    mess_atlas()
    grime()
