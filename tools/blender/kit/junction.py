"""Rail tunnel kit: tunnel_junction, the interchange where lines meet. A round hall (wall JUNC_HALL_R, elliptic dome with an
oculus) with four tunnel mouths north / east / south / west. Each mouth is a short throat of tunnel lining out to its mouth
plane at JUNC_R from the centre, framed on the hall side by a heavy portal (LINE 00 // INTERCHANGE), with walkway ramps down
to the hall floor on both sides (a tunnel's walkway is on its right, whichever way it was laid) and trackwork from both
track positions converging on the turntable. In the middle: the turntable pit (a ramped edge, so the walker can walk in and
out) with its bridge left standing askew, the amber feed glowing in the floor round the pit. Dead lamps hang from the dome.
Every mouth is closed by default by a concrete plug, an optional part: TunnelNetwork drops opt_seal_<k> (bunker_kit.gd
drop_part) where a tunnel connects. Markers: marker_mouth_<k> (k 0..3 = N, E, S, W; mouth plane, turned so a tunnel piece
placed on it runs outward), marker_pylon_<k> (on the diagonals by the wall, facing the centre: an emergency pylon each).
Origin = hall centre at floor level. Blender +Y = Godot -Z = north.
"""
import math

import bmesh
import bpy

import ps1_lib as L
from kit_dims import JUNC_DOME_H, JUNC_HALL_R, JUNC_PIT_D, JUNC_PIT_R, JUNC_R, JUNC_WALL_H, POWER_X, TUN_CROWN, TUN_HW, \
    TUN_LINING, WALK_X0, WALK_Z
from tunnel_lib import TunnelKit, TunnelPath, arch, band, empty_at, rect, sweep

SEGS = 48
T = 0.5                      # hall shell thickness
BRIDGE_YAW = 22.0            # the turntable left where it stopped


