"""Missile Silo 00 generators. Called by missile_silo.py as build(c) after silo_hall (it uses c.FL, c.CEIL and the hall's
centre line). What the amber was piped down here for: three brutalist obsidian machines, 23 m tall, standing in a row
down the hall. Each one: a stepped octagonal plinth, a lower body cut with glowing glyph slits, a waist of amber behind
glass, a crown flaring out to an open amber pool, eight buttress fins that rise past the crown as leaning blades, and
power ducts clamping it to both walls. A conduit hung from the ceiling beams carries the silo main along the hall and
pours an amber stream into every crown. The machines go into c.gen (node silo_gen: no baked AO, the fins stand on the
body's corners and would black it out; the floods shape it instead). Glowing amber that should flow (glass, pools, streams, conduit glasses) goes into
c.gen_liquid (node silo_gen_liquid, world UVs, material silo_gen_amber: SiloGenerators scrolls it); the slits use
silo_glow_gen (SiloGenerators throbs it). Four work floods on each plinth step uplight it (marker_uplight_*:
SiloGenerators, amber). Markers: marker_gen_<i> (hum), marker_light_gen_<i> (waist, shadowed: the fins
throw their shadows round the hall), marker_light_gen_gap_<k> (low over the floor channel between the machines).
"""
import math

from mathutils import Vector

import ps1_lib as L
import silo_hall as HALL
import silo_tower as TOWER

GENS = (-131.0, -145.0, -159.0)          # angles along the hall centre line (HALL.RM)
CONZ = 4.0                               # conduit centre: this far under the ceiling
CON_R = 1.0
# body profiles (height above the floor, radius): plinth steps + lower body; crown flaring out to the pool recess. The
# waist between them is only glass, so the core light inside it shines out between the fins.
BODY = [(0.0, 6.2), (1.0, 6.2), (1.0, 5.5), (2.0, 5.5), (2.0, 4.2), (9.0, 4.2), (9.0, 0.0)]
CROWN = [(12.5, 3.2), (20.8, 5.5), (20.8, 4.7), (20.2, 4.7), (20.2, 0.0)]
BODY_COL = [(0.0, 6.2), (1.0, 6.2), (1.0, 5.5), (2.0, 5.5), (2.0, 6.2), (4.5, 6.2), (11.5, 4.6), (16.0, 4.6), (20.8, 6.1),
            (20.8, 0.0)]
# buttress fin stations (height, inner r, outer r, thickness): out over the plinth, in at the waist, out as a blade
FIN = [(2.0, 3.6, 6.1, 0.9), (4.5, 3.6, 6.1, 0.9), (11.5, 3.6, 4.5, 0.8), (16.0, 3.6, 4.5, 0.8), (20.0, 3.6, 5.9, 0.8),
       (20.8, 3.6, 6.04, 0.75), (20.85, 5.2, 6.05, 0.75), (23.5, 6.1, 6.5, 0.35)]
WAIST = (9.0, 12.5, 2.8)                 # glass: z0, z1, radius
POOL_Z = 20.25
GLYPH_BARS = ((3.4,), (6.1, 7.4), (4.2, 6.8), (7.4,), (3.4, 5.2), (6.1,), (4.6, 7.4), (5.6,))   # crossbar heights per face
HANGERS = (-124.0, -138.0, -152.0, -160.5)                   # portal beams, then one from the ceiling near the cap
CHANNEL = (-121.0, HALL.A1 + 2.2, 0.45)  # floor channel the spent amber runs down: from, to (deg), half width
GAPS = (-124.0, -138.0, -152.0, -165.0)  # low lights over the channel between the machines (and at both ends)
LEDGE = (5.85, 1.0)                      # plinth step the uplights stand on: radius, height (BODY 5.5..6.2 at z 1)


def build(c):
    c.LQ_GEN = L.screen_material("silo_gen_amber", c.T("liquid_flow.png"), 1.7)
    c.M_GEN = L.tex_material("silo_glow_gen", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.32, 0.03), emission_strength=1.8)
    for i, a in enumerate(GENS):
        generator(c, f"gen{i}", Vector(c.polar(HALL.RM, a, c.FL)), a)
        L.empty(f"marker_gen_{i}", c.polar(HALL.RM, a, c.FL + 6.0))
        L.empty(f"marker_light_gen_{i}", c.polar(HALL.RM, a, c.FL + (WAIST[0] + WAIST[1]) / 2))
        L.empty(f"marker_light_gen_pool_{i}", c.polar(HALL.RM, a, c.FL + POOL_Z + 2.0))
    conduit(c)
    channel(c)


