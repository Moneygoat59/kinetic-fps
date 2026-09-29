"""Outpost 73 exterior (v5). Called by outpost73_bunker.py as build(c), where `c` is a namespace of its helpers (B, CYL, PIPE,
TUBE, COL, DECAL, LIQ_CYL, POOL, CRYSTALS), materials (M_*, D_*), dimensions (HX, HY) and the `movers` dict.
Story: a well that has pumped amber out of the ground, unattended, for 200 years. The pump jack behind the bunker still
nods; one line feeds the bunker, the other dives into a valve pit and runs underground to the silo.
Every part must touch the building, another part or the ground (z = 0): check with a contact pass after edits.
Variants (outpost_variants.py, c.V) mirror the roof break, ladder / hatch sides, beacon, branch and dish; their extra
pieces (fallen tree, tanks, crystal overgrowth) live in outpost_extras.py."""
import math
import random

from mathutils import Vector

import ps1_ao as AO
import ps1_lib as L
import outpost_extras as XT

# ---- pump jack (all in the plane y = WY). Mirrored in scripts/bunker/bunker_pump.gd: keep the numbers in sync.
WX, WY = 1.9, 5.6                  # wellhead: polished rod x, plane of the jack
PIVOT = (0.3, 3.0)                 # (x, z) walking-beam bearing
CRANK = (-1.25, 0.9)               # (x, z) crankshaft
CRANK_R = 0.35
TAIL = (-1.55, -0.2)               # tail (equalizer) pin relative to the pivot, beam level
HEAD_R = WX - PIVOT[0]             # horsehead arc radius: the bridle hangs straight down over the well
CARRIER_Z = 2.45                   # carrier bar height with the beam level
PX, PY = 3.6, 5.6                  # valve pit on the buried amber main


def build(c):
    base(c)
    roof(c)
    rubble(c)
    ladder(c)
    hatch(c)
    dish_and_beacon(c)
    wellhead(c)
    pump_jack(c)
    silo_main(c)
    deadwood(c)
    decals(c)
    for name in c.V["extras"]:
        if name != "flood":                              # flood is an interior extra (outpost73_bunker.py runs it)
            getattr(XT, name)(c)


def _m(c, x, y):
    """Point mirrored like the variant's roof break (73: unchanged)."""
    sx, sy = c.V["brk"]
    return (x, y) if (sx, sy) == (1, 1) else (sx * x, sy * y)


def base(c):
    HX, HY = c.HX, c.HY
    c.B("plinth_back", (8.3, 0.35, 1.4), (0, HY + 0.175, -0.3), c.M_CON_T, 0.1)
    for sx in (-1, 1):
        c.B(f"plinth_side{sx}", (0.35, 7.3, 1.4), (sx * 3.775, 0, -0.3), c.M_CON_T, 0.1)
        c.B(f"plinth_front{sx}", (2.75, 0.35, 1.4), (sx * 2.575, -HY - 0.175, -0.3), c.M_CON_T, 0.1)
        for sy in (-1, 1):
            c.B(f"corner{sx}{sy}", (1.5, 1.5, 3.6), (sx * 2.97, sy * 2.67, 2.2), c.M_CON, 0.3)
    c.B("win_brow_f", (2.3, 0.2, 0.1), (0, -HY - 0.1, 3.72), c.M_CON_T, 0.02)          # slit windows: glow + brow
    c.B("win_glow_f", (1.9, 0.05, 0.2), (0, -HY + 0.005, 3.42), c.M_AMBER)
    c.B("win_brow_r", (0.2, 0.9, 0.1), (HX + 0.1, -1.25, 3.42), c.M_CON_T, 0.02)
    c.B("win_glow_r", (0.05, 0.7, 0.2), (HX - 0.005, -1.25, 3.12), c.M_AMBER)
    c.B("win_brow_l", (0.2, 0.9, 0.1), (-HX - 0.1, 1.2, 3.42), c.M_CON_T, 0.02)
    c.B("win_glow_l", (0.05, 0.7, 0.2), (-HX + 0.005, 1.2, 3.12), c.M_AMBER)
    c.B("vent_plate", (1.7, 0.1, 1.7), (-0.9, HY + 0.05, 2.5), c.M_MET_D, 0.03)       # rear louvred vent
    for i in range(6):
        c.B(f"vent_slat{i}", (1.4, 0.07, 0.09), (-0.9, HY + 0.13, 1.95 + i * 0.22), c.M_MET, rot=(25, 0, 0))
    # pump controller cabinet on the rear plinth ledge: status lamp blinks with the roof beacon, cable runs to the jack
    c.B("rc_body", (0.9, 0.3, 1.2), (0.6, HY + 0.15, 1.0), c.M_MET_D, 0.03)
    c.B("rc_handle", (0.04, 0.05, 0.22), (0.95, HY + 0.32, 1.05), c.M_MET)
    c.CYL("rc_lamp", 0.05, 0.06, (0.3, HY + 0.32, 1.42), c.M_BEACON, "y", 8)
    c.PIPE("rc_conduit", [(0.6, HY + 0.15, 1.55), (0.6, HY + 0.15, 1.9), (0.6, HY - 0.05, 1.9)], 0.04)
    c.PIPE("rc_cable", [(0.9, HY + 0.28, 0.45), (0.9, HY + 0.44, 0.36), (0.9, HY + 0.44, 0.034), (0.6, 4.6, 0.034),
                        (-0.95, 4.96, 0.034), (-0.95, 5.08, 0.24), (-1.05, 5.35, 0.45)], 0.03, mat=c.M_CABLE, verts=5)


