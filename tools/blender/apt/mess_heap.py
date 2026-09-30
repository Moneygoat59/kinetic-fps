"""Apartment kit, squalor: the volume of weeks (heaps and spreads, so the flat can be buried without hundreds of markers).
trash_heap / trash_heap_small   bin bags heaped against a wall (8 / 4), a pizza box and cans caught in them, litter round the foot
litter_spread_a / _b / _c        a floor carpet of rubbish, 1.6 x 1.1 m, three different seeds: cans, bottles, paper cups, foam
                                 boxes, a flattened carrier bag, wrappers, crumpled paper, receipts (no collision)
pizza_tower                      eleven pizza boxes stacked by the wall, leaning
pot_crusted                      a saucepan left on the hob, something burnt black inside, the spoon still in it
counter_clutter                  a worktop run of it: bread bag, cereal box, a jar, bottles, cans, a carton
paper_cup                        a takeaway coffee cup with its lid
"""
import math
import random

import apt_forms as F
import ps1_lib as L
from mess_kit import BOTTLE, MessKit
from mess_trash import H_BOX, W_BOX, _bag, _pizza

CUP = [(0, 0), (0.028, 0), (0.029, 0.004), (0.042, 0.11), (0.0435, 0.112), (0.0435, 0.118), (0, 0.118)]
POT = [(0, 0), (0.085, 0), (0.09, 0.006), (0.092, 0.1), (0.086, 0.1), (0.084, 0.008), (0, 0.008)]
CELLS = ("can_cola", "can_lime", "can_energy", "can_orange")
WRAPS = ("apt_sheen_wrap_red", (0.5, 0.04, 0.03)), ("apt_sheen_wrap_blue", (0.05, 0.12, 0.45)), ("apt_sheen_wrap_gold", (0.6, 0.4, 0.05))


def _cup(k, name, loc, rot=(0, 0, 0)):
    m = k.mark()
    k.parts.append(F.lathe(name, CUP, k.PAPER, segs=16))
    k.CYL(name + "_lid", 0.045, 0.012, (0, 0, 0.122), k.BLACK, v=16)
    k.CYL(name + "_sleeve", 0.041, 0.035, (0, 0, 0.065), k.CARD, v=16)
    k.PLACE(m, loc, rot)


def _bottle(k, name, loc, rot, crush=0.0, seed=0):
    m = k.mark()
    b = F.lathe(name, BOTTLE, k.BOTTLE, segs=12)
    if crush:
        b.scale = (1.0 + crush * 0.25, 1.0 - crush * 0.5, 1.0)
        L.jitter(b, crush * 0.006, seed)
    k.glass_parts.append(b)
    k.CYL(name + "_cap", 0.014, 0.016, (0, 0, 0.222), k.CAP, v=12)
    k.PLACE(m, loc, rot)


def _foam_box(k, name, loc, yaw):
    m = k.mark()
    k.B(name, (0.2, 0.18, 0.07), (0, 0, 0.035), k.FOAM, 0.012)
    k.B(name + "_seam", (0.202, 0.182, 0.004), (0, 0, 0.036), k.PAPER, 0.002)
    k.PLACE(m, loc, (0, 0, yaw))