def lathe(name, o, profile, rot, mat, sides=8, closed=False, cap=True):
    """Solid of revolution with `sides` flat faces: profile = [(height above o, radius)], corners at rot + k * 360 / sides.
    Open profiles start at the bottom cap (cap=False: an open tube) and may end on the axis (radius 0); closed profiles
    are a ring (bands)."""
    verts, faces = [], []
    rows = []
    for z, r in profile:
        if r <= 0.0:
            rows.append([len(verts)])
            verts.append((o.x, o.y, o.z + z))
            continue
        row = []
        for k in range(sides):
            t = math.radians(rot + k * 360.0 / sides)
            row.append(len(verts))
            verts.append((o.x + r * math.cos(t), o.y + r * math.sin(t), o.z + z))
        rows.append(row)
    pairs = list(zip(rows, rows[1:])) + ([(rows[-1], rows[0])] if closed else [])
    for a, b in pairs:
        for k in range(sides):
            j = (k + 1) % sides
            if len(b) == 1:
                faces.append((a[k], a[j], b[0]))
            elif len(a) == 1:
                faces.append((a[0], b[j], b[k]))
            else:
                faces.append((a[k], a[j], b[j], b[k]))
    if cap and not closed and len(rows[0]) > 1:
        faces.append(tuple(reversed(rows[0])))
    return _mesh(name, verts, faces, mat)


def _mesh(name, verts, faces, mat):
    import bmesh
    import bpy
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    obj = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(obj)
    if mat is not None:
        me.materials.append(mat)
    return obj


def fin(name, o, ang, mat):
    """Buttress fin on the radial line at `ang` (deg): FIN stations lofted, each a (inner, outer) x thickness slice."""
    d = Vector((math.cos(math.radians(ang)), math.sin(math.radians(ang)), 0.0))
    s = Vector((-d.y, d.x, 0.0))
    verts, faces = [], []
    for z, r0, r1, t in FIN:
        for r, side in ((r0, -1), (r1, -1), (r1, 1), (r0, 1)):
            p = o + d * r + s * (side * t / 2) + Vector((0, 0, z))
            verts.append(tuple(p))
    for i in range(len(FIN) - 1):
        a, b = 4 * i, 4 * (i + 1)
        for k in range(4):
            j = (k + 1) % 4
            faces.append((a + k, a + j, b + j, b + k))
    faces.append((0, 1, 2, 3))
    n = 4 * (len(FIN) - 1)
    faces.append((n + 3, n + 2, n + 1, n))
    return _mesh(name, verts, faces, mat)


