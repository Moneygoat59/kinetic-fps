"""Rail tunnel kit: the company's underground line (single track, amber powered, no trains running). Obsidian concrete
lining with segment rings, a slab track, the amber conductor rail glowing faintly in its glass channel, the amber main and
its sight glass on the left wall, cable racks and a handrail over the raised walkway (cess) on the right, the radio feeder
along the crown, dead caged lamps. Dark: the light comes from the emergency pylons (rail_props.py) and the amber.
Geometry is shared (tunnel_lib.py); sizes in kit_dims.py. Every piece runs along local +Y (Godot -Z) from its origin (entry
face, tunnel centre, invert level) and carries marker_next at its exit: chain them with TunnelLine (Godot).
tunnel_straight   8 m.
tunnel_curve_l/r  TUN_CURVE_DEG left / right on radius TUN_CURVE_R (30.9 m): each advances exactly 8 m along its entry
                  heading (and 1.05 m aside), so a wiggle r,l,l,r is 32 m on and back on line.
tunnel_refuge     8 m with a refuge niche in the right wall at walkway level (marker_refuge: where an emergency_pylon stands,
                  facing the track) and steel steps up from the track to the walkway in front of it.
tunnel_vent       8 m with a duct opening high in the right wall over the walkway (marker_vent: place a duct_mouth there;
                  VentDuct's CLIMB OUT lowers the walker onto the walkway below).
tunnel_bulkhead   2 m portal frame between sections (narrowed opening, hazard jambs, section stencil on both faces).
tunnel_collapse   8 m dead end: the crown has come down 3 m in; a rubble slope to the roof, rock through the hole, the
                  rails and the conductor buried, the main snapped and bleeding amber. No marker_next.
"""
import math
import random

import ps1_lib as L
from kit_dims import DUCT_H, DUCT_T, DUCT_W, GAUGE, MAIN_R, MAIN_X, MAIN_Z, POWER_X, REFUGE_D, REFUGE_H, REFUGE_W, TRACK_X, \
    TUN_BULK_LEN, TUN_CROWN, TUN_CURVE_DEG, TUN_CURVE_R, TUN_HW, TUN_LINING, TUN_SPRING, VENT_Y, VENT_Z, WALK_X0, WALK_Z
from kit_lib import jitter_verts
from tunnel_lib import TunnelKit, TunnelPath, arch, arch_z, empty_at, grime, lining_col, next_marker, ribs, services, shell, \
    sweep, track

SUBDIV, AO_DIST = 0.6, 0.9


def _segment(name, turn=0.0, stencil=True):
    k = TunnelKit(name)
    p = TunnelPath(turn, TUN_CURVE_R * math.radians(abs(turn))) if turn else TunnelPath()
    lining_col(k, shell(k, p))
    ribs(k, p)
    track(k, p)
    services(k, p, glass=5.0)
    grime(k, p, seed=len(name))
    if stencil:
        k.DECAL("line", tuple(p.at(2.6, -TUN_HW + 0.006, 2.35)), 1.3, 0.65, k.D_LINE, facing="+x")
    next_marker(k, p)
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


def tunnel_straight():
    _segment("tunnel_straight")


def tunnel_curve_l():
    _segment("tunnel_curve_l", -TUN_CURVE_DEG, False)


def tunnel_curve_r():
    _segment("tunnel_curve_r", TUN_CURVE_DEG, False)


def _box(k, name, x0, x1, y0, y1, z0, z1, mat, col=True):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    k.B(name, size, loc, mat)
    if col:
        k.COL(size, loc)


