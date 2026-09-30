"""Missile Silo 00: the bore floor and the way down to it. Called by missile_silo.py as build(c) after silo_generator (it
opens the generator hall's inner wall). The floor is c.FLOOR, DEPTH (16 m) under the hall floor c.FL.
Walk: generator hall -> kit blast door in the hall's inner wall (angle PIT_A) -> a tunnel through the lining -> a
catwalk_2m bridge -> a switchback stair of walkway kit down the lining (FLIGHTS flights of 4 m, built like the stair
tower) -> the floor: the launch table (a stepped flame deflector, twelve hold-down clamps sprung open, two torn off),
the amber mains pouring into a pool at the wall, the stair tower's lost flights and landings lying where they fell,
rubble, soot.
Stair frame (pit_xy): u along the lining toward larger angles, v = radius. Landings at u 0 (near end, under the bridge)
and u 10 (far end), lanes A (v 53, by the wall) and B (v 51). Kit frames: landing front = local -Y, flight origin =
its foot, climbing along local +Y.
Markers: marker_kit_* (door, bridge, flights, landings, fallen pieces), marker_light_pit_* (SiloPit), marker_spot_pit_*
(SiloAmbience floods), marker_pit_door (hall floor in front of the door), marker_pit_floor (the stair foot).
"""
import math

from mathutils import Vector

import ps1_lib as L
import silo_bore as BORE
import silo_generator as GEN
import silo_tower as TOWER

PIT_A = -128.0                          # the door, tunnel and stair head (deg)
DEPTH = 16.0                            # hall floor down to the bore floor
FLIGHTS = 4
TUN_HW, TUN_H = 1.2, 2.8                # tunnel half width, height
LANE_A, LANE_B, VM = 53.0, 51.0, 52.0   # lane centres (A by the wall), landing centre line
VB, VF = 54.2, 49.8                     # wall-side / void-side column lines
U_NEAR, U_FAR = 0.0, 10.0               # landing centres
U_COLS = (-1.2, 5.0, 11.2)
DEFLECTOR = [(0.0, 24.0), (0.5, 24.0), (0.5, 22.5), (1.0, 22.5), (1.0, 19.0), (9.0, 3.5), (9.6, 0.0)]
CLAMP_R = 30.0
TORN = (4, 9)                           # clamps ripped off their bases by the launch
POOL_A = -80.0                          # where the three mains pour out (silo_bore.MAINS)


def pit_xy(u, v, z=0.0):
    a = math.radians(PIT_A)
    return (v * math.cos(a) - u * math.sin(a), v * math.sin(a) + u * math.cos(a), z)


def build(c):
    c.M_PIT_POOL = L.emissive_decal_material("silo_amber_pool", c.T("liquid_pool.png"), 1.2)   # pooled amber (glows)
    door(c)
    stair(c)
    frame(c)
    floor(c)
    launch_table(c)
    pool(c)
    wreckage(c)


def _pts(u0, u1, v0, v1):
    return [pit_xy(u, v)[:2] for u, v in ((u0, v0), (u1, v0), (u1, v1), (u0, v1))]


def slab(c, name, u0, u1, v0, v1, z0, z1, mat, into, col=True):
    """Box in the stair frame (u0..u1, v0..v1, z0..z1)."""
    into.append(L.vprism(name, _pts(u0, u1, v0, v1), z0, z1, mat))
    if col:
        c.cols.append(L.vprism(name + "_c", _pts(u0, u1, v0, v1), z0, z1, None))


def door(c):
    """Kit blast door on the hall face of the inner wall, a tunnel through wall, rock and lining, a lamp over it, a warning
    plate beside the door."""
    fl = c.FL
    for target in ("hall_wall_in", "hall_wall_in_c", "lining_lower"):
        L.cut(bpy_obj(target), L.vprism(f"cut_pit_{target}", _pts(-TUN_HW, TUN_HW, 55.4, 60.6), fl - 0.4, fl + TUN_H))
    slab(c, "pit_tun_floor", -TUN_HW, TUN_HW, 55.9, 59.2, fl - 0.25, fl, c.M_PLATE, c.hall)
    slab(c, "pit_tun_ceil", -TUN_HW - 0.3, TUN_HW + 0.3, 55.9, 60.0, fl + TUN_H, fl + TUN_H + 0.4, c.M_CON_T, c.hall, col=False)
    for s in (-1, 1):
        u0, u1 = (TUN_HW, TUN_HW + 0.3) if s > 0 else (-TUN_HW - 0.3, -TUN_HW)
        slab(c, f"pit_tun_wall{s}", u0, u1, 55.9, 60.0, fl, fl + TUN_H, c.M_CON, c.hall)
    slab(c, "pit_tun_lamp", -0.3, 0.3, 57.6, 57.9, fl + TUN_H - 0.12, fl + TUN_H, c.M_LAMP, c.hall, col=False)
    L.empty("marker_light_pit_tunnel", pit_xy(0.0, 57.75, fl + TUN_H - 0.4))
    c.empty("marker_kit_door_blast__pit", pit_xy(0.0, 60.25, fl), PIT_A + 90.0)
    L.empty("marker_pit_door", pit_xy(0.0, 62.0, fl))
    c.DECAL("pit_door_warning", pit_xy(3.2, 60.02, fl + 1.5), 0.64, 0.48, pit_xy(0.0, 1.0), c.D_WARN, into=c.hall_dec)
    c.DECAL("pit_tun_hazard", pit_xy(0.0, 56.3, fl + 0.01), 2.3, 0.4, "+z", c.D_HAZARD, up=pit_xy(1.0, 0.0), into=c.hall_dec)


