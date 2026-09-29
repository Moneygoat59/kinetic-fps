"""Textures for Relay Hub 00 (the routing station the wells feed; see tools/blender/props/relay_hub.py). Same look and helpers
as textures.py: century-faded stencils, amber-painted plates, phosphor screens.
Run: python tools/blender/hub_textures.py   -> models/generated/tex/hub_*.png
Route colours match the relay channels (scripts/hub/hub_routes.gd COLORS): 73 amber, 02 cyan, 03 green, 00 (silo) red.
"""
import os

import numpy as np
from PIL import Image, ImageDraw

from textures import OUT, _crt, _font, _noise, _rgba, _save_img, _streaks

AMBER = (255, 150, 30)
DIM = (120, 70, 15)
INK = (14, 12, 12, 255)
ROUTES = {"73": ((255, 166, 30), "OUTPOST 73", "W-73 > HUB"), "02": ((40, 200, 255), "OUTPOST 02", "W-02 > HUB"),
          "03": ((50, 240, 90), "OUTPOST 03", "W-03 > HUB"), "00": ((255, 40, 25), "MISSILE SILO", "HUB > SILO")}


def stencil(w=192, h=160, seed=71):
    """Front wall stencil: small 'RELAY HUB', big '00', small 'AMBER ROUTING'; flaked like the Outpost 73 one."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 12), "RELAY HUB", font=_font("Oxanium-SemiBold.ttf", 24), fill=255, anchor="mt")
    d.text((w // 2, 88), "00", font=_font("Oxanium-SemiBold.ttf", 96), fill=255, anchor="mm")
    d.text((w // 2, 146), "AMBER ROUTING", font=_font("Oxanium-SemiBold.ttf", 17), fill=255, anchor="mm")
    for y in (92, 118):                                                          # stencil bridges
        d.rectangle([0, y, w, y + 3], fill=0)
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.25 + 1.5 * np.resize(_noise(max(w, h), 6, rng), (h, w)), 0, 1)
    a = a * wear * (rng.random((h, w)) > 0.3)
    _save_img("hub_stencil.png", _rgba((0.46, 0.44, 0.40), a * 0.75))


def route_plate(key, seed):
    """Buried-main plate for one route: amber paint, black stencil, a stripe in the relay channel's colour."""
    col, dest, line = ROUTES[key]
    rng = np.random.default_rng(seed)
    w, h = 128, 128
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, w - 2, h - 2], fill=(122, 78, 14, 255), outline=INK, width=3)
    d.text((w // 2, 16), "ROUTE", font=_font("Silkscreen-Regular.ttf", 12), fill=INK, anchor="mm")
    d.text((w // 2, 50), key, font=_font("Oxanium-SemiBold.ttf", 46), fill=INK, anchor="mm")
    d.rectangle([4, 76, w - 5, 88], fill=tuple(int(c * 0.55) for c in col) + (255,))
    d.text((w // 2, 99), dest, font=_font("Silkscreen-Regular.ttf", 10), fill=INK, anchor="mm")
    d.text((w // 2, 113), line, font=_font("Silkscreen-Regular.ttf", 9), fill=INK, anchor="mm")
    for x, y in ((7, 7), (w - 8, 7), (7, h - 8), (w - 8, h - 8)):
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(20, 10, 6, 255))
    arr = np.asarray(im, dtype=np.float32) / 255
    rot = np.resize(_noise(128, 6, rng), (h, w))
    arr[..., :3] *= (0.4 + 0.4 * rot)[..., None]
    drip = np.zeros((h, w), dtype=np.float32)
    _streaks(drip, rng, 8, 20, 70, -0.6, -1.0, 2)
    arr[..., 0] *= 1 + np.clip(drip, 0, 1) * 0.6
    arr[..., 3] *= (rng.random((h, w)) > 0.1) * (0.65 + 0.35 * (rot < 0.8))
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, f"hub_plate_{key}.png"))
    print(f"TEX hub_plate_{key}.png")


def network_map():
    """Wall map of the relay network: the hub in the middle, one route to each corner. Frame b blinks the dark routes."""
    ends = {"73": (34, 132), "02": (34, 40), "03": (222, 40), "00": (222, 132)}
    for tag in ("a", "b"):
        im = Image.new("RGB", (256, 176), (4, 3, 1))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 3), "RELAY NET // HUB 00", font=_font("VT323-Regular.ttf", 18), fill=AMBER)
        hub = (128, 90)
        for key, p in ends.items():
            col, dest, _ = ROUTES[key]
            live = key == "73"
            dash = 1 if live else 2
            for k in range(0, 12, dash):
                a0, a1 = k / 12, (k + 0.6) / 12
                d.line([(hub[0] + (p[0] - hub[0]) * a0, hub[1] + (p[1] - hub[1]) * a0),
                        (hub[0] + (p[0] - hub[0]) * a1, hub[1] + (p[1] - hub[1]) * a1)], fill=col if live else DIM, width=1)
            lit = live or tag == "a"
            d.rectangle([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], outline=col if lit else DIM, fill=col if live else None)
            d.text((p[0] + (8 if p[0] < 128 else -8), p[1] + 7), dest, font=_font("VT323-Regular.ttf", 14),
                   fill=col if lit else DIM, anchor="lt" if p[0] < 128 else "rt")
            d.text((p[0] + (8 if p[0] < 128 else -8), p[1] - 9), "R-" + key, font=_font("VT323-Regular.ttf", 14),
                   fill=AMBER, anchor="lt" if p[0] < 128 else "rt")
        d.rectangle([hub[0] - 9, hub[1] - 9, hub[0] + 9, hub[1] + 9], outline=AMBER, fill=(60, 34, 6))
        d.text((hub[0], hub[1] + 16), "HUB", font=_font("VT323-Regular.ttf", 14), fill=AMBER, anchor="mt")
        d.text((8, 158), "CARRIER 1/4" if tag == "a" else "CARRIER 1/4  .", font=_font("VT323-Regular.ttf", 16), fill=AMBER)
        _save_img(f"hub_screen_map_{tag}.png", _crt(im))


def notes(w=256, h=128, seed=72):
    """Pin-board notes left by the last routing crew."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sheets = [((6, 6), (82, 114), 2, ["ROUTING", "73 ok", "02 dark D.112", "03 dark D.113", "silo line", "needs all 3"],
               "Caveat-Regular.ttf", 13),
              ((94, 8), (72, 70), -3, ["relays lost", "carrier.", "reprogram at", "the ROUTER"], "ReenieBeanie.ttf", 13),
              ((170, 4), (80, 116), 1, ["NOBODY", "WALKS THE", "LINES", "AT NIGHT", "", "stay near", "the masts"],
               "PermanentMarker.ttf", 9)]
    for (x, y), (sw, sh), rot, lines, fnt, fsz in sheets:
        p = Image.new("RGBA", (sw, sh), (150, 132, 96, 255))
        pd = ImageDraw.Draw(p)
        pd.rectangle([0, 0, sw - 1, sh - 1], outline=(80, 66, 46, 255))
        pd.ellipse([sw // 2 - 3, 2, sw // 2 + 3, 8], fill=(110, 26, 18, 255))
        for i, ln in enumerate(lines):
            pd.text((6, 12 + i * (fsz + 2)), ln, font=_font(fnt, fsz), fill=(24, 20, 16, 255))
        im.alpha_composite(p.rotate(rot, expand=True, resample=Image.BICUBIC), (x, y))
    arr = np.asarray(im, dtype=np.float32) / 255
    stain = np.resize(_noise(256, 8, rng), (h, w))
    arr[..., :3] *= (0.4 + 0.45 * stain)[..., None]
    arr[..., 0] *= 1 + (stain < 0.35) * 0.35
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "hub_notes.png"))
    print("TEX hub_notes.png")


def floor_arrows(w=64, h=256, seed=73):
    """Worn floor paint: a lane of chevrons pointing along +V (down the hall toward the routing wall)."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    for k in range(4):
        y = 24 + k * 60
        d.polygon([(8, y + 26), (32, y), (56, y + 26), (56, y + 40), (32, y + 14), (8, y + 40)], fill=255)
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.2 + 1.4 * np.resize(_noise(256, 5, rng), (h, w)), 0, 1) * (rng.random((h, w)) > 0.25)
    _save_img("hub_floor_arrows.png", _rgba((0.42, 0.30, 0.03), a * wear * 0.7))


if __name__ == "__main__":
    stencil()
    for i, key in enumerate(ROUTES):
        route_plate(key, 80 + i)
    network_map()
    notes()
    floor_arrows()
