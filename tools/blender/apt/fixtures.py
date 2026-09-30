"""Apartment kit: architectural fixtures. Openings follow apt_dims (DOOR_*, FRONT_*, WIN_*); the shell (apt_shell.py) cuts the hole
and places the piece with y = 0 on the wall face the piece fronts (the room side), the wall running back to +y.
door_interior        0.9 x 2.1 opening in a partition: linings, casings both faces, leaf on pivot_leaf (AptDoor swings it)
door_front           entry door, never opens: knob, two deadbolts, chain, two barrel bolts, taped peephole, towel along the sill,
                     pencil tallies on the wall by the latch; marker_use_locks
window_blinds        1.2 x 1.4 double-hung window, sill at 0.9, venetian blinds tilted (sun comes through in stripes), taped latch;
                     opt_sill (stool + apron: drop it with __no_sill where the window sits over a worktop)
window_blinds_raised same, blinds pulled up to the meeting rail; marker_use_window
radiator             cast-iron column radiator (floor, back 5 cm off the wall)
Hanging pieces (origin = centre of the back face on the wall, marker z = hang height): light_switch, outlet (safety caps in
both sockets). Ceiling pieces (origin on the ceiling, hanging down): ceiling_pendant (marker_light_bulb), smoke_detector.
"""
import apt_dims as D
import ps1_lib as L
from apt_lib import AptKit


def _casing(k, w, h, y, z0=0.0, sides=True):
    """Architrave round an opening w wide, h tall (from z0) on the face at y (boards 7 cm, 1.6 cm proud)."""
    if sides:
        for s in (-1, 1):
            k.B(f"casing{s}{y}", (0.07, 0.016, h + 0.07), (s * (w / 2 + 0.035), y, z0 + (h + 0.07) / 2), k.WHITE, 0.003)
    k.B(f"casing_head{y}", (w + 0.14, 0.018, 0.07), (0, y, z0 + h + 0.035), k.WHITE, 0.003)


def _linings(k, w, h, t, z0=0.0):
    for s in (-1, 1):
        k.B(f"lining{s}", (0.02, t, h), (s * (w / 2 - 0.01), t / 2, z0 + h / 2), k.WHITE)
    k.B("lining_head", (w, t, 0.02), (0, t / 2, z0 + h - 0.01), k.WHITE)


def _panels(k, x, y, w, zs, mat, into, ph=0.78):
    for i, z in enumerate(zs):
        k.B(f"panel{y}{i}", (w, 0.006, ph), (x, y, z), mat, 0.002, into=into)


def door_interior():
    k = AptKit("door_interior")
    w, h, t = D.DOOR_W, D.DOOR_H, D.WALL_T
    _linings(k, w, h, t)
    _casing(k, w, h, -0.008)
    _casing(k, w, h, t + 0.008)
    hinge = (-w / 2 + 0.02, 0.012, 0.0)
    leaf = k.PIVOT("pivot_leaf", hinge)
    lw, lh = w - 0.04, h - 0.02
    k.B("leaf", (lw, D.LEAF_T, lh), (0, hinge[1] + D.LEAF_T / 2, 0.01 + lh / 2), k.WHITE, 0.004, into=leaf)
    for y in (hinge[1] - 0.003, hinge[1] + D.LEAF_T + 0.003):
        _panels(k, 0, y, lw - 0.24, (0.55, 1.5), k.WHITE, leaf)
        side = -1 if y < hinge[1] + 0.01 else 1
        k.CYL(f"rose{y}", 0.028, 0.012, (lw / 2 - 0.07, y + side * 0.006, 0.95), k.BRASS, "y", 10, into=leaf)
        k.CYL(f"knob{y}", 0.026, 0.05, (lw / 2 - 0.07, y + side * 0.03, 0.95), k.BRASS, "y", 10, into=leaf)
    for z in (0.25, 1.05, 1.85):
        k.B(f"hinge{z}", (0.012, 0.03, 0.09), (hinge[0] - 0.012, hinge[1] + 0.015, z), k.BRASS)
    k.finish(subdiv=0.4, ao_dist=0.5)