def tunnel_refuge():
    k = TunnelKit("tunnel_refuge")
    p = TunnelPath()
    c, hw, t = 4.0, REFUGE_W / 2, 0.25
    x0, x1, z0, z1 = TUN_HW - 0.1, TUN_HW + REFUGE_D, WALK_Z, WALK_Z + REFUGE_H
    lin = shell(k, p)
    L.cut(lin, L.fast_box("cut_refuge", (x1 - x0 + 0.1, REFUGE_W, z1 - z0 + 0.02), ((x0 + x1) / 2, c, (z0 + z1) / 2 + 0.01)))
    lining_col(k, lin)
    _box(k, "niche_floor", TUN_HW - 0.02, x1 + t, c - hw - t, c + hw + t, z0 - 0.4, z0, k.CON_T)
    _box(k, "niche_back", x1, x1 + t, c - hw - t, c + hw + t, z0, z1 + t, k.CON)
    _box(k, "niche_top", TUN_HW, x1 + t, c - hw - t, c + hw + t, z1, z1 + t, k.CON)
    for s in (-1, 1):
        y = c + s * (hw + t / 2)
        _box(k, f"niche_side{s}", TUN_HW + TUN_LINING - 0.02, x1, y - t / 2, y + t / 2, z0, z1, k.CON)
        _box(k, f"paint_jamb{s}", TUN_HW - 0.012, TUN_HW + 0.002, c + s * (hw + 0.06) - 0.06, c + s * (hw + 0.06) + 0.06, z0, z1,
             k.VIOLET, col=False)
    xh = (TUN_HW ** 2 - (z1 + 0.12 - TUN_SPRING) ** 2) ** 0.5            # the arch face over the niche head
    _box(k, "paint_head", xh - 0.03, xh - 0.015, c - hw - 0.12, c + hw + 0.12, z1, z1 + 0.12, k.VIOLET, col=False)
    sy, sz = c + hw + 0.95, 1.4                                            # sign plate on stand-offs, clear of the rib
    k.B("sign_plate", (0.02, 1.24, 0.44), (TUN_HW - 0.1, sy, sz), k.VIOLET)
    for dy in (-0.45, 0.45):
        k.B(f"sign_stand{dy}", (0.09, 0.04, 0.04), (TUN_HW - 0.05, sy + dy, sz), k.RUST)
    k.DECAL("refuge_sign", (TUN_HW - 0.111, sy, sz), 1.2, 0.415, k.D_REFUGE, facing="-x")        # arrow points at the niche
    for i, (h, back) in enumerate(((WALK_Z / 3, 0.99), (2 * WALK_Z / 3, 0.66), (WALK_Z, 0.33))):   # steps up from the track bed
        _box(k, f"step{i}", WALK_X0 - back, WALK_X0 - back + 0.33, c - 0.6, c + 0.6, 0.0, h, k.PLATE, col=False)
    k.cols.append(L.prism("step_ramp", [(WALK_X0 - 1.32, 0.0), (WALK_X0 + 0.01, 0.0), (WALK_X0 + 0.01, WALK_Z)], 1.2,
                          (0.0, c - 0.6, 0.0)))                          # walked as a ramp (the walker has no step-up)
    k.TUBE("step_post", (WALK_X0 - 0.2, c - 0.75, WALK_Z), (WALK_X0 - 0.2, c - 0.75, WALK_Z + 1.0), 0.025, k.RUST, 6)
    k.DECAL("niche_dust", ((TUN_HW + x1) / 2, c, z0 + 0.004), REFUGE_D, REFUGE_W - 0.1, k.D_DUST, facing="+z")
    ribs(k, p, skip=[(c - hw - 0.3, c + hw + 0.3)])
    track(k, p)
    services(k, p, right_skip=[(c - hw - 0.15, c + hw + 0.15)], glass=6.4)
    grime(k, p, seed=3)
    empty_at(k, "marker_refuge", (x1 - 0.32, c, z0), -90.0)
    next_marker(k, p)
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


