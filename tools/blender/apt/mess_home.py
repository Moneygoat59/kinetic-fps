"""Apartment kit, squalor: the home let go (the flat after night 4; placed by tools/blender/props/apartment_mess.py).
clothes_pile / clothes_pile_small   worn clothes dropped in heaps: a hoodie, jeans, tees, a sock, sleeves trailing
dish_pile      plates stacked askew with dried food, a crusted bowl, mugs with coffee gone to skin, cutlery (worktop / sink)
mug_mould      a mug left for weeks: a dark ring, grey-green fur on the surface
fruit_bowl_rotten  the table's fruit bowl: the apples collapsed and furred, brown juice pooled under them
bed_unmade     the bed with the duvet in a twisted heap, a bare stained sheet, one pillow crushed, the other half off
towel_floor    a towel dropped where it was used
"""
import math

import apt_forms as F
import bedroom
import counter
import ps1_lib as L
from apt_lib import _t
from mess_kit import BOWL, MessKit

MUG = [(0, 0), (0.038, 0), (0.041, 0.006), (0.042, 0.09), (0.036, 0.09), (0.035, 0.008), (0, 0.008)]


def _heap(k, name, spots, seed):
    """Garments dropped on each other: each spot (x, y, sx, sy, h, cloth index, yaw) is one creased lump."""
    for i, (x, y, sx, sy, h, c, yaw) in enumerate(spots):
        k.BLOB(f"{name}{i}", (sx, sy, h), (x, y, h / 2), k.CLOTH[c], seed=seed + i, lumps=0.18, lump_freq=1.4, folds=0.14,
               fold_freq=4.5, fold_stretch=1.0, crease=False, settle=0.9, subdiv=4, rot=(0, 0, yaw))


def _limb(k, name, pts, width, cloth, seed):
    """A sleeve or trouser leg trailing out of a heap: a flattened, softly rumpled strip along pts [(x, y), ...]."""
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        ln = ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5
        yaw = math.degrees(math.atan2(y1 - y0, x1 - x0))
        k.BLOB(f"{name}{i}", (ln + width * 0.6, width, width * 0.35), ((x0 + x1) / 2, (y0 + y1) / 2, width * 0.17), cloth,
               seed=seed + i, lumps=0.12, folds=0.1, fold_freq=5.0, crease=False, settle=0.9, subdiv=3, rot=(0, 0, yaw))


def clothes_pile():
    k = MessKit("clothes_pile")
    _heap(k, "cloth", ((0, 0, 0.62, 0.48, 0.14, 0, 10), (0.12, -0.06, 0.5, 0.36, 0.12, 1, -25), (-0.15, 0.08, 0.42, 0.34, 0.1, 5, 40),
                       (0.05, 0.1, 0.36, 0.3, 0.09, 3, 70), (-0.05, -0.1, 0.3, 0.26, 0.08, 2, -5)), 40)
    _limb(k, "sleeve", [(0.24, 0.0), (0.38, -0.06), (0.52, -0.05)], 0.09, k.CLOTH[0], 3)
    _limb(k, "leg", [(-0.02, -0.16), (-0.1, -0.3), (-0.2, -0.46)], 0.13, k.CLOTH[1], 5)
    k.BLOB("sock", (0.2, 0.07, 0.035), (-0.38, 0.22, 0.017), k.CLOTH[3], seed=7, lumps=0.2, subdiv=3, rot=(0, 0, 30))
    k.finish(subdiv=1.0, ao_dist=0.2)


def clothes_pile_small():
    k = MessKit("clothes_pile_small")
    _heap(k, "cloth", ((0, 0, 0.44, 0.36, 0.1, 4, -15), (0.08, 0.04, 0.34, 0.28, 0.08, 5, 30), (-0.06, -0.05, 0.26, 0.22, 0.07, 2, 80)), 60)
    _limb(k, "sleeve", [(-0.18, 0.05), (-0.3, 0.1), (-0.42, 0.04)], 0.085, k.CLOTH[4], 7)
    k.finish(subdiv=1.0, ao_dist=0.15)


def _mug(k, name, loc, mould=False, seed=0):
    m = k.mark()
    k.parts.append(F.lathe(name, MUG, k.ENAMEL, segs=24))
    k.PIPE(name + "_h", [(0.04, 0, 0.075), (0.062, 0, 0.068), (0.062, 0, 0.032), (0.04, 0, 0.022)], 0.005, k.ENAMEL, verts=8)
    k.CYL(name + "_coffee", 0.035, 0.002, (0, 0, 0.05), k.COFFEE, v=20)
    k.parts.append(F.lathe(name + "_ring", [(0.0352, 0.052), (0.0352, 0.066)], k.FOOD, segs=24))   # the line it dried down from
    if mould:
        k.BLOB(name + "_fur", (0.062, 0.06, 0.014), (0.002, 0.0, 0.056), k.MOULD, seed=seed, lumps=0.35, lump_freq=3.0, subdiv=3)
    k.PLACE(m, loc)


def mug_mould():
    k = MessKit("mug_mould")
    _mug(k, "mug", (0, 0, 0), mould=True, seed=3)
    k.finish(subdiv=1.0, ao_dist=0.06)


