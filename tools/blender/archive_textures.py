"""Textures for the records vault (tools/blender/kit/vault.py) and its furniture (archive.py, drawings.py). Same helpers and
look as textures.py / tunnel_textures.py: dim sRGB paper and card on obsidian, century-faded stencils. Functional labels
only (index scrawl, drawing numbers, zone stencils): no readable text beyond that.
The blueprints are drawings of places that exist in the world, laid out from kit_dims: the tunnel's cross-section, an
interchange hall, Missile Silo 00's section, the vault door.
Run: python tools/blender/archive_textures.py   -> models/generated/tex/kit_arch_*.png, kit_bp_*.png, tun_vault_*.png
then rebuild the pieces (they embed them).
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from textures import _font, _noise, _rgba, _save_img
from tunnel_textures import INK, PALE, _flake, _worn_rgba

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "kit"))
import kit_dims as K  # noqa: E402

CARD = [(64, 50, 34), (56, 45, 32), (72, 58, 40), (48, 40, 30)]     # archive box ends (aged board)
LABEL = (118, 110, 92)
SCRAWL = (34, 30, 28)
SHELF_BACK = (7, 6, 8)
PAPER = (122, 117, 104)
LINE = (44, 44, 50)


def _grime(im, seed, amount=0.35):
    """Dust and damp: a slow noise darkening plus speckle, alpha kept."""
    rng = np.random.default_rng(seed)
    a = np.asarray(im.convert("RGBA"), dtype=np.float32) / 255
    h, w = a.shape[:2]
    n = np.resize(_noise(max(w, h), 5, rng), (h, w))
    a[..., :3] *= (1.0 - amount * n)[..., None] * (0.92 + 0.08 * rng.random((h, w)))[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA")


def _scrawl(d, rng, x0, y0, w, rows=2, gap=4, col=SCRAWL):
    """Illegible handwriting: short wobbling strokes."""
    for r in range(rows):
        x, y = x0, y0 + r * gap
        while x < x0 + w - 3:
            seg = int(rng.integers(3, 9))
            d.line([(x, y + int(rng.integers(-1, 2))), (min(x + seg, x0 + w), y + int(rng.integers(-1, 2)))], fill=col)
            x += seg + int(rng.integers(2, 4))


# ------------------------------------------------------------------ shelf bays (archive_stack)
def box_rows(w=256, h=88, rows=4, seed=301):
    """Four shelf-bay strips (1 m wide each): archive boxes end-on with index cards and finger holes, lever-arch binders,
    gaps showing the dark shelf back. archive.py picks a strip per bay."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h * rows), SHELF_BACK + (255,))
    d = ImageDraw.Draw(im)
    for r in range(rows):
        y1 = (r + 1) * h - 1
        x = int(rng.integers(0, 6))
        while x < w - 8:
            kind = rng.random()
            if kind < 0.1:                                                # a gap
                x += int(rng.integers(10, 30))
                continue
            if kind < 0.3:                                                # a run of binders
                for _ in range(int(rng.integers(3, 7))):
                    bw = int(rng.integers(12, 17))
                    if x + bw > w - 2:
                        break
                    top = y1 - int(rng.integers(72, 84))
                    c = CARD[int(rng.integers(0, 4))]
                    d.rectangle([x, top, x + bw - 1, y1], fill=tuple(int(v * 0.55) for v in c))
                    d.rectangle([x + 3, top + 10, x + bw - 4, top + 26], fill=LABEL)
                    _scrawl(d, rng, x + 4, top + 14, bw - 7, 3, 4)
                    d.ellipse([x + bw // 2 - 3, y1 - 22, x + bw // 2 + 2, y1 - 12], fill=SHELF_BACK)
                    x += bw + 1
                continue
            bw = int(rng.integers(26, 40))                                # an archive box end
            if x + bw > w - 2:
                break
            top = y1 - int(rng.integers(64, 80))
            c = CARD[int(rng.integers(0, 4))]
            d.rectangle([x, top, x + bw - 1, y1], fill=c, outline=tuple(v // 2 for v in c))
            d.rectangle([x + 4, top + 6, x + bw - 5, top + 24], fill=LABEL, outline=(80, 74, 62))
            _scrawl(d, rng, x + 6, top + 11, bw - 11, 3, 4)
            d.ellipse([x + bw // 2 - 6, top + 32, x + bw // 2 + 5, top + 39], fill=(12, 10, 10))
            x += bw + int(rng.integers(0, 3))
        d.line([(0, r * h), (w, r * h)], fill=(3, 3, 4))
    _save_img("kit_arch_boxes.png", _grime(im, seed))


def stack_label(w=96, h=128, seed=302):
    """The index card holder on every stack's end panel: a card in a frame, ranges scrawled, a pull-tab."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (20, 19, 23, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([6, 8, w - 7, 78], fill=(10, 10, 12), outline=(60, 58, 64), width=2)
    d.rectangle([12, 14, w - 13, 72], fill=LABEL)
    for i in range(5):
        _scrawl(d, rng, 16, 22 + i * 10, w - 32, 1)
    d.rectangle([w // 2 - 16, 92, w // 2 + 15, 104], fill=(10, 10, 12), outline=(60, 58, 64))
    d.rectangle([w // 2 - 12, 95, w // 2 + 11, 101], fill=(70, 66, 58))
    _save_img("kit_arch_label.png", _grime(im, seed, 0.25))


# ------------------------------------------------------------------ drawer fronts
def plan_front(w=256, h=80, seed=303):
    """One five-drawer plan chest unit's face (1.35 x 0.42 m): drawer seams, a card slot mid-drawer."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (22, 21, 25, 255))
    d = ImageDraw.Draw(im)
    dh = h // 5
    for i in range(5):
        y = i * dh
        d.rectangle([1, y + 1, w - 2, y + dh - 2], fill=(26, 25, 29), outline=(8, 8, 10))
        d.rectangle([w // 2 - 14, y + 4, w // 2 + 13, y + dh - 5], fill=(12, 12, 14))
        d.rectangle([w // 2 - 11, y + 5, w // 2 + 10, y + dh - 6], fill=LABEL if rng.random() > 0.2 else (12, 12, 14))
        _scrawl(d, rng, w // 2 - 9, y + 8, 18, 1)
    _save_img("kit_arch_plan.png", _grime(im, seed, 0.3))


def catalog_front(w=192, h=256, cols=6, rows=9, seed=304):
    """Card catalogue face: small drawers, each a label frame over a pull. Geometry adds the knobs."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (8, 7, 9, 255))
    d = ImageDraw.Draw(im)
    cw, ch = w // cols, h // rows
    for c in range(cols):
        for r in range(rows):
            x, y = c * cw, r * ch
            d.rectangle([x + 1, y + 1, x + cw - 2, y + ch - 2], fill=(30, 27, 26))
            d.rectangle([x + 7, y + 5, x + cw - 8, y + 13], fill=(58, 56, 60))
            if rng.random() > 0.15:
                d.rectangle([x + 8, y + 6, x + cw - 9, y + 12], fill=LABEL)
                _scrawl(d, rng, x + 10, y + 8, cw - 20, 1)
    _save_img("kit_arch_catalog.png", _grime(im, seed, 0.3))


def file_front(w=96, h=64, seed=305):
    """One filing cabinet drawer face: a label frame over the pull."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), (24, 23, 27, 255))
    d = ImageDraw.Draw(im)
    d.rectangle([2, 2, w - 3, h - 3], outline=(10, 10, 12), width=2)
    d.rectangle([w // 2 - 16, 12, w // 2 + 15, 24], fill=(60, 58, 64))
    d.rectangle([w // 2 - 14, 14, w // 2 + 13, 22], fill=LABEL)
    _scrawl(d, rng, w // 2 - 12, 17, 24, 1)
    _save_img("kit_arch_file.png", _grime(im, seed, 0.3))


# ------------------------------------------------------------------ blueprints (whiteprints gone to the colour of dust)
def _sheet(w, h, seed):
    """Aged sheet, title block bottom right, border, fold creases; alpha frays the edges."""
    rng = np.random.default_rng(seed)
    im = Image.new("RGBA", (w, h), PAPER + (255,))
    d = ImageDraw.Draw(im)
    faint = tuple((p * 3 + q) // 4 for p, q in zip(PAPER, LINE))
    for g in range(16, max(w, h), 16):                                     # the drawing grid, faint
        d.line([(g, 6), (g, h - 7)], fill=faint)
        d.line([(6, g), (w - 7, g)], fill=faint)
    d.rectangle([6, 6, w - 7, h - 7], outline=LINE, width=2)
    tx, ty = w - 110, h - 36
    d.rectangle([tx, ty, w - 7, h - 7], fill=PAPER)
    d.rectangle([tx, ty, w - 7, h - 7], outline=LINE, width=2)
    d.line([(tx, ty + 14), (w - 7, ty + 14)], fill=LINE)
    d.line([(tx + 60, ty + 14), (tx + 60, h - 7)], fill=LINE)
    d.text((tx + 4, ty + 2), "DWG %02d-%03d" % (seed % 7, seed % 997), font=_font("ShareTechMono-Regular.ttf", 10), fill=LINE)
    _scrawl(d, rng, tx + 4, ty + 19, 52, 2, 5, LINE)
    return im, d, rng


def _finish_sheet(im, name, seed):
    rng = np.random.default_rng(seed)
    a = np.asarray(im, dtype=np.float32) / 255
    h, w = a.shape[:2]
    rot = np.resize(_noise(max(w, h), 4, rng), (h, w))
    a[..., :3] *= (0.78 + 0.22 * rot)[..., None]
    for fx in (w // 2,):                                                   # a fold crease down the middle
        a[:, fx - 1:fx + 1, :3] *= 0.7
    a[h // 2 - 1:h // 2 + 1, :, :3] *= 0.75
    edge = np.minimum.reduce([np.arange(w)[None, :].repeat(h, 0), (w - 1 - np.arange(w))[None, :].repeat(h, 0),
                              np.arange(h)[:, None].repeat(w, 1), (h - 1 - np.arange(h))[:, None].repeat(w, 1)])
    a[..., 3] = np.where(edge < 2 + 3 * rot, 0.0, 1.0)                     # frayed edges
    a[..., 3] *= rng.random((h, w)) > 0.002
    out = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8), "RGBA").filter(ImageFilter.SMOOTH)
    _save_img(name, out)


def bp_tunnel(w=384, h=256, seed=311):
    """The single-track bore in section, from kit_dims: lining, arch, track, conductor, walkway, main."""
    im, d, _rng = _sheet(w, h, seed)
    s, cx, base = 32.0, 150, 205                                           # px per metre, tunnel centre, invert line
    X = lambda x: cx + x * s  # noqa: E731
    Z = lambda z: base - z * s  # noqa: E731
    for off in (0.0, K.TUN_LINING):
        r = K.TUN_HW + off
        d.line([(X(-r), Z(0)), (X(-r), Z(K.TUN_SPRING))], fill=LINE, width=2)
        d.line([(X(r), Z(0)), (X(r), Z(K.TUN_SPRING))], fill=LINE, width=2)
        d.arc([X(-r), Z(K.TUN_SPRING + r), X(r), Z(K.TUN_SPRING - r)], 180, 360, fill=LINE, width=2)
    d.line([(X(-K.TUN_HW - 0.8), Z(0)), (X(K.TUN_HW + 0.8), Z(0))], fill=LINE, width=2)
    d.rectangle([X(K.WALK_X0), Z(K.WALK_Z), X(K.TUN_HW), Z(0)], outline=LINE)
    for g in (-K.GAUGE / 2, K.GAUGE / 2):
        d.rectangle([X(K.TRACK_X + g) - 2, Z(K.RAIL_TOP), X(K.TRACK_X + g) + 2, Z(0)], fill=LINE)
    d.rectangle([X(K.TRACK_X - 1.25), Z(0.05), X(K.TRACK_X + 1.25), Z(-0.1)], outline=LINE)
    d.ellipse([X(K.MAIN_X - K.MAIN_R), Z(K.MAIN_Z + K.MAIN_R), X(K.MAIN_X + K.MAIN_R), Z(K.MAIN_Z - K.MAIN_R)], outline=LINE, width=2)
    d.rectangle([X(K.POWER_X - 0.06), Z(0.33), X(K.POWER_X + 0.06), Z(0.2)], fill=LINE)
    for y in (Z(K.TUN_CROWN), Z(0)):                                       # height dimension
        d.line([(X(K.TUN_HW + 1.0), y), (X(K.TUN_HW + 1.5), y)], fill=LINE)
    d.line([(X(K.TUN_HW + 1.25), Z(K.TUN_CROWN)), (X(K.TUN_HW + 1.25), Z(0))], fill=LINE)
    d.line([(X(-K.TUN_HW), Z(-0.45)), (X(K.TUN_HW), Z(-0.45))], fill=LINE)
    _finish_sheet(im, "kit_bp_tunnel.png", seed)


def bp_junction(w=384, h=256, seed=312):
    """An interchange hall in plan: the round hall, four throats, the turntable and its bridge."""
    im, d, _rng = _sheet(w, h, seed)
    s, cx, cy = 7.5, 150, 124
    P = lambda x, y: (cx + x * s, cy - y * s)  # noqa: E731
    for r in (K.JUNC_HALL_R, K.JUNC_HALL_R + 0.5):
        d.ellipse([cx - r * s, cy - r * s, cx + r * s, cy + r * s], outline=LINE, width=2)
    for r in (K.JUNC_PIT_R, K.JUNC_PIT_R - 0.75):
        d.ellipse([cx - r * s, cy - r * s, cx + r * s, cy + r * s], outline=LINE)
    for k in range(4):
        a = math.radians(90 * k)
        u, v = math.cos(a), math.sin(a)
        for side in (-1, 1):
            x0, y0 = u * K.JUNC_HALL_R + side * -v * K.TUN_HW, v * K.JUNC_HALL_R + side * u * K.TUN_HW
            d.line([P(x0, y0), P(x0 + u * (K.JUNC_R - K.JUNC_HALL_R + 3), y0 + v * (K.JUNC_R - K.JUNC_HALL_R + 3))], fill=LINE, width=2)
        d.line([P(u * K.JUNC_PIT_R, v * K.JUNC_PIT_R), P(u * (K.JUNC_R + 3), v * (K.JUNC_R + 3))], fill=LINE)
    u, v = math.cos(math.radians(22)), math.sin(math.radians(22))           # the turntable bridge, left askew
    for side in (-1.2, 1.2):
        d.line([P(-4.8 * u - side * v, -4.8 * v + side * u), P(4.8 * u - side * v, 4.8 * v + side * u)], fill=LINE, width=2)
    _finish_sheet(im, "kit_bp_junction.png", seed)


def bp_silo(w=256, h=384, seed=313):
    """Missile Silo 00 in section: the bore, the cap petals thrown open, the stair tower's switchback, level 09, the lift
    shaft down to the generator hall."""
    im, d, _rng = _sheet(w, h, seed)
    s, cx, top = 1.35, 120, 60
    X = lambda x: cx + x * s  # noqa: E731
    Z = lambda z: top - z * s  # noqa: E731
    d.line([(X(-80), Z(0)), (X(-58), Z(0))], fill=LINE, width=2)
    d.line([(X(58), Z(0)), (X(80), Z(0))], fill=LINE, width=2)
    for x in (-56, 56):
        d.line([(X(x), Z(0)), (X(x), Z(-136))], fill=LINE, width=2)
    d.line([(X(-56), Z(-136)), (X(56), Z(-136))], fill=LINE, width=2)
    for side in (-1, 1):                                                   # petals thrown back
        d.line([(X(side * 58), Z(0)), (X(side * 76), Z(38))], fill=LINE, width=3)
    for i in range(9):                                                     # the stair tower's switchback
        z0 = -4 * i
        d.line([(X(-53 + (i % 2) * 8), Z(z0)), (X(-45 - (i % 2) * 8), Z(z0 - 4))], fill=LINE)
    d.rectangle([X(-60), Z(-34), X(-52), Z(-38)], outline=LINE)            # level 09 / launch control
    d.line([(X(-64), Z(-36)), (X(-64), Z(-120))], fill=LINE)               # lift shaft
    d.line([(X(-67), Z(-36)), (X(-67), Z(-120))], fill=LINE)
    d.rectangle([X(-77), Z(-86), X(-56), Z(-120)], outline=LINE, width=2)  # generator hall
    for z in range(-10, -130, -12):
        d.line([(X(54), Z(z)), (X(56), Z(z))], fill=LINE)
    _finish_sheet(im, "kit_bp_silo.png", seed)


def bp_door(w=384, h=256, seed=314):
    """This vault's own door: elevation (flange, plug, bolts, wheel) and a section through the wall."""
    im, d, _rng = _sheet(w, h, seed)
    s, cx, cy = 48.0, 110, 118
    for r, wd in ((K.DOOR_FLANGE, 2), (K.DOOR_R, 1), (0.55, 2), (0.12, 1)):
        d.ellipse([cx - r * s, cy - r * s, cx + r * s, cy + r * s], outline=LINE, width=wd)
    for i in range(14):
        a = math.tau * i / 14
        d.line([(cx + math.cos(a) * 1.2 * s, cy + math.sin(a) * 1.2 * s), (cx + math.cos(a) * 1.4 * s, cy + math.sin(a) * 1.4 * s)],
               fill=LINE, width=3)
    for i in range(3):
        a = math.tau * i / 3 + 0.5
        d.line([(cx, cy), (cx + math.cos(a) * 0.55 * s, cy + math.sin(a) * 0.55 * s)], fill=LINE, width=2)
    sx = 250                                                               # section: wall, plug, flange, hinge
    d.rectangle([sx, cy - 2.2 * s, sx + K.VAULT_WALL * s * 0.6, cy - K.DOOR_R * s], outline=LINE, width=2)
    d.rectangle([sx, cy + K.DOOR_R * s, sx + K.VAULT_WALL * s * 0.6, cy + 2.2 * s], outline=LINE, width=2)
    d.rectangle([sx - 10, cy - K.DOOR_FLANGE * s, sx, cy + K.DOOR_FLANGE * s], outline=LINE, width=2)
    d.rectangle([sx, cy - (K.DOOR_R - 0.02) * s, sx + K.VAULT_WALL * s * 0.5, cy + (K.DOOR_R - 0.02) * s], outline=LINE)
    _finish_sheet(im, "kit_bp_door.png", seed)


# ------------------------------------------------------------------ the vault's own signage and floor marks
def _stencil(name, lines, w, h, seed, sizes):
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    y = 0
    for text, size in zip(lines, sizes):
        y += size // 2 + 4
        d.text((w // 2, y), text, font=_font("Oxanium-SemiBold.ttf", size), fill=255, anchor="mm")
        y += size // 2 + 2
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.3, 0.2)
    _save_img(name, _rgba(PALE, a * 0.75))


def zone_stencils():
    """Portal plate over the door (tunnel side) and the zone stencils inside, one image each."""
    _stencil("tun_vault.png", ["LINE 00", "RECORDS"], 256, 64, 321, [18, 30])
    _stencil("tun_vault_files.png", ["FILES"], 256, 64, 322, [44])
    _stencil("tun_vault_drawings.png", ["DRAWINGS"], 256, 64, 323, [40])
    _stencil("tun_vault_tapes.png", ["TAPES"], 256, 64, 324, [44])


def row_numbers(cell=64, n=16, seed=325):
    """Floor stencils in front of the stacks, 01..16 in a 4 x 4 atlas (vault.py picks a cell by UV)."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (cell * 4, cell * 4), 0)
    d = ImageDraw.Draw(im)
    for i in range(n):
        x, y = (i % 4) * cell, (i // 4) * cell
        d.text((x + cell // 2, y + cell // 2), "%02d" % (i + 1), font=_font("Oxanium-SemiBold.ttf", 40), fill=255, anchor="mm")
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.35, 0.15)
    _save_img("tun_vault_rows.png", _rgba(PALE, a * 0.6))


def wire_mesh(w=64, h=64):
    """Security cage mesh: a diamond weave, alpha outside the wires (tiles every 0.25 m)."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    for i in range(-w, w * 2, 16):
        d.line([(i, 0), (i + h, h)], fill=(40, 38, 44, 255), width=2)
        d.line([(i, h), (i + h, 0)], fill=(40, 38, 44, 255), width=2)
    _save_img("tun_vault_mesh.png", im)


def dial(w=128, seed=326):
    """The combination dial's face: ticks and numbers round a rim (a decal on the dial)."""
    im = Image.new("RGBA", (w, w), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = w / 2
    d.ellipse([2, 2, w - 3, w - 3], fill=(30, 29, 33, 255), outline=(12, 12, 14, 255), width=3)
    for i in range(100):
        a = math.tau * i / 100 - math.pi / 2
        r0 = c - (14 if i % 10 == 0 else 9)
        d.line([(c + math.cos(a) * r0, c + math.sin(a) * r0), (c + math.cos(a) * (c - 5), c + math.sin(a) * (c - 5))],
               fill=(110, 106, 96, 255), width=1)
        if i % 10 == 0:
            d.text((c + math.cos(a) * (c - 24), c + math.sin(a) * (c - 24)), str(i), font=_font("ShareTechMono-Regular.ttf", 10),
                   fill=(110, 106, 96, 255), anchor="mm")
    d.ellipse([c - 22, c - 22, c + 22, c + 22], fill=(16, 16, 18, 255))
    _worn_rgba(im, seed, holes=0.02).save(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "models",
                                                       "generated", "tex", "tun_vault_dial.png"))
    print("TEX tun_vault_dial.png")


if __name__ == "__main__":
    box_rows()
    stack_label()
    plan_front()
    catalog_front()
    file_front()
    bp_tunnel()
    bp_junction()
    bp_silo()
    bp_door()
    zone_stencils()
    row_numbers()
    wire_mesh()
    dial()
