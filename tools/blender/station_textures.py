"""Textures for the line's station (tools/blender/kit/station.py, station_props.py). Same helpers and look as
tunnel_textures.py: century-faded paint on obsidian, amber only where something still glows. Functional signage only:
the station's name (RECORDS, as the vault stencils it), the platform indicator, a stopped clock, the driver's STOP board.
Run: python tools/blender/station_textures.py   -> models/generated/tex/tun_station_*.png, tun_indicator_*.png
then rebuild the pieces (they embed them).
"""
import math

import numpy as np
from PIL import Image, ImageDraw

from textures import _font, _save_img
from tunnel_textures import INK, _path, _worn_rgba

BOARD = (16, 15, 18, 255)            # enamel panel, gone near black
LETTER = (132, 126, 112, 255)        # its lettering, yellowed
RULE = (70, 42, 14, 255)             # the line's band: amber paint, faded to brown
AMBER = (255, 118, 20)               # indicator dots (emission)


def name_board(w=512, h=128, seed=131):
    """The station name, repeated along the back wall and across the track: a band with LINE 00, then RECORDS."""
    im = Image.new("RGBA", (w, h), BOARD)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=INK, width=4)
    d.rectangle([4, 100, w - 5, 110], fill=RULE)
    d.rectangle([14, 16, 104, 88], outline=LETTER, width=3)
    d.text((59, 36), "LINE", font=_font("Oxanium-SemiBold.ttf", 18), fill=LETTER, anchor="mm")
    d.text((59, 64), "00", font=_font("Oxanium-SemiBold.ttf", 34), fill=LETTER, anchor="mm")
    d.text((126, 54), "RECORDS", font=_font("Oxanium-SemiBold.ttf", 76), fill=LETTER, anchor="lm")
    _worn_rgba(im, seed, holes=0.04).save(_path("tun_station_name.png"))


def way_sign(w=384, h=96, seed=132):
    """Hung over the platform's far end: straight on for RECORDS."""
    im = Image.new("RGBA", (w, h), BOARD)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=INK, width=4)
    d.polygon([(48, 16), (76, 46), (58, 46), (58, 80), (38, 80), (38, 46), (20, 46)], fill=LETTER)
    d.text((100, h // 2), "RECORDS", font=_font("Oxanium-SemiBold.ttf", 54), fill=LETTER, anchor="lm")
    _worn_rgba(im, seed, holes=0.05).save(_path("tun_station_way.png"))


def stop_board(w=64, h=96, seed=133):
    """Where the driver stops the head of the train: STOP over a bar."""
    im = Image.new("RGBA", (w, h), BOARD)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, w - 1, h - 1], outline=LETTER, width=3)
    d.text((w // 2, 34), "STOP", font=_font("Oxanium-SemiBold.ttf", 20), fill=LETTER, anchor="mm")
    d.rectangle([12, 58, w - 13, 70], fill=LETTER)
    _worn_rgba(im, seed, holes=0.05).save(_path("tun_station_stop.png"))


def clock_face(n=128, seed=134):
    """The platform clock: ticks and two hands, stopped."""
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c, r = n / 2, n / 2 - 3
    d.ellipse([c - r, c - r, c + r, c + r], fill=(96, 92, 82, 255), outline=INK, width=4)
    for i in range(60):
        a = math.tau * i / 60
        r0 = r - (13 if i % 5 == 0 else 7)
        d.line([(c + r0 * math.sin(a), c - r0 * math.cos(a)), (c + (r - 5) * math.sin(a), c - (r - 5) * math.cos(a))], fill=INK,
               width=4 if i % 5 == 0 else 1)
    for turn, length, width in ((0.31, 0.5, 6), (0.62, 0.78, 4)):         # hour and minute hands where they stopped
        a = math.tau * turn
        d.line([(c, c), (c + r * length * math.sin(a), c - r * length * math.cos(a))], fill=INK, width=width)
    d.ellipse([c - 5, c - 5, c + 5, c + 5], fill=INK)
    _worn_rgba(im, seed, holes=0.03).save(_path("tun_station_clock.png"))


def _dots(rows, w=64, h=16, dead=(), seed=0):
    """Dot-matrix frame: `rows` = [(text, y)] drawn at 1 px per dot on a w x h grid, each dot blown up to a round 4 px lamp."""
    grid = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(grid)
    for text, y in rows:
        d.text((w // 2, y), text, font=_font("Silkscreen-Regular.ttf", 8), fill=255, anchor="mt")
    on = np.asarray(grid, dtype=np.float32) > 100
    rng = np.random.default_rng(seed)
    lamp = np.array([[0.2, 0.7, 0.7, 0.2], [0.7, 1.0, 1.0, 0.7], [0.7, 1.0, 1.0, 0.7], [0.2, 0.7, 0.7, 0.2]], dtype=np.float32)
    level = np.where(on, 0.55 + 0.45 * rng.random((h, w)), 0.035)             # unlit dots still show, faintly
    for x0, x1 in dead:                                                       # columns of dots gone dark
        level[:, x0:x1] = 0.0
    big = np.kron(level, lamp)
    rgb = np.stack([big * AMBER[0], big * AMBER[1], big * AMBER[2]], -1)
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def indicator():
    """The platform indicator's two frames (kit_prop.gd SCREENS "kit_scr_indicator" flips between them)."""
    _save_img("tun_indicator_a.png", _dots([("LINE 00", 0), ("NO SERVICE", 8)], dead=((50, 52),), seed=1))
    _save_img("tun_indicator_b.png", _dots([("LINE 00", 0)], dead=((50, 52),), seed=2))


if __name__ == "__main__":
    name_board()
    way_sign()
    stop_board()
    clock_face()
    indicator()
