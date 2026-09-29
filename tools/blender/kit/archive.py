"""Records vault kit: paper records (the vault itself: vault.py). Same rules as the rest of the kit: pressed steel gone
matte black, dim card and paper, 200 years of dust; detail in textures (python tools/blender/archive_textures.py).
archive_stack      a mobile shelving carriage (STACK_W x STACK_L x STACK_H): double sided, five 1 m bays of archive boxes
                   and binders a side, a crank wheel and index card on the front end panel (the end that faces the aisle).
                   Carriages roll on floor rails (the room lays the rails): pack them side by side, leave one aisle open.
file_cabinet       four-drawer filing cabinet.
file_cabinet_open  the same with its second drawer pulled out on hanging files, papers on the floor in front.
card_catalog       card index: 6 x 9 small drawers on a stand, one pulled out on its cards.
ArchiveKit (the kit + paper, drawer-face and blueprint materials) is shared with drawings.py.
"""
import math
import random

import ps1_lib as L
from kit_dims import CAT_D, CAT_H, CAT_W, FILE_D, FILE_H, FILE_W, STACK_BAY, STACK_END, STACK_H, STACK_L, STACK_SHELVES, STACK_W
from kit_lib import Kit, _t

STRIPS = 4                      # kit_arch_boxes.png: four shelf-bay strips stacked
SHELF_GAP = 0.33                # a strip's height for a 1 m bay (256 x 88 px)
BLUEPRINTS = ("tunnel", "junction", "silo", "door")


class ArchiveKit(Kit):
    def __init__(self, name):
        super().__init__(name)
        self.PAPER = L.material("kit_paper", (0.07, 0.064, 0.05))
        tex = lambda n, f: L.tex_material(n, _t(f))  # noqa: E731
        self.BOXES, self.LABEL = tex("kit_arch_boxes", "kit_arch_boxes.png"), tex("kit_arch_label", "kit_arch_label.png")
        self.PLAN_F, self.CAT_F = tex("kit_arch_plan", "kit_arch_plan.png"), tex("kit_arch_catalog", "kit_arch_catalog.png")
        self.FILE_F = tex("kit_arch_file", "kit_arch_file.png")
        self.BP = {n: tex(f"kit_bp_{n}", f"kit_bp_{n}.png") for n in BLUEPRINTS}