def trash_heap():
    k = MessKit("trash_heap")
    for i, (x, y, z, sx, sy, sz, white) in enumerate((
            (-0.4, 0.15, 0, 0.5, 0.45, 0.58, False), (0.15, 0.2, 0, 0.55, 0.48, 0.52, False), (0.55, 0.05, 0, 0.44, 0.4, 0.46, True),
            (-0.2, -0.28, 0, 0.5, 0.42, 0.42, False), (0.3, -0.3, 0, 0.42, 0.38, 0.38, True), (-0.65, -0.2, 0, 0.36, 0.32, 0.34, False),
            (-0.1, 0.1, 0.36, 0.46, 0.4, 0.44, False), (0.35, 0.05, 0.3, 0.38, 0.34, 0.36, True))):
        _bag(k, f"bag{i}", (sx, sy, sz), (x, y, z), 100 + i * 7, settle=0.55 if z == 0 else 0.3, white=white)
    m = k.mark()                                                # a pizza box caught in the heap, tipped up against it
    _pizza(k, "box", (0, 0, 0), 0, 4)
    k.PLACE(m, (-0.42, -0.42, 0.06), (28, 0, 30))
    k.CAN_AT("can0", (0.6, -0.45, 0.033), "can_energy", (90, 0, 20))
    k.CAN_AT("can1", (-0.8, -0.45, 0.02), "can_cola", (90, 0, 150), crush=0.7, seed=2)
    for i, (x, y) in enumerate(((0.2, -0.6), (-0.5, -0.62), (0.75, -0.3), (-0.95, 0.0))):
        k.CRUMPLE(f"paper{i}", (x, y, 0.03), 0.035, seed=i)
    k.COL((1.4, 0.8, 0.6), (0, 0, 0.3))
    k.finish(subdiv=1.0, ao_dist=0.35)


def trash_heap_small():
    k = MessKit("trash_heap_small")
    for i, (x, y, z, sx, sy, sz, white) in enumerate(((-0.2, 0.05, 0, 0.46, 0.42, 0.5, False), (0.25, 0.1, 0, 0.42, 0.38, 0.44, True),
                                                      (0.05, -0.22, 0, 0.44, 0.38, 0.36, False), (0.0, 0.08, 0.34, 0.36, 0.32, 0.34, False))):
        _bag(k, f"bag{i}", (sx, sy, sz), (x, y, z), 200 + i * 5, settle=0.5 if z == 0 else 0.3, white=white)
    k.CRUMPLE("paper", (0.35, -0.3, 0.03), 0.035, seed=5)
    k.COL((0.85, 0.6, 0.5), (0, 0, 0.25))
    k.finish(subdiv=1.0, ao_dist=0.3)


def _spread(name, seed):
    """A floor carpet of rubbish, 1.6 x 1.1 m: every item placed by a seeded random walk, lying down."""
    k = MessKit(name)
    r = random.Random(seed)
    wraps = [L.material(n, c, 0.3) for n, c in WRAPS]
    spot = lambda: (r.uniform(-0.75, 0.75), r.uniform(-0.5, 0.5))  # noqa: E731
    for i in range(9):
        x, y = spot()
        if r.random() < 0.3:
            k.CAN_AT(f"can{i}", (x, y, 0.0), r.choice(CELLS), (0, 0, r.uniform(0, 360)))
        else:
            k.CAN_AT(f"can{i}", (x, y, 0.028), r.choice(CELLS), (90, 0, r.uniform(0, 360)), crush=r.choice((0, 0, 0.5, 0.8)), seed=i)
    for i in range(3):
        x, y = spot()
        _bottle(k, f"bottle{i}", (x, y, 0.028), (90, 0, r.uniform(0, 360)), crush=r.choice((0, 0.6)), seed=i)
    for i in range(2):
        x, y = spot()
        _cup(k, f"cup{i}", (x, y, 0.04), (90, 0, r.uniform(0, 360)))
    for i in range(2):
        x, y = spot()
        _foam_box(k, f"foam{i}", (x, y, 0), r.uniform(0, 360))
    x, y = spot()
    k.BLOB("carrier", (0.4, 0.3, 0.04), (x, y, 0.02), k.BAG_W, seed=seed, lumps=0.25, folds=0.2, fold_freq=5, settle=0.9, subdiv=3)
    for i in range(10):
        x, y = spot()
        k.CRUMPLE(f"ball{i}", (x, y, 0.025), r.uniform(0.02, 0.04), r.choice((k.PAPER_D, k.PAPER_D, k.PAPER_Y, k.PAPER)), seed=seed + i)
    for i in range(5):
        x, y = spot()
        k.BLOB(f"wrap{i}", (0.07, 0.05, 0.02), (x, y, 0.01), r.choice(wraps), seed=seed + 40 + i, lumps=0.4, subdiv=2)
    for i in range(4):
        x, y = spot()
        cell = r.choice(("receipt", "receipt", "flyer", "envelope"))
        w, h = {"receipt": (0.07, 0.2), "flyer": (0.21, 0.28), "envelope": (0.23, 0.12)}[cell]
        k.SHEET(f"sheet{i}", (x, y, 0.002 + i * 0.0005), w, h, cell, r.uniform(0, 360), seed=i)
    k.finish(subdiv=1.0, ao_dist=0.08)


