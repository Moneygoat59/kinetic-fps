"""Missile Silo 00 surface. Called by missile_silo.py as build(c) (`c` = namespace of its helpers, materials, dimensions).
Apron ring (R..RA) at walk level, a parapet lip round the bore (gap at the front for the stair bridge, a smashed stretch
where petal 5 went in), and the cap: six hinge plinths with knuckles; five petals stand blown open (a 46 m slab each,
leaning out past vertical, braced by two rams), the sixth tore off and hangs in the bore (silo_bore.fallen_petal).
Petal frame (petal_matrix): hinge along local X, the slab runs along local +Y (toward the centre when closed),
thickness along local Z (+Z = armour face, outward once open; -Z = ribbed underside that faced the launch).
"""
import math

from mathutils import Matrix, Vector

import ps1_lib as L

PL, PT = 46.0, 3.6                    # petal length (hinge to tip), thickness
PW0, PW1 = 26.0, 4.0                  # petal half-width at the hinge / at the tip
RH, ZH = 60.5, 5.6                    # hinge axis radius and height above TOP
FALLEN = 240.0                        # the slot whose petal tore off
# (slot angle deg, opening angle deg: 90 = vertical, > 90 leans outward)
PETALS = [(-60.0, 104.0), (0.0, 113.0), (60.0, 98.0), (120.0, 108.0), (180.0, 116.0)]
BROKEN_LIP = (232.0, 248.0)


def build(c):
    apron(c)
    lip(c)
    for slot in [p[0] for p in PETALS] + [FALLEN]:
        plinth(c, slot, slot == FALLEN)
    for k, (slot, alpha) in enumerate(PETALS):
        m = petal_matrix(c, slot, alpha)
        petal(c, f"petal{k}", m, c.surf)
        rams(c, k, slot, m)
        L.empty(f"marker_light_beacon_{k}", tuple(m @ Vector((0.0, PL - 2.0, PT / 2 + 1.0))))
    scars(c)


def petal_matrix(c, slot, alpha, pivot=None, roll=0.0):
    p = Vector(pivot) if pivot else Vector(c.polar(RH, slot, c.TOP + ZH))
    return (Matrix.Translation(p) @ Matrix.Rotation(math.radians(slot + 90.0), 4, "Z")
            @ Matrix.Rotation(math.radians(alpha), 4, "X") @ Matrix.Rotation(math.radians(roll), 4, "Y"))


def _hw(y):
    return PW0 + (PW1 - PW0) * (y - 1.2) / (PL - 1.2)


def petal(c, name, m, into):
    """One cap petal built in its local frame, then moved by matrix m. Parts go to `into` (surface or bore)."""
    objs = [L.vprism(f"{name}_slab", [(-PW0, 1.2), (PW0, 1.2), (PW1, PL), (-PW1, PL)], -PT / 2, PT / 2, c.M_CON)]
    zb = -PT / 2 - 0.8
    objs.append(L.fast_box(f"{name}_rib_c", (1.4, PL - 4.0, 1.6), (0, PL / 2, zb), c.M_MET_D))
    for s in (-1, 1):
        objs.append(L.fast_box(f"{name}_rib{s}", (1.2, 25.0, 1.6), (s * 12.0, 14.5, zb), c.M_MET_D))
    for y in (8.0, 18.0, 28.0, 38.0):
        objs.append(L.fast_box(f"{name}_x{y}", (2 * _hw(y) - 2.0, 1.0, 1.4), (0, y, zb + 0.1), c.M_RUST))
    for y in (12.0, 24.0, 36.0):
        objs.append(L.fast_box(f"{name}_seam{y}", (2 * _hw(y) - 1.0, 0.5, 0.25), (0, y, PT / 2 + 0.1), c.M_MET_D))
    for x in (-16.5, 0.0, 16.5):
        objs.append(L.fast_cylinder(f"{name}_kn{x}", 2.4, 7.0, (x, 0, 0), c.M_MET, 12, (0, 90, 0)))
    objs.append(L.fast_box(f"{name}_lens", (1.6, 1.0, 0.7), (0, PL - 2.0, PT / 2 + 0.35), c.M_BEACON))
    objs.append(L.fast_box(f"{name}_lens_cage", (2.2, 1.6, 0.25), (0, PL - 2.0, PT / 2 + 0.72), c.M_MET_D))
    dec = [L.quad(f"{name}_stencil", (0, 20.0, PT / 2 + 0.04), 16.0, 24.0, "+z", c.D_STENCIL, up=(0, 1, 0))]
    for i, (y, h) in enumerate(((9.0, 14.0), (22.0, 12.0), (33.0, 10.0))):   # launch soot on the underside, inside the outline
        dec.append(L.quad(f"{name}_soot{i}", (0, y, -PT / 2 - 0.03 - i * 0.004), 2 * _hw(y + h / 2) - 1.0, h, "-z", c.D_SOOT,
                          up=(0, -1, 0)))
    for o in objs + dec:
        o.matrix_world = m @ o.matrix_world
    into.extend(objs)
    (c.dec_in if into is c.bore else c.dec_out).extend(dec)
    return objs


