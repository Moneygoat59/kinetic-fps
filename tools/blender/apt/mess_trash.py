"""Apartment kit, squalor: rubbish (the flat after night 4; placed by marker_mess_* rows in tools/blender/props/apartment_mess.py).
trash_bag / trash_bag_slump   black bin bags, tied; one upright and full, one sagging and split-sided
trash_bag_white               a kitchen bag with its red drawstring pulled tight
trash_bin_full                the pedal bin, lid forced up by a bag that no longer fits, rubbish on top
pizza_box / pizza_stack       a closed box; four boxes stacked askew
pizza_box_open                lid back, crusts and grease inside
takeout                       a noodle carton and an open foam clamshell with dried food, a plastic fork
cans_litter / bottles_litter  soda cans (standing, tipped, one crushed); empty water bottles
paper_litter                  crumpled paper, receipts, used tissues (floor scatter, no collision)
chip_bag                      a crumpled foil snack bag
mail_pile                     weeks of post under the front door: envelopes, flyers, a past-due notice
parcel_boxes                  delivery cartons, one opened and left, shipping labels up
"""
import math

import apt_forms as F
import kitchen
import ps1_lib as L
from mess_kit import BOTTLE, MessKit

W_BOX, H_BOX = 0.36, 0.045                                      # pizza box footprint and height


def _bag(k, name, size, loc, seed, settle=0.5, white=False):
    mat = k.BAG_W if white else k.BAG
    sx, sy, sz = size
    k.BLOB(name, size, (loc[0], loc[1], loc[2] + sz / 2), mat, seed=seed, lumps=0.13, lump_freq=1.5, folds=0.05, fold_freq=5.0,
           fold_stretch=0.3, settle=settle, pinch=(0.55, 0.14, 0.3), pleats=(11, 0.22, 0.05), subdiv=4)
    top = (loc[0], loc[1], loc[2] + sz)
    k.BLOB(name + "_knot", (0.055, 0.05, 0.045), (top[0], top[1], top[2] - 0.01), mat, seed=seed + 1, lumps=0.25, subdiv=2)
    for s in (-1, 1):
        k.BLOB(f"{name}_ear{s}", (0.085, 0.028, 0.05), (top[0] + s * 0.04, top[1], top[2] + 0.012), mat, seed=seed + 2 + s,
               lumps=0.3, subdiv=2, rot=(0, s * 38, 0))
    if white:                                                   # drawstring loops pulled up through the knot
        for s in (-1, 1):
            k.PIPE(f"{name}_tie{s}", [(top[0] + s * 0.02, top[1], top[2]), (top[0] + s * 0.05, top[1] - 0.01, top[2] + 0.04),
                                      (top[0] + s * 0.02, top[1] - 0.015, top[2] + 0.06)], 0.003, k.TIE, verts=6)


def trash_bag():
    k = MessKit("trash_bag")
    _bag(k, "bag", (0.42, 0.38, 0.56), (0, 0, 0), 3)
    k.COL((0.36, 0.32, 0.4), (0, 0, 0.2))
    k.finish(subdiv=1.0, ao_dist=0.3)


def trash_bag_slump():
    k = MessKit("trash_bag_slump")
    _bag(k, "bag", (0.62, 0.5, 0.4), (0, 0, 0), 11, settle=0.9)
    k.COL((0.52, 0.42, 0.28), (0, 0, 0.14))
    k.finish(subdiv=1.0, ao_dist=0.3)


def trash_bag_white():
    k = MessKit("trash_bag_white")
    _bag(k, "bag", (0.34, 0.3, 0.44), (0, 0, 0), 23, settle=0.6, white=True)
    k.COL((0.28, 0.24, 0.3), (0, 0, 0.15))
    k.finish(subdiv=1.0, ao_dist=0.25)


