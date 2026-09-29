"""Missile Silo 00 stair tower. Called by missile_silo.py as build(c). A steel switchback tower stands against the lining at
the front of the bore, built from the walkway kit (tools/blender/kit/walkways.py, sizes in kit_dims.py) on its 2 m grid:
x X0 -/+ HX (column lines), y YB (wall side) .. YF (void side); two 2 m lanes side by side (A by the wall, B on the void
side), 2 m switchback landings at each end, 8 m flights (4 m drop) between them. Odd flights run down lane A leftward
(-X), even flights lane B rightward. This file lays out marker_kit_<piece>__<n>[__no_<rail>] empties (scripts/bunker/
bunker_kit.gd spawns the live pieces, MissileSilo darkens them with AbyssFog) plus what is unique to the silo: the frame
(columns, beams, ties to the lining, hoist), lamps, invisible cage walls, the gantry deck to launch control and the floods.
Walk: apron -> bridge (catwalk_2m) -> top landing -> flights 1-9 -> level 09 (GZ, -36 m) -> deck -> launch control.
Flight 10 below is broken and gated; the tower keeps going down into the dark with a few loose flights.
Kit frames: flight origin = its foot, climbing along local +Y; landing / catwalk / gate: front = local -Y (yaw 0).
"""
import math
import os
import sys

from mathutils import Vector

import ps1_lib as L

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "kit"))
from kit_dims import FLIGHT_RUN, LANDING_W, WALK_W  # noqa: E402

X0, HX = -5.0, 6.2                        # tower centre x, half length to the column lines
XR, XL = X0 + FLIGHT_RUN / 2, X0 - FLIGHT_RUN / 2   # flight ends = inner edges of the right / left landings
YB, YF = -54.2, -49.8                     # wall-side / void-side column lines
LANE_A, LANE_B = -53.0, -51.0             # lane centres (A by the wall)
YM = (LANE_A + LANE_B) / 2                # landing centre line (the lanes meet here)
WALK = 9                                  # flights down to level 09
BROKEN = (10, 14)
MISSING_FLIGHTS, MISSING_LANDINGS = (12, 15), (11, 13)
DEAD_LAMPS = (4, 7)
DECK = (47.0, 55.8, -117.0, -103.0)       # r0, r1, a0, a1


def build(c):
    frame(c)
    for n in range(1, 17):
        if n not in MISSING_FLIGHTS:
            flight(c, n)
    for n in range(0, 17):
        if n not in MISSING_LANDINGS:
            landing(c, n)
    cage(c)
    bridge(c)
    deck(c)
    gate(c)
    floods(c)
    stair_head(c)


def flight(c, n):
    """Kit flight n: from its top at the level above down to the next level. Its foot sits on the landing it descends to."""
    zt = c.TOP - (n - 1) * c.LEVEL
    odd = n % 2 == 1
    foot_x = XL if odd else XR
    piece = "stair_flight_broken" if n in BROKEN else "stair_flight"
    c.empty(f"marker_kit_{piece}__{n}", (foot_x, LANE_A if odd else LANE_B, zt - c.LEVEL), -90.0 if odd else 90.0)


def landing(c, n):
    """Kit landing n (even: right end, odd: left end); its back edge meets the flights, front = the tower end."""
    z = c.TOP - n * c.LEVEL
    right = n % 2 == 0
    xc = XR + WALK_W / 2 if right else XL - WALK_W / 2
    flags = ""
    if n == 0:
        flags = "__no_rail_left"                 # the bridge lands on the wall side
    elif n == WALK:
        flags = "__no_rail_front"                # level 09 opens onto the gantry deck
    c.empty(f"marker_kit_stair_landing__{n}{flags}", (xc, YM, z), 90.0 if right else -90.0)
    col_x = X0 + HX if right else X0 - HX         # lamp hangs on the void-side end column
    lx = col_x - (0.35 if right else -0.35)
    if n in DEAD_LAMPS:
        c.B(f"lamp{n}_dead", (0.3, 0.22, 0.2), (lx, YF, z + 2.3), c.M_MET_D, into=c.bore)
    elif n <= WALK:
        c.B(f"lamp{n}", (0.3, 0.22, 0.2), (lx, YF, z + 2.3), c.M_LAMP, into=c.bore)
        c.B(f"lamp{n}_cage", (0.4, 0.3, 0.06), (lx, YF, z + 2.45), c.M_MET_D, into=c.bore)
        L.empty(f"marker_light_tower_{n}", (lx, YF - 0.5, z + 2.1))


