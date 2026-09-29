"""Apartment kit: kitchen. Base and wall units on a 0.6 m module (back on y = 0, front -Y, origin on the floor), worktop at
apt_dims.COUNTER_H. Label-maker labels on every drawer.
counter_base      0.6: drawer (TOWELS) over a door          counter_drawers  0.6: FORKS / SPOONS / KNIVES (child lock on knives)
counter_sink      0.8: steel basin, gooseneck tap, one soap bottle dead centre; marker_use_tap
stove             0.76 electric range, coils spotless, every knob taped at OFF; marker_use_stove
fridge            0.76 top-freezer, four magnets in a row and nothing under them
wall_cabinet      0.6 upper unit (UPPER_Z .. +0.72), light strip under it (marker_light_strip)
wall_shelf_pantry 1.2 open shelves: cans by colour, labels forward; labelled jars
dining_table      0.9 x 0.7, one placemat          chair_wood  bentwood-ish chair
trash_bin         pedal bin          (worktop things: counter.py)
"""
import math

import apt_dims as D
from apt_lib import AptKit

H = D.COUNTER_H


def _carcass(k, w):
    d = D.COUNTER_D - 0.04
    k.B("plinth", (w - 0.04, d - 0.06, 0.1), (0, -d / 2 + 0.03, 0.05), k.BLACK)
    k.B("carcass", (w, d, H - 0.14), (0, -d / 2, 0.1 + (H - 0.14) / 2), k.CAB)
    k.B("top", (w, D.COUNTER_D, 0.04), (0, -D.COUNTER_D / 2, H - 0.02), k.COUNTER, 0.004)
    k.COL((w, D.COUNTER_D, H), (0, -D.COUNTER_D / 2, H / 2))
    return -d - 0.01                                                                     # front face y


def _shaker(k, name, x, y, w, z0, z1, rail=0.055):
    """Shaker frame on a door face (stiles and rails 1 cm proud): reads as joinery, not a slab."""
    zc, hh = (z0 + z1) / 2, z1 - z0
    for s in (-1, 1):
        k.B(f"{name}_stile{s}", (rail, 0.01, hh), (x + s * (w / 2 - rail / 2), y - 0.005, zc), k.CAB, 0.003)
        k.B(f"{name}_rail{s}", (w - 2 * rail, 0.01, rail), (x, y - 0.005, zc + s * (hh / 2 - rail / 2)), k.CAB, 0.003)


def _front(k, name, w, z0, z1, y, label=None, knob=True):
    k.B(name, (w - 0.02, 0.02, z1 - z0 - 0.01), (0, y, (z0 + z1) / 2), k.CAB, 0.004)
    if z1 - z0 >= 0.3:
        _shaker(k, name, 0, y - 0.01, w - 0.02, z0 + 0.005, z1 - 0.005)
    if knob:
        k.CYL(name + "_knob", 0.012, 0.025, (0, y - 0.02, z1 - 0.05 if z1 - z0 < 0.3 else z1 - 0.08), k.BRASS, "y", 8)
    if label:
        k.LABEL(label, (0, y - 0.0105, z1 - 0.025 if z1 - z0 < 0.3 else z1 - 0.03))


def counter_base():
    k = AptKit("counter_base")
    y = _carcass(k, 0.6)
    _front(k, "drawer", 0.6, H - 0.2, H - 0.04, y, "TOWELS")
    _front(k, "door", 0.6, 0.1, H - 0.21, y)
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


def counter_drawers():
    k = AptKit("counter_drawers")
    y = _carcass(k, 0.6)
    for i, word in enumerate(("FORKS", "SPOONS", "KNIVES")):
        z1 = H - 0.04 - i * 0.26
        _front(k, f"drawer{i}", 0.6, z1 - 0.26, z1, y, word)
    k.B("child_lock", (0.03, 0.05, 0.012), (0.18, y + 0.005, H - 0.566), k.CAP)          # strap over the knives drawer
    k.B("child_lock_hasp", (0.035, 0.012, 0.05), (0.18, y - 0.011, H - 0.6), k.CAP)
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


