"""Records vault kit: drawings (paper records: archive.py; the vault: vault.py). The blueprints are the company's drawings of
places that exist in the world (archive_textures.py draws them from kit_dims).
plan_chest       two five-drawer plan chests on a plinth (PLAN_W x PLAN_D x PLAN_H), loose drawings on top.
plan_chest_open  the same with a top-unit drawer pulled out on its sheets, one curling over the edge.
drafting_table   steel drafting table: a board tilted 20 deg with a drawing pinned on it, the drafting machine's arms and
                 scale head, a dead clamp lamp, a pencil ledge.
tube_rack        pigeonhole cabinet (TUBE_W x TUBE_D x TUBE_H) of rolled drawings, 5 x 8 cells, some empty.
"""
import math
import random

from mathutils import Vector

from archive import ArchiveKit
from kit_dims import PLAN_D, PLAN_H, PLAN_W, TUBE_D, TUBE_H, TUBE_W

PLINTH = 0.08
UNIT = (PLAN_H - PLINTH - 0.03) / 2          # one five-drawer unit's height
BOARD_TILT = 20.0


def _sheet(k, name, center, w, h, mat, up=(0, 1, 0), normal="+z"):
    return k.PANEL(name, center, w, h, mat, facing=normal, up=up)


def _chest(k, open_drawer=None):
    hd = PLAN_D / 2
    k.B("plinth", (PLAN_W - 0.06, PLAN_D - 0.06, PLINTH), (0, 0.02, PLINTH / 2), k.CABLE)
    dh = UNIT / 5
    for u in range(2):
        z0 = PLINTH + u * UNIT
        k.B(f"unit{u}", (PLAN_W, PLAN_D, UNIT - 0.004), (0, 0, z0 + UNIT / 2), k.MET_D, 0.006)
        k.PANEL(f"face{u}", (0, -hd - 0.002, z0 + UNIT / 2), PLAN_W - 0.05, UNIT - 0.02, k.PLAN_F)
        for i in range(5):
            zc = z0 + UNIT - (i + 0.5) * dh
            if u == 1 and i == open_drawer:
                continue
            k.B(f"pull{u}{i}", (0.42, 0.02, 0.012), (0, -hd - 0.012, zc - dh * 0.3), k.RUST)
    top = PLINTH + 2 * UNIT
    k.B("top", (PLAN_W + 0.02, PLAN_D + 0.02, 0.03), (0, 0, top + 0.015), k.MET)
    top += 0.03
    _sheet(k, "loose0", (0.05, 0.02, top + 0.003), 1.0, 0.68, k.BP["junction"], up=(0.08, 1, 0))
    _sheet(k, "loose1", (-0.12, -0.04, top + 0.006), 0.9, 0.6, k.BP["tunnel"], up=(-0.15, 1, 0))
    k.DECAL("dust", (0, 0, top + 0.009), PLAN_W, PLAN_D, k.D_DUST, facing="+z", up=(0, 1, 0))
    if open_drawer is not None:                                          # the pulled drawer: tray, front, sheets
        zc = PLINTH + 2 * UNIT - (open_drawer + 0.5) * dh
        out = 0.6
        k.PANEL("hole", (0, -hd - 0.003, zc), PLAN_W - 0.08, dh - 0.01, k.CABLE)
        k.B("tray", (PLAN_W - 0.1, PLAN_D - 0.05, 0.01), (0, -out, zc - dh / 2 + 0.01), k.MET_D)
        k.B("tray_front", (PLAN_W - 0.06, 0.02, dh - 0.01), (0, -hd - out, zc), k.MET, 0.004)
        k.B("tray_pull", (0.42, 0.02, 0.012), (0, -hd - out - 0.012, zc - dh * 0.3), k.RUST)
        for s in (-1, 1):
            k.B(f"tray_side{s}", (0.01, PLAN_D - 0.05, dh - 0.02), (s * (PLAN_W / 2 - 0.055), -out, zc - 0.005), k.MET_D)
        _sheet(k, "in0", (0, -out + 0.05, zc - dh / 2 + 0.02), 1.15, 0.8, k.BP["silo"], up=(1, 0, 0))
        curl = Vector((0.1, -hd - out + 0.02, zc - dh / 2 + 0.03))           # a sheet slipping over the front edge
        k.PANEL("curl", tuple(curl + Vector((0, 0.18, 0.02))), 0.8, 0.36, k.BP["door"], facing=(0, -0.2, 1), up=(0, 1, 0.2))
        k.PANEL("curl_down", tuple(curl + Vector((0, -0.06, -0.12))), 0.8, 0.26, k.BP["door"], facing=(0, -1, 0.3), up=(0, 0.3, 1))
        k.COL((PLAN_W - 0.06, PLAN_D - 0.05, dh), (0, -out, zc))


