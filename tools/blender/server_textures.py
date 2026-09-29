"""Textures for the server room kit (tools/blender/kit/servers.py) and Missile Silo 00's data room (silo_servers.py).
Run: python tools/blender/server_textures.py   -> models/generated/tex/kit_screen_{rack,rack_dead,nodes,crac}_*.png,
     tex/silo_sign_data.png   (same helpers and look as textures.py / kit_textures.py)
Screens are emission images; runtime frame lists live in scripts/props/kit_prop.gd (SCREENS).
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

from textures import _crt, _font, _noise, _rgba, _save_img

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "kit"))
import kit_dims as K  # noqa: E402

AMBER = (255, 150, 30)
AMBER_DIM = (120, 66, 12)
GREEN = (90, 255, 120)
RED = (255, 60, 40)
PLATE = (9, 8, 11)              # server faceplates: barely lit by the LEDs round them
SLOT = (3, 3, 4)
UNIT_KINDS = ("server", "server", "server", "drives", "blank", "patch")


# ------------------------------------------------------------------ rack equipment face (server_rack, server_rack_open)
def _led(d, x, y, color, on):
    d.rectangle([x, y, x + 1, y + 1], fill=color if on else tuple(c // 10 for c in color))


def _unit(d, kind, y0, w, u, lit):
    """One rack unit u px tall at y0. lit(p) -> bool decides each activity LED this frame (p = chance it is on)."""
    d.rectangle([1, y0 + 1, w - 2, y0 + u - 2], fill=PLATE)
    if kind == "empty":                                        # a pulled blade: black slot, rails either side
        d.rectangle([3, y0 + 1, w - 4, y0 + u - 2], fill=(1, 1, 1))
        return
    if kind == "blank":
        for x in (4, w - 6):
            d.point((x, y0 + u // 2), fill=(40, 38, 42))
        return
    if kind == "server":
        for x in range(5, w // 2 + 4, 3):                      # vent slots
            d.line([(x, y0 + 4), (x, y0 + u - 5)], fill=SLOT)
        _led(d, w - 9, y0 + 4, AMBER, lit(1.0))                # power
        _led(d, w - 9, y0 + 9, AMBER, lit(0.5))                # disk activity
        _led(d, w - 13, y0 + 9, GREEN, lit(0.85))              # link
        return
    if kind == "drives":
        for i in range(4):
            x = 3 + i * 15
            d.rectangle([x, y0 + 3, x + 12, y0 + u - 4], fill=(13, 12, 15), outline=SLOT)
            _led(d, x + 9, y0 + u - 7, AMBER, lit(0.45))
        return
    for row in range(2):                                       # patch panel: two rows of ports, link lamps above some
        for i in range(9):
            x, y = 4 + i * 6, y0 + 4 + row * 5
            d.rectangle([x, y, x + 3, y + 2], fill=(3, 3, 4))
            if (i + row) % 3:
                _led(d, x + 1, y - 1, GREEN, lit(0.7))


def screen_rack(frames=3):
    """server_rack: 14 units of servers, drive shelves, patch panels; activity LEDs change every frame."""
    _rack("kit_screen_rack", frames, dead=False)


def screen_rack_dead(frames=2):
    """server_rack_open: half the blades pulled, the rest dark but for two power lamps and one fault lamp blinking."""
    _rack("kit_screen_rack_dead", frames, dead=True)


def _rack(name, frames, dead):
    w, u = K.SRV_FACE_PX, K.SRV_UNIT_PX
    layout = np.random.default_rng(71 if dead else 70)
    kinds = [UNIT_KINDS[i] for i in layout.integers(0, len(UNIT_KINDS), K.SRV_UNITS)]
    if dead:
        for i in (2, 3, 7, 11):
            kinds[i] = "empty"
        for i in (5, 9, 12):
            kinds[i] = "server"
    for f in range(frames):
        rng = np.random.default_rng(700 + f + (50 if dead else 0))
        im = Image.new("RGB", (w, K.SRV_UNITS * u), (2, 2, 3))
        d = ImageDraw.Draw(im)
        for i, kind in enumerate(kinds):
            if dead:
                on = (lambda p, i=i: i in (5, 9) and p >= 1.0)  # noqa: E731  only two power lamps left
            else:
                on = (lambda p: rng.random() < p)  # noqa: E731
            _unit(d, kind, i * u, w, u, on)
        if dead:
            _led(d, w - 9, 12 * u + 9, RED, f % 2 == 0)
        _save_img(f"{name}_{'abc'[f]}.png", im)


# ------------------------------------------------------------------ terminal_server and crac_unit screens
def screen_nodes():
    """terminal_server: the data room's node status board. Three nodes are down; node 14 keeps dropping out (frame c)."""
    down = {5, 11, 20}
    f16, f18 = _font("VT323-Regular.ttf", 16), _font("VT323-Regular.ttf", 18)
    for tag, flaky_down, scan, cursor in (("a", False, 0, True), ("b", False, 2, False), ("c", True, 3, False)):
        im = Image.new("RGB", (256, 192), (4, 3, 1))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((8, 4), "DATA 09 // NODE STATUS", font=f18, fill=AMBER)
        d.line([(8, 24), (247, 24)], fill=AMBER_DIM)
        for n in range(24):
            col, row = n % 6, n // 6
            x, y = 8 + col * 40, 30 + row * 30
            bad = n in down or (n == 13 and flaky_down)
            color = RED if bad else (AMBER if row == scan else AMBER_DIM)
            d.rectangle([x, y, x + 36, y + 26], outline=color, fill=(40, 6, 3) if bad else None)
            d.text((x + 4, y + 1), f"N{n + 1:02d}", font=f16, fill=color)
            d.text((x + 4, y + 12), "FLT" if bad else "OK", font=f16, fill=color)
        online = 24 - len(down) - (1 if flaky_down else 0)
        d.text((8, 152), f"> {online}/24 ONLINE", font=f18, fill=AMBER)
        d.text((8, 170), "> ", font=f18, fill=AMBER)
        if cursor:
            d.rectangle([22, 174, 29, 186], fill=AMBER)
        _save_img(f"kit_screen_nodes_{tag}.png", _crt(im, glitch_seed=None if tag != "c" else 9))


