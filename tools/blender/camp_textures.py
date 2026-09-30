"""Procedural pixel-art textures for the camp kit (tools/blender/camp/): a camp made by someone lost in the dead forest,
running out of everything, then left. Everything is weathered, faded and grubby; the forest's grey dead wood and ash.
Run: python tools/blender/camp_textures.py   -> models/generated/tex/camp_*.png   (reuses the helpers of textures.py)
Surfaces (seamless, world-projected): tarp (faded blue poly tarp), bag (quilted sleeping bag), wood (grey dead wood),
char (charred wood), stone, pack (worn cordura), cord.
Mapped / decals (RGBA): ash (cold fire bed), tins (3 peeled food-tin labels, one row each), map (a folded map walked in
circles: pencil loops, crossings-out; no words), tally (days notched into a whittled face, groups of five), soot.
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from textures import _fbm, _noise, _save, _save_img  # noqa: E402

TIN_LABELS = [(150, 58, 40), (70, 96, 60), (196, 150, 70)]      # faded red, army green, mustard (camp_lib.TIN_ROWS)


def _rgb(lum, base):
    return lum[..., None] * np.array(base, np.float32)


def _stretch(n, ku, kv, rng):
    """Seamless noise with few cells across u and many down v (grain along v)."""
    g = rng.random((kv, ku)).astype(np.float32)
    big = np.tile(g, (3, 3))
    im = Image.fromarray((big * 255).astype(np.uint8)).resize((3 * n, 3 * n), Image.BICUBIC)
    return np.asarray(im, dtype=np.float32)[n:2 * n, n:2 * n] / 255.0


def _resized(a, w, h):
    return np.asarray(Image.fromarray((a * 255).astype(np.uint8)).resize((w, h), Image.BICUBIC), np.float32) / 255.0


def tarp(n=64):
    """Cheap blue poly tarp left out for weeks: woven grid, sun-bleached blotches, grime and mould spots."""
    rng = np.random.default_rng(301)
    yy, xx = np.mgrid[0:n, 0:n]
    weave = 0.9 + 0.1 * (((xx // 2) + (yy // 2)) % 2)
    bleach = _fbm(n, rng)
    grime = _fbm(n, rng, ((4, 0.4), (8, 0.4), (16, 0.2)))
    base = np.array([0.20, 0.33, 0.52]) * (1 - bleach[..., None] * 0.45) + np.array([0.46, 0.5, 0.52]) * bleach[..., None] * 0.45
    col = base * weave[..., None] * (0.72 + 0.28 * _noise(n, 16, rng))[..., None]
    col *= 1 - 0.5 * np.clip((grime - 0.55) * 3, 0, 1)[..., None]
    spots = rng.random((n, n)) > 0.985
    col[spots] *= 0.35
    _save("camp_tarp.png", col)


def bag(n=64):
    """Quilted sleeping bag, faded rust, baffles running across; the fill has clumped, dirt ground into the seams."""
    rng = np.random.default_rng(302)
    yy = np.arange(n)[:, None].repeat(n, 1)
    baffle = np.abs(np.sin((yy + 0.5) * math.pi / 8))
    lum = 0.55 + 0.45 * baffle ** 0.6
    lum *= 0.8 + 0.2 * _noise(n, 12, rng)
    dirt = np.clip((_fbm(n, rng) - 0.5) * 2.5, 0, 1)
    col = _rgb(lum, (0.52, 0.2, 0.11)) * (1 - 0.55 * dirt[..., None]) + _rgb(lum, (0.2, 0.16, 0.12)) * 0.55 * dirt[..., None]
    col[(yy % 8) == 0] *= 0.55
    _save("camp_bag.png", col)


def wood(n=64):
    """Grey dead wood (the forest's own trees): long grain, splits, a few dark bark scraps left on."""
    rng = np.random.default_rng(303)
    grain = _stretch(n, 10, 2, rng) * 0.6 + _stretch(n, 24, 4, rng) * 0.4
    lum = 0.55 + 0.4 * grain
    splits = _stretch(n, 32, 3, rng) < 0.12
    lum[splits] *= 0.45
    bark = _fbm(n, rng) > 0.8
    col = _rgb(lum, (0.42, 0.4, 0.37))
    col[bark] = _rgb(lum[bark] * 0.5, (0.3, 0.24, 0.2))
    _save("camp_wood.png", col)


def char(n=64):
    """Charcoal: near-black, cracked into blocks (alligatoring), a little grey ash lodged in the cracks."""
    rng = np.random.default_rng(304)
    lum = 0.06 + 0.05 * _noise(n, 24, rng)
    col = _rgb(lum, (1.0, 0.95, 0.9))
    crack = (np.abs(_noise(n, 8, rng) - 0.5) < 0.035) | (np.abs(_noise(n, 12, rng) - 0.5) < 0.03)
    col[crack] = np.array([0.22, 0.21, 0.2])
    _save("camp_char.png", col)


def stone(n=64):
    """Grey field stone: lichen flecks, darker pits."""
    rng = np.random.default_rng(305)
    lum = 0.42 + 0.3 * _fbm(n, rng) + 0.1 * _noise(n, 32, rng)
    col = _rgb(lum, (0.5, 0.49, 0.47))
    lichen = (_noise(n, 16, rng) > 0.78) & (rng.random((n, n)) > 0.3)
    col[lichen] = np.array([0.42, 0.44, 0.34]) * lum[lichen][:, None] * 1.6
    col[rng.random((n, n)) > 0.97] *= 0.5
    _save("camp_stone.png", col)


def pack(n=64):
    """Worn olive cordura: tight weave, rubbed pale where it wore, darker where it soaked up mud."""
    rng = np.random.default_rng(306)
    yy, xx = np.mgrid[0:n, 0:n]
    weave = 0.88 + 0.12 * ((xx + yy) % 2)
    wear = _fbm(n, rng)
    col = _rgb(weave * (0.75 + 0.25 * _noise(n, 20, rng)), (0.24, 0.25, 0.16))
    col += np.clip(wear - 0.7, 0, 1)[..., None] * 0.35
    col *= 1 - 0.4 * np.clip((_fbm(n, rng) - 0.6) * 3, 0, 1)[..., None]
    _save("camp_pack.png", col)


def cord(n=16):
    """Paracord, once orange, faded and dirty."""
    rng = np.random.default_rng(307)
    yy, xx = np.mgrid[0:n, 0:n]
    twist = 0.75 + 0.25 * (((xx + yy) // 2) % 2)
    _save("camp_cord.png", _rgb(twist * (0.8 + 0.2 * rng.random((n, n))), (0.55, 0.3, 0.14)))


def ash(n=128):
    """Cold fire bed: pale grey ash, charcoal crumbs, a sooty ring out to a feathered edge. No embers."""
    rng = np.random.default_rng(308)
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.hypot(xx - n / 2 + 0.5, yy - n / 2 + 0.5) / (n / 2)
    edge = 0.78 + 0.16 * (_noise(n, 8, rng) - 0.5) * 2
    alpha = np.clip((edge - r) / 0.2, 0, 1)
    tone = 0.3 + 0.35 * _fbm(n, rng) - 0.25 * np.clip(r - 0.45, 0, 1)
    rgb = _rgb(np.clip(tone, 0, 1), (0.95, 0.94, 0.92))
    crumbs = (rng.random((n, n)) > 0.9) & (r < 0.6)
    rgb[crumbs] = 0.05
    im = np.concatenate([rgb, alpha[..., None]], -1)
    _save("camp_ash.png", im)


def soot(n=64):
    """Soft soot smudge (blackened tin, stones on the fire side)."""
    rng = np.random.default_rng(309)
    yy, xx = np.mgrid[0:n, 0:n]
    r = np.hypot(xx - n / 2, yy - n / 2) / (n / 2)
    alpha = np.clip(1 - r, 0, 1) ** 1.5 * (0.6 + 0.4 * _fbm(n, rng))
    _save("camp_soot.png", np.concatenate([np.full((n, n, 3), 0.03), alpha[..., None]], -1))


def tins(w=64, h=16):
    """Food-tin label bands, one row per TIN_LABELS colour: faded print, a pale panel, torn and peeled to bare tin in places."""
    rng = np.random.default_rng(310)
    im = Image.new("RGB", (w, h * len(TIN_LABELS)))
    d = ImageDraw.Draw(im)
    for i, c in enumerate(TIN_LABELS):
        y = i * h
        d.rectangle([0, y, w, y + h], fill=c)
        d.rectangle([18, y + 4, 44, y + 11], fill=(214, 204, 176))
        d.rectangle([22, y + 6, 40, y + 7], fill=tuple(int(v * 0.6) for v in c))
        d.rectangle([22, y + 9, 34, y + 9], fill=tuple(int(v * 0.6) for v in c))
        x = 0
        while x < w:                                                  # torn-away strips: bare dull tin
            gap = int(rng.integers(6, 20))
            if rng.random() < 0.4:
                top = int(rng.integers(0, 8))
                d.polygon([(x, y + top), (x + gap, y + top + int(rng.integers(-3, 3))), (x + gap, y + h), (x, y + h)], fill=(120, 118, 112))
            x += gap
    arr = np.asarray(im, np.float32) / 255.0
    arr *= (0.75 + 0.25 * np.asarray(Image.fromarray((rng.random((len(TIN_LABELS) * h, w)) * 255).astype(np.uint8)), np.float32) / 255.0)[..., None]
    _save("camp_tins.png", arr)


def map_sheet(w=160, h=128):
    """A folded trail map: contour lines, a river, then the pencil: the same loops walked again and again, circled, crossed out."""
    rng = np.random.default_rng(311)
    paper = 0.78 + 0.1 * _resized(_fbm(128, rng), w, h)
    base = _rgb(paper, (0.93, 0.89, 0.76))
    im = Image.fromarray((base * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    for x in range(0, w, 10):                                            # printed grid
        d.line([(x, 0), (x, h)], fill=(196, 192, 170))
    for y in range(0, h, 10):
        d.line([(0, y), (w, y)], fill=(196, 192, 170))
    for k in range(9):                                                   # contours
        cx, cy, r = 60 + k * 3, 64 - k * 2, 12 + k * 9
        d.ellipse([cx - r * 1.3, cy - r, cx + r * 1.3, cy + r], outline=(178, 150, 112))
    d.line([(0, 100), (40, 92), (70, 110), (110, 96), (160, 108)], fill=(110, 136, 158), width=2)     # river
    pen = (60, 58, 64)
    pts = []
    for t in np.linspace(0, 6 * math.pi, 90):                          # the walk: loops that keep coming back
        rr = 26 + 8 * math.sin(t * 1.7) + t * 1.2
        pts.append((84 + rr * math.cos(t) + rng.normal(0, 0.6), 60 + rr * 0.7 * math.sin(t) + rng.normal(0, 0.6)))
    d.line(pts, fill=pen, width=1)
    for cx, cy in ((84, 60), (112, 40), (50, 76)):                     # circled, again and again
        for j in range(3):
            r = 6 + j + rng.normal(0, 0.5)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=pen)
    for cx, cy in ((112, 40), (50, 76), (130, 88)):                    # crossed out
        d.line([(cx - 7, cy - 7), (cx + 7, cy + 7)], fill=pen, width=2)
        d.line([(cx - 7, cy + 7), (cx + 7, cy - 7)], fill=pen, width=2)
    arr = np.asarray(im, np.float32) / 255.0
    fold = np.ones((h, w), np.float32)
    fold[:, w // 2 - 1:w // 2 + 1] = 0.7
    fold[h // 2, :] = 0.75
    stain = _resized(_fbm(128, rng), w, h)
    arr = arr * (fold * (1 - 0.35 * np.clip((stain - 0.6) * 3, 0, 1)))[..., None]
    _save("camp_map.png", arr)


def tally(w=32, h=128):
    """A whittled pale face on a grey stick, notched with days in fives. The last groups are uneven, then it stops."""
    rng = np.random.default_rng(312)
    lum = 0.7 + 0.2 * _stretch(max(w, h), 12, 2, rng)[:h, :w]
    col = _rgb(lum, (0.78, 0.72, 0.6))
    im = Image.fromarray((col * 255).astype(np.uint8))
    d = ImageDraw.Draw(im)
    cut = (58, 48, 38)
    y = 6
    days = 31
    for i in range(days):
        wob = 0.3 + i * 0.05
        x0 = int(6 + rng.normal(0, wob))
        if i % 5 == 4:                                                  # the fifth cuts across the four above
            d.line([(x0 + 18, y - 17), (x0 + 1, y - 2)], fill=cut, width=2)
            y += 5
            continue
        d.line([(x0, y), (x0 + 20 + int(rng.normal(0, wob * 2)), y + int(rng.normal(0, wob)))], fill=cut, width=2)
        y += 4
    _save_img("camp_tally.png", im)


if __name__ == "__main__":
    tarp()
    bag()
    wood()
    char()
    stone()
    pack()
    cord()
    ash()
    soot()
    tins()
    map_sheet()
    tally()
