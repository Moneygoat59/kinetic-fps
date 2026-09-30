"""Soft and round shapes for the apartment kit (upholstery, bedding, porcelain, clock faces, curtains). Pure bmesh, baked at the
given location / rotation like ps1_lib's primitives. The kit smooth-shades them (AptKit.shade): Gouraud on the curves, hard
edges where faces meet at more than SMOOTH_ANGLE, the way PS1-era furniture was lit.
  soft_box   rounded box (edge radius r) on a fine grid, optional puff (a cushion's belly) along one axis
  disc       flat round face with the image mapped across it (clock dials)
  pleats     zig-zag hanging fabric (shower curtain, drapes)
  blob       organic lump (bin bags, heaped clothes, a bunched duvet, food, crumpled paper): a noise-displaced sphere
"""
import math

import bmesh
import bpy
from mathutils import Euler, Vector, noise

AXES = {"x": 0, "y": 1, "z": 2}


def _object(name, bm, mat, loc, rot):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    if mat:
        me.materials.append(mat)
    o.location = loc
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    return o


def _cuts(h, r, step):
    """Plane positions across one half-extent: denser through the rounded band so the curve reads."""
    ins = h - r
    pts = {ins, -ins, h - r * 0.35, -(h - r * 0.35)} if r > 1e-4 else set()
    n = max(1, int(2 * ins / step))
    pts |= {-ins + 2 * ins * i / n for i in range(1, n)}
    return sorted(p for p in pts if -h + 1e-4 < p < h - 1e-4)


def soft_box(name, size, loc, mat=None, r=0.04, puff=0.0, axis="+z", step=0.06, rot=(0, 0, 0)):
    """Rounded box `size` centred on `loc`. puff bulges the face(s) along axis ('+z', '-y', 'z' = both sides) by up to `puff`
    metres at the centre, falling to 0 at the edges (cushions, pillows, a duvet)."""
    h = [s / 2 for s in size]
    r = max(0.0, min(r, *[x * 0.98 for x in h]))
    if not puff:
        step = max(step, 0.3)            # flat spans need no grid; the rounded bands keep their own cuts
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    for a in range(3):
        for c in _cuts(h[a], r, step):
            co, no = [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]
            co[a], no[a] = c, 1.0
            geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
            bmesh.ops.bisect_plane(bm, geom=geom, plane_co=co, plane_no=no)
    inner = [x - r for x in h]
    ax = AXES[axis[-1]]
    sides = (1, -1) if axis[0] not in "+-" else ((1,) if axis[0] == "+" else (-1,))
    others = [i for i in range(3) if i != ax]
    for v in bm.verts:
        p = list(v.co)
        q = [max(-inner[i], min(inner[i], p[i])) for i in range(3)]
        d = Vector([p[i] - q[i] for i in range(3)])
        if d.length > 1e-6 and r > 0:
            p = [q[i] + d[i] / d.length * r for i in range(3)]
        if puff and any(p[ax] * s > 0 for s in sides):
            k = 1.0
            for i in others:
                k *= max(0.0, 1.0 - (p[i] / h[i]) ** 2)
            p[ax] += math.copysign(puff * k, p[ax])
        v.co = Vector(p)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _object(name, bm, mat, loc, rot)


def disc(name, center, r, mat, segs=32, uv=(0.0, 0.0, 1.0, 1.0)):
    """Round face in the x-z plane facing -y (a clock dial); uv = the image sub-rect mapped onto its bounding square."""
    bm = bmesh.new()
    lay = bm.loops.layers.uv.new("UVMap")
    verts = [bm.verts.new((r * math.cos(a), 0.0, r * math.sin(a))) for a in (i * math.tau / segs for i in range(segs))]
    f = bm.faces.new(verts)
    u0, v0, u1, v1 = uv
    for loop in f.loops:
        c = loop.vert.co
        loop[lay].uv = (u0 + (0.5 + 0.5 * c.x / r) * (u1 - u0), v0 + (0.5 + 0.5 * c.z / r) * (v1 - v0))
    if f.normal.y > 0:
        bmesh.ops.reverse_faces(bm, faces=[f])
    return _object(name, bm, mat, center, (0, 0, 0))