def trash_bin_full():
    k = MessKit("trash_bin_full")
    kitchen.bin_body(k)
    m = k.mark()                                                # the lid forced up, standing on its back hinge
    k.CYL("lid", 0.145, 0.03, (0, 0, 0.465), k.CHROME, v=14)
    k.PLACE(m, rot=(-78, 0, 0), pivot=(0, 0.145, 0.465))
    k.parts.append(F.lathe("rim_fold", [(0.13, 0.4), (0.152, 0.43), (0.158, 0.455), (0.15, 0.47), (0.13, 0.465)], k.BAG_W, segs=20))
    L.jitter(k.parts[-1], 0.006, 5)
    k.BLOB("bulge", (0.3, 0.29, 0.2), (0, 0, 0.53), k.BAG_W, seed=31, lumps=0.2, folds=0.2, fold_freq=6.0, settle=0.3)
    k.CRUMPLE("paper0", (0.05, -0.04, 0.64), 0.035, seed=1)
    k.CRUMPLE("paper1", (-0.08, 0.05, 0.62), 0.03, k.PAPER_Y, seed=2)
    k.CAN_AT("can", (-0.02, -0.07, 0.61), "can_cola", rot=(90, 0, 30))
    k.CRUMPLE("floor0", (0.2, -0.12, 0.03), 0.03, seed=3)       # what fell off
    k.CRUMPLE("floor1", (-0.18, -0.2, 0.025), 0.025, seed=4)
    k.COL_CYL(0.15, 0.62, (0, 0, 0.31))
    k.finish(subdiv=1.0, ao_dist=0.2)


def _pizza(k, name, loc, yaw, seed, open_deg=0.0):
    """One box (closed, or its lid open_deg back), built on the floor then placed at loc turned by yaw."""
    m = k.mark()
    k.B(name + "_tray", (W_BOX, W_BOX, 0.012 if open_deg else H_BOX), (0, 0, 0.006 if open_deg else H_BOX / 2), k.PBOX, 0.002)
    if open_deg:
        for s in (-1, 1):
            k.B(f"{name}_wall_x{s}", (0.006, W_BOX, H_BOX), (s * (W_BOX / 2 - 0.003), 0, H_BOX / 2), k.PBOX)
            k.B(f"{name}_wall_y{s}", (W_BOX, 0.006, H_BOX), (0, s * (W_BOX / 2 - 0.003), H_BOX / 2), k.PBOX)
        k.PRINT_QUAD(name + "_inside", (0, 0, 0.0125), W_BOX - 0.014, W_BOX - 0.014, "pizza_in")
        for i, (x, y, a) in enumerate(((-0.08, -0.06, 20), (0.06, 0.08, -60), (0.09, -0.08, 110))):
            k.BLOB(f"{name}_crust{i}", (0.13, 0.035, 0.022), (x, y, 0.024), k.FOOD, seed=seed + i, lumps=0.2, subdiv=3,
                   rot=(0, 0, a))
        lm = k.mark()
        k.B(name + "_lid", (W_BOX, W_BOX, 0.006), (0, 0, H_BOX), k.PBOX, 0.002)
        k.PRINT_QUAD(name + "_print", (0, 0, H_BOX + 0.0035), W_BOX - 0.02, W_BOX - 0.02, "pizza_lid", up=(0, -1, 0))
        k.PRINT_QUAD(name + "_under", (0, 0, H_BOX - 0.0035), W_BOX - 0.02, W_BOX - 0.02, "stain_card", facing="-z")
        k.PLACE(lm, rot=(-open_deg, 0, 0), pivot=(0, W_BOX / 2, H_BOX))
    else:
        k.PRINT_QUAD(name + "_print", (0, 0, H_BOX + 0.0006), W_BOX - 0.02, W_BOX - 0.02, "pizza_lid", up=(0, -1, 0))
    k.PLACE(m, loc, (0, 0, yaw))


def pizza_box():
    k = MessKit("pizza_box")
    _pizza(k, "box", (0, 0, 0), 0, 1)
    k.finish(subdiv=1.0, ao_dist=0.15)


def pizza_box_open():
    k = MessKit("pizza_box_open")
    _pizza(k, "box", (0, 0, 0), 0, 5, open_deg=108)
    k.finish(subdiv=1.0, ao_dist=0.15)


def pizza_stack():
    k = MessKit("pizza_stack")
    for i, (dx, dy, yaw) in enumerate(((0, 0, 0), (0.02, -0.015, 7), (-0.015, 0.01, -5), (0.03, 0.02, 14))):
        _pizza(k, f"box{i}", (dx, dy, i * H_BOX), yaw, 10 + i)
    k.COL((W_BOX, W_BOX, 4 * H_BOX), (0, 0, 2 * H_BOX))
    k.finish(subdiv=1.0, ao_dist=0.2)


