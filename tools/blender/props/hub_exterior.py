"""Relay Hub 00 exterior. Called by relay_hub.py as build(c) (`c` = namespace of its helpers, materials and dimensions).
Outpost 73's language, scaled up: plinth, stepped corner piers, one thick cornice (broken at the rear-right corner, rebar
and rubble below), amber slit windows, octagonal door frame. On the roof a clerestory lantern carries the hub's own relay
mast (the tallest thing in the forest, beacon = marker_light_roof) and two comm dishes.
At each corner a buried route main leaves the building (pier flange -> valve -> sight glass hub_flow_<key> -> ground collar)
beside a ROUTE plate; the corner relay mast of that route stands further out at marker_route_<key>.
Everything touches the building, another part or the ground (z = 0)."""
import math

from mathutils import Vector

import ps1_ao as AO
import ps1_lib as L

LZ0, LZ1 = 5.1, 6.4                  # clerestory lantern: bottom (cornice top) / top
LY = 0.4                             # lantern centre y
MAST_Z0, MAST_Z1 = 6.8, 12.6         # hub mast foot / top
PYLON_OUT = (5.2, 4.6)               # corner relay mast: distance beyond the wall planes (x, y)


def build(c):
    base(c)
    cornice(c)
    lantern(c)
    mast(c)
    corner_mains(c)
    rear(c)
    deadwood(c)
    decals(c)
    outdoor_kit(c)
    L.empty("marker_light_front", (0, -c.HY - 0.6, 3.6))
    L.empty("marker_light_roof", (0, LY, MAST_Z1 + 0.3))


def base(c):
    HX, HY = c.HX, c.HY
    c.B("plinth_back", (2 * HX + 0.7, 0.35, 1.4), (0, HY + 0.175, -0.3), c.M_CON_T, 0.1)
    c.COL("plinth_back_c", (2 * HX + 0.7, 0.35, 1.4), (0, HY + 0.175, -0.3))
    for sx in (-1, 1):
        c.B(f"plinth_side{sx}", (0.35, 2 * HY + 0.7, 1.4), (sx * (HX + 0.175), 0, -0.3), c.M_CON_T, 0.1)
        c.COL(f"plinth_side{sx}_c", (0.35, 2 * HY + 0.7, 1.4), (sx * (HX + 0.175), 0, -0.3))
        w = HX + 0.35 - (c.OW + 0.05)
        c.B(f"plinth_front{sx}", (w, 0.35, 1.4), (sx * (c.OW + 0.05 + w / 2), -HY - 0.175, -0.3), c.M_CON_T, 0.1)
        c.COL(f"plinth_front{sx}_c", (w, 0.35, 1.4), (sx * (c.OW + 0.05 + w / 2), -HY - 0.175, -0.3))
        for sy in (-1, 1):
            c.B(f"pier{sx}{sy}", (2.0, 2.0, 4.2), (sx * (HX - 0.85), sy * (HY - 0.85), 2.5), c.M_CON, 0.3)
            c.COL(f"pier{sx}{sy}_c", (2.0, 2.0, 4.2), (sx * (HX - 0.85), sy * (HY - 0.85), 2.5))
        c.B(f"pilaster{sx}", (0.3, 1.2, 4.2), (sx * (HX + 0.15), 0, 2.5), c.M_CON, 0.08)
        # slit windows: glow + brow (front pair flanking the door, one per side wall)
        c.B(f"win_brow_f{sx}", (2.0, 0.2, 0.1), (sx * 3.9, -HY - 0.1, 3.72), c.M_CON_T, 0.02)
        c.B(f"win_glow_f{sx}", (1.6, 0.05, 0.2), (sx * 3.9, -HY + 0.005, 3.42), c.M_AMBER)
        c.B(f"win_brow_s{sx}", (0.2, 1.4, 0.1), (sx * (HX + 0.1), -1.9 * sx, 3.72), c.M_CON_T, 0.02)
        c.B(f"win_glow_s{sx}", (0.05, 1.2, 0.2), (sx * (HX - 0.005), -1.9 * sx, 3.42), c.M_AMBER)
    # door lamp over the frame
    c.B("door_lamp", (0.8, 0.4, 0.18), (0, -HY - 0.2, 3.95), c.M_MET_D, 0.02)
    c.B("door_lamp_lens", (0.62, 0.26, 0.03), (0, -HY - 0.22, 3.855), c.M_AMBER)
    c.PIPE("door_lamp_cond", [(0.35, -HY - 0.08, 4.0), (0.35, -HY - 0.08, 4.6)], 0.03)