def dish_pile():
    k = MessKit("dish_pile")
    for i in range(5):                                          # plates stacked askew, food dried between them
        m = k.mark()
        k.parts.append(F.lathe(f"plate{i}", counter.PLATE, k.PORC, segs=32))
        if i in (1, 3, 4):
            k.BLOB(f"food{i}", (0.1, 0.07, 0.012), (0.02, -0.01, 0.017), k.FOOD, seed=i, lumps=0.3, subdiv=3)
        k.PLACE(m, (0.012 * (i % 3) - 0.01, 0.008 * ((i * 2) % 3) - 0.006, 0.014 * i), (4 * ((i % 2) * 2 - 1), 3 * (i % 3 - 1), i * 23))
    m = k.mark()                                                # a bowl, crusted
    k.parts.append(F.lathe("bowl", BOWL, k.PORC, segs=28))
    k.BLOB("crust", (0.11, 0.1, 0.02), (0, 0, 0.018), k.RICE, seed=9, lumps=0.25, subdiv=3)
    k.PLACE(m, (0.19, 0.05, 0), (0, -8, 0))
    _mug(k, "mug0", (-0.18, 0.08, 0))
    _mug(k, "mug1", (-0.14, -0.1, 0), mould=True, seed=4)
    for i, (x, y, yaw) in enumerate(((0.06, -0.15, 70), (0.12, -0.13, 95))):          # a fork and a knife
        k.B(f"cutlery{i}", (0.012, 0.19, 0.003), (x, y, 0.0015 + 0.004 * i), k.CHROME, rot=(0, 0, yaw))
    k.COL((0.5, 0.36, 0.1), (0, 0, 0.05))
    k.finish(subdiv=1.0, ao_dist=0.1)


def fruit_bowl_rotten():
    k = MessKit("fruit_bowl_rotten")
    k.parts.append(F.lathe("bowl", counter.BOWL, k.PORC, segs=36))
    k.BLOB("juice", (0.15, 0.14, 0.006), (0, 0, 0.017), k.ROT, seed=2, lumps=0.3, subdiv=3)
    for i, (x, y, sq) in enumerate(((-0.036, -0.036, 0.55), (0.036, -0.036, 0.8), (0.036, 0.036, 0.4), (-0.036, 0.036, 0.7))):
        apple = F.lathe(f"apple{i}", counter.APPLE, k.ROT, (x, y, 0.016), segs=16)
        apple.scale = (1.0 - 0.15 * sq, 1.0 - 0.1 * sq, 1.0 - 0.45 * sq)                # collapsing in on itself
        L.jitter(apple, 0.004, i)
        k.parts.append(apple)
        k.BLOB(f"fur{i}", (0.04, 0.035, 0.018), (x + 0.008, y - 0.004, 0.016 + 0.06 * (1 - 0.45 * sq)), k.MOULD, seed=10 + i,
               lumps=0.4, lump_freq=3.0, subdiv=3)
    k.COL_CYL(0.13, 0.08, (0, 0, 0.04))
    k.finish(subdiv=1.0, ao_dist=0.1)


def bed_unmade():
    k = MessKit("bed_unmade")
    sheet = L.tex_material("apt_linen_grey", _t("apt_linen.png"), tint=(0.78, 0.76, 0.7))                 # unwashed
    bedroom.bed_frame(k, sheet)
    w, l, top = bedroom.BED_W, bedroom.BED_L, bedroom.BED_TOP
    k.BLOB("duvet", (w * 0.75, l * 0.62, 0.3), (0.18, -l * 0.62, top + 0.13), k.DUVET, seed=21, lumps=0.2, lump_freq=1.4,
           folds=0.16, fold_freq=4.0, fold_stretch=1.0, crease=False, settle=0.8, subdiv=5, rot=(0, 0, 8))
    k.BLOB("duvet_spill", (0.5, 0.9, 0.34), (w / 2 + 0.05, -l * 0.55, top - 0.1), k.DUVET, seed=22, lumps=0.18, folds=0.14,
           fold_freq=3.5, fold_stretch=0.5, crease=False, settle=0.2, subdiv=4, rot=(0, -25, 0))       # over the side, hanging
    k.SOFT("pillow_a", (0.6, 0.38, 0.1), (-0.3, -0.3, top + 0.045), k.LINEN, 0.06, puff=0.02, axis="z", step=0.06, rot=(-4, 6, 18))
    k.SOFT("pillow_b", (0.58, 0.38, 0.14), (0.42, -0.42, top + 0.02), k.LINEN, 0.07, puff=0.03, axis="z", step=0.06, rot=(8, 32, -30))
    k.BLOB("stain", (0.3, 0.24, 0.004), (-0.25, -0.95, top + 0.001), L.material("apt_stain", (0.36, 0.3, 0.18)), seed=5,
           lumps=0.3, subdiv=3)
    k.finish(wall=True, subdiv=0.3, ao_dist=0.5)


def towel_floor():
    k = MessKit("towel_floor")
    k.BLOB("towel", (0.62, 0.4, 0.07), (0, 0, 0.035), k.TOWEL, seed=13, lumps=0.2, folds=0.18, fold_freq=4.0, fold_stretch=1.0,
           crease=False, settle=0.95, subdiv=4)
    k.finish(subdiv=1.0, ao_dist=0.12)


PROPS = {f.__name__: f for f in (clothes_pile, clothes_pile_small, dish_pile, mug_mould, fruit_bowl_rotten, bed_unmade,
                                 towel_floor)}