def uv_rect(o, u0, v0, u1, v1):
    """Point a quad (L.quad corner order) at a sub-rectangle of its image (u1 < u0 mirrors it)."""
    uv = o.data.uv_layers.active
    for i, p in enumerate(((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
        uv.data[i].uv = p
    return o


def crank(k, y, z, r=0.2):
    """The carriage's handwheel on the front end panel: hub, three spokes, rim, a spinner knob."""
    k.CYL("hub", 0.05, 0.1, (0, y - 0.05, z), k.MET_D, "y", 8)
    rim = [(r * math.cos(a * math.tau / 12), y - 0.1, z + r * math.sin(a * math.tau / 12)) for a in range(13)]
    k.PIPE("rim", rim, 0.016, k.MET, verts=5)
    for i in range(3):
        a = math.tau * i / 3 + 0.3
        k.TUBE(f"spoke{i}", (0, y - 0.1, z), (r * math.cos(a), y - 0.1, z + r * math.sin(a)), 0.012, k.MET, 5)
    k.TUBE("knob", (r * math.cos(0.3), y - 0.1, z + r * math.sin(0.3)), (r * math.cos(0.3), y - 0.2, z + r * math.sin(0.3)),
           0.018, k.RUST, 6)


def archive_stack():
    k = ArchiveKit("archive_stack")
    rng = random.Random(41)
    hl, bays = STACK_L / 2, int(round((STACK_L - 2 * STACK_END) / STACK_BAY))
    y_in = hl - STACK_END
    k.B("base", (STACK_W - 0.04, STACK_L - 0.1, 0.1), (0, 0, 0.09), k.MET_D)
    for y in (-y_in + 0.2, 0.0, y_in - 0.2):
        for x in (-0.3, 0.3):
            k.CYL(f"wheel{x}{y}", 0.045, 0.04, (x, y, 0.045), k.CABLE, "x", 8)
    k.B("divider", (0.02, 2 * y_in, STACK_H - 0.2), (0, 0, 0.14 + (STACK_H - 0.2) / 2), k.PLATE)
    for i in range(bays + 1):
        k.B(f"upright{i}", (STACK_W - 0.04, 0.03, STACK_H - 0.16), (0, -y_in + i * STACK_BAY, 0.14 + (STACK_H - 0.16) / 2), k.MET_D)
    for i, z in enumerate(STACK_SHELVES):
        k.B(f"shelf{i}", (STACK_W - 0.06, 2 * y_in, 0.02), (0, 0, z), k.MET)
    k.B("cap", (STACK_W, STACK_L, 0.04), (0, 0, STACK_H - 0.02), k.MET_D)
    for s in (-1, 1):
        k.B(f"end{s}", (STACK_W, STACK_END, STACK_H - 0.14), (0, s * (hl - STACK_END / 2), 0.14 + (STACK_H - 0.14) / 2), k.MET_D, 0.01)
    k.PANEL("label", (0, -hl - 0.004, 1.62), 0.24, 0.32, k.LABEL)
    crank(k, -hl, 1.1)
    for side in (-1, 1):                                                  # the bays: box rows, gaps, a box pulled out
        for b in range(bays):
            yc = -y_in + (b + 0.5) * STACK_BAY
            for lv, z in enumerate(STACK_SHELVES[:-1]):
                z0 = z + 0.01
                roll = rng.random()
                if roll < 0.12:
                    continue                                              # an empty bay: shelf and divider
                w = STACK_BAY - 0.05 if roll > 0.22 else (STACK_BAY - 0.05) / 2
                yy = yc - (STACK_BAY - 0.05 - w) / 2
                k.B(f"block{side}{b}{lv}", (0.42, w, 0.26), (side * 0.25, yy, z0 + 0.13), k.BOX)
                r = rng.randrange(STRIPS)
                u0, u1 = (0.0, w / STACK_BAY) if rng.random() < 0.5 else (w / STACK_BAY, 0.0)
                face = k.PANEL(f"row{side}{b}{lv}", (side * 0.465, yy, z0 + SHELF_GAP / 2), w, SHELF_GAP, k.BOXES,
                               facing="+x" if side > 0 else "-x")
                uv_rect(face, u0, 1 - (r + 1) / STRIPS, u1, 1 - r / STRIPS)
            z = STACK_SHELVES[-1] + 0.01                                  # the top shelf: loose boxes lying about
            for j in range(rng.randrange(0, 3)):
                k.B(f"loose{side}{b}{j}", (0.36, 0.28, 0.2), (side * 0.24, yc - 0.3 + j * 0.34, z + 0.1), k.BOX,
                    rot=(0, 0, rng.uniform(-12, 12)))
    k.B("pulled", (0.36, 0.13, 0.28), (0.4, -y_in + 2.3, STACK_SHELVES[2] + 0.15), k.BOX, rot=(0, 0, 4))
    k.DECAL("dust", (0, 0, STACK_H + 0.003), STACK_W, STACK_L, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((STACK_W, STACK_L, STACK_H), (0, 0, STACK_H / 2))
    k.COL((0.5, 0.25, 0.5), (0, -hl - 0.12, 1.1))
    k.finish(subdiv=0.5, ao_dist=0.5)


def _cabinet(k, open_drawer=None):
    hd, dz = FILE_D / 2, (FILE_H - 0.08) / 4
    k.B("body", (FILE_W, FILE_D, FILE_H - 0.02), (0, 0, (FILE_H - 0.02) / 2), k.MET_D, 0.008)
    k.B("top", (FILE_W + 0.01, FILE_D + 0.01, 0.02), (0, 0, FILE_H - 0.01), k.MET)
    for i in range(4):
        zc = FILE_H - 0.06 - dz * (i + 0.5)
        y = -hd - (0.5 if i == open_drawer else 0.0)
        k.B(f"drawer{i}", (FILE_W - 0.04, 0.02, dz - 0.02), (0, y - 0.01, zc), k.MET, 0.005)
        k.PANEL(f"face{i}", (0, y - 0.0205, zc), FILE_W - 0.06, dz - 0.03, k.FILE_F)
        k.B(f"pull{i}", (0.14, 0.03, 0.025), (0, y - 0.035, zc - 0.03), k.RUST)
        if i == open_drawer:                                             # the drawer's box and its hanging files
            k.B("tray_floor", (FILE_W - 0.06, 0.5, 0.01), (0, y + 0.25, zc - dz / 2 + 0.02), k.MET_D)
            for s in (-1, 1):
                k.B(f"tray_side{s}", (0.01, 0.5, dz - 0.06), (s * (FILE_W / 2 - 0.035), y + 0.25, zc - 0.02), k.MET_D)
            for j in range(11):
                h = 0.22 if j != 6 else 0.3
                k.B(f"file{j}", (FILE_W - 0.1, 0.012, h), (0, y + 0.05 + j * 0.04, zc - dz / 2 + 0.03 + h / 2),
                    k.PAPER if j % 3 else k.OCHRE, rot=(-4 + j % 3 * 3, 0, 0))
                k.B(f"tab{j}", (0.06, 0.004, 0.025), (-0.12 + (j % 4) * 0.08, y + 0.05 + j * 0.04, zc - dz / 2 + 0.26), k.PAPER)
    k.DECAL("dust", (0, 0, FILE_H + 0.002), FILE_W, FILE_D, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((FILE_W, FILE_D, FILE_H), (0, 0, FILE_H / 2))


def file_cabinet():
    k = ArchiveKit("file_cabinet")
    _cabinet(k)
    k.finish(ao_dist=0.5)


def file_cabinet_open():
    k = ArchiveKit("file_cabinet_open")
    _cabinet(k, open_drawer=1)
    k.DECAL("papers", (0.1, -FILE_D / 2 - 0.55, 0.004), 0.9, 0.9, k.D_PAPERS, facing="+z", up=(0.3, 1, 0))
    k.COL((FILE_W, 0.5, 0.3), (0, -FILE_D / 2 - 0.25, FILE_H - 0.06 - (FILE_H - 0.08) / 4 * 1.5))
    k.finish(ao_dist=0.5)


def card_catalog():
    k = ArchiveKit("card_catalog")
    cols, rows, leg = 6, 9, 0.46
    hw, hd, body = CAT_W / 2, CAT_D / 2, CAT_H - leg - 0.03
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.B(f"leg{sx}{sy}", (0.05, 0.05, leg), (sx * (hw - 0.05), sy * (hd - 0.05), leg / 2), k.MET_D)
    k.B("apron", (CAT_W - 0.04, CAT_D - 0.04, 0.06), (0, 0, leg - 0.03), k.MET_D)
    k.B("slide", (CAT_W - 0.2, 0.36, 0.02), (0, -hd - 0.1, leg - 0.05), k.PLATE)          # reference slide, pulled out
    k.B("body", (CAT_W, CAT_D, body), (0, 0, leg + body / 2), k.MET_D, 0.008)
    k.B("top", (CAT_W + 0.04, CAT_D + 0.04, 0.03), (0, 0, CAT_H - 0.015), k.MET)
    fw, fh = CAT_W - 0.05, body - 0.04
    k.PANEL("face", (0, -hd - 0.002, leg + body / 2), fw, fh, k.CAT_F)
    cw, ch = fw / cols, fh / rows
    pulled = (2, 3)
    for c in range(cols):
        for r in range(rows):
            x, z = -fw / 2 + (c + 0.5) * cw, leg + body / 2 + fh / 2 - (r + 0.5) * ch
            if (c, r) == pulled:
                k.PANEL("hole", (x, -hd - 0.004, z), cw - 0.01, ch - 0.01, k.CABLE)
                k.B("drawer", (cw - 0.02, 0.4, ch - 0.02), (x, -hd - 0.1, z), k.MET_D)
                for j in range(18):
                    k.B(f"card{j}", (cw - 0.05, 0.003, ch - 0.035), (x, -hd - 0.26 + j * 0.018, z + 0.01), k.PAPER,
                        rot=(8 if j == 7 else 0, 0, 0))
                continue
            k.B(f"knob{c}{r}", (0.02, 0.02, 0.02), (x, -hd - 0.012, z - ch * 0.22), k.RUST)
    k.DECAL("cards", (0.2, 0.02, CAT_H + 0.002), 0.4, 0.3, k.D_PAPERS, facing="+z", up=(0.4, 1, 0))
    k.DECAL("dust", (0, 0, CAT_H + 0.003), CAT_W, CAT_D, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((CAT_W, CAT_D, CAT_H), (0, 0, CAT_H / 2))
    k.finish(ao_dist=0.5)


PROPS = {f.__name__: f for f in (archive_stack, file_cabinet, file_cabinet_open, card_catalog)}