def frame(c):
    top = c.TOP + 7.0
    ends = (X0 - HX, X0 + HX)
    for x in (X0 - HX, X0, X0 + HX):
        for y in (YB, YF):
            c.B(f"col{x}{y}", (0.4, 0.4, top - c.FLOOR), (x, y, (top + c.FLOOR) / 2), c.M_MET_D, into=c.bore)
    z = c.TOP
    while z > c.FLOOR:
        for y in (YB, YF):
            c.B(f"beam{z}{y}", (2 * HX, 0.3, 0.3), (X0, y, z - 0.3), c.M_RUST, into=c.bore)
        for x in ends:                                                      # end cross beams only: flights pass mid-tower
            c.B(f"xbeam{z}{x}", (0.3, YF - YB, 0.3), (x, (YB + YF) / 2, z - 0.3), c.M_RUST, into=c.bore)
        if z > -120:
            for xa, xb in ((X0 - HX, X0), (X0, X0 + HX)):
                zz = z - c.LEVEL
                c.TUBE(f"brace{z}{xa}", (xa, YF + 0.05, z - 0.3), (xb, YF + 0.05, zz - 0.3), 0.07, c.M_MET_D, 4, into=c.bore)
                c.TUBE(f"brace2{z}{xa}", (xb, YF + 0.05, z - 0.3), (xa, YF + 0.05, zz - 0.3), 0.07, c.M_MET_D, 4, into=c.bore)
        for x in ends:                                                      # ties back to the lining
            wy = -math.sqrt(c.R * c.R - x * x)
            c.B(f"tie{z}{x}", (0.25, YB - wy + 0.4, 0.25), (x, (YB + wy) / 2, z - 0.8), c.M_RUST_D, into=c.bore)
        z -= c.LEVEL if z > -120 else 2 * c.LEVEL
    for y in (YB, YF):                                                      # head frame + hoist over the void
        c.B(f"head_beam{y}", (2 * HX + 0.4, 0.45, 0.5), (X0, y, top), c.M_MET_D, into=c.bore)
    c.B("hoist_beam", (0.5, 9.0, 0.6), (X0, YF + 3.0, top + 0.5), c.M_RUST, into=c.bore)
    c.CYL("hoist_pulley", 0.6, 0.3, (X0, YF + 7.0, top), c.M_MET, "x", 10, into=c.bore)
    c.TUBE("hoist_chain", (X0, YF + 7.0, top - 0.6), (X0, YF + 7.0, top - 18.0), 0.05, c.M_CABLE, 4, into=c.bore)
    c.B("hoist_hook", (0.3, 0.3, 0.7), (X0, YF + 7.0, top - 18.3), c.M_RUST, into=c.bore)


def cage(c):
    """Invisible walls round the walkable part of the tower (openings: bridge at the top, deck at level 09). The kit rails
    collide too; the cage keeps a jumping player off the void."""
    lo, hi = c.GZ - 1.0, c.TOP + c.LIP
    w = 2 * HX
    c.COL("cage_front", (w, 0.2, hi - lo), (X0, YF + 0.1, (hi + lo) / 2))
    c.COL("cage_back", (w, 0.2, c.TOP - 0.3 - lo), (X0, YB - 0.1, (c.TOP - 0.3 + lo) / 2))
    c.COL("cage_back_top", (XR - (X0 - HX), 0.2, hi - c.TOP + 0.3), ((XR + X0 - HX) / 2, YB - 0.1, (hi + c.TOP - 0.3) / 2))
    c.COL("cage_right", (0.2, YF - YB, hi - lo), (X0 + HX + 0.1, (YB + YF) / 2, (hi + lo) / 2))
    c.COL("cage_left", (0.2, YF - YB, hi - c.GZ - 2.3), (X0 - HX - 0.1, (YB + YF) / 2, (hi + c.GZ + 2.3) / 2))
    c.COL("cage_divider", (XR - XL, 0.1, hi - lo), (X0, YM, (hi + lo) / 2))