def door_front():
    k = AptKit("door_front")
    w, h, t = D.FRONT_W, D.FRONT_H, D.EXT_T
    _linings(k, w, h, t)
    _casing(k, w, h, -0.008)
    navy = L.material("apt_door_navy", (0.055, 0.085, 0.15))
    y0 = 0.04                                                                        # leaf front face (set into the reveal)
    k.B("leaf", (w - 0.03, 0.05, h - 0.02), (0, y0 + 0.025, h / 2), navy, 0.004)
    for x in (-0.22, 0.22):                                                          # raised panels with a moulded edge
        for z in (0.5, 1.55):
            k.SOFT(f"panel{x}{z}", (0.34, 0.012, 0.72), (x, y0 - 0.004, z), navy, 0.005, step=0.2)
            k.SOFT(f"field{x}{z}", (0.26, 0.012, 0.64), (x, y0 - 0.009, z), navy, 0.004, step=0.2)
    lx = w / 2 - 0.1                                                                  # lock stile
    k.CYL("knob_rose", 0.03, 0.012, (lx, y0 - 0.006, 0.97), k.BRASS, "y", 10)
    k.CYL("knob", 0.028, 0.055, (lx, y0 - 0.034, 0.97), k.BRASS, "y", 10, into=k.PIVOT("turn_knob", (lx, y0, 0.97)))
    for i, (z, mat) in enumerate(((1.2, k.BRASS), (1.42, k.CHROME))):                  # the second deadbolt came later
        k.CYL(f"bolt_rose{z}", 0.033, 0.014, (lx, y0 - 0.007, z), mat, "y", 12)
        k.B(f"thumb{z}", (0.014, 0.03, 0.045), (lx, y0 - 0.025, z), mat, 0.004, into=k.PIVOT(f"turn_bolt{i}", (lx, y0, z)))
    # chain: track on the leaf, frame plate on the lining side, chain engaged with a short sag
    k.B("chain_track", (0.12, 0.012, 0.024), (lx - 0.12, y0 - 0.006, 1.62), k.CHROME)
    k.B("chain_plate", (0.02, 0.05, 0.07), (w / 2 + 0.03, -0.034, 1.62), k.CHROME)
    k.PIPE("chain", [(w / 2 + 0.02, -0.05, 1.6), (lx, -0.03, 1.575), (lx - 0.07, y0 - 0.014, 1.62)], 0.0045, k.CHROME, verts=4)
    for z, rod in ((1.95, (0.08, 0.0)), (0.12, (0.0, -0.1))):                         # barrel bolts, top across, bottom down
        k.B(f"bolt_plate{z}", (0.035, 0.012, 0.12), (lx - 0.02, y0 - 0.006, z), k.CHROME)
        if rod[0]:
            k.TUBE(f"bolt_rod{z}", (lx - 0.03, y0 - 0.02, z), (w / 2 + 0.01, y0 - 0.02, z), 0.007, k.CHROME)
            k.B(f"keeper{z}", (0.03, 0.03, 0.04), (w / 2 + 0.01, y0 - 0.02, z), k.CHROME)
        else:
            k.TUBE(f"bolt_rod{z}", (lx - 0.02, y0 - 0.02, z), (lx - 0.02, y0 - 0.02, 0.0), 0.007, k.CHROME)
    k.CYL("peephole", 0.012, 0.02, (0, y0 - 0.01, 1.55), k.CHROME, "y", 8)
    k.DECAL("peephole_tape", (0, y0 - 0.021, 1.55), 0.07, 0.02, k.D_TAPE)             # covered: nothing to see out there
    k.DECAL("tally", (w / 2 + 0.2, -0.003, 1.3), 0.16, 0.32, k.D_TALLY)
    k.CYL("draft_towel", 0.045, w - 0.06, (0, -0.05, 0.045), k.TOWEL, "x", 8)
    k.COL((w, 0.1, h), (0, y0 + 0.03, h / 2))
    k.COL((w - 0.06, 0.1, 0.09), (0, -0.05, 0.045))
    k.USE("locks", (lx - 0.05, -0.12, 1.32))
    k.USE("leave", (-0.15, -0.1, 1.05))                                              # the rest of the leaf: LEAVE (never)
    k.finish(subdiv=0.4, ao_dist=0.45)