def plan_chest():
    k = ArchiveKit("plan_chest")
    _chest(k)
    k.COL((PLAN_W, PLAN_D, PLAN_H), (0, 0, PLAN_H / 2))
    k.finish(ao_dist=0.5)


def plan_chest_open():
    k = ArchiveKit("plan_chest_open")
    _chest(k, open_drawer=1)
    k.COL((PLAN_W, PLAN_D, PLAN_H), (0, 0, PLAN_H / 2))
    k.finish(ao_dist=0.5)


def drafting_table():
    k = ArchiveKit("drafting_table")
    t = math.radians(BOARD_TILT)
    c = Vector((0.0, 0.08, 1.0))                                          # board centre
    right, up, n = Vector((1, 0, 0)), Vector((0, math.cos(t), math.sin(t))), Vector((0, -math.sin(t), math.cos(t)))
    at = lambda u, v, h=0.0: tuple(c + right * u + up * v + n * h)  # noqa: E731
    for s in (-1, 1):                                                     # T-frames and the crossbar
        k.B(f"foot{s}", (0.06, 0.8, 0.05), (s * 0.62, 0.05, 0.025), k.MET_D)
        k.B(f"post{s}", (0.06, 0.06, 0.86), (s * 0.62, 0.1, 0.48), k.MET_D)
        k.B(f"bracket{s}", (0.05, 0.4, 0.05), at(s * 0.62, 0.0, -0.06), k.MET_D, rot=(BOARD_TILT, 0, 0))
    k.TUBE("crossbar", (-0.62, 0.1, 0.3), (0.62, 0.1, 0.3), 0.02, k.MET)
    k.TUBE("footbar", (-0.62, -0.2, 0.12), (0.62, -0.2, 0.12), 0.015, k.RUST)
    k.B("board", (1.5, 1.0, 0.03), tuple(c), k.PLATE, rot=(BOARD_TILT, 0, 0))
    k.B("ledge", (1.5, 0.05, 0.03), at(0, -0.52, 0.02), k.MET_D, rot=(BOARD_TILT, 0, 0))
    k.PANEL("sheet", at(0.05, 0.02, 0.017), 1.1, 0.75, k.BP["door"], facing=tuple(n), up=tuple(up))
    for i, (u, v) in enumerate(((-0.5, 0.38), (0.6, 0.38), (-0.5, -0.34), (0.6, -0.34))):
        k.CYL(f"pin{i}", 0.008, 0.01, at(u, v, 0.02), k.RUST, v=6)
    k.B("clamp", (0.08, 0.06, 0.06), at(-0.7, 0.47, 0.04), k.MET_D, rot=(BOARD_TILT, 0, 0))    # the drafting machine
    k.TUBE("arm0", at(-0.7, 0.47, 0.06), at(-0.25, 0.1, 0.06), 0.01, k.MET, 5)
    k.TUBE("arm1", at(-0.25, 0.1, 0.06), at(0.15, -0.12, 0.05), 0.01, k.MET, 5)
    k.CYL("head", 0.07, 0.025, at(0.15, -0.12, 0.035), k.MET_D, v=10)
    k.B("scale_h", (0.5, 0.05, 0.006), at(0.42, -0.14, 0.021), k.PAPER, rot=(BOARD_TILT, 0, 0))
    k.B("scale_v", (0.05, 0.4, 0.006), at(0.17, 0.12, 0.021), k.PAPER, rot=(BOARD_TILT, 0, 0))
    k.TUBE("lamp_post", at(0.7, 0.5, 0.0), at(0.72, 0.6, 0.45), 0.012, k.MET_D, 5)          # dead clamp lamp
    k.TUBE("lamp_arm", at(0.72, 0.6, 0.45), at(0.4, 0.3, 0.55), 0.012, k.MET_D, 5)
    k.FRUSTUM("lamp_shade", 0.08, 0.04, 0.12, at(0.4, 0.3, 0.5), k.MET_D, axis="z", v=8)
    k.DECAL("dust", at(0.05, 0.02, 0.02), 1.3, 0.85, k.D_DUST, facing=tuple(n), up=tuple(up))
    k.COL((1.5, 0.9, 0.9), (0, 0.1, 0.45))
    k.COL((1.5, 0.4, 0.4), (0, 0.4, 1.1))
    k.finish(subdiv=0.3, ao_dist=0.5)


