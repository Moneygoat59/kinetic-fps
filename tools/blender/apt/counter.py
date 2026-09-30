"""Apartment kit: things on the kitchen worktop (tabletop pieces: place them at apt_dims.COUNTER_H). Round things are turned
(apt_forms.lathe), so they read as ceramic and steel rather than cylinders. Unplugged, cords coiled in front, labels forward.
kettle      brushed-steel electric kettle, black lid, handle and base
toaster     cream two-slot toaster, chrome lever and dial
dish_rack   chrome wire rack on a drip tray: four plates on edge, two mugs upside down
canisters   four identical canisters, wooden lids, label-maker labels SUGAR TEA RICE FLOUR, 12 cm apart
fruit_bowl  white bowl, four apples in a square (for the dining table, at apt_dims.TABLE_H)
"""
import math

import apt_dims as D
import apt_forms as F
from apt_lib import AptKit


def _coil(k, name, c, r=0.03, turns=3, plug=None):
    """Flat spiral of cord, 8 mm further out each turn, plug at the end (plug=node name: its own pivot node, e.g. lift_plug)."""
    grow = lambda i: r + 0.008 * i / 16  # noqa: E731
    pts = [(c[0] + grow(i) * math.cos(i * math.tau / 16), c[1] + grow(i) * math.sin(i * math.tau / 16), 0.0035)
           for i in range(16 * turns + 1)]
    k.PIPE(name, pts, 0.0035, k.CORD, verts=6)
    px = c[0] + grow(16 * turns) + 0.018
    k.B(name + "_plug", (0.03, 0.022, 0.014), (px, c[1], 0.007), k.BLACK, 0.003, into=k.PIVOT(plug, (px, c[1], 0.0)) if plug else None)


def kettle():
    k = AptKit("kettle")
    k.parts.append(F.lathe("base", [(0, 0), (0.088, 0), (0.09, 0.012), (0.084, 0.022), (0, 0.022)], k.BLACK))
    body = [(0, 0.022), (0.078, 0.022), (0.082, 0.03), (0.08, 0.1), (0.072, 0.17), (0.06, 0.205), (0.058, 0.212),
            (0.05, 0.222), (0.03, 0.23), (0.012, 0.232), (0.012, 0.242), (0, 0.244)]
    k.parts.append(F.lathe("body", body, None, mats=[k.STEEL, k.BLACK], ring_mat=[0] * 6 + [1] * 5, segs=32))
    k.PIPE("handle", [(0.065, 0, 0.195), (0.115, 0, 0.2), (0.13, 0, 0.15), (0.12, 0, 0.07), (0.08, 0, 0.045)], 0.012, k.BLACK,
           verts=10)
    k.B("spout", (0.045, 0.03, 0.02), (-0.075, 0, 0.198), k.STEEL, 0.008, rot=(0, -28, 0))
    k.B("window", (0.004, 0.018, 0.11), (0.079, 0, 0.1), k.BLACK, 0.002)                           # water gauge
    k.B("switch", (0.02, 0.018, 0.012), (0.115, 0, 0.055), k.CAP, 0.003)
    _coil(k, "cord", (0.0, -0.14))
    k.COL_CYL(0.09, 0.24, (0, 0, 0.12))
    k.finish(subdiv=1.0, ao_dist=0.12)


def toaster():
    k = AptKit("toaster")
    k.SOFT("body", (0.28, 0.17, 0.18), (0, 0, 0.1), k.ENAMEL, 0.045, step=0.03)
    k.B("foot_band", (0.26, 0.15, 0.012), (0, 0, 0.006), k.BLACK, 0.004)
    for y in (-0.032, 0.032):
        k.B(f"slot{y}", (0.2, 0.026, 0.006), (0, y, 0.19), k.BLACK, 0.002)
        k.B(f"slot_rim{y}", (0.21, 0.034, 0.002), (0, y, 0.1895), k.CHROME, 0.001)
    k.B("lever_track", (0.004, 0.012, 0.09), (0.141, 0, 0.1), k.BLACK)
    k.B("lever", (0.03, 0.028, 0.016), (0.155, 0, 0.14), k.CHROME, 0.005)
    k.CYL("dial", 0.014, 0.012, (0.146, 0.0, 0.06), k.CHROME, "x", 16)
    k.B("crumb", (0.12, 0.004, 0.012), (0, -0.086, 0.025), k.CHROME, 0.001)
    _coil(k, "cord", (-0.02, -0.15), plug="lift_plug")
    k.COL((0.28, 0.17, 0.19), (0, 0, 0.095))
    k.USE("plugs", (0.15, -0.05, 0.1))
    k.finish(subdiv=1.0, ao_dist=0.12)