def bpy_obj(name):
    import bpy
    return bpy.data.objects[name]


def stair(c):
    """Bridge from the tunnel mouth to the top landing's wall side, then FLIGHTS flights between the two landing ends."""
    fl = c.FL
    c.empty("marker_kit_catwalk_2m__pit_bridge", pit_xy(0.0, 55.0, fl), PIT_A - 90.0)
    for n in range(FLIGHTS):                                  # landings 0 .. FLIGHTS-1; the last flight lands on the floor
        near = n % 2 == 0
        flags = "__no_rail_right" if n == 0 else ""           # the bridge lands on landing 0's wall side (+X)
        c.empty(f"marker_kit_stair_landing__pit{n}{flags}", pit_xy(U_NEAR if near else U_FAR, VM, fl - n * c.LEVEL),
                PIT_A if near else PIT_A + 180.0)
    for n in range(1, FLIGHTS + 1):
        odd = n % 2 == 1                                      # odd: lane A, top at the near end; even: lane B
        foot = pit_xy(U_FAR - 1.0 if odd else U_NEAR + 1.0, LANE_A if odd else LANE_B, fl - n * c.LEVEL)
        c.empty(f"marker_kit_stair_flight__pit{n}", foot, PIT_A + 180.0 if odd else PIT_A)
    L.empty("marker_pit_floor", pit_xy(-2.5, VM, c.FLOOR))


def frame(c):
    """Columns from the floor to the bridge, beams under each landing level, ties to the lining, a lamp at each landing
    on the void-side end column, and a work flood hung off the far end aimed across the floor at the deflector."""
    fl, top = c.FL, c.FL + 3.0
    for u in U_COLS:
        for v in (VB, VF):
            c.B(f"pit_col{u}{v}", (0.4, 0.4, top - c.FLOOR), pit_xy(u, v, (top + c.FLOOR) / 2), c.M_MET_D, rot=(0, 0, PIT_A),
                into=c.bore)
    ulen = U_COLS[-1] - U_COLS[0]
    umid = (U_COLS[-1] + U_COLS[0]) / 2
    for n in range(FLIGHTS):
        z = fl - n * c.LEVEL - 0.3
        for v in (VB, VF):
            c.B(f"pit_beam{n}{v}", (0.3, ulen, 0.3), pit_xy(umid, v, z), c.M_RUST, rot=(0, 0, PIT_A), into=c.bore)
        for u in (U_COLS[0], U_COLS[-1]):
            c.B(f"pit_xbeam{n}{u}", (VB - VF, 0.3, 0.3), pit_xy(u, VM, z), c.M_RUST, rot=(0, 0, PIT_A), into=c.bore)
            c.B(f"pit_tie{n}{u}", (56.0 - VB + 0.4, 0.25, 0.25), pit_xy(u, (VB + 56.0) / 2, z - 0.5), c.M_RUST_D, rot=(0, 0, PIT_A),
                into=c.bore)
        for ua, ub in ((U_COLS[0], U_COLS[1]), (U_COLS[1], U_COLS[2])):
            zz = z - c.LEVEL
            c.TUBE(f"pit_brace{n}{ua}", pit_xy(ua, VF - 0.05, z), pit_xy(ub, VF - 0.05, zz), 0.07, c.M_MET_D, 4, into=c.bore)
            c.TUBE(f"pit_brace2{n}{ua}", pit_xy(ub, VF - 0.05, z), pit_xy(ua, VF - 0.05, zz), 0.07, c.M_MET_D, 4, into=c.bore)
        near = n % 2 == 0
        u = U_COLS[0] + 0.35 if near else U_COLS[-1] - 0.35
        z_l = fl - n * c.LEVEL
        c.B(f"pit_lamp{n}", (0.3, 0.22, 0.2), pit_xy(u, VF, z_l + 2.3), c.M_LAMP, rot=(0, 0, PIT_A), into=c.bore)
        c.B(f"pit_lamp{n}_cage", (0.4, 0.3, 0.06), pit_xy(u, VF, z_l + 2.45), c.M_MET_D, rot=(0, 0, PIT_A), into=c.bore)
        L.empty(f"marker_light_pit_stair_{n}", pit_xy(u, VF - 0.5, z_l + 2.1))
    TOWER.flood(c, "pit_floor", c.polar(34.0, -112.0, c.FLOOR + 2.2), c.polar(6.0, -100.0, c.FLOOR + 5.0), c.FLOOR,
                prefix="marker_spot_pit_", into=c.bore)          # on a tripod out on the floor, lighting the deflector