def takeout():
    k = MessKit("takeout")
    m = k.mark()                                                 # noodle carton, flaps open, wire handle
    k.FRUSTUM("carton", 0.048, 0.064, 0.1, (0, 0, 0.05), k.PAPER, axis="z", v=4)
    k.parts[-1].rotation_euler = (0, 0, math.radians(45))
    k.PRINT_QUAD("carton_print", (0, -0.042, 0.05), 0.075, 0.09, "carton", facing=(0, -1, 0.16), up=(0, 0, 1))
    for i, (x, y, rx, ry) in enumerate(((0, -0.056, -35, 0), (0, 0.056, 35, 0), (-0.056, 0, 0, 35), (0.056, 0, 0, -35))):
        k.B(f"flap{i}", (0.09 if x == 0 else 0.004, 0.004 if x == 0 else 0.09, 0.05), (x, y, 0.12), k.PAPER, rot=(rx, ry, 0))
    k.PIPE("handle", [(-0.045, 0, 0.1), (-0.03, 0, 0.16), (0.03, 0, 0.16), (0.045, 0, 0.1)], 0.0015, k.CHROME, verts=4)
    k.PLACE(m, (-0.1, 0.05, 0), (0, 0, 20))
    m = k.mark()                                                 # foam clamshell, lid flopped back, food dried in it
    k.B("shell", (0.2, 0.18, 0.035), (0, 0, 0.0175), k.FOAM, 0.01)
    k.BLOB("rice", (0.12, 0.1, 0.03), (0.02, 0.01, 0.04), k.RICE, seed=4, lumps=0.25, subdiv=3)
    k.BLOB("sauce", (0.08, 0.06, 0.012), (-0.05, -0.03, 0.037), k.FOOD, seed=5, lumps=0.3, subdiv=3)
    lm = k.mark()
    k.B("shell_lid", (0.2, 0.18, 0.03), (0, 0, 0.05), k.FOAM, 0.01)
    k.PLACE(lm, rot=(-150, 0, 0), pivot=(0, 0.09, 0.035))
    k.B("fork", (0.012, 0.13, 0.003), (0.07, -0.04, 0.04), k.CAP, rot=(0, 0, 25))
    k.PLACE(m, (0.09, -0.06, 0), (0, 0, -15))
    k.finish(subdiv=1.0, ao_dist=0.12)


def cans_litter():
    k = MessKit("cans_litter")
    for i, (x, y, cell, rot, crush) in enumerate(((0, 0, "can_cola", (0, 0, 20), 0), (0.09, 0.04, "can_energy", (0, 0, -40), 0),
                                                  (-0.12, -0.05, "can_lime", (90, 0, 35), 0.0), (0.05, -0.13, "can_cola", (90, 0, -70), 0.6),
                                                  (-0.02, 0.14, "can_orange", (90, 0, 150), 0.0))):
        z = 0.033 if rot[0] else 0.0                              # tipped cans lie on their sides
        k.CAN_AT(f"can{i}", (x, y, z), cell, rot, crush, seed=i)
    k.finish(subdiv=1.0, ao_dist=0.1)


def bottles_litter():
    k = MessKit("bottles_litter")
    for i, (x, y, rot) in enumerate(((0, 0, (0, 0, 0)), (0.12, -0.05, (90, 0, 25)), (-0.1, 0.07, (90, 0, -110)))):
        m = k.mark()
        k.glass_parts.append(F.lathe(f"bottle{i}", BOTTLE, k.BOTTLE, segs=14))
        k.CYL(f"label{i}", 0.0328, 0.05, (0, 0, 0.09), k.PLASTIC if i == 1 else k.TIE, v=14)
        k.CYL(f"cap{i}", 0.014, 0.016, (0, 0, 0.222), k.CAP, v=12)
        k.PLACE(m, (x, y, 0.032 if rot[0] else 0.0), rot)
    k.finish(subdiv=1.0, ao_dist=0.1)


def paper_litter():
    k = MessKit("paper_litter")
    for i, (x, y, r) in enumerate(((0.0, 0.0, 0.04), (0.18, 0.1, 0.035), (-0.22, 0.06, 0.03), (0.1, -0.2, 0.045), (-0.1, -0.15, 0.03),
                                   (0.28, -0.08, 0.028))):
        k.CRUMPLE(f"ball{i}", (x, y, r * 0.8), r, k.PAPER_Y if i == 2 else k.PAPER_D, seed=i)
    for i, (x, y) in enumerate(((-0.28, -0.1), (0.3, 0.18), (-0.02, 0.2))):
        k.CRUMPLE(f"tissue{i}", (x, y, 0.018), 0.025, k.LINEN, seed=10 + i)
    for i, (x, y, yaw, cell) in enumerate(((0.05, 0.25, 30, "receipt"), (-0.25, 0.2, -20, "receipt"), (0.2, -0.25, 70, "flyer"))):
        w, h = (0.07, 0.2) if cell == "receipt" else (0.21, 0.28)
        k.SHEET(f"sheet{i}", (x, y, 0.002), w, h, cell, yaw, seed=i)
    k.finish(subdiv=1.0, ao_dist=0.08)


