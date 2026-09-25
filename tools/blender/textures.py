"""Procedural pixel-art textures for the PS1 look (small, seamless, no external assets).
Run: python tools/blender/textures.py   -> models/generated/tex/*.png
Values are sRGB. Target: dark basalt (mean ~0.15), warm-neutral, with just enough structure to read under fog.
"""
import os

import numpy as np
from PIL import Image

OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "models", "generated", "tex"))


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
    Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8)).save(os.path.join(OUT, name))
    print("TEX", name)


def _tint(lum, r, g, b):
    return np.stack([lum * r, lum * g, lum * b], -1)


def basalt(n=128, seed=1, base=0.085, rough=0.12):
    """Dark vesicular basalt: fine pits, light grit specks, vertical rain streaks, pour seam, tie-holes."""
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng)
    lum = base + v * rough + rng.random((n, n)) * 0.035
    streak = _noise(n, 6, rng)                                         # low-frequency dirt
    col_streak = np.repeat(_noise(n, 3, rng)[:1, :], n, axis=0)        # vertical streaking (same along y)
    lum = lum - streak * 0.03 - col_streak * 0.035
    img = _tint(lum, 1.03, 1.0, 0.95)                                  # neutral-warm charcoal
    pits = rng.random((n, n)) > 0.975
    img[pits] *= 0.5
    specks = rng.random((n, n)) > 0.992                                # glassy plagioclase glints
    img[specks] = np.minimum(img[specks] * 2.6 + 0.02, 0.5)
    img[n // 2 - 1:n // 2 + 1, :] *= 0.62                              # horizontal pour seam
    img[:, 0:2] *= 0.7                                                 # vertical panel seam
    for x in (n // 4, 3 * n // 4):                                     # tie-holes
        for y in (n // 4 + 1, 3 * n // 4 + 1):
            img[y - 1:y + 2, x - 1:x + 2] *= 0.45
    _save("basalt.png", img)


def basalt_smooth(n=128, seed=4):
    """Slightly lighter, finer cap/plinth stone (cornice, plinth, frames)."""
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng, ((8, 0.4), (16, 0.4), (32, 0.2)))
    lum = 0.12 + v * 0.09 + rng.random((n, n)) * 0.03
    img = _tint(lum, 1.03, 1.0, 0.96)
    img[n // 2, :] *= 0.7
    _save("basalt_smooth.png", img)


def floor(n=128, seed=2):
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng)
    lum = 0.07 + v * 0.08 + rng.random((n, n)) * 0.03
    stain = (_noise(n, 4, rng) > 0.66)[..., None]                      # oil / damp stains
    img = _tint(lum, 1.02, 0.98, 0.93)
    img = np.where(stain, img * 0.55, img)
    img[::32, :] *= 0.55                                               # slab joints
    img[:, ::32] *= 0.55
    _save("floor.png", img)


def metal(n=64, seed=3):
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng, ((4, 0.6), (8, 0.4)))
    lum = 0.11 + v * 0.07 + rng.random((n, n)) * 0.025
    img = _tint(lum, 1.05, 0.99, 0.93)                                 # warm dark steel
    img[0, :] *= 0.5
    img[:, 0] *= 0.5
    for x in (5, n - 6):                                               # rivets
        for y in (5, n - 6):
            img[y, x] *= 1.9
    rust = (_noise(n, 8, rng) > 0.9)[..., None]
    img = np.where(rust, img * np.array([1.45, 1.0, 0.72]), img)
    _save("metal.png", img)


def plate(n=64, seed=5):
    """Interior wall plating: big panels, seam grooves, bolt rows, grime gradient."""
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng, ((4, 0.5), (8, 0.5)))
    lum = 0.10 + v * 0.06 + rng.random((n, n)) * 0.02
    img = _tint(lum, 1.04, 0.99, 0.92)
    img[0:2, :] *= 0.45
    img[:, 0:2] *= 0.45
    for i in range(6, n, 12):
        img[3, i] *= 1.8
        img[n - 4, i] *= 1.8
    img *= (0.75 + 0.25 * np.linspace(0, 1, n))[:, None, None]         # grime toward the bottom of each tile
    _save("plate.png", img)


if __name__ == "__main__":
    basalt()
    basalt_smooth()
    floor()
    metal()
    plate()