def floor(c):
    """The bore floor (the deflector covers its middle), a collision ring round the lining's foot, soot rayed out from
    the centre, dust along the wall."""
    z = c.FLOOR
    c.ring("pit_floor", 23.0, c.R + 0.5, [z - 1.0, z], 0.0, 360.0, 64, c.M_FLOOR, into=c.bore, sub=4.0)
    c.cols.append(L.fast_cylinder("pit_floor_c", c.R + 0.5, 1.0, (0, 0, z - 0.5), None, 32))
    c.ring("pit_wall_c", c.R, c.R + 1.0, [z, z + 6.0], 0.0, 360.0, 64, c.M_PLATE, into=c.cols)
    for k in range(12):
        a = k * 30.0 + 8.0
        c.DECAL(f"pit_soot{k}", c.polar(38.0, a, z + 0.01), 14.0, 30.0, "+z", c.D_SOOT, up=c.polar(1.0, a), inside=True)
    for k in range(10):
        a = k * 36.0 + 20.0
        c.DECAL(f"pit_dust{k}", c.polar(c.R - 3.0, a, z + 0.015), 8.0, 5.0, "+z", c.D_DUST, up=c.polar(1.0, a + 90.0), inside=True)


def launch_table(c):
    """The flame deflector (a stepped plinth rising to a cone, walkable), amber seeping out of its cracks and pooling at its
    foot, and the ring of hold-down clamps round it, their jaws flung open by what left; two were torn off and lie on
    the floor."""
    z = c.FLOOR
    o = Vector((0.0, 0.0, z))
    seep(c, z)
    c.bore.append(GEN.lathe("pit_deflector", o, DEFLECTOR[:5], 11.25, c.M_CON_T, sides=16))
    c.bore.append(GEN.lathe("pit_cone", o, DEFLECTOR[4:], 11.25, c.M_BASALT, sides=16, cap=False))
    c.cols.append(GEN.lathe("pit_deflector_c", o, DEFLECTOR, 11.25, None, sides=16))
    for k in range(8):
        a = k * 45.0 + 22.5
        c.DECAL(f"pit_cone_soot{k}", c.polar(11.0, a, z + 5.2), 6.0, 16.0, Vector(c.polar(0.46, a, 0.89)), c.D_SOOT,
                up=c.polar(-0.89, a, 0.46), inside=True)
    for k in range(12):
        a = k * 30.0 + 15.0
        torn = k in TORN
        base = c.ABOX(f"clamp{k}", CLAMP_R, a, (4.0, 6.0, 2.4 if torn else 3.0), z + (1.2 if torn else 1.5), c.M_CON, into=c.bore,
                      c=0.1)
        c.ACOL(f"clamp{k}_c", CLAMP_R, a, (4.0, 6.0, 3.0), z + 1.5)
        c.DECAL(f"clamp{k}_haz", c.polar(CLAMP_R - 3.02, a, z + 2.3), 3.6, 0.4, c.polar(-1.0, a), c.D_HAZARD, inside=True)
        if torn:
            L.jitter(base, 0.25, k)
            c.ABOX(f"clamp{k}_arm", CLAMP_R + 9.0, a + 6.0, (2.2, 7.0, 1.4), z + 0.7, c.M_MET_D, into=c.bore, c=0.08)
            c.ACOL(f"clamp{k}_arm_c", CLAMP_R + 9.0, a + 6.0, (2.2, 7.0, 1.4), z + 0.7)
            continue
        c.ABOX(f"clamp{k}_arm", CLAMP_R - 2.4, a, (2.2, 1.4, 7.0), z + 5.4, c.M_MET_D, into=c.bore, c=0.08, tilt=-50.0)
        c.CYL(f"clamp{k}_pin", 0.5, 2.6, c.polar(CLAMP_R - 2.2, a, z + 3.1), c.M_RUST, v=10, into=c.bore, rot=(90, 0, a))


SEEPS = (12.0, 71.0, 139.0, 196.0, 250.0, 318.0)       # angles of the cracks amber seeps down