def roof(c):
    """One cornice slab with a jagged broken front-right corner (sharp boolean faces), a stepped upper fracture, a notch
    where the ladder arrives, and rusted rebar coming out of the break."""
    cor = L.chamfer_box("cornice", (8.2, 7.6, 0.5), (0, 0, 4.25), c.M_CON_T, 0.25)
    brk = [(4.4, -1.55), (3.75, -1.82), (3.35, -1.62), (2.95, -2.02), (2.55, -1.93), (2.3, -2.45), (2.02, -2.7),
           (2.18, -3.15), (1.85, -3.5), (2.0, -4.2)]
    step = [(4.4, -1.25), (3.7, -1.5), (3.2, -1.36), (2.7, -1.72), (2.25, -1.62), (1.98, -2.2), (1.72, -2.55),
            (1.86, -3.1), (1.5, -3.42), (1.62, -4.2)]
    brk, step = [_m(c, *p) for p in brk], [_m(c, *p) for p in step]
    lx = c.V["ladder"]
    L.cut(cor, L.vprism("cut_break", brk + [_m(c, 4.6, -4.4), _m(c, 4.6, -1.55)], 3.9, 4.7))
    L.cut(cor, L.vprism("cut_step", step + [_m(c, 4.6, -4.4), _m(c, 4.6, -1.25)], 4.33, 4.7))
    L.cut(cor, L.vprism("cut_ladder", [(lx * 3.2, -0.75), (lx * 4.4, -0.75), (lx * 4.4, 0.35), (lx * 3.2, 0.35)], 3.9, 4.7))
    c.parts.append(cor)
    sx, sy = c.V["brk"]
    c.COL("cornice_a_c", (6.2, 7.6, 0.5), (sx * -1.0, 0, 4.25))
    c.COL("cornice_b_c", (2.0, 5.7, 0.5), (sx * 3.1, sy * 0.95, 4.25))
    for i in range(1, len(brk) - 2):                     # rebar: starts 18 cm inside the slab, sticks out and droops
        p0, p1 = Vector(brk[i]), Vector(brk[i + 1])
        m, d = (p0 + p1) / 2, (p1 - p0).normalized()
        n = Vector((-d.y, d.x))
        if n.dot(Vector((0.0, sy * 1.0)) - m) < 0:
            n = -n
        z = 4.12 + 0.07 * (i % 2)
        s, e = m + n * 0.18, m - n * (0.28 + 0.06 * (i % 3))
        c.PIPE(f"rebar{i}", [(s.x, s.y, z), (m.x - n.x * 0.1, m.y - n.y * 0.1, z + 0.02), (e.x, e.y, z - 0.12)], 0.018,
               mat=c.M_RUST, verts=5)
    for i, (x, y, sz, r) in enumerate(((2.9, -2.6, 0.34, 20), (3.35, -2.25, 0.22, -35), (2.5, -3.05, 0.26, 50))):
        x, y = _m(c, x, y)
        o = c.B(f"roof_debris{i}", (sz, sz * 0.8, sz * 0.55), (x, y, 4.0 + sz * 0.22), c.M_CON_T, 0.04, rot=(8, -6, r))
        L.jitter(o, 0.03, 30 + i)