def tunnel_vent():
    k = TunnelKit("tunnel_vent")
    p = TunnelPath()
    hw = DUCT_W / 2 + DUCT_T + 0.03
    lin = shell(k, p)
    L.cut(lin, L.fast_box("cut_vent", (TUN_LINING + 0.6, 2 * hw, DUCT_H + 2 * DUCT_T + 0.06),
                          (TUN_HW + TUN_LINING / 2, VENT_Y, VENT_Z + DUCT_H / 2)))
    lining_col(k, lin)
    ribs(k, p, skip=[(VENT_Y - 1.0, VENT_Y + 1.0)])
    track(k, p)
    services(k, p, right_skip=[(VENT_Y - hw - 0.25, VENT_Y + hw + 0.25)], glass=1.6)
    grime(k, p, seed=5)
    k.DECAL("vent_streak", (TUN_HW - 0.008, VENT_Y + 0.2, VENT_Z - 0.75), 1.2, 1.4, k.D_STREAK, facing="-x")
    k.DECAL("vent_dust", ((WALK_X0 + TUN_HW) / 2, VENT_Y, WALK_Z + 0.006), TUN_HW - WALK_X0, 1.6, k.D_PAPERS, facing="+z")
    k.DECAL("line", tuple(p.at(2.6, -TUN_HW + 0.006, 2.35)), 1.3, 0.65, k.D_LINE, facing="+x")
    empty_at(k, "marker_vent", (TUN_HW, VENT_Y, VENT_Z), -90.0)
    next_marker(k, p)
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


def tunnel_bulkhead():
    k = TunnelKit("tunnel_bulkhead")
    p = TunnelPath(0.0, TUN_BULK_LEN)
    lining_col(k, shell(k, p))
    ox0, ox1, oz, ch = -2.35, TUN_HW - 0.3, 4.3, 0.5                       # the narrowed opening (walkway still passes)
    opening = [(ox1, 0.0), (ox1, oz - ch), (ox1 - ch, oz), (ox0 + ch, oz), (ox0, oz - ch), (ox0, 0.0)]
    s0, s1 = 0.55, 1.45
    portal = sweep("portal", arch(-0.03) + opening, p, s0, s1, k.CON_B)
    k.parts.append(portal)
    k.COL_COPY(portal)
    for s, face in ((s0 - 0.006, "-y"), (s1 + 0.006, "+y")):
        k.DECAL(f"section{s}", (0.18, s, oz + 0.62), 1.9, 0.66, k.D_SECTION, facing=face)
        for x in (ox0 - 0.2, ox1 + 0.15):
            k.DECAL(f"haz{s}{x}", (x, s, 2.2), 0.24, 3.0, k.D_HAZARD, facing=face)
        for i, x in enumerate((ox0 - 0.05, ox1 + 0.05)):                   # steel edging round the opening
            k.B(f"edge{s}{i}", (0.1, 0.06, oz - ch), (x, s, (oz - ch) / 2), k.MET_D)
        k.B(f"edge_top{s}", (ox1 - ox0 - 2 * ch, 0.06, 0.1), ((ox0 + ox1) / 2, s, oz + 0.05), k.MET_D)
    ribs(k, p)
    track(k, p)
    services(k, p, right_skip=[(s0 - 0.05, s1 + 0.05)])
    next_marker(k, p)
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


def _mound(k, rng, s0, s1, nx=16, ns=18):
    """The rubble slope: a height field across the bore from s0 (toe) to s1, rising to the roof, noisy."""
    import bmesh
    bm = bmesh.new()
    rows = []
    for j in range(ns + 1):
        s = s0 + (s1 - s0) * j / ns
        u = min(1.0, (s - s0) / 3.8)
        row = []
        for i in range(nx + 1):
            x = -TUN_HW + 0.02 + (2 * TUN_HW - 0.04) * i / nx
            h = TUN_CROWN * (u * u * (3 - 2 * u)) + rng.uniform(-0.35, 0.45) * (0.4 + u)
            h = max(0.02 if j else 0.0, min(h, arch_z(x) - 0.04 if abs(x) < TUN_HW - 0.03 else TUN_SPRING))
            row.append(bm.verts.new((x, s, h)))
        rows.append(row)
    for a, b in zip(rows, rows[1:]):
        for i in range(nx):
            bm.faces.new((a[i], a[i + 1], b[i + 1], b[i]))
    o = L._bm_object("mound", bm, k.ROCK)
    k.parts.append(o)
    k.COL_COPY(o)


