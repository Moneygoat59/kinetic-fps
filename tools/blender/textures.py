"""Procedural pixel-art textures for the PS1 look (small, seamless, no external assets except the project's own fonts).
Run: python tools/blender/textures.py   -> models/generated/tex/*.png
Surfaces (sRGB, dark, warm-neutral): concrete, concrete_top, floor, metal, plate (+ scratches, dirt, cracks, streaks).
Decals (RGBA): decal_streaks, decal_stencil, decal_hazard, decal_warning, decal_stain, decal_notes.
Screens (emission, RGB): screen_term_a/b (amber terminal), screen_scan_a/b (green rad monitor), screen_static,
screen_map_a/b (site map), screen_gen_a/b (generator LCD). The *_a/_b pairs are flipped at runtime (bunker_screens.gd).
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(ROOT, "models", "generated", "tex")
FONTS = os.path.join(ROOT, "fonts")


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


def _streaks(lum, rng, count, minlen, maxlen, lo, hi, wmax=3):
    n = lum.shape[0]
    for _ in range(count):
        x, w = int(rng.integers(0, n)), int(rng.integers(1, wmax + 1))
        ln, y0 = int(rng.integers(minlen, maxlen)), int(rng.integers(0, n))
        s = rng.uniform(lo, hi)
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


# ------------------------------------------------------------------ surfaces
def concrete(n=256, seed=1):
    """Poured concrete, board-formed: 32 px boards (0.25 m), tie-holes, rain streaks, chips, cracks, scratches."""
    rng = np.random.default_rng(seed)
    lum = 0.115 + _fbm(n, rng) * 0.09 + rng.random((n, n)) * 0.03 + (_noise(n, 5, rng) - 0.5) * 0.05
    lum += np.repeat(rng.random((n, 1)), n, axis=1) * 0.02                      # horizontal formwork grain
    for b in range(n // 32):
        lum[b * 32:(b + 1) * 32, :] += rng.uniform(-0.015, 0.015)              # board-to-board tone
        lum[b * 32, :] -= 0.05                                                   # board seam
    _streaks(lum, rng, 46, 60, 220, 0.02, 0.07)
    for x in (64, 192):
        for y in (48, 176):                                                      # tie-holes with a lighter rim
            lum[y - 3:y + 4, x - 3:x + 4] += 0.03
            lum[y - 1:y + 2, x - 1:x + 2] -= 0.12
    lum[rng.random((n, n)) > 0.985] += 0.07                                      # exposed aggregate
    lum[rng.random((n, n)) > 0.99] -= 0.06                                       # pits
    _cracks(lum, rng, 3, 40, 110)
    lum += _scratches(n, rng, 34, 8, 40) * 0.6
    _save("concrete.png", _tint(lum, 1.03, 1.0, 0.95))


def concrete_top(n=128, seed=4):
    """Cornice / plinth / frames: smoother, dustier, water-stained."""
    rng = np.random.default_rng(seed)
    lum = 0.13 + _fbm(n, rng, ((8, 0.4), (16, 0.4), (32, 0.2))) * 0.08 + rng.random((n, n)) * 0.025
    lum -= (_noise(n, 3, rng) > 0.7) * 0.03
    _streaks(lum, rng, 14, 30, 100, 0.02, 0.05)
    _cracks(lum, rng, 2, 20, 70)
    lum += _scratches(n, rng, 12, 6, 30) * 0.5
    lum[n // 2, :] *= 0.75
    _save("concrete_top.png", _tint(lum, 1.03, 1.0, 0.96))


def floor(n=128, seed=2):
    rng = np.random.default_rng(seed)
    lum = 0.075 + _fbm(n, rng) * 0.075 + rng.random((n, n)) * 0.03
    img = _tint(lum, 1.02, 0.98, 0.93)
    stain = (_noise(n, 4, rng) > 0.66)[..., None]
    img = np.where(stain, img * 0.55, img)                                       # oil / damp stains
    img[::32, :] *= 0.55
    img[:, ::32] *= 0.55                                                         # slab joints
    img += _scratches(n, rng, 40, 6, 34, 0.03, 0.09, 1)[..., None] * 0.7         # scuffs
    _save("floor.png", img)


def metal(n=128, seed=3):
    """Painted dark steel: brushed grain, scratches, paint chips, rivets, sparse rust, bottom grime."""
    rng = np.random.default_rng(seed)
    lum = 0.11 + _fbm(n, rng, ((4, 0.6), (8, 0.4))) * 0.07 + rng.random((n, n)) * 0.02
    lum += np.repeat(rng.random((n, 1)), n, axis=1) * 0.02                       # brushed grain
    lum += _scratches(n, rng, 30, 6, 34, 0.04, 0.10) * 0.8
    lum[rng.random((n, n)) > 0.992] += 0.10                                      # paint chips
    img = _tint(lum, 1.05, 0.99, 0.93)
    img[0, :] *= 0.5
    img[:, 0] *= 0.5
    for x in (10, n - 11):
        for y in (10, n - 11):
            img[y - 1:y + 1, x - 1:x + 1] *= 1.9                                 # rivets
    rust = (_noise(n, 8, rng) > 0.9)[..., None]
    img = np.where(rust, img * np.array([1.45, 1.0, 0.72]), img)
    img *= (0.8 + 0.2 * np.linspace(0, 1, n))[:, None, None]
    _save("metal.png", img)


def plate(n=128, seed=5):
    """Interior wall plating: 64 px panels, seam grooves, bolts, drip streaks from the seams, scratches, grime."""
    rng = np.random.default_rng(seed)
    lum = 0.10 + _fbm(n, rng, ((4, 0.5), (8, 0.5))) * 0.06 + rng.random((n, n)) * 0.02
    for k in (0, 64):
        lum[k:k + 2, :] -= 0.05
        lum[:, k:k + 2] -= 0.05
        _streaks(lum, rng, 2, 30, 64, 0.03, 0.06, 2)
    img = _tint(lum, 1.04, 0.99, 0.92)
    for i in range(8, n, 16):
        for k in (5, 69):
            img[k, i] *= 1.9
    img += _scratches(n, rng, 30, 8, 44, 0.05, 0.13)[..., None] * 0.8
    img *= (0.75 + 0.25 * np.linspace(0, 1, n))[:, None, None]
    _save("plate.png", img)


# ------------------------------------------------------------------ decals (RGBA)
def _rgba(color, alpha):
    a = np.zeros(alpha.shape + (4,), dtype=np.float32)
    a[..., 0], a[..., 1], a[..., 2], a[..., 3] = color[0], color[1], color[2], alpha
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")


def decal_streaks(w=128, h=256, seed=11):
    """Vertical rain/dirt streaks (dark, translucent) for the walls under the cornice and window sills."""
    rng = np.random.default_rng(seed)
    a = np.zeros((h, w), dtype=np.float32)
    for _ in range(18):
        x, ww = int(rng.integers(0, w - 8)), int(rng.integers(2, 9))
        ln = int(rng.integers(60, h))
        s = rng.uniform(0.10, 0.42)
        for yy in range(ln):
            a[yy, x:x + ww] = np.maximum(a[yy, x:x + ww], s * (1 - yy / ln) ** 0.8 * (0.7 + 0.3 * rng.random()))
    a[:20, :] *= np.linspace(0.4, 1, 20)[:, None]
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.8)), dtype=np.float32) / 255
    _save_img("decal_streaks.png", _rgba((0.02, 0.018, 0.015), a))


def decal_stencil(w=128, h=192, seed=12):
    """Worn stencil lettering: small 'OUTPOST' over a big '73', with stencil bridges and paint wear."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    f_small, f_big = _font("Oxanium-SemiBold.ttf", 22), _font("Oxanium-SemiBold.ttf", 120)
    d.text((w // 2, 14), "OUTPOST", font=f_small, fill=255, anchor="mt")
    d.text((w // 2, 112), "73", font=f_big, fill=255, anchor="mm")
    for y in (118, 150):                                                         # stencil bridges
        d.rectangle([0, y, w, y + 3], fill=0)
    d.rectangle([w // 2 - 2, 60, w // 2 + 2, h], fill=0)
    a = np.asarray(im, dtype=np.float32) / 255
    a *= np.clip(0.45 + 1.4 * _noise(w, 6, rng)[:h, :w] if w >= h else 0.45 + 1.4 * np.resize(_noise(w, 6, rng), (h, w)), 0, 1)
    a *= (rng.random((h, w)) > 0.12)                                             # paint flakes
    _save_img("decal_stencil.png", _rgba((0.62, 0.6, 0.55), a * 0.9))


def decal_hazard(w=256, h=32, seed=13):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w]
    stripe = (((xx + yy) // 16) % 2 == 0)
    col = np.where(stripe[..., None], np.array([0.72, 0.56, 0.05]), np.array([0.03, 0.03, 0.03]))
    a = np.clip(0.55 + 1.2 * np.resize(_noise(max(w, h), 5, rng), (h, w)) - 0.5, 0, 1) * (rng.random((h, w)) > 0.08)
    a[:2, :] = a[-2:, :] = 0.95
    im = np.dstack([col, a]).astype(np.float32)
    _save_img("decal_hazard.png", Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8), "RGBA"))


def decal_warning(w=96, h=128, seed=14):
    """Radiation warning sign: yellow plate, black border, trefoil, small caption."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([2, 2, w - 3, h - 3], 6, fill=(190, 150, 20, 255), outline=(15, 15, 15, 255), width=3)
    cx, cy, r = w // 2, 50, 30
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(15, 15, 15, 255))
    for a0 in (30, 150, 270):
        d.pieslice([cx - r + 4, cy - r + 4, cx + r - 4, cy + r - 4], a0, a0 + 60, fill=(190, 150, 20, 255))
    d.ellipse([cx - 9, cy - 9, cx + 9, cy + 9], fill=(190, 150, 20, 255))
    d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=(15, 15, 15, 255))
    d.text((w // 2, 100), "RADIATION", font=_font("Silkscreen-Regular.ttf", 12), fill=(15, 15, 15, 255), anchor="mm")
    d.text((w // 2, 115), "AREA", font=_font("Silkscreen-Regular.ttf", 10), fill=(15, 15, 15, 255), anchor="mm")
    arr = np.asarray(im, dtype=np.float32) / 255
    arr[..., :3] *= (0.7 + 0.3 * np.resize(_noise(128, 6, rng), (h, w)))[..., None]     # grime
    arr[..., 3] *= (rng.random((h, w)) > 0.03)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_warning.png"))
    print("TEX decal_warning.png")


def decal_stain(n=128, seed=15):
    """Soft irregular stain blob (damp / oil)."""
    rng = np.random.default_rng(seed)
    f = _fbm(n, rng, ((3, 0.5), (6, 0.3), (12, 0.2)))
    yy, xx = np.mgrid[0:n, 0:n]
    fall = np.clip(1 - np.hypot(xx - n / 2, yy - n / 2) / (n * 0.48), 0, 1)
    a = np.clip((f * fall - 0.28) * 2.2, 0, 0.6)
    _save_img("decal_stain.png", _rgba((0.015, 0.012, 0.008), a))


def decal_notes(w=256, h=128, seed=16):
    """Pinned paper notes with handwriting: a spooky shift log."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sheets = [((6, 4), (80, 118), -3, ["SHIFT LOG", "D38 nothing", "D39 nothing", "D40 hum in", "the walls", "D41 its at", "the door"], "Caveat-Regular.ttf", 12),
              ((90, 14), (76, 60), 2, ["SUPPLY DROP", "MISSED AGAIN", "3rd time"], "ReenieBeanie.ttf", 13),
              ((170, 6), (84, 112), -1, ["DO NOT", "OPEN AFTER", "DARK", "", "keys in the", "tracker.", "take it &", "GO. NOW."], "PermanentMarker.ttf", 9)]
    for (x, y), (sw, sh), rot, lines, fnt, fsz in sheets:
        p = Image.new("RGBA", (sw, sh), (176, 168, 140, 255))
        pd = ImageDraw.Draw(p)
        pd.rectangle([0, 0, sw - 1, sh - 1], outline=(110, 100, 80, 255))
        pd.ellipse([sw // 2 - 3, 2, sw // 2 + 3, 8], fill=(150, 30, 20, 255))            # pin
        for i, ln in enumerate(lines):
            pd.text((6, 12 + i * (fsz + 2)), ln, font=_font(fnt, fsz), fill=(30, 26, 22, 255))
        p = p.rotate(rot, expand=True, resample=Image.BICUBIC)
        im.alpha_composite(p, (x, y))
    arr = np.asarray(im, dtype=np.float32) / 255
    arr[..., :3] *= (0.55 + 0.4 * np.resize(_noise(256, 8, rng), (h, w)))[..., None]    # grubby
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "decal_notes.png"))
    print("TEX decal_notes.png")


# ------------------------------------------------------------------ screens (emission)
def _crt(im, color=(1.0, 0.6, 0.15), vignette=0.55, bloom=1.6):
    """Phosphor look: bloom, scanlines, edge vignette, a touch of noise."""
    a = np.asarray(im.convert("RGB"), dtype=np.float32) / 255
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
    lines = ["OUTPOST 73 // AUTO-STATION", "-" * 30, "UPLINK .......... OFFLINE", "MAIN PWR ........ 12% (BAK)",
             "BLAST DOOR ...... SEALED", "RAD SHIELD ...... NOMINAL", "LAST OPERATOR ... 04:17", "",
             "> DOSIMETER ISSUE PENDING", "> AWAITING OPERATOR"]
    for tag, cur in (("a", (8 + int(20 * 0.4) * 19, 6 + 9 * 18 + 3)), ("b", None)):
        im = _text_screen(lines, 20, amber, cursor=cur)
        _save_img(f"screen_term_{tag}.png", _crt(im))

    green = (90, 255, 120)
    rng = np.random.default_rng(21)
    for tag, val, seed in (("a", "0.42", 1), ("b", "0.47", 2)):
        r = np.random.default_rng(seed)
        im = Image.new("RGB", (256, 160), (1, 4, 2))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 4), "RAD MONITOR // CH-01", font=_font("VT323-Regular.ttf", 18), fill=green)
        d.text((8, 22), val, font=_font("VT323-Regular.ttf", 54), fill=green)
        d.text((104, 50), "mSv/h", font=_font("VT323-Regular.ttf", 20), fill=green)
        for i in range(16):                                                        # bar graph
            bh = int(6 + 34 * r.random() * (0.4 + i / 26))
            d.rectangle([120 + i * 8, 46 - bh, 125 + i * 8, 46], fill=green)
        pts = [(8 + i * 4, 110 + int(16 * math.sin(i * 0.35 + seed) + r.uniform(-5, 5))) for i in range(62)]
        d.line(pts, fill=green, width=1)
        d.line([(8, 110), (248, 110)], fill=(30, 90, 40))
        d.text((8, 138), "SECTOR SCAN: NO CONTACTS", font=_font("VT323-Regular.ttf", 16), fill=green)
        _save_img(f"screen_scan_{tag}.png", _crt(im))

    im = Image.new("L", (256, 256), 0)                                             # rolling static with a NO SIGNAL card
    n = rng.random((256, 256)) ** 1.6
    for y in range(0, 256, 1):
        if rng.random() < 0.06:
            n[y, :] = np.roll(n[y, :], int(rng.integers(0, 256)))
    im = Image.fromarray((n * 255).astype(np.uint8), "L").convert("RGB")
    d = ImageDraw.Draw(im)
    d.rectangle([28, 96, 228, 160], fill=(6, 8, 10))
    d.fontmode = "1"
    d.text((128, 116), "NO SIGNAL", font=_font("PressStart2P-Regular.ttf", 16), fill=(200, 210, 220), anchor="mm")
    d.text((128, 142), "CH 03 // CHECK ANTENNA", font=_font("VT323-Regular.ttf", 16), fill=(120, 130, 140), anchor="mm")
    _save_img("screen_static.png", _crt(im, vignette=0.4, bloom=1.0))

    for tag in ("a", "b"):                                                          # site map, beacon blinks between frames
        im = Image.new("RGB", (256, 160), (4, 3, 1))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 4), "SITE MAP // SECTOR 04", font=_font("VT323-Regular.ttf", 18), fill=amber)
        nodes = {"HUB": (120, 84), "OUT-02": (190, 44), "OUT-03": (198, 118), "SILO": (56, 128)}
        me = (40, 56)
        for k, p in nodes.items():
            d.line([me if k == "HUB" else nodes["HUB"], p], fill=(120, 70, 15), width=1)
        for k, p in nodes.items():
            col = (255, 60, 40) if k == "SILO" else amber
            d.rectangle([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], outline=col)
            d.text((p[0] + 8, p[1] - 8), k, font=_font("VT323-Regular.ttf", 15), fill=col)
        d.ellipse([me[0] - 3, me[1] - 3, me[0] + 3, me[1] + 3], fill=(120, 255, 140) if tag == "a" else (10, 40, 15))
        d.text((me[0] - 8, me[1] + 6), "YOU", font=_font("VT323-Regular.ttf", 14), fill=(120, 255, 140))
        _save_img(f"screen_map_{tag}.png", _crt(im))

    for tag, out in (("a", "3%"), ("b", "4%")):                                     # generator LCD
        im = Image.new("RGB", (128, 64), (2, 6, 6))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((6, 4), "GEN-02  IDLE", font=_font("VT323-Regular.ttf", 20), fill=(90, 230, 210))
        d.text((6, 26), f"OUT {out}  T 41C", font=_font("VT323-Regular.ttf", 20), fill=(90, 230, 210))
        d.text((6, 46), "FUEL 18%  LOW", font=_font("VT323-Regular.ttf", 14), fill=(255, 150, 30))
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
    screens()