PLATE = [(0, 0), (0.05, 0), (0.052, 0.004), (0.07, 0.006), (0.1, 0.016), (0.112, 0.022), (0.11, 0.026), (0.098, 0.021),
         (0.068, 0.012), (0, 0.011)]
MUG = [(0, 0), (0.038, 0), (0.041, 0.006), (0.042, 0.09), (0.036, 0.09), (0.035, 0.008), (0, 0.008)]


def dish_rack():
    k = AptKit("dish_rack")
    k.SOFT("tray", (0.44, 0.32, 0.02), (0, 0, 0.01), k.PLASTIC, 0.008, step=0.05)
    for y in (-0.13, 0.13):                                                        # wire frame
        for z in (0.035, 0.12):
            k.TUBE(f"rail{y}{z}", (-0.2, y, z), (0.2, y, z), 0.003, k.CHROME, verts=8)
    for x in (-0.2, 0.2):
        for y in (-0.13, 0.13):
            k.TUBE(f"post{x}{y}", (x, y, 0.02), (x, y, 0.12), 0.003, k.CHROME, verts=8)
    for i in range(9):                                                             # tines the plates stand between
        x = -0.19 + i * 0.024
        for y in (-0.1, 0.1):
            k.TUBE(f"tine{i}{y}", (x, y, 0.035), (x, y, 0.1), 0.0022, k.CHROME, verts=6)
    for i in range(4):
        k.parts.append(F.lathe(f"plate{i}", PLATE, k.PORC, (-0.178 + i * 0.048, 0.0, 0.14), segs=32, rot=(0, 90, 0)))
    for i, y in enumerate((-0.06, 0.06)):
        k.parts.append(F.lathe(f"mug{i}", MUG, k.ENAMEL, (0.12, y, 0.128), segs=24, rot=(180, 0, 0)))
        k.PIPE(f"mug{i}_h", [(0.162, y, 0.11), (0.182, y, 0.098), (0.182, y, 0.068), (0.162, y, 0.058)], 0.005, k.ENAMEL, verts=8)
    k.COL((0.44, 0.32, 0.26), (0, 0, 0.13))
    k.finish(subdiv=1.0, ao_dist=0.12)


CANISTER = [(0, 0), (0.048, 0), (0.05, 0.006), (0.05, 0.14), (0.047, 0.142), (0, 0.142)]
LID = [(0, 0.14), (0.052, 0.14), (0.052, 0.158), (0.03, 0.162), (0.012, 0.164), (0.012, 0.176), (0, 0.178)]


def canisters():
    k = AptKit("canisters")
    for i, word in enumerate(("SUGAR", "TEA", "RICE", "FLOUR")):
        x = (i - 1.5) * 0.12
        k.parts.append(F.lathe(f"can{i}", CANISTER, k.PORC, (x, 0, 0), segs=32))
        k.parts.append(F.lathe(f"lid{i}", LID, k.WOOD_L, (x, 0, 0), segs=32))
        k.WRAP_UV(f"lbl{i}", (x, 0), 0.0505, 0.08, 0.1, 216, 324, k.D_LABELS, D.label_uv(word), segs=8)
    k.COL((0.48, 0.1, 0.18), (0, 0, 0.09))
    k.finish(subdiv=1.0, ao_dist=0.1)


APPLE = [(0, 0.004), (0.02, 0), (0.034, 0.012), (0.04, 0.03), (0.037, 0.05), (0.024, 0.062), (0.01, 0.058), (0, 0.052)]
BOWL = [(0, 0), (0.05, 0), (0.052, 0.008), (0.1, 0.03), (0.13, 0.075), (0.126, 0.078), (0.095, 0.036), (0.048, 0.014),
        (0, 0.014)]


def fruit_bowl():
    k = AptKit("fruit_bowl")
    k.parts.append(F.lathe("bowl", BOWL, k.PORC, segs=36))
    for i, (x, y) in enumerate(((-0.036, -0.036), (0.036, -0.036), (0.036, 0.036), (-0.036, 0.036))):
        k.parts.append(F.lathe(f"apple{i}", APPLE, k.APPLE, (x, y, 0.016), segs=20))
        k.TUBE(f"stem{i}", (x, y, 0.07), (x + 0.004, y, 0.082), 0.0022, k.CARD, verts=5)
    k.COL_CYL(0.13, 0.08, (0, 0, 0.04))
    k.finish(subdiv=1.0, ao_dist=0.1)


PROPS = {f.__name__: f for f in (kettle, toaster, dish_rack, canisters, fruit_bowl)}
