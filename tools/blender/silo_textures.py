"""Textures for Missile Silo 00 (the bore the amber network feeds; see tools/blender/props/missile_silo.py). Same look and
helpers as textures.py / hub_textures.py: century-faded stencils, amber-painted plates, soot.
Run: python tools/blender/silo_textures.py   -> models/generated/tex/silo_*.png
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from textures import OUT, _font, _noise, _rgba, _save_img, _streaks

INK = (14, 12, 12, 255)
PAINT = (122, 78, 14, 255)


def _flake(a, rng, keep=0.3, lo=0.25):
    h, w = a.shape
    wear = np.clip(lo + 1.5 * np.resize(_noise(max(w, h), 6, rng), (h, w)), 0, 1)
    return a * wear * (rng.random((h, w)) > keep)


def petal_stencil(w=128, h=192, seed=91):
    """Huge painted number on each cap petal's outer face: 'SILO' over a tall '00'."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 14), "SILO", font=_font("Oxanium-SemiBold.ttf", 26), fill=255, anchor="mt")
    d.text((w // 2, 112), "00", font=_font("Oxanium-SemiBold.ttf", 92), fill=255, anchor="mm")
    for y in (104, 124):
        d.rectangle([0, y, w, y + 3], fill=0)
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.35, 0.15)
    _save_img("silo_stencil.png", _rgba((0.46, 0.44, 0.40), a * 0.7))


def depth_marker(w=192, h=64, seed=92):
    """Stencil beside the mid-level gantry door."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((6, 4), "LEVEL 09", font=_font("Oxanium-SemiBold.ttf", 22), fill=255)
    d.text((6, 32), "-36 M  LAUNCH CTRL", font=_font("Oxanium-SemiBold.ttf", 17), fill=255)
    d.rectangle([150, 6, 186, 26], fill=255)
    d.polygon([(158, 10), (178, 16), (158, 22)], fill=0)
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.25)
    _save_img("silo_depth.png", _rgba((0.46, 0.44, 0.40), a * 0.75))


def warning(w=128, h=96, seed=93):
    """Amber plate on the gate that closes the broken stairs below the gantry."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, w - 2, h - 2], fill=PAINT, outline=INK, width=3)
    d.text((w // 2, 18), "DANGER", font=_font("Oxanium-SemiBold.ttf", 22), fill=INK, anchor="mm")
    d.text((w // 2, 44), "STAIR 1 FAILED", font=_font("Silkscreen-Regular.ttf", 10), fill=INK, anchor="mm")
    d.text((w // 2, 60), "BELOW LEVEL 09", font=_font("Silkscreen-Regular.ttf", 10), fill=INK, anchor="mm")
    d.text((w // 2, 80), "NO DESCENT", font=_font("Oxanium-SemiBold.ttf", 15), fill=INK, anchor="mm")
    arr = np.asarray(im, dtype=np.float32) / 255
    rot = np.resize(_noise(128, 6, rng), (h, w))
    arr[..., :3] *= (0.4 + 0.4 * rot)[..., None]
    arr[..., 3] *= (rng.random((h, w)) > 0.1) * (0.65 + 0.35 * (rot < 0.8))
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "silo_warning.png"))
    print("TEX silo_warning.png")


def soot(w=128, h=256, seed=94):
    """Launch soot: black plume streaks rising up the bore wall and over the lip (densest at the bottom edge)."""
    rng = np.random.default_rng(seed)
    sq = np.zeros((h, h), dtype=np.float32)                  # _streaks wants a square field
    _streaks(sq, rng, 140, 60, h, 0.2, 0.55, 6)
    a = np.clip(-sq[:, :w], 0, 1)
    a = a[::-1] * np.linspace(0.35, 1.0, h)[:, None]
    body = np.resize(_noise(256, 5, rng), (h, w))
    a = np.clip(a + body * np.linspace(0.1, 0.75, h)[:, None], 0, 1)
    edge = np.minimum(np.linspace(0, 1, w) * 5, np.linspace(1, 0, w) * 5).clip(0, 1)
    a *= edge[None, :] * np.linspace(0.0, 1.0, h).clip(0, 1)[:, None] ** 0.3
    a = np.asarray(Image.fromarray((a * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2)), dtype=np.float32) / 255
    _save_img("silo_soot.png", _rgba((0.012, 0.010, 0.012), a * 0.92))


if __name__ == "__main__":
    petal_stencil()
    depth_marker()
    warning()
    soot()