def screen_crac():
    """crac_unit: the cooling unit's LCD. Half its fans are gone and the room runs hot (frame b is the alarm)."""
    f = _font("VT323-Regular.ttf", 17)
    for tag, alarm in (("a", False), ("b", True)):
        im = Image.new("RGB", (128, 64), (2, 5, 3))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((5, 2), "COOLING  2/4", font=f, fill=GREEN)
        d.text((5, 20), "RETURN   38 C", font=f, fill=GREEN)
        if alarm:
            d.rectangle([3, 40, 124, 60], fill=(60, 8, 4))
            d.text((64, 50), "HIGH TEMP", font=f, fill=RED, anchor="mm")
        else:
            d.text((5, 40), "FAN 2,4  FAIL", font=f, fill=GREEN)
        _save_img(f"kit_screen_crac_{tag}.png", _crt(im, vignette=0.3, bloom=0.8))


# ------------------------------------------------------------------ silo data room wall stencil (RGBA decal)
def sign_data():
    """Stencil on the data room's end wall above the terminal, flaked like the silo's other stencils."""
    rng = np.random.default_rng(72)
    w, h = 256, 128
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 50), "DATA 09", font=_font("Oxanium-SemiBold.ttf", 62), fill=255, anchor="mm")
    d.text((w // 2, 108), "AUTHORISED OPERATORS ONLY", font=_font("Oxanium-SemiBold.ttf", 15), fill=255, anchor="mm")
    d.rectangle([0, 52, w, 55], fill=0)                                                # stencil bridge
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.3 + 1.4 * np.resize(_noise(256, 6, rng), (h, w)), 0, 1)
    _save_img("silo_sign_data.png", _rgba((0.46, 0.44, 0.40), a * wear * (rng.random((h, w)) > 0.22) * 0.8))


if __name__ == "__main__":
    screen_rack()
    screen_rack_dead()
    screen_nodes()
    screen_crac()
    sign_data()
