"""Apartment kit: living room. Everything squared, centred and in even numbers; the tape on the floor says where it goes back.
sofa            3-seat, dusty teal, cushions dead level, two pillows mirrored, throw folded to a square on the right arm
armchair        mustard, matching legs
coffee_table    walnut, four coasters in a square, two remotes parallel, books squared on the shelf, blue tape at each foot
tv_console      low cabinet + flat TV (off), cables bundled and tied
floor_lamp      tripod, drum shade (marker_light_lamp)
table_lamp      ceramic base, drum shade (marker_light_lamp); tabletop
side_table      round, at apt_dims.SIDE_H
plant_snake     snake plant: symmetric fan of leaves
rug_living      1.6 x 2.4 rug (apt_rug.png)
picture_frame_a..d  hanging (origin = back centre): walnut frame, cream mat, print cell 0..3 of apt_art.png
wall_clock      hanging: live hands (hand_h / hand_m / hand_s, AptClock)
"""
import math

import apt_dims as D
import ps1_lib as L
from apt_lib import AptKit
import library
from kit_lib import jitter_verts

def _legs(k, xs, ys, h, r=0.022, mat=None, taper=0.7):
    for x in xs:
        for y in ys:
            k.FRUSTUM(f"leg{x}{y}", r, r * taper, h, (x, y, h / 2), mat or k.WOOD, axis="z", v=6)


def sofa():
    k = AptKit("sofa")
    w, d = 2.0, 0.9
    _legs(k, (-0.9, 0.9), (-0.36, 0.36), 0.1, 0.024, k.WOOD_D)
    k.SOFT("base", (w - 0.04, d - 0.02, 0.24), (0, 0, 0.22), k.SOFA, 0.035, step=0.1)
    k.SOFT("back", (w - 0.34, 0.2, 0.52), (0, d / 2 - 0.1, 0.6), k.SOFA, 0.06, step=0.1)
    for s in (-1, 1):                                                                   # rolled arms
        k.SOFT(f"arm{s}", (0.19, d, 0.52), (s * (w / 2 - 0.095), 0, 0.36), k.SOFA, 0.085, puff=0.012, axis="z", step=0.08)
    cw = (w - 0.38) / 3
    for i in range(3):
        x = (i - 1) * cw
        k.SOFT(f"seat{i}", (cw - 0.01, 0.66, 0.15), (x, -0.1, 0.415), k.SOFA, 0.05, puff=0.022, step=0.07)
        k.SOFT(f"back_cush{i}", (cw - 0.01, 0.2, 0.44), (x, 0.17, 0.71), k.SOFA, 0.07, puff=0.035, axis="-y", step=0.07,
               rot=(-10, 0, 0))
    for s in (-1, 1):                                                                    # four pillows, mirrored
        k.SOFT(f"pillow{s}", (0.42, 0.15, 0.42), (s * 0.6, 0.06, 0.73), k.CREAM, 0.07, puff=0.04, axis="y", step=0.06,
               rot=(-16, 0, 0))
        k.SOFT(f"pillow_in{s}", (0.36, 0.13, 0.34), (s * 0.42, -0.01, 0.69), k.RUSTF, 0.06, puff=0.035, axis="y", step=0.06,
               rot=(-18, 0, 0))
    k.SOFT("throw", (0.2, 0.48, 0.05), (w / 2 - 0.095, 0.0, 0.645), k.KNIT, 0.02, puff=0.008, step=0.05)   # folded square
    k.COL((w, d, 0.85), (0, 0, 0.425))
    k.finish(subdiv=0.25, ao_dist=0.5)


def armchair():
    k = AptKit("armchair")
    _legs(k, (-0.33, 0.33), (-0.32, 0.32), 0.14, 0.022, k.WOOD_D)
    k.SOFT("base", (0.8, 0.78, 0.24), (0, 0, 0.26), k.CHAIR, 0.04, step=0.08)
    k.SOFT("seat", (0.54, 0.6, 0.13), (0, -0.07, 0.445), k.CHAIR, 0.05, puff=0.02, step=0.06)
    k.SOFT("back", (0.7, 0.2, 0.54), (0, 0.3, 0.66), k.CHAIR, 0.08, puff=0.03, axis="-y", step=0.07, rot=(-9, 0, 0))
    for s in (-1, 1):
        k.SOFT(f"arm{s}", (0.14, 0.78, 0.3), (s * 0.33, 0, 0.53), k.CHAIR, 0.065, step=0.07)
    k.COL((0.82, 0.8, 0.9), (0, 0, 0.45))
    k.finish(subdiv=0.25, ao_dist=0.45)