def seep(c, z):
    """Glowing veins zigzagging down the cone from near its tip, each ending in a small glowing puddle at the plinth."""
    glow = L.tex_material("silo_glow_seep", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.3, 0.03), emission_strength=1.3)
    pool_mat = c.M_PIT_POOL
    r0, z0, r1, z1 = DEFLECTOR[5][1], DEFLECTOR[5][0], DEFLECTOR[4][1], DEFLECTOR[4][0]   # cone: near the tip .. its foot
    for k, a in enumerate(SEEPS):
        pts = []
        for j in range(7):
            t = j / 6.0
            r = r0 + 1.0 + (r1 - r0 - 1.2) * t
            h = z0 + (z1 - z0) * (r - r0) / (r1 - r0) + 0.06
            pts.append(Vector(c.polar(r, a + (1.8 if j % 2 else -1.4) * (0.4 + t), z + h)))
        for j in range(6):
            c.bore.append(L.fast_tube(f"pit_seep{k}_{j}", tuple(pts[j]), tuple(pts[j + 1]), 0.07, glow, 4))
        c.DECAL(f"pit_seep_pool{k}", c.polar(r1 + 1.6, a, z + DEFLECTOR[4][0] + 0.02), 3.2, 2.2, "+z", pool_mat, up=c.polar(1.0, a),
                inside=True)
    L.empty("marker_light_pit_cone", (0.0, 0.0, z + 11.5))


def pool(c):
    """The three mains end MAIN_LIFT over the floor (silo_bore.py) and pour: amber streams into a pool at the
    wall, crust crawling out from it toward the deflector."""
    z = c.FLOOR
    for i, a in enumerate((-77.0, -80.0, -83.0)):
        top = c.polar(c.R - 1.0, a, c.FLOOR + BORE.MAIN_LIFT - 0.2)
        c.liquids.append(L.fast_tube(f"pit_stream{i}", top, c.polar(c.R - 1.4, a, z), 0.22, c.LQ_FLOW, 8))
    pool_mat = c.M_PIT_POOL
    c.DECAL("pit_pool", c.polar(c.R - 4.0, POOL_A, z + 0.03), 11.0, 8.0, "+z", pool_mat, up=c.polar(1.0, POOL_A), inside=True)
    for k, (r, da, w, h) in enumerate(((c.R - 10.0, 3.0, 7.0, 5.0), (c.R - 16.0, -2.0, 6.0, 4.0), (c.R - 22.0, 4.0, 5.0, 3.5),
                                       (c.R - 4.5, 9.0, 4.0, 3.0))):
        c.DECAL(f"pit_crust{k}", c.polar(r, POOL_A + da, z + 0.02 + 0.002 * k), w, h, "+z", c.D_CRUST, up=c.polar(1.0, POOL_A + da),
                inside=True)
    L.empty("marker_light_pit_pool", c.polar(c.R - 5.0, POOL_A, z + 1.6))


# What fell from the stair tower (silo_tower MISSING_*): (kit piece, radius, angle, height over the floor, x tilt, y tilt, yaw)
FALLEN = [("stair_flight_broken", 45.0, -99.0, 0.9, 0.0, 78.0, 40.0), ("stair_landing", 41.0, -91.0, 0.45, 10.0, -6.0, 25.0),
          ("stair_flight_broken", 47.5, -86.0, 1.0, 180.0, -12.0, -70.0), ("stair_landing", 38.0, -104.0, 0.5, -8.0, 14.0, 120.0)]


def wreckage(c):
    for i, (piece, r, a, h, rx, ry, yaw) in enumerate(FALLEN):
        e = L.empty(f"marker_kit_{piece}__fallen{i}", c.polar(r, a, c.FLOOR + h))
        e.rotation_euler = (math.radians(rx), math.radians(ry), math.radians(a + yaw))
    for k in range(9):                                        # loose treads and bits of lining round the tower's foot
        a = -96.0 + (k - 4) * 3.1
        r = 43.0 + (k * 7 % 9)
        o = c.B(f"pit_tread{k}", (1.9, 0.4, 0.05), c.polar(r, a, c.FLOOR + 0.05), c.M_PLATE, rot=(0, (k * 23) % 30 - 15, a * 3.0),
                into=c.bore)
        L.jitter(o, 0.03, k)
    for k in range(14):
        a = -158.0 + k * 2.3 + (k % 3)
        s = 0.6 + (k * 5 % 7) * 0.25
        o = c.B(f"pit_rubble{k}", (s * 1.4, s, s * 0.8), c.polar(c.R - 1.2 - (k % 4) * 0.9, a, c.FLOOR + s * 0.35), c.M_BASALT,
                rot=(k * 17 % 40, k * 29 % 40, k * 41), into=c.bore)
        L.jitter(o, 0.12 * s, k)