def rubble(c):
    """Fallen cornice chunks under the broken corner: irregular, part-sunk, one leaning on the plinth, rebar in the big one."""
    chunks = [((3.25, -4.45, 0.12), (1.25, 0.9, 0.42), (9, -7, 28)), ((2.15, -3.98, 0.24), (0.8, 0.42, 0.4), (-28, 4, 8)),
              ((4.3, -4.05, 0.1), (0.55, 0.45, 0.32), (18, 10, 60)), ((3.1, -5.35, 0.07), (0.4, 0.34, 0.24), (-8, 22, 15)),
              ((4.4, -3.2, 0.08), (0.45, 0.38, 0.26), (12, -15, 40)), ((2.6, -4.95, 0.05), (0.26, 0.2, 0.16), (25, 5, 80)),
              ((3.9, -5.0, 0.04), (0.22, 0.2, 0.14), (-15, 30, 10)), ((1.7, -4.6, 0.04), (0.2, 0.16, 0.14), (10, -20, 35))]
    for i, (loc, size, rot) in enumerate(chunks):
        o = c.B(f"rubble{i}", size, (*_m(c, loc[0], loc[1]), loc[2]), c.M_CON_T, min(size) * 0.2, rot=rot)
        L.jitter(o, min(size) * 0.12, 11 + i)
    c.PIPE("rubble_rebar", [(*_m(c, x, y), z) for x, y, z in ((3.2, -4.4, 0.2), (3.75, -4.75, 0.42), (4.05, -4.9, 0.38))],
           0.018, mat=c.M_RUST, verts=5)


def ladder(c):
    """Roof ladder 22 cm off the side wall (V["ladder"]: +1 right, -1 left) with a gooseneck over the cornice notch. With
    V["lad_fall"] the lower section rotted off and lies against the plinth, only bent bracket stubs left on the wall where
    it hung; otherwise the ladder still runs down to the plinth."""
    HX, lx, fall = c.HX, c.V["ladder"], c.V["lad_fall"]
    x, y0 = lx * (HX + 0.22), -0.2
    for s in (-1, 1):
        y = y0 + s * 0.28
        c.PIPE(f"lad_rail{s}", [(x, y, 1.72 if fall else 0.4), (x, y, 4.85), (x - lx * 0.26, y, 5.05), (lx * 3.3, y, 4.85),
                                (lx * 3.3, y, 3.98)], 0.03)
        if fall:
            c.TUBE(f"lad_stub{s}", (x, y, 1.73), (x + lx * 0.08, y + 0.02 * s, 1.6), 0.028)       # torn-off rail ends
        for z in (2.1, 3.0, 3.9) if fall else (1.2, 2.1, 3.0, 3.9):
            c.B(f"lad_brk{z}{s}", (0.26, 0.05, 0.05), (lx * (HX + 0.11), y, z), c.M_MET_D)
        if fall:
            c.B(f"lad_brk_old{s}", (0.14, 0.05, 0.05), (lx * (HX + 0.06), y, 1.2), c.M_RUST)
            c.TUBE(f"lad_brk_bent{s}", (lx * (HX + 0.12), y, 1.2), (lx * (HX + 0.17), y, 1.12), 0.02, c.M_RUST, 5)
    rungs = [2.0 + k * 0.3 for k in range(10)] if fall else [0.8 + k * 0.3 for k in range(14)]
    for i, z in enumerate(rungs):
        if i != (3 if fall else 8):                                                      # one rung rotted through
            c.TUBE(f"lad_rung{i}", (x, y0 - 0.28, z), (x, y0 + 0.28, z), 0.022, c.M_MET, 6)
    if not fall:
        return
    a, b = Vector((lx * 5.35, -0.3, 0.028)), Vector((lx * 3.88, -0.3, 0.392))           # fallen lower section
    for s in (-1, 1):
        c.TUBE(f"lad_fall_rail{s}", a + Vector((0, s * 0.28, 0)), b + Vector((0, s * 0.28, 0)), 0.03, c.M_RUST, 6)
    for i in range(1, 5):
        if i != 2:
            p = a.lerp(b, i / 5)
            c.TUBE(f"lad_fall_rung{i}", p + Vector((0, -0.28, 0)), p + Vector((0, 0.28, 0)), 0.022, c.M_RUST, 6)