def _corner(pts, k=1.3):
    """Map (x, y) points from Outpost 73's front-right cornice corner (4.1, -3.8) onto the hub's rear-right corner."""
    return [(7.45 + (x - 4.1) * k, 5.85 - (y + 3.8) * k) for x, y in pts]


def cornice(c):
    cor = L.chamfer_box("cornice", (2 * c.HX + 0.9, 2 * c.HY + 0.9, 0.5), (0, 0, c.H + 0.25), c.M_CON_T, 0.25)
    brk = [(4.4, -1.55), (3.75, -1.82), (3.35, -1.62), (2.95, -2.02), (2.55, -1.93), (2.3, -2.45), (2.02, -2.7),
           (2.18, -3.15), (1.85, -3.5), (2.0, -4.2)]
    step = [(4.4, -1.25), (3.7, -1.5), (3.2, -1.36), (2.7, -1.72), (2.25, -1.62), (1.98, -2.2), (1.72, -2.55),
            (1.86, -3.1), (1.5, -3.42), (1.62, -4.2)]
    z0, z1 = c.H - 0.1, c.H + 0.6
    L.cut(cor, L.vprism("cut_break", _corner(brk + [(4.6, -4.4), (4.6, -1.55)]), z0, z1))
    L.cut(cor, L.vprism("cut_step", _corner(step + [(4.6, -4.4), (4.6, -1.25)]), c.H + 0.33, z1))
    c.parts.append(cor)
    b = _corner(brk)
    for i in range(1, len(b) - 2):                    # rebar out of the break, drooping
        p0, p1 = Vector(b[i]), Vector(b[i + 1])
        m, d = (p0 + p1) / 2, (p1 - p0).normalized()
        n = Vector((-d.y, d.x))
        if n.dot(Vector((0.0, 0.0)) - m) < 0:
            n = -n
        z = c.H + 0.12 + 0.07 * (i % 2)
        s, e = m + n * 0.18, m - n * (0.3 + 0.07 * (i % 3))
        c.PIPE(f"rebar{i}", [(s.x, s.y, z), (m.x - n.x * 0.1, m.y - n.y * 0.1, z + 0.02), (e.x, e.y, z - 0.14)], 0.018,
               mat=c.M_RUST, verts=5)
    chunks = [((-0.85, -0.65, 0.12), (1.4, 1.0, 0.45), (9, -7, 28)), ((-1.95, -0.18, 0.2), (0.9, 0.5, 0.42), (-28, 4, 8)),
              ((0.2, -0.25, 0.1), (0.6, 0.5, 0.34), (18, 10, 60)), ((-1.0, -1.55, 0.07), (0.45, 0.38, 0.26), (-8, 22, 15)),
              ((-1.5, -1.15, 0.05), (0.3, 0.24, 0.18), (25, 5, 80))]
    for i, ((dx, dy, z), size, rot) in enumerate(chunks):
        x, y = _corner([(4.1 + dx, -3.8 + dy)])[0]
        o = c.B(f"rubble{i}", size, (x, y, z), c.M_CON_T, min(size) * 0.2, rot=rot)
        L.jitter(o, min(size) * 0.12, 21 + i)
    c.DECAL("dust_rubble", (6.4, 7.0, 0.014), 3.4, 2.6, "+z", c.D_DUST, up=(0, 1, 0))


def lantern(c):
    ly0, ly1 = LY - 2.1, LY + 2.1
    c.B("lantern", (7.0, 4.2, LZ1 - LZ0 + 0.1), (0, LY, (LZ0 + LZ1) / 2 - 0.05), c.M_CON, 0.12)
    c.B("lantern_cap", (7.5, 4.7, 0.3), (0, LY, LZ1 + 0.15), c.M_CON_T, 0.1)
    for x in (-2.2, 0.0, 2.2):
        for y, s in ((ly0, -1), (ly1, 1)):
            c.B(f"lan_glow{x}{s}", (1.2, 0.05, 0.16), (x, y + s * 0.005, 5.8), c.M_AMBER)
            c.B(f"lan_brow{x}{s}", (1.4, 0.2, 0.08), (x, y + s * 0.1, 5.98), c.M_CON_T, 0.02)
    c.DECAL("dust_cornice", (-4.2, 2.6, c.H + 0.512), 3.2, 3.2, "+z", c.D_DUST, up=(0, 1, 0))
    c.DECAL("dust_cap", (1.2, LY - 0.6, LZ1 + 0.302), 3.0, 3.0, "+z", c.D_DUST, up=(0, 1, 0))
    _dish(c, "dish_a", (2.5, LY - 1.2, LZ1 + 0.3), (40, 0, -35), 1.0)
    _dish(c, "dish_b", (-2.6, LY + 1.3, LZ1 + 0.3), (30, 0, 150), 0.75)