def tube_rack():
    k = ArchiveKit("tube_rack")
    rng = random.Random(23)
    cols, rows, hw, hd, base = 5, 8, TUBE_W / 2, TUBE_D / 2, 0.08
    for s in (-1, 1):
        k.B(f"side{s}", (0.03, TUBE_D, TUBE_H), (s * (hw - 0.015), 0, TUBE_H / 2), k.MET_D)
    k.B("back", (TUBE_W, 0.02, TUBE_H), (0, hd - 0.01, TUBE_H / 2), k.PLATE)
    k.B("plinth", (TUBE_W, TUBE_D, base), (0, 0, base / 2), k.CABLE)
    k.B("top", (TUBE_W + 0.02, TUBE_D + 0.02, 0.03), (0, 0, TUBE_H - 0.015), k.MET)
    iw, ih = TUBE_W - 0.06, TUBE_H - base - 0.03
    cw, ch = iw / cols, ih / rows
    for i in range(1, cols):
        k.B(f"vdiv{i}", (0.012, TUBE_D - 0.02, ih), (-iw / 2 + i * cw, -0.01, base + ih / 2), k.MET_D)
    for j in range(rows + 1):
        k.B(f"hdiv{j}", (iw, TUBE_D - 0.02, 0.012), (0, -0.01, base + j * ch), k.MET_D)
    for i in range(cols):                                                 # rolled drawings, some cells empty
        for j in range(rows):
            n = rng.choice((0, 1, 2, 3, 3, 4))
            for r in range(n):
                rad = rng.uniform(0.03, 0.045)
                ln = rng.uniform(0.5, 0.72)
                x = -iw / 2 + (i + 0.5) * cw + rng.uniform(-0.05, 0.05)
                z = base + j * ch + 0.006 + rad + (r // 2) * 0.07
                y = hd - 0.02 - ln / 2 - rng.uniform(0.0, 0.2)
                k.CYL(f"roll{i}{j}{r}", rad, ln, (x, y, z), k.PAPER if (i + j + r) % 4 else k.OCHRE, "y", 6)
    for r in range(2):                                                    # two left lying on top
        k.CYL(f"top_roll{r}", 0.04, 0.9, (-0.2 + r * 0.1, -0.05, TUBE_H + 0.04), k.PAPER, "x", 6)
    k.DECAL("dust", (0.2, 0, TUBE_H + 0.002), 0.7, TUBE_D, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((TUBE_W, TUBE_D, TUBE_H), (0, 0, TUBE_H / 2))
    k.finish(subdiv=0.4, ao_dist=0.4)


PROPS = {f.__name__: f for f in (plan_chest, plan_chest_open, drafting_table, tube_rack)}
