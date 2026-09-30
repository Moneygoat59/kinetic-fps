"""Missile Silo 00 bore. Called by missile_silo.py as build(c). Everything here goes into silo_bore (AbyssFog at runtime:
it fades to black with depth, so from the rim the shaft reads bottomless; its floor, c.FLOOR, is silo_pit.py's). The lining
is a 3 m obsidian shell (R..RL); the upper part (c.lining, cut by silo_room.py for the level 09 door and window) and its
foot on the floor are dense for vertex AO, the deep part between is coarse (silo_pit.py cuts its tunnel through it).
Seven launch guide rails, ring girders every ~22 m, launch soot up the walls, three amber mains (the silo main from the hub)
running over the lip and down to the floor with sight glasses every 5 m, two service arms (one folded, one torn and
hanging) and the petal that tore off, jammed head-down against the wall.
"""
import math

from mathutils import Vector

import ps1_ao as AO
import ps1_lib as L
import silo_rim as RIM

TOWER_ZONE = (-107.0, -84.0)        # no girders / rails / soot where the stair tower stands
RAILS = (0.0, 45.0, 90.0, 135.0, 180.0, -135.0, -45.0)
GIRDERS = (-10.0, -28.0, -50.0, -72.0, -94.0, -116.0)
MAINS = (-77.0, -80.0, -83.0)
MAIN_LIFT = 6.0                    # the mains end this far over the bore floor and pour out there (silo_pit.py)


PIT_ZONE = (-131.0, -114.0)         # no girder at the pit stair's head (silo_pit.py: the tunnel comes out under it)
PIT_GIRDER = -116.0


def _in_tower(a):
    a = (a + 180.0) % 360.0 - 180.0
    return TOWER_ZONE[0] <= a <= TOWER_ZONE[1]


def _in_pit(a, z):
    a = (a + 180.0) % 360.0 - 180.0
    return z == PIT_GIRDER and PIT_ZONE[0] <= a <= PIT_ZONE[1]


def build(c):
    c.lining = c.ring("lining_upper", c.R, c.RL, [-60.0, -52.0, -44.0, -38.0, -31.0, -24.0, -18.0, -12.0, -6.0], 0, 360, 96,
                      c.M_BASALT, into=c.bore, sub=3.5)
    c.ring("lining_foot", c.R, c.RL, [c.FLOOR, c.FLOOR + 4.0, c.FLOOR + 8.0], 0, 360, 96, c.M_BASALT, into=c.bore, sub=3.5)
    c.ring("lining_lower", c.R, c.RL, [c.FLOOR + 8.0, -110.0, -80.0, -60.0], 0, 360, 64, c.M_BASALT, into=c.bore)
    girders(c)
    rails(c)
    soot(c)
    mains(c)
    arm(c, "arm_a", Vector(c.polar(c.R - 3.2, -62.0, -22.0)), Vector(c.polar(c.R - 3.2, -34.0, -22.0)), 1.2)
    top = Vector(c.polar(c.R - 3.2, -128.0, -12.0))
    arm(c, "arm_b", top, top + Vector(c.polar(4.0, -128.0 + 180.0, -30.0)), 1.2, torn=True)
    fallen_petal(c)


def girders(c):
    seg = 360.0 / 64
    for z in GIRDERS:
        for i in range(64):
            a = i * seg
            if _in_tower(a) or _in_pit(a, z):
                continue
            c.ABOX(f"gird{int(z)}_{i}", c.R - 0.6, a, (2 * math.pi * c.R / 64 - 0.1, 1.2, 0.9), z, c.M_MET_D, into=c.bore)
            if i % 2 == 0:
                c.ABOX(f"gbr{int(z)}_{i}", c.R - 0.45, a, (0.4, 0.9, 1.6), z - 1.2, c.M_RUST, into=c.bore)


def rails(c):
    for a in RAILS:
        k = int(a) % 360
        h = c.TOP + 0.8 - c.FLOOR
        zc = c.FLOOR + h / 2
        c.ABOX(f"rail_web{k}", c.R - 0.8, a, (0.5, 1.6, h), zc, c.M_MET_D, into=c.bore)
        c.ABOX(f"rail_flange{k}", c.R - 1.75, a, (2.6, 0.35, h), zc, c.M_MET, into=c.bore)
        c.ABOX(f"rail_cap{k}", c.R - 0.9, a, (3.2, 2.2, 0.8), c.TOP + 0.4, c.M_RUST, into=c.bore)
        for z in range(-6, -130, -12):      # rail shoes bolted through the lining
            c.ABOX(f"rail_shoe{k}_{z}", c.R - 0.35, a, (3.4, 0.7, 1.0), z, c.M_RUST_D, into=c.bore)
        c.DECAL(f"rail_soot{k}", c.polar(c.R - 1.95, a, -22.0), 3.0, 40.0, c.polar(1.0, a + 180.0), c.D_SOOT, inside=True)


def soot(c):
    for k in range(22):
        a = k * (360.0 / 22) + 4.0
        if _in_tower(a) or _in_tower(a - 8) or _in_tower(a + 8):
            continue
        h = 34.0 + (k % 3) * 6.0
        c.DECAL(f"wall_soot{k}", c.polar(c.R - 0.03, a, -6.0 - h / 2), 15.0, h, c.polar(1.0, a + 180.0), c.D_SOOT, inside=True)
        if k % 2 == 0:
            c.DECAL(f"wall_streak{k}", c.polar(c.R - 0.05, a + 5.0, -14.0), 6.0, 12.0, c.polar(1.0, a + 185.0), c.D_STREAK, inside=True)