def lathe(name, prof, mat, a0=0.0, a1=360.0, segs=SEGS):
    """Solid of revolution about Z: prof = closed polygon [(r, z), ...] (r > 0), swept from a0 to a1 degrees."""
    full = abs(a1 - a0) >= 359.9
    n = segs if full else max(2, int(segs * abs(a1 - a0) / 360.0))
    bm = bmesh.new()
    rings = []
    for i in range(n if full else n + 1):
        a = math.radians(a0 + (a1 - a0) * i / n)
        rings.append([bm.verts.new((r * math.cos(a), r * math.sin(a), z)) for r, z in prof])
    pairs = list(zip(rings, rings[1:])) + ([(rings[-1], rings[0])] if full else [])
    m = len(prof)
    for ra, rb in pairs:
        for j in range(m):
            bm.faces.new((ra[j], ra[(j + 1) % m], rb[(j + 1) % m], rb[j]))
    if not full:
        bm.faces.new(rings[0])
        bm.faces.new(list(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return L._bm_object(name, bm, mat)


def _shell_profile():
    inner = [(JUNC_HALL_R, -0.02), (JUNC_HALL_R, JUNC_WALL_H)]
    outer = []
    for i in range(1, 13):
        a = math.radians(90.0 * i / 12)
        inner.append((max(0.3, JUNC_HALL_R * math.cos(a)), JUNC_WALL_H + JUNC_DOME_H * math.sin(a)))
        outer.append((max(0.3, (JUNC_HALL_R + T) * math.cos(a)), JUNC_WALL_H + (JUNC_DOME_H + T) * math.sin(a)))
    outer = [(JUNC_HALL_R + T, -0.02), (JUNC_HALL_R + T, JUNC_WALL_H)] + outer
    return inner + list(reversed(outer))


def _lists(k):
    return [k.parts, k.cols, k.decals] + [lst for n in k.opts for lst in k.opts[n]]


def _marks(k):
    """Snapshot of how full every list of the kit is (by list identity: optional parts may be added in between)."""
    return {id(lst): len(lst) for lst in _lists(k)}


def _new(k, marks):
    """Everything added to the kit's lists since `marks`."""
    return [o for lst in _lists(k) for o in lst[marks.get(id(lst), 0):]]


def _turn(objs, deg):
    """Rotate placed objects about the hall centre. Refresh first: rotate_about reads matrix_world, which Blender only
    updates on a view layer update (a new cutter's location or a tube's tilt would be lost)."""
    bpy.context.view_layer.update()
    L.rotate_about(objs, (0, 0, 0), (0, 0, deg))


def _strip(k, name, a, b, mat, w=0.07, h=0.12, z=0.06):
    """A strip on the floor from a to b (x, y): a rail head, a glowing feed."""
    dx, dy = b[0] - a[0], b[1] - a[1]
    k.B(name, (w, math.hypot(dx, dy), h), ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, z), mat,
        rot=(0, 0, -math.degrees(math.atan2(dx, dy))))


def _rail(k, name, a, b):
    _strip(k, name, a, b, k.MET)


def _mouth(k, i):
    """One mouth built facing north (throat along +Y), then turned to its compass point."""
    marks = _marks(k)
    p = TunnelPath(0.0, JUNC_R)
    s0 = JUNC_HALL_R - 0.9
    lin = sweep(f"throat{i}", band(0.0, -TUN_LINING), p, s0, JUNC_R, k.CON)
    slab = sweep(f"throat_slab{i}", rect(-TUN_HW - TUN_LINING, TUN_HW + TUN_LINING, -0.5, 0.0), p, s0, JUNC_R, k.CON_T)
    portal = sweep(f"portal{i}", band(-0.02, -0.95), p, s0 - 0.35, s0 + 0.1, k.CON_B)
    k.parts += [lin, slab, portal]
    for o in (lin, slab, portal):
        k.COL_COPY(o)
    k.DECAL(f"portal_sign{i}", (0.0, s0 - 0.36, TUN_CROWN + 0.42), 1.9, 0.5, k.D_JUNC, facing="-y")
    for side in (-1, 1):                                            # walkway ramps down to the hall floor, both sides
        x0, x1 = sorted((side * WALK_X0, side * (TUN_HW + 0.02)))
        ramp = L.ramp(f"ramp{i}{side}", x0, x1, JUNC_R - 2.0, JUNC_R, -0.01, 0.0, WALK_Z, k.CON_T)
        k.parts.append(ramp)
        k.COL_COPY(ramp)
        fx = side * -POWER_X                                         # amber feeds in the floor, clear of the sleepers
        _strip(k, f"feed{i}{side}", (fx, JUNC_R - 0.1), (fx, JUNC_PIT_R + 0.7), k.RAIL_GLOW, 0.06, 0.02, 0.012)
        _strip(k, f"feed_in{i}{side}", (fx, JUNC_PIT_R + 0.7), (side * 1.3, JUNC_PIT_R + 0.14), k.RAIL_GLOW, 0.06, 0.02, 0.012)
    y_join, y_end = 7.4, JUNC_PIT_R + 0.15
    for off in (-0.6, 0.6):                                          # trackwork from either track position onto the table
        for g in (-0.7175, 0.7175):
            _rail(k, f"rail{i}{off}{g}", (off + g, JUNC_R), (g, y_join))
    for g in (-0.7175, 0.7175):
        _rail(k, f"rail{i}{g}", (g, y_join), (g, y_end))
    y = y_end + 0.3
    while y < JUNC_R - 0.2:
        k.B(f"sleeper{i}_{y:.1f}", (3.2 if y > y_join else 2.5, 0.24, 0.1), (0.0, y, -0.01), k.CON_B)
        y += 0.65
    seal = k.OPT(f"seal_{i}")
    seal.append(sweep(f"plug{i}", arch(-0.02), p, JUNC_R - 0.45, JUNC_R - 0.05, k.CON_B))
    for z in (0.9, 1.5):
        seal.append(L.box(f"plug_band{i}{z}", (5.6, 0.02, 0.22), (0.0, JUNC_R - 0.46, z), k.HAZ))
    k.OPT_COL(f"seal_{i}", (2 * TUN_HW, 0.4, TUN_CROWN), (0.0, JUNC_R - 0.25, TUN_CROWN / 2))
    _turn(_new(k, marks), -90.0 * i)
    a = math.radians(90.0 - 90.0 * i)
    empty_at(k, f"marker_mouth_{i}", (JUNC_R * math.cos(a), JUNC_R * math.sin(a), 0.0), -90.0 * i)


def _turntable(k):
    k.CYL("pit_floor", JUNC_PIT_R + 0.1, 0.2, (0, 0, -JUNC_PIT_D - 0.1), k.CON_T, v=SEGS)
    k.COL_CYL(JUNC_PIT_R + 0.1, 0.2, (0, 0, -JUNC_PIT_D - 0.1), v=24)
    k.cols.append(lathe("pit_ramp", [(JUNC_PIT_R + 0.02, 0.0), (JUNC_PIT_R - 0.75, -JUNC_PIT_D), (JUNC_PIT_R + 0.02, -JUNC_PIT_D)], None))
    k.parts.append(lathe("pit_rail", [(JUNC_PIT_R - 0.3, -JUNC_PIT_D), (JUNC_PIT_R - 0.2, -JUNC_PIT_D), (JUNC_PIT_R - 0.2, -JUNC_PIT_D + 0.1),
                                      (JUNC_PIT_R - 0.3, -JUNC_PIT_D + 0.1)], k.MET))
    k.parts.append(lathe("feed_ring", [(JUNC_PIT_R + 0.25, -0.02), (JUNC_PIT_R + 0.31, -0.02), (JUNC_PIT_R + 0.31, 0.012),
                                       (JUNC_PIT_R + 0.25, 0.012)], k.RAIL_GLOW))
    k.CYL("pivot", 0.45, 0.3, (0, 0, -JUNC_PIT_D + 0.1), k.MET_D, v=12)
    span = 2 * JUNC_PIT_R - 0.3
    bridge = _marks(k)
    k.B("deck", (2.4, span, 0.06), (0, 0, -0.03), k.PLATE)
    for s in (-1, 1):
        k.B(f"girder{s}", (0.14, span, 0.3), (s * 1.1, 0, -0.2), k.MET_D)
        k.B(f"carriage{s}", (2.6, 0.5, 0.25), (0, s * (span / 2 - 0.25), -JUNC_PIT_D + 0.22), k.RUST)
        for w in (-1, 1):
            k.CYL(f"wheel{s}{w}", 0.14, 0.12, (w * 0.9, s * (span / 2 - 0.25), -JUNC_PIT_D + 0.14), k.MET, "x", 10)
        k.B(f"deck_rail{s}", (0.07, span, 0.12), (s * 0.7175, 0, 0.06), k.MET)
    k.B("cab", (1.1, 1.3, 2.0), (1.95, span / 2 - 1.2, 1.0), k.MET_D, 0.03)
    k.B("cab_window", (0.02, 0.9, 0.5), (1.39, span / 2 - 1.2, 1.45), k.GLASS_DEAD)
    k.B("cab_roof", (1.3, 1.5, 0.08), (1.95, span / 2 - 1.2, 2.04), k.RUST)
    k.B("lever_stand", (0.25, 0.25, 1.0), (-0.9, -span / 2 + 0.9, 0.5), k.MET_D)
    k.TUBE("lever", (-0.9, -span / 2 + 0.9, 1.0), (-0.75, -span / 2 + 1.2, 1.55), 0.03, k.RUST, 6)
    k.COL((2.4, span, 0.3), (0, 0, -0.15))
    k.COL((1.1, 1.3, 2.0), (1.95, span / 2 - 1.2, 1.0))
    k.COL((0.25, 0.25, 1.0), (-0.9, -span / 2 + 0.9, 0.5))
    _turn(_new(k, bridge), BRIDGE_YAW)


def _dome(k):
    crown = JUNC_WALL_H + JUNC_DOME_H
    k.CYL("oculus_collar", 0.45, 0.4, (0, 0, crown - 0.1), k.MET_D, v=12)
    k.TUBE("chain", (0, 0, crown - 0.2), (0, 0, crown - 2.6), 0.03, k.RUST, 6)
    k.parts.append(lathe("lamp_ring", [(2.2, crown - 2.75), (2.35, crown - 2.75), (2.35, crown - 2.6), (2.2, crown - 2.6)], k.MET_D))
    for j in range(6):
        a = math.radians(60 * j + 15)
        x, y = 2.28 * math.cos(a), 2.28 * math.sin(a)
        k.B(f"lamp{j}", (0.3, 0.3, 0.16), (x, y, crown - 2.86), k.MET_D)
        k.B(f"lamp_glass{j}", (0.22, 0.22, 0.04), (x, y, crown - 2.95), k.GLASS_DEAD)
        k.TUBE(f"hanger{j}", (x, y, crown - 2.6), (0, 0, crown - 1.6), 0.01, k.CABLE, 4)
    for j in range(4):                                               # cable trays between the mouths
        k.parts.append(lathe(f"tray{j}", [(JUNC_HALL_R - 0.45, 3.5), (JUNC_HALL_R - 0.05, 3.5), (JUNC_HALL_R - 0.05, 3.56),
                                          (JUNC_HALL_R - 0.45, 3.56)], k.RUST, 90 * j + 22, 90 * j + 68, 24))
        for c in range(3):
            r = JUNC_HALL_R - 0.15 - 0.1 * c
            k.parts.append(lathe(f"tray_cable{j}{c}", [(r, 3.58), (r + 0.05, 3.58), (r + 0.05, 3.63), (r, 3.63)], k.CABLE,
                                 90 * j + 20, 90 * j + 70, 24))
        a = math.radians(90 * j + 45)
        empty_at(k, f"marker_pylon_{j}", ((JUNC_HALL_R - 0.4) * math.cos(a), (JUNC_HALL_R - 0.4) * math.sin(a), 0.0), 90 * j + 45 - 90)
        for side in (-1, 1):
            b = math.radians(90 * j + 45 + side * 14)
            k.DECAL(f"streak{j}{side}", ((JUNC_HALL_R - 0.03) * math.cos(b), (JUNC_HALL_R - 0.03) * math.sin(b), 2.6), 1.6, 3.0,
                    k.D_STREAK, facing=(-math.cos(b), -math.sin(b), 0.0))
        k.DECAL(f"dust{j}", (7.4 * math.cos(a), 7.4 * math.sin(a), 0.004), 2.4, 2.0, k.D_DUST, facing="+z")


def tunnel_junction():
    k = TunnelKit("tunnel_junction")
    shell = lathe("hall", _shell_profile(), k.CON)
    for i in range(4):
        cutter = L.prism(f"cut{i}", arch(-0.01), JUNC_R + 1.0 - (JUNC_HALL_R - 2.0), (0.0, JUNC_HALL_R - 2.0, 0.0))
        _turn([cutter], -90.0 * i)
        L.cut(shell, cutter)
    k.parts.append(shell)
    k.COL_COPY(shell)
    floor = lathe("floor", [(JUNC_PIT_R, -0.5), (JUNC_HALL_R + T, -0.5), (JUNC_HALL_R + T, 0.0), (JUNC_PIT_R, 0.0)], k.CON_T)
    k.parts.append(floor)
    k.COL_COPY(floor)
    for i in range(4):
        _mouth(k, i)
    _turntable(k)
    _dome(k)
    k.finish(subdiv=0.9, ao_dist=0.9)


PROPS = {"tunnel_junction": tunnel_junction}