def litter_spread_a():
    _spread("litter_spread_a", 1)


def litter_spread_b():
    _spread("litter_spread_b", 2)


def litter_spread_c():
    _spread("litter_spread_c", 3)


def pizza_tower():
    k = MessKit("pizza_tower")
    lean = 0.0
    for i in range(11):
        lean += 0.004 * (i % 3)
        _pizza(k, f"box{i}", (lean + 0.01 * math.sin(i * 1.7), 0.008 * math.cos(i * 2.3), i * H_BOX), 6 * math.sin(i * 1.3), 20 + i)
    k.COL((W_BOX, W_BOX, 11 * H_BOX), (0.02, 0, 5.5 * H_BOX))
    k.finish(subdiv=1.0, ao_dist=0.25)


def pot_crusted():
    k = MessKit("pot_crusted")
    k.parts.append(F.lathe("pot", POT, k.STEEL, segs=24))
    k.CYL("burnt", 0.084, 0.006, (0, 0, 0.012), k.BLACK, v=24)
    k.BLOB("crust", (0.15, 0.13, 0.03), (0, 0, 0.022), k.FOOD, seed=3, lumps=0.3, subdiv=3)
    k.TUBE("handle", (0.09, 0, 0.085), (0.26, 0, 0.1), 0.012, k.BLACK, verts=8)
    k.B("spoon", (0.02, 0.24, 0.006), (-0.02, 0.07, 0.09), k.WOOD_L, rot=(-35, 0, 10))
    k.finish(subdiv=1.0, ao_dist=0.12)


def counter_clutter():
    k = MessKit("counter_clutter")
    k.BLOB("bread", (0.34, 0.14, 0.1), (-0.22, 0.02, 0.05), k.BAG_W, seed=4, lumps=0.15, folds=0.2, fold_freq=6, settle=0.6, subdiv=3)
    m = k.mark()
    k.B("cereal", (0.2, 0.07, 0.29), (0, 0, 0.145), k.PBOX, 0.003)
    k.PRINT_QUAD("cereal_face", (0, -0.0355, 0.16), 0.17, 0.2, "chips", facing="-y", up=(0, 0, 1))
    k.PLACE(m, (0.02, 0.1, 0), (0, 0, 8))
    jar = F.lathe("jar", [(0, 0), (0.045, 0), (0.047, 0.01), (0.047, 0.13), (0.035, 0.14), (0, 0.14)], k.GLASS, segs=16)
    jar.location = (0.2, 0.08, 0)
    k.glass_parts.append(jar)
    k.CYL("jar_lid", 0.037, 0.02, (0.2, 0.08, 0.15), k.CHROME, v=16)
    k.BLOB("jar_mould", (0.08, 0.08, 0.05), (0.2, 0.08, 0.035), k.MOULD, seed=8, lumps=0.3, subdiv=3)
    _bottle(k, "bottle0", (0.3, -0.06, 0), (0, 0, 0))
    k.CAN_AT("can0", (-0.05, -0.08, 0), "can_cola", (0, 0, 40))
    k.CAN_AT("can1", (0.1, -0.1, 0.028), "can_orange", (90, 0, -20), crush=0.6, seed=3)
    _cup(k, "cup", (-0.4, -0.06, 0))
    k.finish(subdiv=1.0, ao_dist=0.1)


def paper_cup():
    k = MessKit("paper_cup")
    _cup(k, "cup", (0, 0, 0))
    k.finish(subdiv=1.0, ao_dist=0.06)


PROPS = {f.__name__: f for f in (trash_heap, trash_heap_small, litter_spread_a, litter_spread_b, litter_spread_c, pizza_tower,
                                 pot_crusted, counter_clutter, paper_cup)}