def counter_sink():
    k = AptKit("counter_sink")
    w, d = 0.8, D.COUNTER_D
    k.B("plinth", (w - 0.04, d - 0.1, 0.1), (0, -d / 2 + 0.03, 0.05), k.BLACK)
    k.B("carcass", (w, d - 0.04, H - 0.14), (0, -(d - 0.04) / 2, 0.1 + (H - 0.14) / 2), k.CAB)
    bw, bd, by = 0.52, 0.38, -0.33                                                       # basin
    f1, b0 = by - bd / 2, by + bd / 2                                                    # worktop in four pieces round the hole
    k.B("top_f", (w, f1 + d, 0.04), (0, (f1 - d) / 2, H - 0.02), k.COUNTER)
    k.B("top_b", (w, -b0, 0.04), (0, b0 / 2, H - 0.02), k.COUNTER)
    for s in (-1, 1):
        k.B(f"top_side{s}", ((w - bw) / 2, bd, 0.04), (s * (w + bw) / 4, by, H - 0.02), k.COUNTER)
    k.B("basin", (bw, bd, 0.02), (0, by, H - 0.2), k.STEEL)
    for s in (-1, 1):
        k.B(f"basin_x{s}", (0.01, bd, 0.18), (s * bw / 2, by, H - 0.1), k.STEEL)
        k.B(f"basin_y{s}", (bw, 0.01, 0.18), (0, by + s * bd / 2, H - 0.1), k.STEEL)
    k.CYL("drain", 0.03, 0.004, (0, by, H - 0.188), k.CHROME, v=8)
    k.PIPE("tap", [(0, -0.07, H), (0, -0.07, H + 0.3), (0, -0.17, H + 0.33), (0, -0.25, H + 0.24)], 0.014, k.CHROME, verts=8)
    k.CYL("tap_base", 0.03, 0.03, (0, -0.07, H + 0.015), k.CHROME, v=10)
    k.B("tap_lever", (0.1, 0.018, 0.014), (0.06, -0.07, H + 0.07), k.CHROME, into=k.PIVOT("turn_lever", (0.015, -0.07, H + 0.07)))
    k.B("soap", (0.06, 0.04, 0.16), (-0.33, -0.1, H + 0.08), k.PLASTIC, 0.008)          # the one bottle, dead centre of its corner
    k.B("soap_pump", (0.015, 0.05, 0.03), (-0.33, -0.11, H + 0.18), k.CAP)
    y = -(d - 0.04) - 0.01
    for s in (-1, 1):
        k.B(f"door{s}", (w / 2 - 0.02, 0.02, H - 0.17), (s * w / 4, y, 0.1 + (H - 0.16) / 2), k.CAB, 0.004)
        _shaker(k, f"door{s}", s * w / 4, y - 0.01, w / 2 - 0.02, 0.105, H - 0.065)
        k.CYL(f"knob{s}", 0.012, 0.025, (s * 0.06, y - 0.02, H - 0.14), k.BRASS, "y", 8)
    k.COL((w, d, H), (0, -d / 2, H / 2))
    k.USE("tap", (0.05, -0.12, H + 0.15))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


def stove():
    k = AptKit("stove")
    w, d = 0.76, 0.65
    k.SOFT("body", (w, d - 0.02, H - 0.04), (0, -(d - 0.02) / 2, (H - 0.04) / 2), k.PORC, 0.012, step=0.2)
    k.B("cooktop", (w, d, 0.04), (0, -d / 2, H - 0.02), k.PORC, 0.006)
    for x in (-0.18, 0.18):
        for y, r in ((-0.44, 0.1), (-0.2, 0.08)):
            k.CYL(f"pan{x}{y}", r + 0.02, 0.006, (x, y, H + 0.003), k.CHROME, v=24)
            for rr in (r * 0.45, r * 0.75, r):
                ring = [(x + rr * math.cos(a * math.tau / 24), y + rr * math.sin(a * math.tau / 24), H + 0.012) for a in range(25)]
                k.PIPE(f"coil{x}{y}{rr}", ring, 0.006, k.CORD, verts=6)
    k.B("backguard", (w, 0.06, 0.2), (0, -0.03, H + 0.1), k.PORC, 0.006)
    for i, x in enumerate((-0.27, -0.09, 0.09, 0.27)):                                   # turn_knob0..3 (AptCheck)
        knob = k.PIVOT(f"turn_knob{i}", (x, -0.06, H + 0.1))
        k.CYL(f"knob{x}", 0.022, 0.025, (x, -0.0725, H + 0.1), k.CHROME, "y", 10, into=knob)
        k.B(f"knob_mark{x}", (0.004, 0.004, 0.018), (x, -0.086, H + 0.108), k.BLACK, into=knob)
        k.DECAL(f"knob_tape{x}", (x, -0.0865, H + 0.098), 0.07, 0.016, k.D_TAPE)
    k.B("oven_door", (w - 0.06, 0.03, 0.55), (0, -d - 0.005, 0.44), k.PORC, 0.006)
    k.PANEL("oven_window", (0, -d - 0.021, 0.46), 0.44, 0.24, k.TV)
    k.TUBE("oven_handle", (-0.3, -d - 0.06, 0.76), (0.3, -d - 0.06, 0.76), 0.012, k.CHROME)
    k.B("drawer", (w - 0.06, 0.03, 0.12), (0, -d - 0.005, 0.08), k.PORC, 0.006)
    k.COL((w, d, H + 0.2), (0, -d / 2, (H + 0.2) / 2))
    k.USE("stove", (0, -0.35, H + 0.06))
    k.finish(wall=True, subdiv=0.25, ao_dist=0.35)