def rams(c, k, slot, m):
    """Two rams per petal: anchor block on the apron, barrel, rod up to the armour face."""
    base = Matrix.Translation(Vector(c.polar(RH, slot, c.TOP))) @ Matrix.Rotation(math.radians(slot + 90.0), 4, "Z")
    for s in (-1, 1):
        a = base @ Vector((s * 12.0, -14.0, 0.0))
        c.B(f"ram_block{k}{s}", (4.0, 4.0, 2.4), (a.x, a.y, a.z + 1.2), c.M_CON_T, 0.35, (0, 0, slot))
        c.ACOL(f"ram_block{k}{s}_c", math.hypot(a.x, a.y), math.degrees(math.atan2(a.y, a.x)), (4.0, 4.0, 2.4), a.z + 1.2)
        p0 = a + Vector((0, 0, 2.0))
        p1 = m @ Vector((s * 12.0, 16.0, PT / 2))
        mid = p0.lerp(p1, 0.56)
        c.TUBE(f"ram_barrel{k}{s}", p0, mid, 1.1, c.M_RUST, 10)
        c.TUBE(f"ram_rod{k}{s}", p0.lerp(p1, 0.5), p1, 0.55, c.M_MET, 8)
        c.TUBE(f"ram_collar{k}{s}", p0.lerp(p1, 0.54), p0.lerp(p1, 0.58), 1.3, c.M_MET_D, 10)


def apron(c):
    c.ring("apron", c.R, c.RA, [-6.0, c.TOP], 0, 360, 96, c.M_CON_T, sub=5.0)
    c.ring("apron_skirt", c.RA, c.RA + 4.0, [-6.0, c.TOP], 0, 360, 96, c.M_CON_T, top_out=-0.8)   # meets the terrain past the hole
    c.ring("apron_c", c.R, c.RA, [-6.0, c.TOP], 0, 360, 96, c.M_CON_T, into=c.cols)
    c.ring("apron_skirt_c", c.RA, c.RA + 4.0, [-6.0, c.TOP], 0, 360, 96, c.M_CON_T, into=c.cols, top_out=-0.8)
    for k in range(48):                    # expansion joints: dark seams radiating out, one every 7.5 deg
        a = k * 7.5 + 3.75
        c.ABOX(f"joint{k}", (c.R + c.RA) / 2 + 0.6, a, (0.25, c.RA - c.R - 2.0, 0.04), c.TOP + 0.005, c.M_SOOT)