def pleats(name, x0, x1, y, z0, z1, depth, folds, mat):
    """Hanging fabric from x0 to x1 at y, z0..z1, zig-zagging `depth` either side of y over `folds` folds (both faces drawn)."""
    bm = bmesh.new()
    n = folds * 2
    top, bot = [], []
    for i in range(n + 1):
        x = x0 + (x1 - x0) * i / n
        dy = depth * (1 if i % 2 else -1)
        top.append(bm.verts.new((x, y + dy, z1)))
        bot.append(bm.verts.new((x, y + dy * 1.3, z0)))                 # the hem swings out a little further
    for i in range(n):
        bm.faces.new((bot[i], bot[i + 1], top[i + 1], top[i]))
    front = bm.faces[:]
    back = bmesh.ops.duplicate(bm, geom=front)["geom"]
    bmesh.ops.reverse_faces(bm, faces=[g for g in back if isinstance(g, bmesh.types.BMFace)])
    return _object(name, bm, mat, (0, 0, 0), (0, 0, 0))


def blob(name, size, loc, mat=None, seed=0, lumps=0.12, lump_freq=1.6, folds=0.0, fold_freq=5.0, fold_stretch=0.35, settle=0.0,
         pinch=None, pleats=None, crease=True, subdiv=4, rot=(0, 0, 0)):
    """Organic lump filling the box `size` (full extents) centred on `loc`. An icosphere is pushed in and out along its normals
    by smooth noise (lumps: fraction of the radius at lump_freq over the unit sphere) and creased by folds (sharp valleys
    along the noise's zero lines, plastic and paper; crease=False: soft rolling folds, cloth; fold_stretch < 1 runs them
    vertically, as gravity hangs them). settle 0..1:
    the bottom flattens onto the ground and bulges out (a full sack slumping; a heap spreading). pinch=(z0, r, rise): above
    unit height z0 the surface is gathered to radius r and drawn up by rise (a bag's tied neck). pleats=(count, depth, z0):
    folds radiating up to the top from unit height z0, deepening toward it (plastic gathered into a knot). The result is rescaled to
    exactly `size`, so placements stay predictable. Low subdiv + high lumps = crumpled paper (the kit's smoothing angle keeps
    the creases hard)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=1.0)
    off = Vector((seed * 7.31 + 0.5, seed * 3.17 + 1.5, seed * 5.93 + 2.5))
    floor = -1.0 + 0.9 * settle
    for v in bm.verts:
        n = v.co.normalized()
        d = lumps * noise.noise(n * lump_freq + off)
        if folds:
            q = Vector((n.x * fold_freq, n.y * fold_freq, n.z * fold_freq * fold_stretch)) + off * 1.7
            if crease:
                d -= folds * (1.0 - min(1.0, abs(noise.noise(q)) * 3.0)) ** 3
            else:
                d += folds * noise.noise(q)
        if pleats and n.z > pleats[2]:
            t = (n.z - pleats[2]) / (1.0 - pleats[2])
            ang = math.atan2(n.y, n.x) + 0.3 * noise.noise(n * 3.0 + off)
            d -= pleats[1] * t * (1.0 - abs(math.sin(ang * pleats[0] / 2.0))) ** 3
        p = n * (1.0 + d)
        if settle:
            low = max(0.0, -p.z)
            p.x *= 1.0 + settle * 0.35 * low
            p.y *= 1.0 + settle * 0.35 * low
            if p.z < floor:
                p.z = floor - (floor - p.z) * 0.06
        if pinch and n.z > pinch[0]:
            t = (n.z - pinch[0]) / (1.0 - pinch[0])
            k = 1.0 - t * (1.0 - pinch[1])
            p.x *= k
            p.y *= k
            p.z += pinch[2] * t
        v.co = p
    lo = Vector([min(v.co[i] for v in bm.verts) for i in range(3)])
    hi = Vector([max(v.co[i] for v in bm.verts) for i in range(3)])
    for v in bm.verts:
        v.co = Vector([((v.co[i] - lo[i]) / max(hi[i] - lo[i], 1e-6) - 0.5) * size[i] for i in range(3)])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _object(name, bm, mat, loc, rot)