def _window(name, raised, shut=False, check=None):
    k = AptKit(name)
    w, h, s, t = D.WIN_W, D.WIN_H, D.WIN_SILL, D.EXT_T
    top = s + h
    _linings(k, w, h, t, s)
    _casing(k, w, h, -0.008, s)
    sill = k.OPT("sill")                                                               # __no_sill: over a worktop
    k.B("stool", (w + 0.16, 0.16, 0.03), (0, 0.01, s - 0.015), k.WHITE, 0.004, into=sill)
    k.B("apron", (w + 0.06, 0.016, 0.08), (0, -0.008, s - 0.07), k.WHITE, 0.003, into=sill)
    sy = 0.2                                                                           # sash plane
    for sx in (-1, 1):
        k.B(f"stile{sx}", (0.05, 0.05, h - 0.04), (sx * (w / 2 - 0.045), sy, s + h / 2), k.WHITE)
    for z in (s + 0.045, top - 0.045):
        k.B(f"rail{z}", (w - 0.04, 0.05, 0.05), (0, sy, z), k.WHITE)
    k.B("meeting_rail", (w - 0.04, 0.07, 0.05), (0, sy, s + h / 2), k.WHITE)
    for z in (s + h * 0.26, s + h * 0.74):
        k.GLASS_B(f"pane{z}", (w - 0.14, 0.006, h / 2 - 0.1), (0, sy, z))
    k.B("latch", (0.07, 0.02, 0.018), (0, sy - 0.045, s + h / 2 + 0.03), k.BRASS,
        into=k.PIVOT("turn_latch", (0, sy - 0.035, s + h / 2 + 0.03)))
    k.DECAL("latch_tape", (0, sy - 0.057, s + h / 2 + 0.03), 0.12, 0.03, k.D_TAPE)
    by, bw = 0.055, w - 0.06                                                           # blinds, inside mount
    k.B("headrail", (w - 0.04, 0.05, 0.05), (0, by, top - 0.045), k.WHITE, 0.004)
    bottom = s + h * 0.5 + 0.06 if raised else s + 0.03
    n = int((top - 0.09 - bottom) / (0.022 if raised else 0.045))
    for i in range(n):
        z = top - 0.09 - (i + 0.5) * (top - 0.09 - bottom) / n
        k.B(f"slat{i}", (bw, 0.04, 0.0025), (0, by, z), k.WHITE, rot=(10 if raised else 48 if shut else 32, 0, 0))
    k.B("bottom_rail", (bw, 0.045, 0.015), (0, by, bottom - 0.01), k.WHITE, 0.003)
    for x in (-bw / 2 + 0.18, bw / 2 - 0.18):
        for dy in (-0.021, 0.021):
            k.B(f"ladder{x}{dy}", (0.004, 0.002, top - 0.07 - bottom), (x, by + dy, (top - 0.07 + bottom) / 2), k.PAPER)
    k.TUBE("wand", (bw / 2 - 0.06, by - 0.03, top - 0.07), (bw / 2 - 0.06, by - 0.03, top - 0.8), 0.005, k.GLASS)
    k.COL((w, 0.06, h), (0, sy, s + h / 2))
    if raised if check is None else check:
        k.USE("window", (0, -0.05, s + 0.12))
    k.finish(subdiv=0.4, ao_dist=0.35)


def window_blinds():
    _window("window_blinds", False)