def tunnel_collapse():
    k = TunnelKit("tunnel_collapse")
    p = TunnelPath()
    rng = random.Random(41)
    lin = shell(k, p)
    hole = L.fast_box("cut_crown", (3.4, 5.0, 2.4), (0.2, 6.3, TUN_CROWN + 0.2))
    jitter_verts(hole, 0.35, 7)
    L.cut(lin, hole)
    lining_col(k, lin)
    rock = L.fast_box("rock", (4.6, 5.0, 2.2), (0.2, 6.2, TUN_CROWN + 0.9), k.ROCK)
    L.jitter(rock, 0.3, 8)
    k.parts.append(rock)
    _mound(k, rng, 2.6, 8.0)
    for i in range(16):                                                    # lining slabs (still curved: ribbed faces) on the slope
        s = rng.uniform(2.9, 6.6)
        x = rng.uniform(-2.5, 2.5)
        u = min(1.0, (s - 2.6) / 3.8)
        z = TUN_CROWN * u * u * (3 - 2 * u) * 0.9
        slab = k.B(f"slab{i}", (rng.uniform(0.7, 1.6), rng.uniform(0.5, 1.1), rng.uniform(0.2, 0.36)), (x, s, z), k.CON,
                   rot=(rng.uniform(-50, 50), rng.uniform(-40, 40), rng.uniform(0, 180)))
        jitter_verts(slab, 0.06, i)
    for i in range(14):                                                    # loose lumps run out over the track
        s = rng.uniform(1.4, 3.4)
        x = rng.uniform(-2.2, 1.6)
        r = rng.uniform(0.08, 0.26) * (1.3 if s > 2.6 else 1.0)
        lump = k.B(f"lump{i}", (r * 2, r * 1.7, r * 1.4), (x, s, r * 0.5), k.CON if i % 3 else k.ROCK,
                   rot=(rng.uniform(0, 40), rng.uniform(0, 40), rng.uniform(0, 180)))
        jitter_verts(lump, r * 0.25, 40 + i)
    for i in range(6):                                                     # rebar out of the torn crown
        a = rng.uniform(-1.3, 1.5)
        z0 = arch_z(a) - 0.05
        k.TUBE(f"rebar{i}", (a, 3.9 + rng.uniform(0, 0.3), z0), (a + rng.uniform(-0.3, 0.3), 3.5, z0 - rng.uniform(0.6, 1.3)),
               0.014, k.RUST, 4)
    ribs(k, p, s1=2.5)
    track(k, p, 0.0, 3.2)
    for side in (-1, 1):                                                   # a rail torn up out of the rubble
        x = TRACK_X + side * GAUGE / 2
        k.TUBE(f"rail_bent{side}", (x, 3.2, 0.13), (x + side * 0.3, 4.3, 0.9 + 0.3 * side), 0.04, k.MET, 4)
    services(k, p, 0.0, 3.0, glass=None)
    k.PIPE("main_stub", [(MAIN_X, 3.0, MAIN_Z), (MAIN_X + 0.25, 3.5, MAIN_Z - 0.5)], MAIN_R, k.MET_D, verts=10)
    k.DECAL("main_drips", (-TUN_HW + 0.006, 3.2, MAIN_Z - 0.8), 0.7, 1.4, k.D_DRIPS, facing="+x")
    k.POOL("main_pool", (MAIN_X + 0.4, 3.1, 0.012), 1.5, 1.2)
    k.POOL("rail_pool", (POWER_X + 0.1, 3.0, 0.014), 0.9, 0.7)
    k.DECAL("crust", (POWER_X + 0.4, 2.6, 0.016), 1.4, 1.2, k.D_CRUST, facing="+z")
    grime(k, p, 0.0, 3.0, seed=9)
    k.DECAL("crack", (-TUN_HW + 0.006, 2.2, 3.1), 1.6, 1.6, k.D_CRACK, facing="+x")
    k.LIGHT("marker_light_amber", (MAIN_X + 0.6, 3.1, 0.4))
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


PROPS = {f.__name__: f for f in (tunnel_straight, tunnel_curve_l, tunnel_curve_r, tunnel_refuge, tunnel_vent, tunnel_bulkhead,
                                 tunnel_collapse)}