def bridge(c):
    """catwalk_2m from the apron's inner edge (r = R at x 0) to the top landing's wall side: exactly one 2 m module."""
    c.empty("marker_kit_catwalk_2m__bridge", (0.0, -c.R + WALK_W / 2, c.TOP), 0.0)
    c.DECAL("bridge_hazard", (0.0, -c.R - 0.9, c.TOP + 0.02), 2.4, 0.45, "+z", c.D_HAZARD)


def deck(c):
    r0, r1, a0, a1 = DECK
    z = c.GZ
    c.ring("deck", r0, r1, [z - 0.35, z], a0, a1, 10, c.M_PLATE, into=c.bore)
    c.ring("deck_c", r0, r1, [z - 0.35, z], a0, a1, 10, c.M_PLATE, into=c.cols)
    c.ring("deck_rail_c", r0, r0 + 0.3, [z, z + 1.2], a0, a1, 10, c.M_PLATE, into=c.cols)
    for k in range(8):                                                      # brackets under the deck, into the lining
        a = a0 + (a1 - a0) * (k + 0.5) / 8
        c.TUBE(f"deck_strut{k}", c.polar(r0 + 0.3, a, z - 0.35), c.polar(c.R - 0.1, a, z - 5.0), 0.12, c.M_RUST, 5, into=c.bore)
        c.TUBE(f"deck_post{k}", c.polar(r0 + 0.1, a, z), c.polar(r0 + 0.1, a, z + 1.05), 0.03, c.M_MET_D, 4, into=c.bore)
    for k in range(10):
        p, q = c.polar(r0 + 0.1, a0 + (a1 - a0) * k / 10, z + 1.05), c.polar(r0 + 0.1, a0 + (a1 - a0) * (k + 1) / 10, z + 1.05)
        c.TUBE(f"deck_rail{k}", p, q, 0.035, c.M_RUST, 5, into=c.bore)
    e0, e1 = c.polar(r0 + 0.1, a0, z + 1.05), c.polar(r1, a0, z + 1.05)
    c.TUBE("deck_end_rail", e0, e1, 0.035, c.M_RUST, 5, into=c.bore)
    c.ACOL("deck_end_c", (r0 + r1) / 2, a0, (0.2, r1 - r0, 1.2), z + 0.6)
    p0, p1 = Vector(c.polar(r0 + 0.1, a1, z + 1.05)), Vector((X0 - HX, YF, z + 1.05))
    c.TUBE("deck_tower_rail", p0, p1, 0.035, c.M_RUST, 5, into=c.bore)
    mid, dd = (p0 + p1) / 2, p1 - p0
    c.COL("deck_tower_c", (0.2, dd.length, 1.2), (mid.x, mid.y, z + 0.6), (0, 0, math.degrees(math.atan2(dd.y, dd.x)) - 90))
    # filler plate: the deck's radial end edge to the level 09 landing's open end (straight edge x = XL - WALK_W)
    e_in, e_out = Vector(c.polar(r0, a1)), Vector(c.polar(r1, a1))
    xd = lambda y: e_in.x + (e_out.x - e_in.x) * (y - e_in.y) / (e_out.y - e_in.y)  # noqa: E731
    xe, y_wall = XL - WALK_W, YM - LANDING_W / 2
    pts = [(xe, y_wall), (xd(y_wall), y_wall), (xd(YF), YF), (xe, YF)]
    c.bore.append(L.vprism("deck_filler", pts, z - 0.2, z, c.M_PLATE))
    c.cols.append(L.vprism("deck_filler_c", pts, z - 0.3, z, None))
    L.empty("marker_light_deck", c.polar(c.R - 1.0, -112.0, z + 3.0))
    c.B("deck_lamp", (0.3, 0.22, 0.2), c.polar(c.R - 0.2, -112.0, z + 3.3), c.M_LAMP, into=c.bore)