def hatch(c):
    """Sealed maintenance hatch on the wall opposite the ladder: concrete surround, recessed steel plate, hinges, lever on
    standoffs. o = outward sign of that wall (-1: left)."""
    o = -c.V["ladder"]
    x, y = o * c.HX, -0.9
    c.B("hatch_jamb_a", (0.12, 0.16, 1.66), (x + o * 0.06, y - 0.58, 1.37), c.M_CON_T, 0.03)
    c.B("hatch_jamb_b", (0.12, 0.16, 1.66), (x + o * 0.06, y + 0.58, 1.37), c.M_CON_T, 0.03)
    c.B("hatch_lintel", (0.12, 1.32, 0.16), (x + o * 0.06, y, 2.18), c.M_CON_T, 0.03)
    c.B("hatch_sill", (0.16, 1.32, 0.12), (x + o * 0.08, y, 0.56), c.M_CON_T, 0.03)
    c.B("hatch_plate", (0.08, 1.0, 1.48), (x + o * 0.02, y, 1.36), c.M_MET_D, 0.02)
    for z in (1.0, 1.75):
        c.B(f"hatch_rib{z}", (0.04, 0.9, 0.08), (x + o * 0.08, y, z), c.M_MET)
    for z in (0.85, 1.85):
        c.CYL(f"hatch_hinge{z}", 0.045, 0.25, (x + o * 0.08, y - 0.46, z), c.M_MET, "z", 6)
    for z in (1.22, 1.48):
        c.B(f"hatch_standoff{z}", (0.11, 0.04, 0.04), (x + o * 0.105, y + 0.35, z), c.M_MET)
    c.CYL("hatch_handle", 0.025, 0.34, (x + o * 0.16, y + 0.35, 1.35), c.M_RUST, "z", 6)


def dish_and_beacon(c):
    """Comm dish (open bowl, rim, feed on three struts) sagged on its mount; bent antenna; caged amber beacon on a post.
    V["dish"] == "fallen": only the pedestal, a torn mount stub and a snapped antenna are left up here (the dish itself lies
    on the ground, outpost_extras.fallen_dish)."""
    c.CYL("dish_pedestal", 0.25, 0.5, (1.0, 0.6, 4.75), c.M_MET_D, v=8)
    p = Vector((1.0, 0.5, 5.1))
    if c.V["dish"] == "roof":
        c.TUBE("dish_mount", (1.0, 0.6, 4.96), tuple(p), 0.05)
        dish = dish_parts(c, p)
        L.rotate_about(dish, tuple(p), (38, 0, 30))                                    # sagged on its mount
        c.parts.extend(dish)
        c.TUBE("antenna_lo", (0.2, 0.9, 4.48), (0.2, 0.9, 5.3), 0.025)
        c.TUBE("antenna_hi", (0.2, 0.9, 5.3), (0.85, 1.35, 5.65), 0.022)                 # bent over
    else:
        c.TUBE("dish_mount", (1.0, 0.6, 4.96), (1.07, 0.52, 5.05), 0.05)                # torn off
        c.TUBE("antenna_lo", (0.2, 0.9, 4.48), (0.2, 0.9, 4.92), 0.025)                  # snapped
        c.TUBE("antenna_snap", (0.2, 0.9, 4.92), (0.27, 0.83, 4.99), 0.018)
    bx, by = c.V["beacon"]
    c.CYL("beacon_base", 0.18, 0.06, (bx, by, 4.53), c.M_MET_D, v=8)
    c.TUBE("beacon_post", (bx, by, 4.5), (bx, by, 5.17), 0.04)
    c.CYL("beacon_housing", 0.12, 0.08, (bx, by, 5.19), c.M_MET_D, v=8)
    c.CYL("beacon_lens", 0.09, 0.2, (bx, by, 5.33), c.M_BEACON, v=8)
    for k in range(4):
        a = k * math.tau / 4 + 0.4
        c.TUBE(f"beacon_cage{k}", (bx + math.cos(a) * 0.11, by + math.sin(a) * 0.11, 5.22), (bx + math.cos(a) * 0.11, by + math.sin(a) * 0.11, 5.46), 0.012, c.M_MET, 4)
    c.CYL("beacon_cap", 0.13, 0.04, (bx, by, 5.46), c.M_MET_D, v=8)
    c.PIPE("beacon_cable", [(bx, by + 0.03, 4.9), (bx + 0.25, by - 0.4, 4.52), (0.95, 0.75, 4.52)], 0.02, mat=c.M_CABLE, verts=4)


