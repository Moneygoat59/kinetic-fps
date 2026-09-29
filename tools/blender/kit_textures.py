"""Textures for the Outpost 73 prop kit (terminals, furniture, storage): screens, control panels, keycaps and labels.
Run: python tools/blender/kit_textures.py   -> models/generated/tex/kit_*.png   (reuses the helpers and look of textures.py)
Screens are emission images; runtime frame lists live in scripts/props/kit_prop.gd (SCREENS).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

from textures import _crt, _font, _noise, _rgba, _save_img, _streaks, _text_screen

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "kit"))
import kit_dims as K  # noqa: E402

AMBER = (255, 150, 30)
GREEN = (90, 255, 120)
TEAL = (90, 230, 210)
RED = (255, 60, 40)


# ------------------------------------------------------------------ screens (emission)
def screen_log():
    """terminal_crt: relay log that has retried the hub every day for 200 years."""
    head = ["RELAY 12 // OUTPOST NET", "-" * 30]
    days = [f"DAY 73,0{47 + i}  HUB ..... NO ACK" for i in range(5)]
    for tag, clock, cur in (("a", "23:59:58", True), ("b", "23:59:57", False)):
        lines = head + days + [f"> RETRY IN {clock}", "> KEEP LINE OPEN"]
        cursor = (8 + int(20 * 0.4) * 16, 6 + 8 * 18 + 3) if cur else None
        _save_img(f"kit_screen_log_{tag}.png", _crt(_text_screen(lines, 20, AMBER, cursor=cursor), glitch_seed=None if cur else 5))


def screen_radar(frames=12):
    """terminal_console: green motion sweep. One contact nobody has identified."""
    blips = [(0.55, 40, 0.8), (0.8, 145, 0.6), (0.35, 250, 1.0)]  # (radius frac, bearing deg, size)
    cx, cy, r = 92, 104, 78
    f18, f16 = _font("VT323-Regular.ttf", 18), _font("VT323-Regular.ttf", 16)
    for k in range(frames):
        sweep = k * 360 / frames
        im = Image.new("RGB", (256, 192), (1, 4, 2))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        for rr in (r, r * 2 / 3, r / 3):
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=(20, 80, 34))
        d.line([(cx - r, cy), (cx + r, cy)], fill=(20, 70, 30))
        d.line([(cx, cy - r), (cx, cy + r)], fill=(20, 70, 30))
        for t in range(10):  # fading trail behind the beam
            a = math.radians(sweep - t * 3)
            v = 1.0 - t / 10
            d.line([(cx, cy), (cx + r * math.cos(a), cy + r * math.sin(a))], fill=tuple(int(c * v * (0.35 if t else 1)) for c in GREEN))
        for rf, brg, sz in blips:
            age = (sweep - brg) % 360
            v = max(0.15, 1.0 - age / 300)
            bx, by = cx + rf * r * math.cos(math.radians(brg)), cy + rf * r * math.sin(math.radians(brg))
            s = 2 + int(2 * sz)
            d.rectangle([bx - s, by - s, bx + s, by + s], fill=tuple(int(c * v) for c in GREEN))
        d.text((178, 8), "MOTION", font=f18, fill=GREEN)
        d.text((178, 26), "SWEEP", font=f18, fill=GREEN)
        d.text((178, 60), "CONTACTS", font=f16, fill=GREEN)
        d.text((178, 76), "3", font=_font("VT323-Regular.ttf", 34), fill=GREEN)
        d.text((178, 116), "ID: ???", font=f16, fill=RED if k % 2 else GREEN)
        d.text((178, 136), "BG 2.4", font=f16, fill=GREEN)
        d.text((178, 152), "mSv/h", font=f16, fill=GREEN)
        _save_img(f"kit_screen_radar_{k}.png", _crt(im, bloom=1.2))


def screen_seal():
    """terminal_wall: bulkhead keypad. Something keeps trying codes (frame c is the rejection)."""
    base = ["BULKHEAD 04", "STATUS .... SEALED", "SINCE .. DAY 00,112", "", "ENTER CODE:"]
    for tag, code, cur, deny in (("a", "[ _ _ _ _ ]", True, False), ("b", "[ _ _ _ _ ]", False, False), ("c", "[ * * * * ]", False, True)):
        im = _text_screen(base + [code], 22, AMBER, cursor=(27, 6 + 5 * 19 + 5) if cur else None, step=19)
        if deny:
            d = ImageDraw.Draw(im)
            d.fontmode = "1"
            d.rectangle([8, 146, 247, 184], fill=(60, 8, 4))
            d.text((128, 165), "ACCESS DENIED", font=_font("PressStart2P-Regular.ttf", 14), fill=RED, anchor="mm")
        _save_img(f"kit_screen_seal_{tag}.png", _crt(im))


def screen_tape():
    """terminal_mainframe: tape-drive LCD, still reading the crew archive block by block."""
    for tag, blk in (("a", "007213"), ("b", "007214")):
        im = Image.new("RGB", (128, 64), (2, 6, 6))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        d.text((6, 3), "TAPE 4/9  READ", font=_font("VT323-Regular.ttf", 19), fill=TEAL)
        d.text((6, 23), f"BLK {blk}", font=_font("VT323-Regular.ttf", 19), fill=TEAL)
        d.text((6, 45), "ARCHIVE: CREW 73", font=_font("VT323-Regular.ttf", 14), fill=AMBER)
        _save_img(f"kit_screen_tape_{tag}.png", _crt(im, vignette=0.3, bloom=0.8))


# ------------------------------------------------------------------ control surfaces (albedo, lit panels glow faintly)
def _grime(arr, rng, h, w, dark=0.45):
    rot = np.resize(_noise(128, 6, rng), (h, w))
    arr[..., :3] *= (dark + 0.35 * rot)[..., None]
    return arr


def panel():
    """Console control deck: button grid, toggle row, two lit status LEDs, faded labels (emission = same image)."""
    rng = np.random.default_rng(51)
    w, h = 128, 64
    im = Image.new("RGB", (w, h), (13, 11, 15))
    d = ImageDraw.Draw(im)
    for row in range(3):
        for col in range(8):
            x, y = 6 + col * 11, 6 + row * 11
            lit = (row, col) in ((0, 1), (1, 5), (2, 2))
            d.rectangle([x, y, x + 8, y + 8], fill=(26, 22, 26), outline=(4, 4, 5))
            if lit:
                d.rectangle([x + 2, y + 2, x + 6, y + 6], fill=(255, 140, 30) if row != 1 else (90, 255, 120))
    for col in range(5):  # toggle switches
        x = 96 + (col % 2) * 14
        y = 6 + (col // 2) * 16
        d.rectangle([x, y, x + 8, y + 12], fill=(6, 6, 7))
        d.rectangle([x + 3, y + 2 + (col % 2) * 5, x + 5, y + 5 + (col % 2) * 5], fill=(70, 66, 60))
    d.rectangle([4, 42, 124, 43], fill=(60, 44, 10))
    d.fontmode = "1"
    d.text((6, 48), "PUMP  VALVE  SWEEP", font=_font("Silkscreen-Regular.ttf", 8), fill=(70, 64, 54))
    arr = _grime(np.asarray(im, dtype=np.float32) / 255, rng, h, w, 0.6)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(_path("kit_panel.png"))


def keys():
    """Chunky keyboard: 4 rows of keycaps with pale legends, a long space bar, worn home row."""
    rng = np.random.default_rng(52)
    w, h = 128, 48
    im = Image.new("RGB", (w, h), (8, 7, 9))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f = _font("Silkscreen-Regular.ttf", 8)
    rows = ["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]
    for r, keys_ in enumerate(rows):
        for i, ch in enumerate(keys_):
            x, y = 3 + r * 3 + i * 12, 2 + r * 9
            d.rectangle([x, y, x + 10, y + 7], fill=(34, 30, 34), outline=(3, 3, 4))
            d.text((x + 3, y), ch, font=f, fill=(92, 86, 76))
    d.rectangle([30, 39, 96, 45], fill=(34, 30, 34), outline=(3, 3, 4))
    arr = _grime(np.asarray(im, dtype=np.float32) / 255, rng, h, w, 0.7)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(_path("kit_keys.png"))


def keypad():
    """Wall keypad: 3 x 4 steel keys, worn digits, one amber key lamp."""
    rng = np.random.default_rng(53)
    w, h = 48, 64
    im = Image.new("RGB", (w, h), (10, 9, 11))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    f = _font("Silkscreen-Regular.ttf", 8)
    for i, ch in enumerate("123456789*0#"):
        x, y = 4 + (i % 3) * 14, 4 + (i // 3) * 15
        d.rectangle([x, y, x + 11, y + 12], fill=(40, 36, 40), outline=(3, 3, 4))
        d.text((x + 3, y + 2), ch, font=f, fill=(110, 100, 86))
    d.rectangle([4, 62, 43, 63], fill=(200, 110, 20))
    arr = _grime(np.asarray(im, dtype=np.float32) / 255, rng, h, w, 0.6)
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(_path("kit_keypad.png"))


# ------------------------------------------------------------------ labels (RGBA decals)
def _worn(im, seed, holes=0.12, rust=True):
    rng = np.random.default_rng(seed)
    arr = np.asarray(im, dtype=np.float32) / 255
    h, w = arr.shape[:2]
    rot = np.resize(_noise(128, 6, rng), (h, w))
    arr[..., :3] *= (0.45 + 0.4 * rot)[..., None]
    if rust:
        drip = np.zeros((h, w), dtype=np.float32)
        _streaks(drip, rng, 8, 10, 40, -0.6, -1.0, 2)
        arr[..., 0] *= 1 + np.clip(drip, 0, 1) * 0.6
    arr[..., 3] *= (rng.random((h, w)) > holes) * (0.65 + 0.35 * (rot < 0.8))
    return Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")


def label_supply():
    """Crate stencil: 'OUTPOST 73 / SUPPLY / NO. 04', flaked like the bunker's wall stencil."""
    rng = np.random.default_rng(54)
    w, h = 192, 96
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 14), "OUTPOST 73", font=_font("Oxanium-SemiBold.ttf", 18), fill=255, anchor="mm")
    d.text((w // 2, 50), "SUPPLY", font=_font("Oxanium-SemiBold.ttf", 44), fill=255, anchor="mm")
    d.text((w // 2, 84), "NO. 04  //  KEEP DRY", font=_font("Oxanium-SemiBold.ttf", 13), fill=255, anchor="mm")
    d.rectangle([0, 52, w, 54], fill=0)  # stencil bridge
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.3 + 1.4 * np.resize(_noise(192, 6, rng), (h, w)), 0, 1)
    _save_img("kit_decal_supply.png", _rgba((0.46, 0.44, 0.40), a * wear * (rng.random((h, w)) > 0.25) * 0.8))


def label_amber():
    """Amber-hazard label (drums, cells): faded amber plate, black drop icon, KEEP SEALED."""
    w, h = 96, 96
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([2, 2, w - 3, h - 3], fill=(130, 84, 14, 255), outline=(12, 12, 12, 255), width=3)
    d.polygon([(48, 12), (66, 42), (62, 54), (48, 60), (34, 54), (30, 42)], fill=(12, 12, 12, 255))  # drop
    d.ellipse([40, 38, 50, 48], fill=(130, 84, 14, 255))
    d.text((48, 72), "AMBER", font=_font("Silkscreen-Regular.ttf", 12), fill=(12, 12, 12, 255), anchor="mm")
    d.text((48, 85), "KEEP SEALED", font=_font("Silkscreen-Regular.ttf", 8), fill=(12, 12, 12, 255), anchor="mm")
    _worn(im, 55).save(_path("kit_decal_amber.png"))


def label_plate():
    """Riveted ID plate for terminals, lockers and cabinets: 'OUTPOST 73' + a unit code."""
    w, h = 128, 48
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, w - 2, h - 2], fill=(70, 66, 58, 255), outline=(14, 12, 12, 255), width=2)
    d.text((w // 2, 13), "OUTPOST 73 // RELAY", font=_font("Silkscreen-Regular.ttf", 8), fill=(14, 12, 12, 255), anchor="mm")
    d.text((w // 2, 32), "UNIT T-04", font=_font("Oxanium-SemiBold.ttf", 16), fill=(14, 12, 12, 255), anchor="mm")
    for x, y in ((5, 5), (w - 6, 5), (5, h - 6), (w - 6, h - 6)):
        d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=(20, 10, 6, 255))
    _worn(im, 56, holes=0.06).save(_path("kit_decal_plate.png"))


# ------------------------------------------------------------------ field dosimeter + its wall rack
def meter_face():
    """Backlit analog meter (albedo + emission): amber scale 0..10 over the needle's +-50 deg swing, red top end.
    Needle pivot (64, 78) and radius 60 px match kit_dims (NEEDLE_PIVOT_Z, NEEDLE_LEN, NEEDLE_SWING)."""
    rng = np.random.default_rng(57)
    w, h = 128, 80
    im = Image.new("RGB", (w, h), (150, 104, 40))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    cx, cy, r = 64, 78, 60
    ink = (24, 16, 10)
    a0, a1 = 270 - K.NEEDLE_SWING, 270 + K.NEEDLE_SWING         # PIL angles: 0 = east, clockwise
    d.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=ink, width=2)
    d.arc([cx - r + 3, cy - r + 3, cx + r - 3, cy + r - 3], a1 - 20, a1, fill=(150, 30, 16), width=5)   # red zone
    f = _font("Silkscreen-Regular.ttf", 8)
    for i in range(11):
        a = math.radians(a0 + (a1 - a0) * i / 10)
        ln = 8 if i % 5 == 0 else 5
        p0 = (cx + r * math.cos(a), cy + r * math.sin(a))
        p1 = (cx + (r - ln) * math.cos(a), cy + (r - ln) * math.sin(a))
        d.line([p0, p1], fill=ink, width=1)
        if i % 2 == 0:
            d.text((cx + (r - 16) * math.cos(a), cy + (r - 16) * math.sin(a)), str(i), font=f, fill=ink, anchor="mm")
    d.text((64, 50), "SIGNAL", font=f, fill=ink, anchor="mm")
    d.text((5, 72), "x10", font=f, fill=ink, anchor="lm")
    d.text((123, 72), "MK-IV", font=f, fill=ink, anchor="rm")
    arr = np.asarray(im, dtype=np.float32) / 255
    yy, xx = np.mgrid[0:h, 0:w]
    arr *= np.clip(1.15 - 0.55 * (((xx - 64) / 64) ** 2 + ((yy - 30) / 60) ** 2), 0.35, 1.0)[..., None]    # uneven backlight
    arr *= (0.85 + 0.15 * np.resize(_noise(128, 6, rng), (h, w)))[..., None]                             # yellowed plastic
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGB").save(_path("kit_meter_face.png"))


def screen_dosi():
    """Dosimeter display on its charger: the bar graph with every bar unlit (standby). The held device lights the same
    layout live (scripts/dosimeter_view.gd BAR_*: 10 bars, x0 6, 12 wide, gap 3, bottom 70, height 18..60)."""
    im = Image.new("RGB", (160, 80), (4, 3, 1))
    d = ImageDraw.Draw(im)
    dim = tuple(int(c * 0.16) for c in AMBER)
    for i in range(10):
        h = round(18 + (60 - 18) * i / 9)
        x = 6 + i * 15
        d.rectangle([x, 70 - h, x + 11, 69], fill=dim)
    _save_img("kit_screen_dosi.png", _crt(im, vignette=0.4, bloom=1.0))


def label_dosimeter():
    """Front print strip under the meter: model name and a small trefoil."""
    w, h = 128, 24
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    d.text((20, 7), "FIELD DOSIMETER", font=_font("Silkscreen-Regular.ttf", 8), fill=(170, 160, 140, 255), anchor="lm")
    d.text((20, 17), "MK-IV  OUTPOST 73", font=_font("Silkscreen-Regular.ttf", 8), fill=(120, 112, 98, 255), anchor="lm")
    d.ellipse([3, 3, 17, 17], fill=(150, 104, 30, 255))
    for a0 in (30, 150, 270):
        d.pieslice([5, 5, 15, 15], a0, a0 + 60, fill=(14, 12, 12, 255))
    _worn(im, 58, holes=0.05, rust=False).save(_path("kit_decal_dosi.png"))


def label_shadowboard():
    """Field-kit rack shadow board: painted device outlines behind the three slots, stencil header, slot numbers and the
    sign-out chalk of the two that never came back (day 112: the day the bulkhead was sealed)."""
    rng = np.random.default_rng(59)
    w, h = int(K.BOARD_W * K.BOARD_PPM), int(K.BOARD_H * K.BOARD_PPM)
    px = lambda x: w / 2 + x * K.BOARD_PPM                      # noqa: E731
    py = lambda z: h / 2 - (z - K.RACK_ZC) * K.BOARD_PPM        # noqa: E731
    paint = (190, 176, 150, 255)
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((w // 2, 12), "FIELD KIT  //  SIGN OUT", font=_font("Oxanium-SemiBold.ttf", 15), fill=paint, anchor="mm")
    base, top = K.RACK_DEVICE_Z, K.RACK_DEVICE_Z + K.DOSI_H
    for i, sx in enumerate(K.RACK_SLOTS):
        x0, x1 = px(sx - K.DOSI_W / 2 - 0.006), px(sx + K.DOSI_W / 2 + 0.006)
        d.rounded_rectangle([x0, py(top + 0.006), x1, py(base - 0.004)], 4, outline=paint, width=2)            # body
        d.line([(px(sx - 0.07), py(top)), (px(sx - 0.07), py(base + K.DOSI_TOP)), (px(sx + 0.07), py(base + K.DOSI_TOP)),
                (px(sx + 0.07), py(top))], fill=paint, width=2)                                                 # handle
        d.rectangle([px(sx + K.DOSI_W / 2 + 0.004), py(top - 0.01), px(sx + K.DOSI_W / 2 + 0.036), py(base + 0.012)],
                    outline=paint, width=1)                                                                     # probe
        d.text((px(sx), py(base - 0.045)), f"0{i + 1}", font=_font("Oxanium-SemiBold.ttf", 16), fill=paint, anchor="mm")
    chalk = (200, 196, 186, 255)
    for i, (name, day) in enumerate((("R. Kovac", "out D112"), ("Mira", "out D112 ??"))):
        x = px(K.RACK_SLOTS[i])
        d.text((x, py(base - 0.105)), name, font=_font("Caveat-Regular.ttf", 17), fill=chalk, anchor="mm")
        d.text((x, py(base - 0.155)), day, font=_font("Caveat-Regular.ttf", 15), fill=chalk, anchor="mm")
    a = np.asarray(im, dtype=np.float32) / 255
    wear = np.clip(0.35 + 1.3 * np.resize(_noise(256, 6, rng), (h, w)), 0, 1) * (rng.random((h, w)) > 0.18)
    a[..., 3] *= wear * 0.85
    a[..., :3] *= 0.8
    Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA").save(_path("kit_decal_shadowboard.png"))


def label_relay():
    """Relay-mast warning plate: the mast's field keeps things away (the stalker safe zone), so the plate says so."""
    w, h = 128, 96
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    ink = (14, 12, 12, 255)
    d.rectangle([1, 1, w - 2, h - 2], fill=(128, 92, 16, 255), outline=ink, width=3)
    d.text((w // 2, 15), "RELAY MAST", font=_font("Oxanium-SemiBold.ttf", 17), fill=ink, anchor="mm")
    d.text((w // 2, 31), "OUTPOST NET", font=_font("Silkscreen-Regular.ttf", 8), fill=ink, anchor="mm")
    d.line([(34, 46), (48, 58), (58, 46), (70, 58), (80, 46), (94, 58)], fill=ink, width=3)       # field zigzag
    d.text((w // 2, 72), "FIELD ACTIVE", font=_font("Silkscreen-Regular.ttf", 10), fill=ink, anchor="mm")
    d.text((w // 2, 85), "WITHIN 20 M", font=_font("Silkscreen-Regular.ttf", 10), fill=ink, anchor="mm")
    _worn(im, 60).save(_path("kit_decal_relay.png"))


def screen_route():
    """terminal_router placeholder frame (the live table is drawn at runtime by hub_console_view.gd)."""
    lines = ["RELAY HUB 00 // ROUTER", "-" * 30, "R-73  OUTPOST 73   CARRIER", "R-02  OUTPOST 02   NO CARRIER",
             "R-03  OUTPOST 03   NO CARRIER", "R-00  SILO         NO CARRIER", "", "> AWAITING OPERATOR"]
    _save_img("kit_screen_route.png", _crt(_text_screen(lines, 18, AMBER, w=320, h=176, step=18)))


def label_route_keys():
    """Stencilled strip under the router's four route keys."""
    w, h = 256, 16
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i, key in enumerate(("R-73", "R-02", "R-03", "R-00")):
        d.text((32 + i * 64, h // 2), key, font=_font("Silkscreen-Regular.ttf", 10), fill=(150, 140, 120, 255), anchor="mm")
    _worn(im, 61, holes=0.2, rust=False).save(_path("kit_route_keys.png"))


def _path(name):
    import os
    from textures import OUT
    os.makedirs(OUT, exist_ok=True)
    print("TEX", name)
    return os.path.join(OUT, name)


if __name__ == "__main__":
    screen_log()
    screen_radar()
    screen_seal()
    screen_tape()
    panel()
    keys()
    keypad()
    label_supply()
    label_amber()
    label_plate()
    meter_face()
    screen_dosi()
    label_dosimeter()
    label_shadowboard()
    label_relay()
    screen_route()
    label_route_keys()