def _dish(c, name, base, tilt, s):
    """Comm dish on a short pedestal, sagged on its mount (open bowl, rim, feed on three struts)."""
    bx, by, bz = base
    c.CYL(f"{name}_ped", 0.25 * s, 0.5 * s, (bx, by, bz + 0.25 * s), c.M_MET_D, v=8)
    p = Vector((bx, by, bz + 0.6 * s))
    c.TUBE(f"{name}_mount", (bx, by, bz + 0.45 * s), tuple(p), 0.05 * s)
    dish = [L.open_cone(f"{name}_bowl", 0.06 * s, 0.75 * s, 0.32 * s, tuple(p + Vector((0, 0, 0.16 * s))), c.M_MET, 12),
            L.open_cone(f"{name}_rim", 0.75 * s, 0.78 * s, 0.05 * s, tuple(p + Vector((0, 0, 0.34 * s))), c.M_MET_D, 12),
            L.cylinder(f"{name}_hub", 0.12 * s, 0.16 * s, tuple(p), c.M_MET_D, 8)]
    focus = p + Vector((0, 0, 0.75 * s))
    for k in range(3):
        a = k * math.tau / 3
        dish.append(AO.tube(f"{name}_strut{k}", p + Vector((math.cos(a) * 0.72 * s, math.sin(a) * 0.72 * s, 0.32 * s)), focus,
                            0.014, c.M_MET_D, 4))
    dish.append(L.cylinder(f"{name}_feed", 0.06 * s, 0.16 * s, tuple(focus), c.M_MET_D, 6))
    L.rotate_about(dish, tuple(p), tilt)
    c.parts.extend(dish)


def mast(c):
    """The hub's relay mast: tapered steel tower on the lantern, two cross-arms with dipoles, caged beacon, four guy wires."""
    c.B("mast_foot", (1.1, 1.1, 0.12), (0, LY, LZ1 + 0.36), c.M_MET_D, 0.02)
    o = L.cone("mast", 0.5, 0.17, MAST_Z1 - MAST_Z0 + 0.4, (0, LY, (MAST_Z0 + MAST_Z1) / 2 - 0.2), c.M_MET_D, 4)
    o.rotation_euler = (0, 0, math.radians(45))
    c.parts.append(o)
    for z, w in ((MAST_Z1 - 1.6, 2.6), (MAST_Z1 - 0.6, 1.7)):
        c.B(f"arm{z}", (w, 0.1, 0.1), (0, LY, z), c.M_MET)
        for s in (-1, 1):
            c.TUBE(f"dipole{z}{s}", (s * (w / 2 - 0.08), LY, z - 0.5), (s * (w / 2 - 0.08), LY, z + 0.55), 0.025, c.M_MET)
    for i in range(10):                                                              # rungs up the front face
        z = MAST_Z0 + 0.5 + i * 0.5
        hy = 0.5 - (0.5 - 0.17) * (z - MAST_Z0 + 0.2) / (MAST_Z1 - MAST_Z0 + 0.4)
        c.PIPE(f"mrung{i}", [(-0.09, LY - hy * 0.7 + 0.01, z), (-0.09, LY - hy * 0.7 - 0.07, z), (0.09, LY - hy * 0.7 - 0.07, z),
                             (0.09, LY - hy * 0.7 + 0.01, z)], 0.012, c.M_MET, verts=5)
    top = MAST_Z1 + 0.05
    c.CYL("beacon_base", 0.22, 0.1, (0, LY, top), c.M_MET_D, v=10)
    c.CYL("beacon_lens", 0.16, 0.36, (0, LY, top + 0.23), c.M_BEACON, v=10)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        c.TUBE(f"beacon_cage{i}", (0.2 * math.cos(a), LY + 0.2 * math.sin(a), top + 0.05),
               (0.2 * math.cos(a), LY + 0.2 * math.sin(a), top + 0.45), 0.012, c.M_MET)
    c.CYL("beacon_cap", 0.23, 0.05, (0, LY, top + 0.47), c.M_MET_D, v=10)
    c.TUBE("beacon_rod", (0, LY, top + 0.5), (0, LY, top + 1.3), 0.015, c.M_MET)
    for sx in (-1, 1):
        for sy in (-1, 1):
            a = (sx * 3.45, LY + sy * 2.05, LZ1 + 0.3)
            c.TUBE(f"guy{sx}{sy}", (sx * 0.2, LY + sy * 0.2, MAST_Z1 - 2.2), a, 0.01, c.M_CABLE, 4)
            c.TUBE(f"guy_eye{sx}{sy}", a, (a[0], a[1], a[2] + 0.08), 0.03, c.M_RUST)
    c.PIPE("mast_cable", [(0.25, LY + 0.1, MAST_Z0 + 0.3), (0.6, LY + 0.6, LZ1 + 0.33), (2.0, LY + 1.0, LZ1 + 0.33)], 0.03,
           mat=c.M_CABLE, verts=5)