def fridge():
    k = AptKit("fridge")
    w, d, h = 0.76, 0.7, 1.78
    k.SOFT("body", (w, d - 0.04, h), (0, -(d - 0.04) / 2, h / 2), k.PORC, 0.035, step=0.15)
    for name, z0, z1 in (("door_low", 0.04, 1.22), ("door_top", 1.24, h - 0.02)):
        k.SOFT(name, (w - 0.01, 0.05, z1 - z0), (0, -d + 0.0225, (z0 + z1) / 2), k.PORC, 0.022, step=0.15)
        k.TUBE(name + "_handle", (-w / 2 + 0.06, -d - 0.04, z0 + 0.1 if name == "door_top" else z1 - 0.5),
               (-w / 2 + 0.06, -d - 0.04, z1 - 0.1), 0.012, k.CHROME)
    for i, mat in enumerate((k.RUSTF, k.CHAIR, k.SOFA, k.CREAM)):                          # four magnets, holding nothing
        k.CYL(f"magnet{i}", 0.016, 0.01, (-0.12 + i * 0.09, -d - 0.005, 1.6), mat, "y", 8)
    k.B("grille", (w - 0.08, 0.02, 0.04), (0, -d + 0.03, 0.02), k.BLACK)
    k.COL((w, d, h), (0, -d / 2, h / 2))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


def wall_cabinet():
    k = AptKit("wall_cabinet")
    w, d, z0, h = 0.6, 0.34, D.UPPER_Z, 0.72
    k.B("box", (w, d, h), (0, -d / 2, z0 + h / 2), k.CAB)
    for s in (-1, 1):
        k.B(f"door{s}", (w / 2 - 0.01, 0.02, h - 0.02), (s * w / 4, -d - 0.01, z0 + h / 2), k.CAB, 0.004)
        _shaker(k, f"door{s}", s * w / 4, -d - 0.02, w / 2 - 0.01, z0 + 0.01, z0 + h - 0.01)
        k.CYL(f"knob{s}", 0.011, 0.022, (s * 0.04, -d - 0.03, z0 + 0.08), k.BRASS, "y", 8)
    k.B("strip", (w - 0.08, 0.03, 0.012), (0, -d + 0.05, z0 - 0.006), k.BULB)
    k.LIGHT("marker_light_strip", (0, -d + 0.06, z0 - 0.04))
    k.COL((w, d, h), (0, -d / 2, z0 + h / 2))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.3, ground=False)