def dish_parts(c, p):
    """Comm dish assembly around its hub point p, bowl up (open bowl, rim, hub, feed on three struts); not yet in c.parts."""
    dish = [L.open_cone("dish_bowl", 0.06, 0.62, 0.28, tuple(p + Vector((0, 0, 0.14))), c.M_MET, 12),
            L.open_cone("dish_rim", 0.62, 0.65, 0.05, tuple(p + Vector((0, 0, 0.3))), c.M_MET_D, 12),
            L.cylinder("dish_hub", 0.1, 0.14, tuple(p), c.M_MET_D, 8)]
    focus = p + Vector((0, 0, 0.62))
    for k in range(3):
        a = k * math.tau / 3
        dish.append(AO.tube(f"dish_strut{k}", p + Vector((math.cos(a) * 0.6, math.sin(a) * 0.6, 0.28)), focus, 0.014, c.M_MET_D, 4))
    dish.append(L.cylinder("dish_feed", 0.05, 0.14, tuple(focus), c.M_MET_D, 6))
    return dish


def wellhead(c):
    """Casing + collar in the ground, a stuffing box leaking amber around the polished rod, feed line into the rear wall."""
    HY = c.HY
    c.CYL("wh_collar", 0.95, 1.4, (WX, WY, -0.3), c.M_CON_T, v=12)                      # z -1.0 .. 0.4
    c.CYL("wh_casing", 0.5, 1.3, (WX, WY, 1.05), c.M_MET_D, v=10)                       # z 0.4 .. 1.7
    c.CYL("wh_flange_lo", 0.62, 0.08, (WX, WY, 0.9), c.M_MET, v=10)
    c.CYL("wh_flange_hi", 0.62, 0.08, (WX, WY, 1.7), c.M_MET, v=10)
    c.CYL("wh_stuffing_box", 0.14, 0.3, (WX, WY, 1.85), c.M_MET, v=8)
    c.LIQ_CYL("wh_glow", 0.36, 0.05, (WX, WY, 1.76), "z", 10)                           # amber welling round the seal
    c.COL("wh_col", (1.9, 1.9, 2.8), (WX, WY, 0.4))
    c.CRYSTALS("wh_cr", WX, WY, 0.4, 6, 0.75, 5, 1.1)
    c.CRYSTALS("wh_cr_top", WX, WY, 1.7, 3, 0.36, 8, 0.6)
    fx = 1.75                                                                            # feed line into the bunker
    c.PIPE("feed", [(fx, WY - 0.3, 1.3), (fx, HY - 0.1, 1.3)], 0.1, c.M_MET_D, clamps=0.9)
    c.CYL("feed_wall_flange", 0.2, 0.06, (fx, HY + 0.03, 1.3), c.M_MET, "y", 10)
    c.TUBE("feed_valve_stem", (fx, 4.4, 1.4), (fx, 4.4, 1.8), 0.03, c.M_MET, 6)
    c.CYL("feed_valve_wheel", 0.17, 0.03, (fx, 4.4, 1.82), c.M_MET_D, v=8)
    for y in (4.0, 4.85):
        c.LIQ_CYL(f"feed_glass{y}", 0.118, 0.28, (fx, y, 1.3), "y")
    c.POOL("spill_wh", (WX, WY, 0.045), 3.4, 3.4)
    c.DECAL("crust_wh", (WX, WY, 0.03), 3.0, 3.0, "+z", c.D_CRUST, up=(0, 1, 0))