def gate(c):
    """Flight 10 failed: a kit gate closes lane B at level 09, with the silo's own NO DESCENT sign wired to it."""
    gx = XL - 0.05
    c.empty("marker_kit_gate_barred__10", (gx, LANE_B, c.GZ), -90.0)
    c.B("gate_sign", (0.012, 0.5, 0.38), (gx - 0.02, LANE_B - 0.5, c.GZ + 0.75), c.M_MET_D, into=c.bore)
    c.DECAL("gate_warning", (gx - 0.033, LANE_B - 0.5, c.GZ + 0.75), 0.48, 0.36, "-x", c.D_WARN, inside=True)


# Work floods (SiloAmbience makes a SpotLight3D at each marker_spot_<name>, aimed at marker_spot_<name>_target): pools of
# light along the near lining, the only way to see how far the wall goes. (name, position, target)
FLOODS = [("head_l", (X0 - HX - 0.35, YF + 0.35, 5.5), (-42.1, -35.4, -28.0)),
          ("mid_r", (X0 + HX + 0.35, YF + 0.35, -14.0), (33.9, -43.4, -34.0)),
          ("deck", (-24.2, -49.6, -32.5), (-47.7, -25.4, -48.0)),
          ("head_down", (X0 + 0.4, YF + 6.4, 6.6), (X0, YF + 3.0, -70.0)),
          ("lip_fallen", (-29.67, -49.37, 1.9), (-43.25, -27.03, -32.0))]


def floods(c):
    for name, pos, target in FLOODS:
        flood(c, name, pos, target, c.TOP if name.startswith("lip") else None)


def flood(c, name, pos, target, ground=None, into=None, prefix="marker_spot_"):
    """Work flood (lamp head on a yoke) at pos aimed at target; ground = floor height for a tripod (None: hung from the
    frame). SiloAmbience lights it from <prefix><name> / <prefix><name>_target (SiloAmbience.add_spots). into = the list
    for all its parts (default: the head in c.bore, the tripod legs on the apron in c.surf)."""
    p, t = Vector(pos), Vector(target)
    d = (t - p).normalized()
    head = c.bore if into is None else into
    legs = c.surf if into is None else into
    c.TUBE(f"flood_{name}", p - d * 0.25, p + d * 0.3, 0.3, c.M_MET_D, 8, into=head)
    c.TUBE(f"flood_{name}_lens", p + d * 0.3, p + d * 0.34, 0.25, c.M_LAMP, 8, into=head)
    c.TUBE(f"flood_{name}_yoke", p, p - d * 0.2 + Vector((0, 0, -0.6)), 0.05, c.M_RUST, 4, into=head)
    if ground is not None:
        for k in range(3):
            g = Vector(c.polar(0.9, k * 120.0, ground)) + Vector((p.x, p.y, 0))
            c.TUBE(f"flood_{name}_leg{k}", p + Vector((0, 0, -0.55)), g, 0.04, c.M_RUST, 4, into=legs)
    L.empty(f"{prefix}{name}", tuple(p + d * 0.4))
    L.empty(f"{prefix}{name}_target", tuple(t))


# (prop, x, y, yaw) on the apron by the stair head. Kit fronts face local -Y at yaw 0.
KIT = [("floodlight", -4.0, -58.8, 200), ("floodlight", 4.8, -58.9, 160), ("barrier_concrete", -3.2, -62.0, 90),
       ("barrier_concrete", -3.3, -64.1, 92), ("barrier_concrete_broken", 4.4, -62.5, 80), ("crate_large", 6.2, -64.5, 12),
       ("crate_small", 6.2, -64.5, 40), ("drum_amber", -5.4, -61.2, 0), ("drum_amber", -6.1, -62.0, 50)]


def stair_head(c):
    for i, (prop, x, y, yaw) in enumerate(KIT):
        z = c.TOP + (0.6 if i == 6 else 0.0)
        c.empty(f"marker_kit_{prop}__{i}", (x, y, z), yaw)