def coffee_table():
    k = AptKit("coffee_table")
    w, d, h = 1.1, 0.6, D.COFFEE_H
    k.B("top", (w, d, 0.035), (0, 0, h - 0.0175), k.WOOD, 0.006)
    for x in (-0.5, 0.5):
        for y in (-0.25, 0.25):
            k.B(f"leg{x}{y}", (0.045, 0.045, h - 0.035), (x, y, (h - 0.035) / 2), k.WOOD)
            for dx, dy in ((0.04, 0), (0, 0.04)):                                        # tape corner at each foot
                k.DECAL(f"tape{x}{y}{dx}", (x + math.copysign(dx, x), y + math.copysign(dy, y), 0.002), 0.09 if dx else 0.02,
                        0.02 if dx else 0.09, k.D_TAPE_B, facing="+z", up=(0, 1, 0))
    k.B("shelf", (w - 0.1, d - 0.1, 0.02), (0, 0, 0.12), k.WOOD)
    library.flat_stack(k, library.TABLE, -0.2, -0.08, 0.13)
    for x in (-0.07, 0.07):                                                              # four coasters, a perfect square
        for y in (-0.07, 0.07):
            k.CYL(f"coaster{x}{y}", 0.045, 0.006, (0.28 + x, y, h + 0.003), k.CORD if (x > 0) == (y > 0) else k.WOOD_L, v=10)
    for i, y in enumerate((-0.1, -0.02)):
        k.B(f"remote{i}", (0.2, 0.05, 0.022), (-0.18, y - 0.1, h + 0.011), k.BLACK, 0.005)
    k.COL((w, d, h), (0, 0, h / 2))
    k.finish(subdiv=0.2, ao_dist=0.4)


def tv_console():
    k = AptKit("tv_console")
    k.B("cabinet", (1.6, 0.42, 0.44), (0, 0, 0.28), k.WOOD, 0.008)
    _legs(k, (-0.72, 0.72), (-0.15, 0.15), 0.06, 0.018, k.WOOD_D, 1.0)
    for x in (-0.4, 0.4):
        k.B(f"door{x}", (0.78, 0.012, 0.38), (x, -0.215, 0.28), k.WOOD_L, 0.004)
        k.B(f"pull{x}", (0.1, 0.02, 0.012), (x + (0.3 if x < 0 else -0.3), -0.228, 0.42), k.BRASS)
    k.B("stand", (0.3, 0.2, 0.02), (0, 0.02, 0.51), k.BLACK)
    k.B("neck", (0.06, 0.04, 0.12), (0, 0.05, 0.58), k.BLACK)
    k.B("tv", (1.12, 0.05, 0.66), (0, 0.06, 0.95), k.BLACK, 0.006)
    k.PANEL("screen", (0, 0.0345, 0.96), 1.08, 0.61, k.TV)
    k.PIPE("cables", [(0.05, 0.09, 0.8), (0.05, 0.2, 0.6), (0.05, 0.2, 0.3), (0.1, 0.19, 0.0)], 0.012, k.CORD, verts=5)
    for z in (0.55, 0.4):
        k.CYL(f"tie{z}", 0.016, 0.012, (0.05, 0.2, z), k.CAP, v=6)
    k.COL((1.6, 0.42, 0.5), (0, 0, 0.25))
    k.finish(subdiv=0.25, ao_dist=0.4)


def _shade_lamp(k, z_shade, r_top, r_bot, hs):
    k.FRUSTUM("shade", r_bot, r_top, hs, (0, 0, z_shade), k.SHADE, axis="z", v=12, into=k.noshadow)
    k.LIGHT("marker_light_lamp", (0, 0, z_shade - hs * 0.2))


def floor_lamp():
    k = AptKit("floor_lamp")
    for a in (90, 210, 330):
        x, y = 0.22 * math.cos(math.radians(a)), 0.22 * math.sin(math.radians(a))
        k.TUBE(f"leg{a}", (x, y, 0.0), (0, 0, 1.0), 0.013, k.WOOD)
    k.TUBE("stem", (0, 0, 1.0), (0, 0, 1.42), 0.01, k.BRASS)
    _shade_lamp(k, 1.52, 0.19, 0.22, 0.3)
    k.COL_CYL(0.22, 1.66, (0, 0, 0.83))
    k.finish(subdiv=0.3, ao_dist=0.3)


def table_lamp():
    k = AptKit("table_lamp")
    k.FRUSTUM("base", 0.07, 0.05, 0.2, (0, 0, 0.1), k.PORC, axis="z", v=20)
    k.CYL("base_foot", 0.075, 0.012, (0, 0, 0.006), k.BRASS, v=20)
    k.CYL("neck", 0.02, 0.12, (0, 0, 0.26), k.BRASS, v=6)
    _shade_lamp(k, 0.4, 0.11, 0.15, 0.2)
    k.COL_CYL(0.15, 0.5, (0, 0, 0.25))
    k.finish(subdiv=0.1, ao_dist=0.15)