def pump_jack(c):
    """The pump that pulls the amber up. Moving parts go into c.movers (node origin = pivot) and are animated in Godot."""
    ox, oz = PIVOT
    cx, cz = CRANK
    mv = {k: v[0] for k, v in c.movers.items()}
    c.B("pj_pad", (2.9, 1.2, 0.6), (-0.45, WY, -0.1), c.M_CON_T, 0.06)                  # skid pad, z -0.4 .. 0.2
    c.COL("pj_col", (3.0, 1.4, 3.0), (-0.45, WY, 1.5))
    for s in (-1, 1):                                                                    # samson post (A-frame)
        c.TUBE(f"pj_leg_f{s}", (ox + 0.45, WY + s * 0.5, 0.18), (ox + 0.02, WY + s * 0.13, 2.8), 0.06, verts=6)
        c.TUBE(f"pj_leg_r{s}", (ox - 0.55, WY + s * 0.5, 0.18), (ox - 0.02, WY + s * 0.13, 2.8), 0.06, verts=6)
        c.TUBE(f"pj_brace{s}", (ox + 0.28, WY + s * 0.36, 1.2), (ox - 0.36, WY + s * 0.36, 1.2), 0.035, verts=6)
    c.B("pj_bearing", (0.3, 0.4, 0.14), (ox, WY, oz - 0.2), c.M_MET, 0.02)
    c.CYL("pj_axle", 0.05, 0.5, (ox, WY, oz), c.M_MET, "y", 8)
    c.B("pj_gearbox", (0.75, 0.6, 0.9), (cx, WY, 0.65), c.M_MET_D, 0.05)
    c.CYL("pj_crankshaft", 0.07, 0.9, (cx, WY, cz), c.M_MET, "y", 8)
    c.B("pj_motor", (0.35, 0.45, 0.4), (-1.85, WY, 0.4), c.M_MET_D, 0.04)
    c.B("pj_belt_guard", (0.3, 0.12, 0.3), (-1.72, WY + 0.2, 0.62), c.M_RUST, 0.02)
    c.LIQ_CYL("pj_motor_glass", 0.07, 0.04, (-1.85, WY - 0.23, 0.45), "y", 8)
    # walking beam + horsehead + equalizer (node pump_beam, pivots on the bearing)
    c.B("pj_beam", (2.9, 0.22, 0.26), (0.1, WY, oz), c.M_MET_D, 0.03, into=mv["pump_beam"])
    head = [(ox + r * math.cos(math.radians(a)), oz + r * math.sin(math.radians(a))) for r, angs in
            ((HEAD_R, range(-28, 23, 10)), (HEAD_R - 0.38, range(22, -29, -10))) for a in angs]
    mv["pump_beam"].append(L.prism("pj_head", head, 0.3, (0, WY - 0.15, 0), c.M_HAZ))
    tx, tz = ox + TAIL[0], oz + TAIL[1]
    c.B("pj_eq_hanger", (0.1, 0.16, 0.22), (tx, WY, tz + 0.03), c.M_MET_D, into=mv["pump_beam"])
    c.B("pj_equalizer", (0.12, 1.06, 0.1), (tx, WY, tz), c.M_MET_D, into=mv["pump_beam"])
    # crank arms + counterweights (node pump_crank, turns on the crankshaft)
    px = cx + CRANK_R
    for s in (-1, 1):
        y = WY + s * 0.38
        c.B(f"pj_crank{s}", (0.77, 0.06, 0.16), (cx + 0.035, y, cz), c.M_MET_D, into=mv["pump_crank"])
        c.B(f"pj_cw{s}", (0.5, 0.08, 0.5), (cx - 0.38, y, cz), c.M_RUST, 0.04, into=mv["pump_crank"])
        c.CYL(f"pj_pin{s}", 0.05, 0.2, (px, y + s * 0.08, cz), c.M_MET, "y", 6, into=mv["pump_crank"])
        # pitman arms (node pump_pitman, hangs from the tail pin)
        c.TUBE(f"pj_pitman{s}", (tx, WY + s * 0.5, tz), (px, WY + s * 0.5, cz), 0.05, c.M_MET_D, 6, into=mv["pump_pitman"])
    # carrier bar + polished rod (node pump_rod) and bridle cables (node pump_bridle, stretched along its length)
    c.B("pj_carrier", (0.3, 0.28, 0.06), (WX, WY, CARRIER_Z), c.M_MET, into=mv["pump_rod"])
    c.CYL("pj_rod", 0.035, 1.1, (WX, WY, CARRIER_Z - 0.55), c.M_MET, v=6, into=mv["pump_rod"])
    c.B("pj_rod_clamp", (0.1, 0.1, 0.08), (WX, WY, CARRIER_Z + 0.07), c.M_MET_D, into=mv["pump_rod"])
    for s in (-1, 1):
        c.TUBE(f"pj_bridle{s}", (WX, WY + s * 0.08, oz), (WX, WY + s * 0.08, CARRIER_Z + 0.02), 0.012, c.M_CABLE, 4, into=mv["pump_bridle"])
    c.DECAL("crust_pad", (cx + 0.2, WY, 0.212), 1.6, 1.1, "+z", c.D_CRUST, up=(0, 1, 0))


