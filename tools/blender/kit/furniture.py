"""Outpost 73 kit: furniture. Heavy pressed-steel government issue, 200 years of dust.
table_steel  1.6 x 0.9 work table, clean top at TABLE_TOP (tabletop props go on it), drawer, lower shelf
chair_steel  matching chair, cracked vinyl seat
locker       double steel locker, left door hanging open on a rad suit, mask and boots
shelf_rack   1.2 m steel shelving: binders, boxes, canisters, glowing amber sample jars, a cable coil
"""
import math
import random

import ps1_lib as L
from kit_lib import TABLE_TOP, Kit, jitter_verts


def table_steel():
    k = Kit("table_steel")
    t, hd = TABLE_TOP, 0.45                                                        # top height, half depth (0.9 m deep)
    k.B("top", (1.6, 2 * hd, 0.04), (0, 0, t - 0.02), k.MET, 0.01)
    for s in (-1, 1):
        k.B(f"apron_y{s}", (1.42, 0.03, 0.09), (0, s * (hd - 0.06), t - 0.085), k.MET_D)
        k.B(f"apron_x{s}", (0.03, 2 * hd - 0.18, 0.09), (s * 0.72, 0, t - 0.085), k.MET_D)
        for sy in (-1, 1):
            k.B(f"leg{s}{sy}", (0.06, 0.06, t - 0.04), (s * 0.74, sy * (hd - 0.06), (t - 0.04) / 2), k.MET_D)
            k.B(f"foot{s}{sy}", (0.09, 0.09, 0.02), (s * 0.74, sy * (hd - 0.06), 0.01), k.MET)
    k.B("shelf", (1.46, 2 * hd - 0.14, 0.025), (0, 0, 0.18), k.PLATE)
    k.B("drawer", (0.42, 2 * hd - 0.18, 0.15), (0.45, 0, t - 0.205), k.MET_D, 0.008)        # hangs under the apron
    k.B("drawer_front", (0.40, 0.02, 0.12), (0.45, -hd + 0.08, t - 0.205), k.MET, 0.005)
    k.B("drawer_pull", (0.12, 0.025, 0.02), (0.45, -hd + 0.06, t - 0.195), k.RUST)
    k.B("crate_under", (0.44, 0.34, 0.22), (-0.35, 0.05, 0.3025), k.BOX, rot=(0, 0, 8))   # forgotten box on the shelf
    k.DECAL("stain", (-0.45, 0.1, t + 0.002), 0.5, 0.5, k.D_STAIN, facing="+z", up=(0, 1, 0))
    k.DECAL("dust", (0.2, -0.05, t + 0.003), 1.3, 0.8, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.DECAL("dust_shelf", (0.2, 0, 0.1935), 1.3, 0.7, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((1.6, 2 * hd, t), (0, 0, t / 2))
    k.finish(ao_dist=0.6)


def chair_steel():
    k = Kit("chair_steel")
    k.B("seat", (0.44, 0.42, 0.04), (0, 0, 0.46), k.MET_D, 0.01)
    cush = k.B("cushion", (0.40, 0.37, 0.035), (0, -0.01, 0.495), k.CABLE, 0.01)
    jitter_verts(cush, 0.006, 4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.TUBE(f"leg{sx}{sy}", (sx * 0.18, sy * 0.17, 0.45), (sx * 0.21, sy * 0.2, 0.0), 0.016, k.MET)
        k.TUBE(f"rail{sx}", (sx * 0.195, -0.185, 0.15), (sx * 0.195, 0.185, 0.15), 0.01, k.MET)
        k.TUBE(f"post{sx}", (sx * 0.19, 0.18, 0.46), (sx * 0.19, 0.23, 0.92), 0.016, k.MET)
    k.B("back", (0.42, 0.035, 0.24), (0, 0.222, 0.8), k.MET_D, 0.01, rot=(-6, 0, 0))
    k.COL((0.46, 0.46, 0.92), (0, 0.02, 0.46))
    k.finish(subdiv=0.2, ao_dist=0.5)


def _locker_door(k, x, lst, seed):
    """0.38 m door centred on x: louvre slats top and bottom, pull handle near the centre seam."""
    k.B(f"door{x}", (0.38, 0.02, 1.76), (x, -0.24, 0.99), k.MET_D, 0.006, into=lst)
    for z0 in (1.58, 0.22):
        for i in range(5):
            k.B(f"louvre{x}{z0}{i}", (0.24, 0.012, 0.018), (x, -0.252, z0 + i * 0.04), k.CABLE, into=lst)
    hx = x + (0.15 if x < 0 else -0.15)
    k.B(f"pull{x}", (0.025, 0.035, 0.16), (hx, -0.262, 1.0), k.RUST, into=lst)
    k.B(f"tag{x}", (0.08, 0.006, 0.04), (x, -0.252, 1.3), k.MET, into=lst)


def locker():
    k = Kit("locker")
    k.B("back", (0.8, 0.02, 1.9), (0, 0.24, 0.95), k.PLATE)
    for s in (-1, 1):
        k.B(f"side{s}", (0.02, 0.5, 1.9), (s * 0.39, 0, 0.95), k.PLATE)
        k.B(f"shelf{s}", (0.36, 0.46, 0.015), (s * 0.195, 0.01, 1.62), k.MET_D)
    k.B("top", (0.82, 0.52, 0.02), (0, 0, 1.91), k.MET_D, 0.005)
    k.B("plinth", (0.8, 0.5, 0.1), (0, 0, 0.05), k.MET_D)
    k.B("divider", (0.02, 0.48, 1.78), (0, 0, 0.99), k.PLATE)
    _locker_door(k, 0.195, k.parts, 1)
    left = []
    _locker_door(k, -0.195, left, 2)
    L.rotate_about(left, (-0.39, -0.25, 0), (0, 0, -40))                            # hanging open
    k.parts.extend(left)
    # inside the open half: rad suit on a hook rod, gas mask on the shelf, boots
    k.TUBE("rod", (-0.38, 0.0, 1.52), (-0.01, 0.0, 1.52), 0.01, k.MET)
    suit = L.vprism("suit", [(-0.32, 0.07), (-0.08, 0.07), (-0.06, -0.09), (-0.34, -0.09)], 0.72, 1.5, k.OCHRE)
    jitter_verts(suit, 0.012, 7)
    k.parts.append(suit)
    k.CYL("mask", 0.07, 0.08, (-0.2, -0.02, 1.667), k.CABLE, v=10)
    k.CYL("filter", 0.04, 0.05, (-0.2, -0.07, 1.645), k.MET, "y", 8)
    for i, x in enumerate((-0.28, -0.14)):
        k.B(f"boot{i}", (0.1, 0.24, 0.14), (x, 0.0, 0.17), k.CABLE, 0.02, rot=(0, 0, 6 - 12 * i))
    k.DECAL("dust", (0, 0, 1.922), 0.8, 0.5, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.DECAL("streak", (0.195, -0.2515, 1.2), 0.36, 0.8, k.D_STREAK)
    k.COL((0.8, 0.5, 1.92), (0, 0, 0.96))
    k.finish(ao_dist=0.6)


def shelf_rack():
    k = Kit("shelf_rack")
    rng = random.Random(9)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.B(f"post{sx}{sy}", (0.04, 0.04, 1.9), (sx * 0.58, sy * 0.205, 0.95), k.MET_D)
    tops = []
    for i, z in enumerate((0.12, 0.62, 1.12, 1.62)):
        k.B(f"shelf{i}", (1.2, 0.45, 0.025), (0, 0, z), k.MET)
        k.B(f"lip{i}", (1.2, 0.02, 0.05), (0, -0.225, z - 0.012), k.MET_D)
        tops.append(z + 0.0125)
    for s in (-1, 1):
        k.TUBE(f"brace{s}", (s * 0.56, 0.215, 0.12), (-s * 0.56, 0.215, 1.62), 0.008)
    z = tops[0]                                                              # floor shelf: canisters and a box
    for i, x in enumerate((-0.42, -0.22)):
        k.CYL(f"can{i}", 0.09, 0.3, (x, 0.02, z + 0.15), k.RUST, v=10)
        k.CYL(f"can_lid{i}", 0.092, 0.02, (x, 0.02, z + 0.3), k.MET_D, v=10)
    k.B("box0", (0.38, 0.32, 0.26), (0.3, 0.02, z + 0.13), k.BOX, rot=(0, 0, -5))
    z = tops[1]                                                              # binders, one fallen over
    for i in range(9):
        h = rng.uniform(0.24, 0.3)
        mat = (k.OCHRE, k.CABLE, k.BOX)[i % 3]
        k.B(f"binder{i}", (0.045, 0.26, h), (-0.5 + i * 0.05, 0.0, z + h / 2), mat, rot=(0, 0, rng.uniform(-3, 3)))
    k.B("binder_fallen", (0.26, 0.28, 0.045), (0.1, 0.0, z + 0.0225), k.OCHRE, rot=(0, 0, 12))
    k.B("box1", (0.3, 0.3, 0.2), (0.4, 0.02, z + 0.1), k.BOX)
    z = tops[2]                                                              # amber sample jars and a toolbox
    for i in range(4):
        x = -0.45 + i * 0.11
        k.CYL(f"jar{i}", 0.04, 0.13, (x, -0.05 + (i % 2) * 0.06, z + 0.065), k.LIQUID, v=8)
        k.CYL(f"jar_cap{i}", 0.043, 0.025, (x, -0.05 + (i % 2) * 0.06, z + 0.142), k.MET, v=8)
    k.B("toolbox", (0.42, 0.2, 0.16), (0.3, 0.0, z + 0.08), k.RUST, 0.01)
    k.B("toolbox_handle", (0.25, 0.02, 0.04), (0.3, 0.0, z + 0.18), k.MET_D)
    z = tops[3]                                                              # top: box stack and a cable coil
    k.B("box2", (0.36, 0.34, 0.22), (-0.35, 0.0, z + 0.11), k.BOX)
    k.B("box3", (0.3, 0.28, 0.16), (-0.33, 0.02, z + 0.3), k.BOX, rot=(0, 0, 14))
    ring = [(0.3 + 0.16 * math.cos(a * math.tau / 10), 0.16 * math.sin(a * math.tau / 10), z + 0.02) for a in range(11)]
    k.PIPE("coil", ring, 0.02, k.CABLE, verts=5)
    k.DECAL("dust", (0, 0, z + 0.003), 1.2, 0.45, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_light_amber", (-0.3, -0.35, tops[2] + 0.1))
    k.COL((1.2, 0.45, 1.9), (0, 0, 0.95))
    k.finish(ao_dist=0.5)


PROPS = {f.__name__: f for f in (table_steel, chair_steel, locker, shelf_rack)}
