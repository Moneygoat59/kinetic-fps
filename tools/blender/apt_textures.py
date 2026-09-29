"""Procedural pixel-art textures for the apartment kit (tools/blender/apt/): warm, clean, lived-in-by-one-person domestic surfaces.
Run: python tools/blender/apt_textures.py   -> models/generated/tex/apt_*.png   (reuses the helpers of textures.py)
Surfaces (seamless, sRGB): wood_floor, paint, ceiling, tile_subway, tile_hex, tile_bath, checker, wood, wood_light, fabric,
linen, knit, counter, steel.  Atlases / one-offs: rug, view (window backdrop), art (4 framed pictures), labels (label-maker
tape), rx (4 pharmacy labels), organizer (7-day lids), cans (can labels), clock, alarm_a/b (LED), tv, towel, curtain, tape,
tape_blue, tally, pencil (level lines).  Atlas cell layouts are mirrored in tools/blender/apt/apt_dims.py.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "apt"))
from textures import _fbm, _font, _noise, _save, _save_img  # noqa: E402
import apt_dims as D  # noqa: E402


def _aniso(n, ku, kv, rng):
    """Seamless noise stretched along u (few cells across, many down): wood grain, brushed steel, weave."""
    g = rng.random((kv, ku)).astype(np.float32)
    big = np.tile(g, (3, 3))
    im = Image.fromarray((big * 255).astype(np.uint8)).resize((3 * n, 3 * n), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32)[n:2 * n, n:2 * n] / 255.0


def _rgb(lum, base, var=None):
    var = var if var is not None else lum
    return np.stack([base[0] * (0.8 + 0.4 * var), base[1] * (0.8 + 0.4 * var), base[2] * (0.8 + 0.4 * var)], -1) * lum[..., None]


def _grain(n, rng, rows, base, contrast=0.35, seams=True):
    """Plank field: `rows` planks across v, grain along u, staggered end joints, per-plank tone (seams=False: furniture boards)."""
    out = np.zeros((n, n, 3), np.float32)
    grain = _aniso(n, 3, 48, rng)
    fine = _aniso(n, 8, 96, rng)
    h = n // rows
    for r in range(rows):
        tone = rng.uniform(0.82, 1.12) if seams else 1.0
        hue = rng.uniform(-0.04, 0.04) if seams else 0.0
        joint = int(rng.integers(0, n))
        band = slice(r * h, (r + 1) * h)
        lum = (1 - contrast) + contrast * (0.6 * grain[band] + 0.4 * fine[band])
        col = np.array([base[0] * (1 + hue), base[1], base[2] * (1 - hue)]) * tone
        out[band] = lum[..., None] * col
        if not seams:
            continue
        out[r * h, :] *= 0.55                                          # seam between planks
        out[band, joint] *= 0.6                                        # end joint
        out[band, (joint + n // 2 + int(rng.integers(-8, 8))) % n] *= 0.65
    return out


def surfaces():
    rng = np.random.default_rng(101)
    _save("apt_wood_floor.png", _grain(128, rng, 8, (0.72, 0.48, 0.27)))          # honey oak, 8 planks per metre
    _save("apt_wood.png", _grain(64, rng, 2, (0.46, 0.28, 0.16), 0.3, False))           # walnut furniture
    _save("apt_wood_light.png", _grain(64, rng, 2, (0.86, 0.72, 0.52), 0.22, False))    # birch / pine
    n = _fbm(64, rng)
    _save("apt_paint.png", np.stack([0.93 + 0.05 * n] * 3, -1))                  # tinted per room by the material
    _save("apt_ceiling.png", np.stack([0.95 + 0.04 * (rng.random((64, 64)) > 0.7)] * 3, -1))
    _save("apt_tile_subway.png", _tiles(64, 2, 4, (0.94, 0.93, 0.9), (0.72, 0.7, 0.66), rng, brick=True))
    _save("apt_tile_bath.png", _tiles(64, 4, 4, (0.72, 0.86, 0.8), (0.9, 0.92, 0.88), rng))
    _save("apt_checker.png", _checker(64, 4, (0.93, 0.9, 0.82), (0.55, 0.66, 0.58), rng))
    _save("apt_tile_hex.png", _hex(64, rng))
    _save("apt_fabric.png", _weave(64, rng, 0.07))
    _save("apt_linen.png", _weave(64, rng, 0.04))
    k = _aniso(64, 16, 16, rng)
    rows = (np.sin(np.arange(64) * math.pi / 2)[:, None] > 0) * 0.08
    _save("apt_knit.png", np.stack([0.84 + 0.12 * k - rows] * 3, -1))
    c = rng.random((256, 256))                                                      # fine speckle: 2 mm grains, not a mosaic
    speck = 0.86 + 0.08 * _fbm(256, rng) - 0.22 * (c > 0.94) + 0.08 * (c < 0.05) - 0.1 * (c > 0.985)
    _save("apt_counter.png", _rgb(speck, (0.88, 0.85, 0.8), np.ones_like(speck)))
    b = _aniso(64, 2, 64, rng)
    _save("apt_steel.png", np.stack([0.7 + 0.12 * b] * 3, -1) * np.array([0.97, 0.98, 1.0]))


def _tiles(n, cols, rows, fill, grout, rng, brick=False):
    out = np.zeros((n, n, 3), np.float32)
    tw, th = n // cols, n // rows
    for r in range(rows):
        off = tw // 2 if brick and r % 2 else 0
        for q in range(cols + 1):
            x0 = q * tw - off
            tone = rng.uniform(0.95, 1.04)
            for x in range(max(0, x0), min(n, x0 + tw)):
                out[r * th:(r + 1) * th, x] = np.array(fill) * tone
        out[r * th, :] = grout
        for q in range(cols + 1):
            out[r * th:(r + 1) * th, (q * tw - off) % n] = grout
    out[:, :, :] += (rng.random((n, n, 1)) - 0.5) * 0.02
    return out


def _checker(n, k, a, b, rng):
    yy, xx = np.mgrid[0:n, 0:n] // (n // k)
    out = np.where(((xx + yy) % 2 == 0)[..., None], np.array(a), np.array(b)).astype(np.float32)
    return out * (0.97 + 0.03 * _fbm(n, rng))[..., None]


def _hex(n, rng):
    """Small white penny/hex bathroom floor tile (approximated by offset circles on a grout ground)."""
    im = Image.new("RGB", (n, n), (150, 150, 146))
    d = ImageDraw.Draw(im)
    s = n // 8
    for r in range(-1, 9):
        for q in range(-1, 9):
            cx, cy = q * s + (s // 2 if r % 2 else 0), r * s
            v = int(232 + rng.integers(-8, 8))
            d.regular_polygon((cx, cy, s // 2 - 1), 6, fill=(v, v, v - 4))
    return np.asarray(im, dtype=np.float32) / 255


def _weave(n, rng, depth):
    yy, xx = np.mgrid[0:n, 0:n]
    w = ((xx // 2 + yy // 2) % 2) * depth
    return np.stack([1 - depth + w + 0.06 * _noise(n, 16, rng)] * 3, -1)


def rug(w=128, h=192):
    """Living-room rug: muted terracotta field, cream border, a quiet diamond medallion. Perfectly symmetric, of course."""
    im = Image.new("RGB", (w, h), (150, 74, 52))
    d = ImageDraw.Draw(im)
    for i, col in enumerate([(226, 208, 176), (60, 70, 88), (226, 208, 176)]):
        m = 4 + i * 5
        d.rectangle([m, m, w - 1 - m, h - 1 - m], outline=col, width=3 if i == 1 else 2)
    cx, cy = w // 2, h // 2
    for r, col in ((40, (226, 208, 176)), (30, (60, 70, 88)), (18, (196, 120, 70)), (8, (226, 208, 176))):
        d.polygon([(cx, cy - r * 1.4), (cx + r, cy), (cx, cy + r * 1.4), (cx - r, cy)], fill=col)
    for sy in (-1, 1):
        for sx in (-1, 1):
            x, y = cx + sx * 36, cy + sy * 62
            d.polygon([(x, y - 8), (x + 6, y), (x, y + 8), (x - 6, y)], fill=(226, 208, 176))
    a = np.asarray(im, dtype=np.float32) / 255
    _save("apt_rug.png", a * (0.92 + 0.08 * np.random.default_rng(5).random((h, w, 1))))


def view(w=512, h=256):
    """Window backdrop (emission): golden-hour sky over the block across the street. Top = sky, bottom = facades."""
    rng = np.random.default_rng(7)
    yy = np.linspace(0, 1, h)[:, None, None]
    sky = (1 - yy) * np.array([0.98, 0.72, 0.42]) + yy * np.array([1.0, 0.86, 0.62])
    sky = np.broadcast_to(sky, (h, w, 3)).copy()
    sky[: h // 3] = sky[: h // 3] * 0.85 + np.array([0.55, 0.6, 0.78]) * 0.15 * (1 - np.linspace(0, 1, h // 3))[:, None, None]
    cl = _fbm(w, rng)[:h]
    sky += (cl > 0.62)[..., None] * np.array([0.08, 0.02, -0.04])
    im = Image.fromarray((np.clip(sky, 0, 1) * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    x = 0
    while x < w:
        bw, top = int(rng.integers(40, 90)), int(rng.integers(int(h * 0.3), int(h * 0.6)))
        tone = int(rng.integers(0, 3))
        face = [(118, 70, 58), (96, 72, 70), (132, 96, 74)][tone]
        d.rectangle([x, top, x + bw, h], fill=face)
        d.rectangle([x, top, x + bw, top + 3], fill=tuple(int(c * 0.7) for c in face))
        for wy in range(top + 10, h - 4, 14):
            for wx in range(x + 6, x + bw - 8, 12):
                lit = rng.random()
                col = (255, 200, 120) if lit > 0.82 else (tuple(int(c * 0.55) for c in face) if lit > 0.3 else (70, 64, 70))
                d.rectangle([wx, wy, wx + 5, wy + 7], fill=col)
        x += bw + int(rng.integers(0, 6))
    d.ellipse([w * 0.12 - 18, h * 0.26 - 18, w * 0.12 + 18, h * 0.26 + 18], fill=(255, 236, 190))   # the low sun
    _save_img("apt_view.png", im.filter(ImageFilter.GaussianBlur(0.6)))


def art():
    """Four framed prints in a 2x2 atlas (apt_dims.ART_CELLS): calm, symmetric subjects."""
    s = 64
    im = Image.new("RGB", (2 * s, 2 * s), (240, 234, 222))
    d = ImageDraw.Draw(im)
    d.rectangle([4, 4, 59, 59], fill=(178, 196, 204))                                     # 0 sea horizon
    d.rectangle([4, 36, 59, 59], fill=(62, 96, 120))
    d.ellipse([24, 18, 40, 34], fill=(248, 214, 150))
    ox = s                                                                                  # 1 single tree
    d.rectangle([ox + 4, 4, ox + 59, 59], fill=(222, 214, 196))
    d.rectangle([ox + 30, 34, ox + 33, 52], fill=(90, 70, 52))
    d.ellipse([ox + 18, 12, ox + 46, 40], fill=(108, 140, 96))
    oy = s                                                                                  # 2 concentric squares
    for i, col in enumerate([(196, 120, 78), (232, 204, 160), (82, 106, 124), (232, 204, 160)]):
        d.rectangle([4 + i * 7, oy + 4 + i * 7, 59 - i * 7, oy + 59 - i * 7], fill=col)
    d.rectangle([ox + 4, oy + 4, ox + 59, oy + 59], fill=(236, 226, 206))                 # 3 botanical: one leaf
    d.line([(ox + 32, oy + 54), (ox + 32, oy + 12)], fill=(80, 110, 70), width=2)
    for k in range(5):
        y = oy + 18 + k * 7
        d.polygon([(ox + 32, y), (ox + 46 - k, y - 6), (ox + 34, y + 3)], fill=(110, 146, 92))
        d.polygon([(ox + 32, y), (ox + 18 + k, y - 6), (ox + 30, y + 3)], fill=(110, 146, 92))
    _save_img("apt_art.png", im)


def _atlas_text(name, cells, size, bg, fg, font, fsize, pad=3):
    """Horizontal strips: one text cell per row (cells = list of strings), each size=(w, h) px."""
    w, h = size
    im = Image.new("RGBA", (w, h * len(cells)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f = _font(font, fsize)
    for i, t in enumerate(cells):
        y = i * h
        d.rounded_rectangle([0, y + 1, w - 1, y + h - 2], radius=2, fill=bg)
        tw = d.textlength(t, font=f)
        d.text(((w - tw) / 2, y + pad), t, font=f, fill=fg)
    _save_img(name, im)


def labels():
    """Label-maker tape: black with white caps. Every drawer, shelf and jar in the flat has one."""
    _atlas_text("apt_labels.png", D.LABELS, (64, 12), (20, 20, 22, 255), (236, 236, 230, 255), "Silkscreen-Regular.ttf", 8, 1)


def rx():
    """Pharmacy labels wrapped round the pill bottles (apt_dims.RX): white, blue header, name, directions, refill line."""
    w, h = 128, 40
    im = Image.new("RGBA", (w, h * len(D.RX)), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f8, f6 = _font("Silkscreen-Regular.ttf", 8), _font("ShareTechMono-Regular.ttf", 9)
    for i, (drug, dose, sig) in enumerate(D.RX):
        y = i * h
        d.rectangle([0, y, w - 1, y + h - 1], fill=(246, 244, 238, 255))
        d.rectangle([0, y, w - 1, y + 9], fill=(52, 84, 140, 255))
        d.text((4, y), "PHARMACY  RX 0%d4471" % (i + 3), font=f8, fill=(236, 240, 250, 255))
        d.text((4, y + 11), f"{drug} {dose}", font=f8, fill=(24, 24, 28, 255))
        d.text((4, y + 21), sig, font=f6, fill=(60, 60, 66, 255))
        d.text((4, y + 30), "REFILLS: 0", font=f6, fill=(150, 40, 40, 255))
    _save_img("apt_rx.png", im)


def organizer():
    """Seven lid tops S M T W T F S on translucent colours (one cell per day, 16 x 16)."""
    cols = [(210, 80, 80), (230, 150, 60), (230, 210, 80), (100, 180, 100), (80, 160, 200), (110, 110, 200), (170, 100, 190)]
    im = Image.new("RGB", (16 * 7, 16), (0, 0, 0))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f = _font("Silkscreen-Regular.ttf", 8)
    for i, (day, c) in enumerate(zip("SMTWTFS", cols)):
        d.rectangle([i * 16, 0, i * 16 + 15, 15], fill=c)
        d.text((i * 16 + 5, 3), day, font=f, fill=(250, 250, 250))
    _save_img("apt_organizer.png", im)


def cans():
    """Can label bands (apt_dims.CANS), one row each: colour field, a white oval, a stripe."""
    w, h = 64, 16
    im = Image.new("RGB", (w, h * len(D.CANS)), (0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, c in enumerate(D.CANS):
        y = i * h
        d.rectangle([0, y, w, y + h], fill=c)
        d.rectangle([0, y + 1, w, y + 2], fill=(240, 232, 210))
        d.rectangle([0, y + h - 3, w, y + h - 2], fill=(240, 232, 210))
        d.ellipse([w // 2 - 9, y + 4, w // 2 + 9, y + 12], fill=(246, 240, 228))
    _save_img("apt_cans.png", im)


def clock():
    """Dial mapped onto a round face (apt_shapes.disc): the circle fills the image; minute marks, heavier hours, no numerals."""
    n, c = 128, 64
    im = Image.new("RGB", (n, n), (236, 230, 216))
    d = ImageDraw.Draw(im)
    d.ellipse([1, 1, n - 2, n - 2], outline=(200, 192, 176), width=3)
    for k in range(60):
        a = k * math.pi / 30
        r0, r1, wid = (46, 58, 3) if k % 5 == 0 else (54, 58, 1)
        if k % 15 == 0:
            r0 = 40
        d.line([(c + r0 * math.sin(a), c - r0 * math.cos(a)), (c + r1 * math.sin(a), c - r1 * math.cos(a))], fill=(38, 36, 34), width=wid)
    _save_img("apt_clock.png", im)
    f = _font("VT323-Regular.ttf", 30)
    for tag, text in (("a", "6:59"), ("b", "6 59")):
        im = Image.new("RGB", (64, 32), (6, 2, 2))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((6, 0), text, font=f, fill=(255, 60, 40))
        _save_img(f"apt_alarm_{tag}.png", im)


def misc():
    rng = np.random.default_rng(11)
    tv = np.zeros((64, 64, 3), np.float32) + 0.04
    tv[:, :] += np.linspace(0.05, 0, 64)[None, :, None] * np.linspace(0.06, 0, 64)[:, None, None] * 10
    _save("apt_tv.png", tv)
    yy = np.arange(64)[:, None]
    stripe = ((yy // 6) % 5 == 0) * 0.18
    _save("apt_towel.png", np.stack([0.86 - stripe + 0.05 * _aniso(64, 32, 4, rng)] * 3, -1) * np.array([1.0, 0.98, 0.94]))
    xx = np.arange(64)[None, :]
    pleat = 0.9 + 0.1 * np.sin(xx * math.pi / 8)
    _save("apt_curtain.png", np.broadcast_to(np.stack([pleat * 0.92, pleat * 0.96, pleat], -1), (64, 64, 3)))
    # masking tape strip (beige, torn ends) and painter's tape (blue)
    for name, col in (("apt_tape.png", (222, 204, 160)), ("apt_tape_blue.png", (78, 132, 200))):
        im = Image.new("RGBA", (64, 16), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.polygon([(2, 1), (61, 2), (63, 8), (61, 14), (1, 15), (0, 8)], fill=col + (235,))
        _save_img(name, im)
    tally()
    im = Image.new("RGBA", (128, 64), (0, 0, 0, 0))            # faint pencil level lines + crosses where the frames hang
    d = ImageDraw.Draw(im)
    for y in (8, 56):
        d.line([(0, y), (127, y)], fill=(90, 90, 96, 90))
    for x in (16, 48, 80, 112):
        for y in (8, 56):
            d.line([(x - 3, y), (x + 3, y)], fill=(70, 70, 76, 160))
            d.line([(x, y - 3), (x, y + 3)], fill=(70, 70, 76, 160))
    _save_img("apt_pencil.png", im)


def tally():
    """Tally marks in pencil (counts of something checked), gates of five, getting less steady towards the end."""
    rng = np.random.default_rng(23)
    im = Image.new("RGBA", (64, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for g in range(26):
        x0, y0 = 4 + (g % 4) * 15, 4 + (g // 4) * 18
        wob = 0.4 + g * 0.08
        for k in range(4):
            x = x0 + k * 3
            d.line([(x + rng.normal(0, wob), y0), (x + rng.normal(0, wob), y0 + 12)], fill=(58, 56, 62, 200))
        d.line([(x0 - 1, y0 + 10), (x0 + 11, y0 + 2 + rng.normal(0, wob))], fill=(58, 56, 62, 200))
    _save_img("apt_tally.png", im)


if __name__ == "__main__":
    surfaces()
    rug()
    view()
    art()
    labels()
    rx()
    organizer()
    cans()
    clock()
    misc()
    import apt_book_art
    apt_book_art.build()