def window_blinds_raised():
    _window("window_blinds_raised", True)


def window_blinds_shut():
    """Blinds down and turned shut (the squalor swaps window_blinds for it): light only through the slat gaps."""
    _window("window_blinds_shut", False, shut=True)


def window_blinds_shut_check():
    """The same, for the window that is checked (the squalor swaps window_blinds_raised for it): keeps the CHECK use."""
    _window("window_blinds_shut_check", False, shut=True, check=True)


def radiator():
    k = AptKit("radiator")
    cream = k.WHITE
    for i in range(11):
        x = -0.375 + i * 0.075
        k.B(f"col{i}", (0.055, 0.14, 0.56), (x, -0.12, 0.36), cream, 0.012)
    for z in (0.12, 0.6):
        k.CYL(f"header{z}", 0.025, 0.82, (0, -0.12, z), cream, "x", 8)
    for x in (-0.4, 0.4):
        k.B(f"foot{x}", (0.05, 0.16, 0.08), (x, -0.12, 0.04), cream, 0.01)
    k.CYL("valve", 0.02, 0.08, (0.46, -0.12, 0.14), k.BRASS, "x", 8)
    k.CYL("wheel", 0.035, 0.015, (0.5, -0.12, 0.14), k.BLACK, "x", 10)
    k.TUBE("feed", (0.5, -0.12, 0.14), (0.5, -0.12, 0.0), 0.012, k.CHROME)
    k.COL((0.88, 0.16, 0.64), (0, -0.12, 0.32))
    k.finish(wall=True, subdiv=0.15, ao_dist=0.3)


def light_switch():
    k = AptKit("light_switch")
    k.B("plate", (0.075, 0.008, 0.115), (0, -0.004, 0), k.PLASTIC, 0.002)
    k.B("toggle", (0.014, 0.014, 0.028), (0, -0.012, 0.004), k.CAP, 0.003, rot=(-12, 0, 0))
    k.finish(wall=True, subdiv=0.05, ao_dist=0.04, ground=False)


def outlet():
    k = AptKit("outlet")
    k.B("plate", (0.075, 0.008, 0.115), (0, -0.004, 0), k.PLASTIC, 0.002)
    for z in (-0.025, 0.025):
        k.B(f"cap{z}", (0.034, 0.008, 0.03), (0, -0.012, z), k.CAP, 0.004)             # child-safety plug caps
        k.B(f"tab{z}", (0.01, 0.006, 0.008), (0, -0.018, z), k.CAP)
    k.finish(wall=True, subdiv=0.05, ao_dist=0.04, ground=False)


def ceiling_pendant():
    k = AptKit("ceiling_pendant")
    k.CYL("canopy", 0.06, 0.03, (0, 0, -0.015), k.WHITE, v=12)
    k.TUBE("cord", (0, 0, -0.03), (0, 0, -0.5), 0.004, k.CORD)
    k.FRUSTUM("shade", 0.19, 0.05, 0.2, (0, 0, -0.6), k.SHADE, axis="z", v=12, into=k.noshadow)
    k.CYL("bulb", 0.035, 0.05, (0, 0, -0.66), k.BULB, v=8)
    k.LIGHT("marker_light_bulb", (0, 0, -0.74))
    k.finish(subdiv=0.2, ao_dist=0.2, ground=False)


def smoke_detector():
    k = AptKit("smoke_detector")
    k.CYL("disc", 0.07, 0.035, (0, 0, -0.0175), k.PLASTIC, v=12)
    k.CYL("led", 0.005, 0.004, (0.035, 0, -0.037), k.BLINK, v=6)
    k.finish(subdiv=0.1, ao_dist=0.05, ground=False)


PROPS = {f.__name__: f for f in (door_interior, door_front, window_blinds, window_blinds_raised, window_blinds_shut,
                                 window_blinds_shut_check, radiator, light_switch, outlet,
                                 ceiling_pendant, smoke_detector)}