def generator(c, name, o, a):
    rot = a                                                   # corners (and fins) on the radial line and every 45 deg
    for part, profile in (("body", BODY), ("crown", CROWN)):
        c.gen.append(lathe(f"{name}_{part}", o, profile, rot, c.M_CON))
    c.cols.append(lathe(f"{name}_c", o, BODY_COL, rot, None))
    z0, z1, rw = WAIST
    c.gen_liquid.append(lathe(f"{name}_glass", o, [(z0, rw), (z1, rw)], rot + 11.25, c.LQ_GEN, sides=16, cap=False))
    c.gen_liquid.append(lathe(f"{name}_pool", o, [(POOL_Z - 0.1, 4.68), (POOL_Z, 4.68), (POOL_Z, 0.0)], rot, c.LQ_GEN))
    for z in (z0, (z0 + z1) / 2, z1 - 0.3):                   # steel bands round the glass
        c.gen.append(lathe(f"{name}_band{z}", o, [(z, 2.78), (z, 2.98), (z + 0.3, 2.98), (z + 0.3, 2.78)], rot + 11.25,
                            c.M_MET_D, sides=16, closed=True))
    for k in range(8):
        t = rot + k * 45.0
        c.gen.append(fin(f"{name}_fin{k}", o, t, c.M_CON))
        c.B(f"{name}_mull{k}", (0.22, 0.22, z1 - z0), tuple(o + Vector(c.polar(2.9, t + 22.5, (z0 + z1) / 2))), c.M_MET_D,
            rot=(0, 0, t + 22.5), into=c.gen)
        glyph(c, f"{name}_glyph{k}", o, t + 22.5, k)
    for s, reach in ((1, HALL.RO - HALL.RM), (-1, HALL.RM - HALL.RI)):     # power ducts clamp it to both walls
        for dz in (13.2, 15.0):
            p0 = o + Vector(c.polar(4.2 * s, a, dz))
            p1 = o + Vector(c.polar((reach + 0.2) * s, a, dz))
            c.B(f"{name}_duct{s}{dz}", ((p1 - p0).length, 1.1, 1.1), tuple((p0 + p1) / 2), c.M_MET_D, 0.05, (0, 0, a), into=c.gen)
            c.B(f"{name}_clamp{s}{dz}", (1.2, 1.6, 1.6), tuple(p1 - (p1 - p0).normalized() * 0.6), c.M_RUST_D, 0.05, (0, 0, a),
                into=c.gen)
    for k in range(4):                                        # floods on the plinth step graze up the faces between fins
        t = rot + 22.5 + k * 90.0
        r, z = LEDGE
        TOWER.flood(c, f"{name}_{k}", tuple(o + Vector(c.polar(r, t, z + 0.4))), tuple(o + Vector(c.polar(1.5, t, 12.0))),
                    into=c.hall, prefix="marker_uplight_")
    streaks(c, name, o, rot)


def glyph(c, name, o, t, k):
    """Glowing slit on a lower-body face (t = face centre angle): a tall stroke and one or two crossbars, never the same."""
    face = 4.2 * math.cos(math.radians(22.5))
    c.B(f"{name}_v", (0.24, 0.16, 5.4), tuple(o + Vector(c.polar(face, t, 5.4))), c.M_GEN, rot=(0, 0, t - 90), into=c.gen)
    for n, z in enumerate(GLYPH_BARS[k]):
        off = 0.35 if (k + n) % 2 else -0.35
        c.B(f"{name}_h{n}", (0.7, 0.16, 0.16), tuple(o + Vector(c.polar(face, t, z)) + Vector(c.polar(off, t - 90))),
            c.M_GEN, rot=(0, 0, t - 90), into=c.gen)


def streaks(c, name, o, rot):
    """Dried amber run down three crown faces from the pool lip."""
    z0, z1, r0, r1 = 12.5, 20.8, 3.2, 5.5
    slope = (r1 - r0) / (z1 - z0)
    for k in (1, 4, 6):
        t = rot + 22.5 + k * 45.0
        out = Vector(c.polar(1.0, t))
        n = (out - Vector((0, 0, slope))).normalized()
        up = (out * slope + Vector((0, 0, 1))).normalized()
        zc = z1 - 2.6
        r = (r0 + slope * (zc - z0)) * math.cos(math.radians(22.5))
        c.DECAL(f"{name}_crust{k}", tuple(o + out * r + Vector((0, 0, zc)) + n * 0.03), 2.2, 5.0, tuple(n), c.D_CRUST, tuple(up), into=c.hall_dec)