def corner_mains(c):
    """Buried route mains out of the corner piers, each beside its ROUTE plate; the route's relay mast stands further out."""
    for key, (sx, sy) in c.CORNERS.items():
        x0, x1, y = sx * (c.HX + 0.1), sx * (c.HX + 0.9), sy * (c.HY - 0.85)
        c.PIPE(f"main_{key}", [(x0, y, 1.2), (x1, y, 1.2), (x1, y, -0.3)], 0.14, clamps=0.0)
        c.CYL(f"main_wall_fl_{key}", 0.24, 0.06, (sx * (c.HX + 0.18), y, 1.2), c.M_MET, "x", 10)
        c.CYL(f"main_collar_{key}", 0.38, 0.9, (x1, y, -0.15), c.M_CON_T, v=10)
        c.B(f"main_valve_{key}", (0.28, 0.28, 0.28), (sx * (c.HX + 0.5), y, 1.2), c.M_RUST, 0.03)
        c.TUBE(f"main_stem_{key}", (sx * (c.HX + 0.5), y, 1.34), (sx * (c.HX + 0.5), y, 1.6), 0.025, c.M_MET)
        c.WHEEL(f"main_wheel_{key}", (sx * (c.HX + 0.5), y, 1.62), 0.16, c.M_HAZ, c.parts, axis="z")
        c.LIQ_CYL(f"main_glass_{key}", 0.17, 0.34, (x1, y, 0.72), "z", 10, c.LQ_ROUTE[key])
        for dz in (-0.19, 0.19):
            c.CYL(f"main_glass_fl_{key}{dz}", 0.21, 0.05, (x1, y, 0.72 + dz), c.M_MET, v=10)
        c.COL(f"main_{key}_c", (1.0, 0.8, 1.8), (sx * (c.HX + 0.55), y, 0.6))
        px, py = sx * (c.HX + 1.6), y - sy * 1.1
        c.TUBE(f"sign_post_{key}", (px, py, -0.6), (px, py, 1.45), 0.035, c.M_MET_D, 6)
        c.B(f"sign_plate_{key}", (0.03, 0.6, 0.6), (px + sx * 0.045, py, 1.12), c.M_MET_D)
        c.DECAL(f"sign_face_{key}", (px + sx * 0.068, py, 1.12), 0.56, 0.56, "+x" if sx > 0 else "-x", c.D_PLATE[key])
        c.DECAL(f"main_dust_{key}", (x1, y, 0.013), 2.4, 2.4, "+z", c.D_DUST, up=(0, 1, 0))
        L.empty(f"marker_route_{key}", (sx * (c.HX + PYLON_OUT[0]), sy * (c.HY + PYLON_OUT[1]), 0.0))
    x1, y = -(c.HX + 0.9), -(c.HY - 0.85)                          # route 73 still flows: its seal weeps amber
    c.POOL("spill_73", (x1 - 0.3, y + 0.2, 0.04), 2.2, 2.2)
    c.DECAL("crust_73", (x1 - 0.2, y + 0.1, 0.03), 2.4, 2.4, "+z", c.D_CRUST, up=(0, 1, 0))