def lip(c):
    f0, f1 = c.FRONT + c.GAP, c.FRONT + 360.0 - c.GAP
    b0, b1 = BROKEN_LIP
    for i, (a0, a1) in enumerate(((f0, b0), (b1, f1))):
        c.ring(f"lip{i}", c.R, c.R + 1.2, [c.TOP, c.TOP + c.LIP], a0, a1, max(4, int((a1 - a0) / 3)), c.M_CON, sub=4.0)
    c.ring("lip_c", c.R, c.R + 1.2, [c.TOP, c.TOP + c.LIP + 0.2], f0, f1, 120, c.M_CON, into=c.cols)
    import random
    rng = random.Random(5)
    for i in range(9):                     # the broken stretch: lip blocks shoved onto the apron
        a = rng.uniform(b0 + 1.0, b1 - 1.0)
        c.ABOX(f"lip_chunk{i}", c.R + rng.uniform(2.0, 9.0), a, (rng.uniform(1.5, 3.2), 1.2, c.LIP),
               c.TOP + 0.4, c.M_CON, c=0.1, tilt=rng.uniform(-25, 25))
    for end, sgn in ((b0, 1.0), (b1, -1.0)):   # rebar sticking out of the torn ends into the gap
        t = Vector((-math.sin(math.radians(end)), math.cos(math.radians(end)), 0.0)) * sgn
        for j in range(4):
            p = Vector(c.polar(c.R + 0.25 + j * 0.25, end, c.TOP + 0.3 + j * 0.28))
            c.TUBE(f"rebar{int(end)}_{j}", p, p + t * (0.8 + 0.3 * j) + Vector((0, 0, 0.35 - 0.2 * j)), 0.04, c.M_RUST, 4)

def plinth(c, slot, broken):
    k = int(slot) % 360
    c.ABOX(f"plinth{k}", RH + 0.5, slot, (46.0, 7.0, 4.6), c.TOP + 2.3, c.M_CON, c=0.5)
    c.ABOX(f"plinth{k}_top", RH + 1.2, slot, (40.0, 4.6, 1.2), c.TOP + 5.2, c.M_CON_T, c=0.3)
    c.ACOL(f"plinth{k}_c", RH + 0.5, slot, (46.0, 7.0, 7.0), c.TOP + 3.5)
    base = Matrix.Translation(Vector(c.polar(RH, slot, c.TOP + ZH))) @ Matrix.Rotation(math.radians(slot + 90.0), 4, "Z")
    for i, x in enumerate((-24.0, -8.25, 8.25, 24.0)):
        if broken and i in (1, 2):
            continue
        p = base @ Vector((x, 0, 0))
        length = 3.2 if broken else 6.5
        c.CYL(f"knuckle{k}_{i}", 2.4, length, tuple(p), c.M_MET, v=12, rot=(0, 90, slot + 90.0))
    for s in (-1, 1):                      # stepped buttresses behind the plinth ends
        a = slot + s * math.degrees(21.0 / 70.0)
        for j, (r, h) in enumerate(((66.3, 4.4), (69.8, 2.9), (73.3, 1.4))):
            c.ABOX(f"butt{k}{s}{j}", r, a, (3.0, 3.5, h), c.TOP + h / 2, c.M_CON, c=0.25)
        c.ACOL(f"butt{k}{s}_c", 69.8, a, (3.0, 10.5, 4.4), c.TOP + 2.2)
    if not broken:
        c.ABOX(f"alarm{k}", RH + 1.2, slot, (1.4, 1.4, 0.9), c.TOP + 6.25, c.M_BEACON)
        c.ABOX(f"alarm{k}_cage", RH + 1.2, slot, (1.8, 1.8, 0.2), c.TOP + 6.8, c.M_MET_D)
        L.empty(f"marker_light_alarm_{k}", c.polar(RH + 1.2, slot, c.TOP + 7.4))


def scars(c):
    """Launch soot fanning out over the apron from the lip, plus the painted SILO 00 by the stair head."""
    for k in range(18):
        a = k * 20.0 + 7.0
        if abs(((a - c.FRONT + 180) % 360) - 180) < 12:
            continue
        p = c.polar(c.R + 8.5, a, c.TOP + 0.02 + (k % 3) * 0.004)
        c.DECAL(f"apron_soot{k}", p, 12.0, 17.0, "+z", c.D_SOOT, up=c.polar(1.0, a))
    c.DECAL("apron_stencil", c.polar(67.0, c.FRONT - 9.0, c.TOP + 0.03), 9.0, 13.5, "+z", c.D_STENCIL, up=c.polar(1.0, c.FRONT + 180.0))