def silo_main(c):
    """Export line: from the casing down into a valve pit, then underground to the silo. Glowing sight glass in the pit."""
    c.PIPE("main", [(WX + 0.4, WY, 0.9), (PX - 0.28, WY, 0.9), (PX - 0.28, WY, -0.35), (PX + 0.75, WY, -0.35)], 0.1, c.M_MET_D)
    c.TUBE("main_clamp", (2.64, WY, 0.9), (2.72, WY, 0.9), 0.14, c.M_MET, 8)
    c.TUBE("main_valve_stem", (3.05, WY, 1.0), (3.05, WY, 1.4), 0.03, c.M_MET, 6)
    c.CYL("main_valve_wheel", 0.17, 0.03, (3.05, WY, 1.42), c.M_MET_D, v=8)
    c.LIQ_CYL("main_glass", 0.118, 0.24, (2.48, WY, 0.9), "x")
    for s in (-1, 1):
        c.B(f"pit_wall_y{s}", (1.1, 0.15, 0.92), (PX, PY + s * 0.525, -0.24), c.M_CON_T, 0.03)
        c.B(f"pit_wall_x{s}", (0.15, 0.9, 0.92), (PX + s * 0.475, PY, -0.24), c.M_CON_T, 0.03)
    c.B("pit_floor", (0.8, 0.9, 0.1), (PX, PY, -0.65), c.M_CON_T)
    c.POOL("pit_pool", (PX, PY, -0.595), 0.8, 0.9)
    c.LIQ_CYL("pit_glass", 0.118, 0.3, (PX + 0.15, PY, -0.35), "x")
    c.B("pit_valve", (0.2, 0.26, 0.26), (PX - 0.06, PY, -0.35), c.M_RUST, 0.03)
    c.TUBE("pit_valve_stem", (PX - 0.06, PY, -0.25), (PX - 0.06, PY, 0.3), 0.025, c.M_MET, 6)
    c.CYL("pit_valve_wheel", 0.15, 0.03, (PX - 0.06, PY, 0.31), c.M_MET_D, v=8)
    for i, x in enumerate((-0.12, 0.04, 0.2, 0.35)):                                    # grating; one bar sagged in
        if i == 2:
            c.B("pit_bar_bent", (0.04, 1.1, 0.04), (PX + x, PY + 0.05, 0.13), c.M_RUST, rot=(12, 0, 4))
        else:
            c.B(f"pit_bar{i}", (0.04, 1.2, 0.04), (PX + x, PY, 0.24), c.M_MET)
    c.COL("pit_col", (1.1, 1.2, 0.5), (PX, PY, 0.0))
    sx, sy = 4.35, 6.4                                                                   # buried-line marker
    c.TUBE("sign_post", (sx, sy, -0.6), (sx, sy, 1.25), 0.035, c.M_MET_D, 6)
    c.B("sign_plate", (0.03, 0.52, 0.38), (sx + 0.045, sy, 1.02), c.M_MET_D)
    c.DECAL("sign_face", (sx + 0.068, sy, 1.02), 0.5, 0.36, "+x", c.D_SIGN)