def conduit(c):
    """The silo main along the hall: out of the stair end wall under the ceiling, hung from every portal beam, a drop and
    a nozzle over each generator, capped past the last one."""
    z = c.CEIL - CONZ
    a_end = GENS[-1] - 3.0
    steps = int(abs(a_end - HALL.A0) / 2.5)
    pts = [Vector(c.polar(HALL.RM, HALL.A0 + 1.5 + (a_end - HALL.A0 - 1.5) * i / steps, z)) for i in range(steps + 1)]
    for i in range(steps):
        c.TUBE(f"con{i}", pts[i], pts[i + 1], CON_R, c.M_MET_D, 8, into=c.hall)
        c.TUBE(f"con_collar{i}", pts[i] - (pts[i + 1] - pts[i]).normalized() * 0.25,
               pts[i] + (pts[i + 1] - pts[i]).normalized() * 0.25, CON_R * 1.2, c.M_RUST_D, 8, into=c.hall)
        if i % 3 == 1:
            mid, d = (pts[i] + pts[i + 1]) / 2, (pts[i + 1] - pts[i]).normalized()
            c.gen_liquid.append(L.fast_tube(f"con_glass{i}", mid - d * 0.7, mid + d * 0.7, CON_R * 1.06, c.LQ_GEN, 8))
    c.CYL("con_cap", CON_R * 1.3, 0.6, tuple(pts[-1]), c.M_RUST_D, "z", 8, into=c.hall, rot=(90, 0, a_end))
    mouth = Vector(c.polar(HALL.RM, HALL.A0 + 0.2, z))
    c.CYL("con_mouth", CON_R * 1.6, 1.2, tuple(mouth), c.M_CON_T, "z", 8, into=c.hall, rot=(90, 0, HALL.A0))
    for a in HANGERS:
        p = Vector(c.polar(HALL.RM, a, z))
        roof = c.CEIL - (2.6 if a in HALL.PORTALS else 0.0)
        for s in (-1.15, 1.15):
            q = p + Vector(c.polar(s, a, -CON_R - 0.2))
            c.TUBE(f"con_hang{a}{s}", q, Vector((q.x, q.y, roof)), 0.12, c.M_RUST, 5, into=c.hall)
        c.B(f"con_saddle{a}", (0.5, 2.6, 0.4), tuple(p - Vector((0, 0, CON_R + 0.2))), c.M_RUST, rot=(0, 0, a - 90), into=c.hall)
    for i, a in enumerate(GENS):
        top = Vector(c.polar(HALL.RM, a, z - CON_R))
        c.B(f"drop_valve{i}", (1.8, 1.8, 1.4), tuple(top - Vector((0, 0, 0.5))), c.M_MET_D, 0.1, (0, 0, a), into=c.hall)
        c.CYL(f"drop_wheel{i}", 0.7, 0.12, tuple(top + Vector(c.polar(1.0, a - 90, -0.5))), c.M_RUST, "z", 10, into=c.hall,
              rot=(90, 0, a))
        c.TUBE(f"drop_pipe{i}", top - Vector((0, 0, 1.2)), top - Vector((0, 0, 2.6)), 0.6, c.M_MET_D, 8, into=c.hall)
        c.TUBE(f"drop_bell{i}", top - Vector((0, 0, 2.6)), top - Vector((0, 0, 3.1)), 0.85, c.M_RUST_D, 8, into=c.hall)
        pool = Vector(c.polar(HALL.RM, a, c.FL + POOL_Z))
        c.gen_liquid.append(L.fast_tube(f"stream{i}", pool, top - Vector((0, 0, 3.0)), 0.42, c.LQ_GEN, 10))
        c.gen_liquid.append(L.fast_tube(f"splash{i}", pool, pool + Vector((0, 0, 0.25)), 1.1, c.LQ_GEN, 12))


def channel(c):
    """Spent amber runs out of every plinth along a kerbed floor channel down the hall to a grated drain at the far end."""
    a0, a1, hw = CHANNEL
    fl = c.FL
    c.ring("channel", HALL.RM - hw, HALL.RM + hw, [fl - 0.05, fl + 0.02], a1, a0, 40, c.LQ_GEN, into=c.gen_liquid)
    for s in (-1, 1):
        r = HALL.RM + s * (hw + 0.12)
        c.ring(f"channel_kerb{s}", r - 0.12, r + 0.12, [fl, fl + 0.1], a1, a0, 40, c.M_MET_D, into=c.hall)
    drain = Vector(c.polar(HALL.RM, a1 - 0.6, fl))
    c.B("drain_grate", (2.4, 2.4, 0.1), tuple(drain + Vector((0, 0, 0.05))), c.M_PLATE, rot=(0, 0, a1), into=c.hall)
    c.B("drain_kerb", (2.8, 2.8, 0.08), tuple(drain + Vector((0, 0, 0.03))), c.M_MET_D, rot=(0, 0, a1), into=c.hall)
    c.DECAL("drain_crust", tuple(drain + Vector((0, 0, 0.12))), 3.2, 3.2, "+z", c.D_CRUST, into=c.hall_dec)
    for k, a in enumerate(GAPS):
        L.empty(f"marker_light_gen_gap_{k}", c.polar(HALL.RM, a, fl + 1.2))