def wall_shelf_pantry():
    k = AptKit("wall_shelf_pantry")
    w, d = 1.2, 0.26
    for i, z in enumerate((1.45, 1.8)):
        k.B(f"shelf{i}", (w, d, 0.025), (0, -d / 2, z), k.WOOD_L, 0.003)
        for s in (-1, 1):
            k.PRISM(f"bracket{i}{s}", [(0, 0), (0, -0.1), (-(d - 0.06), 0)], 0.018, (s * (w / 2 - 0.12) - 0.009, 0, z - 0.0125),
                    k.WOOD_D, plane="yz")
    top = 1.45 + 0.0125
    for i in range(12):                                                                    # cans sorted by label colour
        c = i * len(D.CANS) // 12
        x = -w / 2 + 0.07 + i * 0.09
        k.CYL(f"can{i}", 0.037, 0.11, (x, -0.12, top + 0.055), k.CHROME, v=10)
        k.WRAP_UV(f"can_label{i}", (x, -0.12), 0.0385, top + 0.012, top + 0.098, 200, 340, k.CANS, D.row_uv(c, len(D.CANS)))
    top = 1.8 + 0.0125
    for i, word in enumerate(("FLOUR", "RICE", "SALT", "SUGAR", "TEA")):                    # alphabetical, of course
        x = -w / 2 + 0.14 + i * 0.23
        k.CYL(f"jar{i}", 0.05, 0.18, (x, -0.12, top + 0.09), k.GLASS, v=10)
        k.CYL(f"jar_fill{i}", 0.046, 0.12, (x, -0.12, top + 0.062), k.PAPER if i != 4 else k.CARD, v=10)
        k.CYL(f"jar_lid{i}", 0.052, 0.025, (x, -0.12, top + 0.19), k.WOOD, v=10)
        k.LABEL(word, (x, -0.172, top + 0.13), 0.06)
    k.finish(wall=True, subdiv=0.3, ao_dist=0.25, ground=False)


def dining_table():
    k = AptKit("dining_table")
    h = D.TABLE_H
    k.B("top", (0.9, 0.7, 0.03), (0, 0, h - 0.015), k.WOOD_L, 0.005)
    for x in (-0.4, 0.4):
        for y in (-0.3, 0.3):
            k.B(f"leg{x}{y}", (0.045, 0.045, h - 0.03), (x, y, (h - 0.03) / 2), k.WOOD_L)
    k.B("apron", (0.76, 0.56, 0.07), (0, 0, h - 0.065), k.WOOD_L)
    k.B("placemat", (0.42, 0.3, 0.003), (0, -0.18, h + 0.0015), k.LINEN)                 # one place, squared to the edge
    k.COL((0.9, 0.7, h), (0, 0, h / 2))
    k.finish(subdiv=0.25, ao_dist=0.35)


def chair_wood():
    k = AptKit("chair_wood")
    k.B("seat", (0.42, 0.42, 0.03), (0, 0, 0.45), k.WOOD_L, 0.006)
    for x in (-0.18, 0.18):
        for y in (-0.18, 0.18):
            k.TUBE(f"leg{x}{y}", (x, y, 0.44), (x * 1.08, y * 1.08, 0.0), 0.016, k.WOOD_L)
        k.TUBE(f"post{x}", (x, 0.19, 0.46), (x, 0.22, 0.9), 0.015, k.WOOD_L)
    for i, z in enumerate((0.62, 0.72, 0.84)):
        k.B(f"slat{i}", (0.36, 0.02, 0.05), (0, 0.205 + (z - 0.46) * 0.07, z), k.WOOD_L)
    k.COL((0.44, 0.46, 0.9), (0, 0.01, 0.45))
    k.finish(subdiv=0.2, ao_dist=0.3)


def bin_body(k):
    """The pedal bin without its lid (trash_bin here; mess_trash.trash_bin_full lifts the lid on a bag that does not fit)."""
    k.CYL("body", 0.14, 0.44, (0, 0, 0.23), k.CHROME, v=14)
    k.CYL("base", 0.145, 0.02, (0, 0, 0.01), k.BLACK, v=14)
    k.B("pedal", (0.08, 0.06, 0.015), (0, -0.16, 0.03), k.BLACK)


def trash_bin():
    k = AptKit("trash_bin")
    bin_body(k)
    k.CYL("lid", 0.145, 0.03, (0, 0, 0.465), k.CHROME, v=14)
    k.COL_CYL(0.145, 0.48, (0, 0, 0.24))
    k.finish(subdiv=0.15, ao_dist=0.2)


PROPS = {f.__name__: f for f in (counter_base, counter_drawers, counter_sink, stove, fridge, wall_cabinet, wall_shelf_pantry,
                                 dining_table, chair_wood, trash_bin)}