def chip_bag():
    k = MessKit("chip_bag")
    k.SOFT("bag", (0.19, 0.25, 0.028), (0, 0, 0.026), k.FOIL, 0.012, puff=0.012, axis="z", step=0.025)
    L.jitter(k.parts[-1], 0.0015, 3)
    for s, crush in ((-1, 0.0), (1, 1.0)):                     # heat-sealed ends; the far one torn open and crushed
        k.BLOB(f"seal{s}", (0.2, 0.025 + 0.02 * crush, 0.012 + 0.02 * crush), (0, s * 0.135, 0.024), k.FOIL, seed=6 + s,
               lumps=0.15 + 0.2 * crush, subdiv=2 + int(crush))
    puff = lambda x, y: 0.04 + 0.012 * max(0.0, 1 - (x / 0.095) ** 2) * max(0.0, 1 - (y / 0.125) ** 2) + 0.002  # noqa: E731
    k.PRINT_GRID("print", 0.15, 0.19, "chips", puff)
    k.finish(subdiv=1.0, ao_dist=0.06)


def mail_pile():
    k = MessKit("mail_pile")
    rng = [0.13, 0.71, 0.37, 0.92, 0.55, 0.21, 0.83, 0.44, 0.66, 0.08, 0.29, 0.97, 0.5, 0.77, 0.35, 0.6]
    for i in range(16):
        u, v = rng[i], rng[(i * 7 + 3) % 16]
        x, y = (u - 0.5) * 0.5, (v - 0.35) * 0.5 - i * 0.012        # fanned out from under the door (+Y side)
        cell = ("notice" if i in (4, 11) else "flyer" if i % 5 == 2 else "envelope")
        w, h = (0.21, 0.28) if cell == "flyer" else (0.23, 0.12)
        z = 0.0015 + 0.0035 * (i % 5 + (1 if abs(x) < 0.12 else 0))
        m = k.mark()
        k.B(f"env{i}", (w, h, 0.003), (0, 0, 0), k.PAPER_Y if cell == "notice" else k.PAPER)
        k.PRINT_QUAD(f"env{i}_print", (0, 0, 0.0016), w - 0.004, h - 0.004, cell, up=(0, 1, 0))
        k.PLACE(m, (x, y, z), (0, 0, (u * 97 + v * 53) % 70 - 35))
    k.finish(subdiv=1.0, ao_dist=0.05)


def parcel_boxes():
    k = MessKit("parcel_boxes")
    for i, (size, loc, yaw) in enumerate((((0.46, 0.34, 0.3), (0, 0, 0), 0), ((0.34, 0.26, 0.22), (0.03, -0.02, 0.3), 12),
                                          ((0.4, 0.3, 0.26), (0.5, 0.05, 0), -8))):
        m = k.mark()
        sx, sy, sz = size
        k.B(f"box{i}", size, (0, 0, sz / 2), k.SHIP, 0.004)
        k.PRINT_QUAD(f"label{i}", (sx * 0.15, 0, sz + 0.0008), 0.12, 0.12, "ship_label", up=(0, 1, 0))
        if i == 2:                                              # this one was opened, flaps left up, the paper still in it
            for s in (-1, 1):
                k.B(f"flap{i}{s}", (sx, 0.004, sy / 2), (0, s * (sy / 2 + sy / 4 * 0.7), sz + sy / 4 * 0.7), k.SHIP, rot=(s * 45, 0, 0))
            k.CRUMPLE(f"fill{i}", (0, 0, sz - 0.02), 0.09, k.PAPER, seed=8)
        else:
            k.B(f"tape{i}", (0.05, sy + 0.002, 0.002), (-sx * 0.25, 0, sz + 0.001), k.TAPE)
        k.PLACE(m, loc, (0, 0, yaw))
    k.COL((0.95, 0.4, 0.5), (0.24, 0, 0.25))
    k.finish(subdiv=1.0, ao_dist=0.25)


PROPS = {f.__name__: f for f in (trash_bag, trash_bag_slump, trash_bag_white, trash_bin_full, pizza_box, pizza_box_open, pizza_stack,
                                 takeout, cans_litter, bottles_litter, paper_litter, chip_bag, mail_pile, parcel_boxes)}