def deadwood(c):
    """The forest has been dropping on it for 200 years: a dead branch across the roof (V["branch"]: side of the roof edge
    it lies from, -1 left, +1 right, 0 none), a log against the rear-left corner (V["log"])."""
    b = c.V["branch"]
    if b:
        pts = [(b * 3.3, -1.2, 4.565), (b * 1.9, 0.1, 4.55), (b * 0.7, 1.3, 4.535), (b * -0.3, 1.9, 4.525)]
        for i in range(3):
            c.TUBE(f"branch{i}", pts[i], pts[i + 1], 0.075 - i * 0.017, c.M_WOOD, 6)
        c.TUBE("branch_fork_a", (b * 1.9, 0.1, 4.55), (b * 1.3, -0.7, 4.53), 0.03, c.M_WOOD, 5)
        c.TUBE("branch_fork_b", (b * 0.7, 1.3, 4.535), (b * 0.9, 2.3, 4.525), 0.025, c.M_WOOD, 5)
        c.TUBE("branch_twig", (b * 1.3, -0.7, 4.53), (b * 1.45, -1.25, 4.6), 0.015, c.M_WOOD, 4)
    if not c.V["log"]:
        return
    c.PIPE("log", [(-4.95, 2.1, 0.12), (-4.3, 2.55, 0.74), (-3.62, 3.2, 1.45)], 0.15, c.M_WOOD, verts=7)  # leans on the corner
    c.TUBE("log_stub", (-4.3, 2.55, 0.74), (-4.62, 2.95, 1.0), 0.05, c.M_WOOD, 5)
    c.TUBE("log_splinter", (-4.95, 2.1, 0.12), (-5.25, 1.95, 0.05), 0.07, c.M_WOOD, 5)


def decals(c):
    HX, HY = c.HX, c.HY
    D = c.DECAL
    sl = c.V["ladder"]                                   # ladder wall (sl): stencil; hatch wall (-sl): warning sign
    fl, fh = ("+x", "-x") if sl > 0 else ("-x", "+x")
    D("stencil_r", (sl * (HX + 0.012), 1.15, 2.2), 1.05, 1.575, fl, c.D_STENCIL)
    D("sign_l", (-sl * (HX + 0.012), 0.55, 1.6), 0.6, 0.8, fh, c.D_WARN)
    D("streak_r", (sl * (HX + 0.012), -1.25, 2.0), 1.0, 2.0, fl, c.D_STREAK)
    D("streak_l", (-sl * (HX + 0.012), 1.45, 2.0), 0.9, 2.0, fh, c.D_STREAK)
    D("streak_b1", (-0.9, HY + 0.012, 0.85), 1.5, 1.5, "+y", c.D_STREAK)
    D("streak_b2", (0.3, HY + 0.012, 2.6), 0.5, 1.7, "+y", c.D_STREAK)
    D("streak_hatch", (-sl * (HX + 0.072), -0.9, 1.2), 0.9, 1.3, fh, c.D_STREAK)
    D("crack_f", (1.92, -HY - 0.012, 1.9), 0.5, 1.0, "-y", c.D_CRACK)
    D("crack_l", (-sl * (HX + 0.012), 1.75, 1.6), 0.4, 1.2, fh, c.D_CRACK)
    D("crack_r", (sl * (HX + 0.012), 1.7, 1.1), 0.4, 1.2, fl, c.D_CRACK)
    D("drips_feed", (1.75, HY + 0.012, 0.95), 0.8, 1.2, "+y", c.D_DRIPS)                 # the wall seal weeps amber
    D("dust_rubble", (*_m(c, 3.2, -4.4), 0.014), 3.0, 2.2, "+z", c.D_DUST, up=(0, 1, 0))
    D("dust_roof_break", (*_m(c, 2.95, -2.6), 4.012), 1.4, 1.4, "+z", c.D_DUST, up=(0, 1, 0))
    D("dust_roof", (*_m(c, -1.2, 0.8), 4.512), 3.0, 3.0, "+z", c.D_DUST, up=(0, 1, 0))