def rear(c):
    HY = c.HY
    for x in (-3.4, 3.4):
        c.B(f"vent_plate{x}", (1.7, 0.1, 1.7), (x, HY + 0.05, 2.7), c.M_MET_D, 0.03)
        for i in range(6):
            c.B(f"vent_slat{x}{i}", (1.4, 0.07, 0.09), (x, HY + 0.13, 2.15 + i * 0.22), c.M_MET, rot=(25, 0, 0))
    for i, x in enumerate((-0.95, 0.0, 0.95)):                     # relay cabinet bank on the rear ledge
        c.B(f"rack{i}", (0.85, 0.34, 1.3), (x, HY + 0.17, 1.05), c.M_MET_D, 0.03)
        c.B(f"rack_handle{i}", (0.04, 0.05, 0.22), (x + 0.3, HY + 0.36, 1.1), c.M_MET)
        c.CYL(f"rack_lamp{i}", 0.045, 0.06, (x - 0.28, HY + 0.36, 1.52), c.M_BEACON, "y", 8)
        for j in range(3):
            c.B(f"rack_louvre{i}{j}", (0.6, 0.02, 0.03), (x, HY + 0.345, 0.62 + j * 0.07), c.M_CABLE, rot=(25, 0, 0))
        c.PIPE(f"rack_cond{i}", [(x, HY + 0.17, 1.7), (x, HY + 0.17, 2.0), (x, HY - 0.05, 2.0)], 0.04)
    c.COL("rack_c", (2.7, 0.34, 1.3), (0, HY + 0.17, 1.05))


def deadwood(c):
    HX = c.HX
    c.PIPE("log", [(-HX - 1.8, 2.3, 0.12), (-HX - 1.0, 2.65, 0.8), (-HX - 0.05, 3.0, 1.55)], 0.16, c.M_WOOD, verts=7)
    c.TUBE("log_stub", (-HX - 1.0, 2.65, 0.8), (-HX - 1.3, 3.1, 1.05), 0.05, c.M_WOOD, 5)
    pts = [(-6.4, -3.6, c.H + 0.575), (-5.2, -2.6, c.H + 0.56), (-4.2, -1.9, c.H + 0.55), (-3.6, -1.35, c.H + 0.545)]
    for i in range(3):
        c.TUBE(f"branch{i}", pts[i], pts[i + 1], 0.075 - i * 0.017, c.M_WOOD, 6)
    c.TUBE("branch_fork", (-5.2, -2.6, c.H + 0.56), (-4.6, -3.5, c.H + 0.54), 0.03, c.M_WOOD, 5)


def decals(c):
    HX, HY = c.HX, c.HY
    D = c.DECAL
    D("stencil", (-3.9, -HY - 0.012, 2.1), 1.9, 1.58, "-y", c.D_STENCIL)
    D("sign_f", (3.4, -HY - 0.012, 1.7), 0.6, 0.8, "-y", c.D_WARN)
    for i, (x, h) in enumerate(((-2.2, 2.2), (2.3, 1.8), (5.0, 2.4))):
        D(f"streak_f{i}", (x, -HY - 0.012, 2.3), 1.0, h, "-y", c.D_STREAK)
    for i, (y, face, sx) in enumerate(((1.2, "+x", 1), (-2.9, "-x", -1), (3.0, "+x", 1))):
        D(f"streak_s{i}", (sx * (HX + 0.012), y, 2.2), 1.0, 2.0, face, c.D_STREAK)
    D("crack_f", (1.9, -HY - 0.012, 1.4), 0.5, 1.0, "-y", c.D_CRACK)
    D("crack_s", (-HX - 0.012, 1.3, 2.6), 0.4, 1.2, "-x", c.D_CRACK)
    D("crack_b", (2.2, HY + 0.012, 3.0), 0.5, 1.2, "+y", c.D_CRACK)
    D("haz_ramp", (0, -HY - 1.25, 0.03), 2.6, 0.22, "+z", c.D_HAZARD, up=(0, 1, 0))
    D("dust_front", (-2.6, -HY - 1.8, 0.012), 3.0, 2.2, "+z", c.D_DUST, up=(0, 1, 0))


# outdoor kit only (no terminals / furniture outside): (prop, x, y, yaw)
OUTDOOR = [("floodlight", 3.1, -8.1, -131), ("barrier_concrete", -3.3, -7.9, 12), ("barrier_concrete_broken", -5.6, -7.2, -24),
           ("drum_amber", 8.2, 1.4, 0), ("drum_amber", 8.0, 0.75, 50), ("crate_large", -8.2, -1.2, 25),
           ("crate_small", -8.1, -2.1, -10)]


def outdoor_kit(c):
    for i, (prop, x, y, yaw) in enumerate(OUTDOOR):
        L.empty(f"marker_kit_{prop}__{50 + i}", (x, y, 0.0)).rotation_euler = (0, 0, math.radians(yaw))
