"""Procedural pixel-art textures for the PS1 look (small, seamless, no external assets).
Run: python tools/blender/textures.py   -> models/generated/tex/*.png
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


def _fbm(n, rng, octaves=((4, 0.5), (8, 0.3), (16, 0.15), (32, 0.08))):
    a = sum(_noise(n, k, rng) * w for k, w in octaves)
    return (a - a.min()) / (a.max() - a.min())


def _save(name, arr):
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(arr * 255, 0, 255).astype(np.uint8)).save(os.path.join(OUT, name))
    print("TEX", name)


def concrete(n=128, seed=1):
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng, ((4, 0.2), (8, 0.3), (16, 0.3), (32, 0.2)))
    grit = rng.random((n, n)) * 0.07
    stain = _noise(n, 3, rng)
    lum = 0.13 + v * 0.15 + grit - stain * 0.05
    base = np.stack([lum * 1.10, lum * 0.98, lum * 0.86], -1)          # warm dark basalt concrete
    pits = rng.random((n, n)) > 0.985
    base[pits] *= 0.55
    base[n // 2 - 1:n // 2 + 1, :] *= 0.72                            # a horizontal pour seam
    _save("concrete.png", base)


def floor(n=128, seed=2):
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng)
    lum = 0.11 + v * 0.11 + rng.random((n, n)) * 0.05
    base = np.stack([lum * 1.02, lum * 0.98, lum * 0.92], -1)
    base[::32, :] *= 0.6
    base[:, ::32] *= 0.6
    _save("floor.png", base)


def metal(n=64, seed=3):
    rng = np.random.default_rng(seed)
    v = _fbm(n, rng, ((4, 0.6), (8, 0.4)))
    lum = 0.16 + v * 0.09 + rng.random((n, n)) * 0.03
    base = np.stack([lum * 1.06, lum * 0.98, lum * 0.90], -1)          # warm dark steel
    base[0, :] *= 0.5
    base[:, 0] *= 0.5
    for x in (5, n - 6):                                               # rivets
        for y in (5, n - 6):
            base[y, x] *= 1.7
    rust = (_noise(n, 8, rng) > 0.80)[..., None]
    base = np.where(rust, base * np.array([1.25, 0.9, 0.7]), base)
    _save("metal.png", base)


if __name__ == "__main__":
    concrete()
    floor()
    metal()