def mains(c):
    """The silo main: three pipes rise out of a valve pit on the apron, cross the lip and drop into the bore."""
    pit = c.polar(71.0, MAINS[1], c.TOP + 0.4)
    c.B("main_pit", (8.0, 5.0, 0.8), pit, c.M_CON_T, 0.15, (0, 0, MAINS[1] - 90.0))
    c.B("main_pit_grate", (6.4, 3.6, 0.06), (pit[0], pit[1], c.TOP + 0.82), c.M_PLATE, rot=(0, 0, MAINS[1] - 90.0))
    c.ACOL("main_pit_c", 71.0, MAINS[1], (8.0, 5.0, 0.8), c.TOP + 0.4)
    sign = Vector(c.polar(73.55, MAINS[1], c.TOP + 0.45))
    c.DECAL("main_sign", tuple(sign), 1.2, 0.72, c.polar(1.0, MAINS[1]), c.D_SIGN)
    for i, a in enumerate(MAINS):
        z = c.TOP + 1.0
        pts = [c.polar(71.0, a, c.TOP + 0.5), c.polar(71.0, a, z), c.polar(c.R + 2.0, a, z), c.polar(c.R + 2.0, a, c.TOP + 2.3),
               c.polar(c.R - 1.0, a, c.TOP + 2.3), c.polar(c.R - 1.0, a, c.FLOOR + MAIN_LIFT)]
        c.bore.extend(AO.pipe(f"main{i}", pts, 0.5, c.M_MET_D, 8, 0.0, c.M_MET))
        for r in (64.0, 68.0):
            c.liquids.append(L.fast_cylinder(f"main{i}_glass{r}", 0.58, 1.0, c.polar(r, a, z), c.LQ_FLOW, 10, (0, 90, a)))
            c.ABOX(f"main{i}_sleeper{r}", r + 1.5, a, (1.6, 0.5, z - c.TOP - 0.2), (z + c.TOP) / 2 - 0.2, c.M_RUST)
        for n, zz in enumerate(range(-3, int(c.FLOOR + MAIN_LIFT), -5)):
            c.liquids.append(L.fast_cylinder(f"main{i}_g{n}", 0.58, 1.0, c.polar(c.R - 1.0, a, zz - 0.5 * i), c.LQ_FLOW, 10))
            if n % 2 == 0:
                c.ABOX(f"main{i}_br{n}", c.R - 0.5, a, (0.3, 1.0, 0.3), zz - 2.5, c.M_RUST, into=c.bore)


def arm(c, name, p0, p1, h, torn=False):
    """Service (umbilical) arm: square box truss from a hinge block at p0 to p1, 2h wide."""
    d = (p1 - p0).normalized()
    side = d.cross(Vector((0, 0, 1)))
    side = side.normalized() if side.length > 0.1 else Vector((1, 0, 0))
    up = side.cross(d).normalized()
    corners = [side * sx * h + up * sy * h for sx, sy in ((1, 1), (-1, 1), (-1, -1), (1, -1))]
    n = int((p1 - p0).length / 3.0)
    for k, o in enumerate(corners):
        c.TUBE(f"{name}_chord{k}", p0 + o, p1 + o, 0.16, c.M_RUST, 6, into=c.bore)
    for j in range(n):
        a, b = p0 + d * (j * 3.0), p0 + d * ((j + 1) * 3.0)
        for k in range(4):
            o0, o1 = corners[k], corners[(k + 1) % 4]
            c.TUBE(f"{name}_br{j}_{k}", a + (o0 if j % 2 else o1), b + (o1 if j % 2 else o0), 0.07, c.M_MET_D, 4, into=c.bore)
    wall = Vector((p0.x, p0.y, 0)).normalized()
    c.B(f"{name}_hinge", (3.0, 3.0, 5.0), tuple(p0 + wall * 1.5), c.M_MET_D, 0.2, (0, 0, math.degrees(math.atan2(wall.y, wall.x)) - 90), into=c.bore)
    if torn:                                # frayed end: bent chords and dangling cables
        for k, o in enumerate(corners[:2]):
            c.TUBE(f"{name}_bent{k}", p1 + o, p1 + o + d * 2.0 + side * (1.5 - 3 * k), 0.14, c.M_RUST, 6, into=c.bore)
        for k in range(3):
            c.TUBE(f"{name}_cable{k}", p1 + corners[k], p1 + corners[k] + Vector((0.3 * k, 0.2, -6.0 - 3 * k)), 0.05, c.M_CABLE, 4, into=c.bore)
    else:
        c.B(f"{name}_plate", (2.8, 1.0, 2.8), tuple(p1), c.M_MET, 0.1, (0, 0, math.degrees(math.atan2(d.y, d.x))), into=c.bore)
        for k in range(4):                  # umbilical hoses sagging back to the wall
            q = p0 + d * (4.0 + k * 6.0) - up * h
            c.TUBE(f"{name}_hose{k}", q, q + wall * 2.4 - up * 2.5, 0.12, c.M_CABLE, 5, into=c.bore)


def fallen_petal(c):
    """Petal 5 (slot RIM.FALLEN) tore off its hinge and slid in: jammed head-down, ribs against the lining."""
    m = RIM.petal_matrix(c, -148.0, -72.0, pivot=c.polar(52.0, -148.0, -20.0), roll=10.0)
    RIM.petal(c, "fallen", m, c.bore)
    L.empty("marker_light_fallen", tuple(m @ Vector((0.0, RIM.PL - 2.0, RIM.PT / 2 + 1.0))))