def side_table():
    k = AptKit("side_table")
    h = D.SIDE_H
    k.CYL("top", 0.23, 0.03, (0, 0, h - 0.015), k.WOOD, v=32)
    k.CYL("stem", 0.03, h - 0.05, (0, 0, (h - 0.03) / 2 + 0.02), k.WOOD, v=8)
    k.CYL("foot", 0.18, 0.02, (0, 0, 0.01), k.WOOD, v=32)
    k.COL_CYL(0.23, h, (0, 0, h / 2))
    k.finish(subdiv=0.15, ao_dist=0.25)


def plant_snake():
    k = AptKit("plant_snake")
    k.FRUSTUM("pot", 0.13, 0.16, 0.3, (0, 0, 0.15), k.PORC, axis="z", v=10)
    k.CYL("soil", 0.145, 0.01, (0, 0, 0.29), k.SOIL, v=10)
    for i in range(9):
        a = i * math.tau / 9
        lean = 8 + 6 * (i % 2)
        h = 0.55 + 0.15 * ((i * 7) % 3) / 2
        leaf = L.vprism(f"leaf{i}", [(-0.028, -0.006), (0.028, -0.006), (0.02, 0.006), (-0.02, 0.006)], 0.28, 0.28 + h, k.GREEN)
        L.rotate_about([leaf], (0, 0, 0.28), (lean, 0, math.degrees(a)))
        jitter_verts(leaf, 0.004, i)
        k.parts.append(leaf)
    k.COL_CYL(0.16, 0.3, (0, 0, 0.15))
    k.finish(subdiv=0.2, ao_dist=0.2)


def rug_living():
    k = AptKit("rug_living")
    k.B("pad", (1.6, 2.4, 0.008), (0, 0, 0.004), k.CREAM)
    k.PANEL("face", (0, 0, 0.0085), 1.6, 2.4, k.RUG, facing="+z", up=(0, 1, 0))
    k.finish(subdiv=0.5, ao_dist=0.1)


def _frame(name, cell):
    k = AptKit(name)
    w, h = 0.36, 0.46
    for s in (-1, 1):
        k.B(f"side{s}", (0.03, 0.025, h), (s * (w / 2 - 0.015), -0.0125, 0), k.WOOD_D)
        k.B(f"rail{s}", (w, 0.025, 0.03), (0, -0.0125, s * (h / 2 - 0.015)), k.WOOD_D)
    k.B("mat", (w - 0.05, 0.006, h - 0.05), (0, -0.006, 0), k.PAPER)
    k.QUAD_UV("print", (0, -0.0095, 0.0), w - 0.14, (w - 0.14) * 1.0, "-y", k.ART, D.cell_uv(cell), into=k.panels)
    k.finish(wall=True, subdiv=0.1, ao_dist=0.08, ground=False)


def picture_frame_a():
    _frame("picture_frame_a", 0)


def picture_frame_b():
    _frame("picture_frame_b", 1)


def picture_frame_c():
    _frame("picture_frame_c", 2)


def picture_frame_d():
    _frame("picture_frame_d", 3)


def wall_clock():
    k = AptKit("wall_clock")
    k.CYL("rim", 0.165, 0.045, (0, -0.0225, 0), k.WOOD_D, "y", 40)
    k.CYL("bezel", 0.152, 0.006, (0, -0.047, 0), k.BRASS, "y", 40)
    k.DISC("face", (0, -0.0505, 0), 0.145, k.CLOCK, 40)
    for name, length, width, y in (("hand_h", 0.075, 0.012, -0.053), ("hand_m", 0.11, 0.008, -0.056), ("hand_s", 0.12, 0.003, -0.059)):
        hand = k.PIVOT(name, (0, y, 0))
        k.B(name + "_bar", (width, 0.002, length), (0, y, length / 2 - 0.015), k.RUSTF if name == "hand_s" else k.BLACK, into=hand)
    k.CYL("spindle", 0.008, 0.012, (0, -0.06, 0), k.BRASS, "y", 12)
    k.finish(wall=True, subdiv=0.1, ao_dist=0.06, ground=False)


PROPS = {f.__name__: f for f in (sofa, armchair, coffee_table, tv_console, floor_lamp, table_lamp, side_table,
                                 plant_snake, rug_living, picture_frame_a, picture_frame_b, picture_frame_c, picture_frame_d,
                                 wall_clock)}
