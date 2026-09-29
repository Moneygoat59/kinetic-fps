"""Small fittings inside Missile Silo 00's freight lift cage (tools/blender/props/silo_lift_cab.py), finer than the walls
(256 px per metre) because they carry lettering: the control panel face and the capacity plate. Drawn at 3x and averaged
down (anti-aliased), in the same dark obsidian steel as lift_textures.py with amber only as worn paint.
Layout is shared with silo_lift_cab.py, keep equal: PANEL is 0.5 x 0.8 m, the two glowing buttons sit at BUTTONS (fractions
of the face, from its top left), the stop button at STOP.
Run: python tools/blender/lift_fixtures.py   -> models/generated/tex/lift_panel.png, lift_plate.png
"""
import numpy as np
from PIL import Image, ImageDraw

from textures import _fbm, _font, _save_img

K = 3                                            # supersampling
STEEL = (30, 26, 32)
EDGE = (52, 45, 52)
AMBER = (112, 72, 15)
INK = (14, 12, 14)
PALE = (128, 114, 96)
BUTTONS = ((0.32, 0.43), (0.32, 0.61))           # RAISE above LOWER (to the hall)
LAMPS = ((0.30, 0.19), (0.70, 0.19))
STOP = (0.5, 0.75)


class Sheet:
    """A canvas in output pixels, drawn at K times and averaged down."""

    def __init__(self, w, h, fill):
        self.w, self.h = w, h
        self.im = Image.new("RGB", (w * K, h * K), fill)
        self.d = ImageDraw.Draw(self.im)

    def rect(self, x0, y0, x1, y1, **kw):
        self.d.rectangle([x0 * K, y0 * K, x1 * K, y1 * K], **kw)

    def circ(self, cx, cy, r, **kw):
        self.d.ellipse([(cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K], **kw)

    def line(self, pts, width, fill):
        self.d.line([(x * K, y * K) for x, y in pts], fill=fill, width=int(width * K))

    def poly(self, pts, fill):
        self.d.polygon([(x * K, y * K) for x, y in pts], fill=fill)

    def hatch_disc(self, cx, cy, r, fill, ink):
        """A disc of diagonal stripes, clipped to its circle."""
        layer = Image.new("RGB", self.im.size, fill)
        d = ImageDraw.Draw(layer)
        for k in range(-int(r * 1.4), int(r * 1.4) + 1, 7):
            d.line([((cx + k - r) * K, (cy + r) * K), ((cx + k + r) * K, (cy - r) * K)], fill=ink, width=int(2.4 * K))
        mask = Image.new("L", self.im.size, 0)
        ImageDraw.Draw(mask).ellipse([(cx - r) * K, (cy - r) * K, (cx + r) * K, (cy + r) * K], fill=255)
        self.im.paste(layer, (0, 0), mask)

    def text(self, x, y, s, size, fill, anchor="mm"):
        self.d.text((x * K, y * K), s, font=_font("Oxanium-SemiBold.ttf", int(size * K)), fill=fill, anchor=anchor)

    def done(self):
        return np.asarray(self.im.resize((self.w, self.h), Image.LANCZOS), dtype=np.float32) / 255


def weather(a, seed, grime=0.4, rust=0.35):
    """Smooth century wear: uneven grime, rust bloom toward the bottom, a faint grain."""
    rng = np.random.default_rng(seed)
    h, w = a.shape[:2]
    n = max(h, w)
    f = _fbm(n, rng, ((3, 0.4), (6, 0.3), (12, 0.2), (24, 0.1)))[:h, :w]
    a = a * (1 - grime * f)[..., None]
    r = np.clip((f - 0.6) * 3, 0, 1) * np.linspace(0.2, 1, h)[:, None] * rust
    a = a * (1 - 0.5 * r[..., None]) + np.array([0.075, 0.032, 0.011]) * r[..., None]
    a *= (0.96 + 0.08 * rng.random((h, w)))[..., None]
    return np.clip(a, 0, 1)


def save(name, a):
    _save_img(name, Image.fromarray((a * 255).astype(np.uint8)))


def panel(w=128, h=205):
    """Control panel face: LIFT 00 nameplate, two status lamps (09 / HALL), the RAISE and LOWER rings, the stop button under
    a hatch-marked ring, an intercom grille."""
    s = Sheet(w, h, STEEL)
    s.rect(1.5, 1.5, w - 2.5, h - 2.5, outline=EDGE, width=K * 2)
    s.rect(14, 9, w - 15, 28, fill=AMBER, outline=INK, width=K)
    s.text(w / 2, 18.5, "LIFT 00", 13, INK)
    for (fx, fy), label in zip(LAMPS, ("09", "HALL")):
        s.circ(fx * w, fy * h, 8, fill=(40, 26, 16), outline=(70, 52, 34), width=K)
        s.text(fx * w, fy * h + 18, label, 11, PALE)
    for (fx, fy), (up, label) in zip(BUTTONS, ((True, "RAISE"), (False, "LOWER"))):
        cx, cy = fx * w, fy * h
        s.circ(cx, cy, 17, fill=(36, 30, 32), outline=AMBER, width=K * 2)
        s.circ(cx, cy, 11.5, fill=(20, 17, 18), outline=INK, width=K)
        tri = [(cx - 6, cy + 5), (cx + 6, cy + 5), (cx, cy - 6)] if up else [(cx - 6, cy - 5), (cx + 6, cy - 5), (cx, cy + 6)]
        s.poly(tri, (74, 50, 18))
        s.text(cx + 24, cy, label, 12, PALE, "lm")
    sx, sy = STOP[0] * w, STOP[1] * h
    s.hatch_disc(sx, sy, 19, AMBER, INK)
    s.circ(sx, sy, 19, outline=INK, width=K)
    s.circ(sx, sy, 11, fill=(46, 24, 14), outline=INK, width=K)
    s.text(sx, sy + 29, "STOP", 11, PALE)
    for gy in (h - 15, h - 10, h - 5):
        for gx in range(16, w - 12, 8):
            s.circ(gx, gy, 1.5, fill=(6, 5, 6))
    for bx, by in ((6, 6), (w - 7, 6), (6, h - 7), (w - 7, h - 7)):
        s.circ(bx, by, 2.2, fill=(96, 82, 74), outline=INK, width=1)
    save("lift_panel.png", weather(s.done(), 301, 0.3, 0.25))


def plate(w=169, h=102):
    """Capacity plate: the lift's name, its run, its load, and the one rule. Amber paint on steel, half rubbed away."""
    s = Sheet(w, h, AMBER)
    s.rect(3, 3, w - 4, h - 4, outline=INK, width=K * 2)
    s.text(w / 2, 19, "FREIGHT LIFT 00", 17, INK)
    s.line([(11, 32), (w - 11, 32)], 1.2, INK)
    for y, text in ((47, "LEVEL 09 - HALL 84 M"), (62, "MAX LOAD 6000 KG"), (79, "GATES SHUT"), (91, "BEFORE TRAVEL")):
        s.text(w / 2, y, text, 11, INK)
    for bx, by in ((8, 8), (w - 9, 8), (8, h - 9), (w - 9, h - 9)):
        s.circ(bx, by, 3, fill=(56, 38, 10), outline=INK, width=K)
    a = weather(s.done(), 302, 0.35, 0.5)
    rng = np.random.default_rng(303)
    f = _fbm(max(h, w), rng, ((4, 0.5), (8, 0.3), (16, 0.2)))[:h, :w]
    bare = np.clip((f - 0.68) * 6, 0, 1)[..., None]                       # paint rubbed off to dark steel
    a = a * (1 - bare) + (np.array(STEEL) / 255) * 0.9 * bare
    save("lift_plate.png", a)


if __name__ == "__main__":
    panel()
    plate()
