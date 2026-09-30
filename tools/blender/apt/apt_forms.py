"""Formed shapes for the apartment kit (pure bmesh / mesh data, baked at the given location / rotation like apt_shapes):
  book    a book mapped onto tex/apt_books.png (spine, cover colour, page edges, optional front cover); goes into k.panels
  lathe   a profile turned round Z (kettles, plates, bowls, canisters, mugs): closed, smooth where the kit shades it smooth
  mesh    raw verts / faces with a material per face (the shoe builder in entry.py uses it); sheet: a thin slab from a grid
  holed_slab  a worktop slab with an oval cut-out (vanity basin, drop-in sinks)
Book frame: spine faces -Y, front cover +X, top +Z, fore edge +Y, origin at the base centre (a book standing on a shelf with
its spine out). rot=(0, 0, -90) turns the cover to face -Y (face-out); rot=(0, -90, 0) lays it flat, cover up, spine still -Y.
"""
import math

import bmesh
import bpy
from mathutils import Euler

import apt_books as K


def _obj(name, me, mats, loc, rot):
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    for m in mats:
        me.materials.append(m)
    o.location = loc
    o.rotation_euler = Euler([math.radians(a) for a in rot])
    return o


def mesh(name, verts, faces, mats, face_mat=None, loc=(0, 0, 0), rot=(0, 0, 0), weld=False):
    """faces[i] gets mats[face_mat[i]] (all mats[0] if face_mat is None). weld merges coincident verts (collapsed grid ends)."""
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    if face_mat:
        for poly, m in zip(me.polygons, face_mat):
            poly.material_index = m
    bm = bmesh.new()
    bm.from_mesh(me)
    if weld:
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
        bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    return _obj(name, me, mats, loc, rot)


def sheet(name, grid, thick, mat, loc=(0, 0, 0)):
    """A thin closed slab from a grid of top points (rows of equal length), `thick` deep straight down (a shoe tongue)."""
    rows, cols = len(grid), len(grid[0])
    top = [p for row in grid for p in row]
    verts = top + [(x, y, z - thick) for x, y, z in top]
    n = len(top)
    faces = []
    for i in range(rows - 1):
        for j in range(cols - 1):
            a = i * cols + j
            faces += [[a, a + 1, a + cols + 1, a + cols], [n + a + cols, n + a + cols + 1, n + a + 1, n + a]]
    edge = [j for j in range(cols)] + [i * cols + cols - 1 for i in range(1, rows)]
    edge += [(rows - 1) * cols + j for j in reversed(range(cols - 1))] + [i * cols for i in reversed(range(1, rows - 1))]
    for a, b in zip(edge, edge[1:] + edge[:1]):
        faces.append([a, b, n + b, n + a])
    return mesh(name, verts, faces, [mat], loc=loc)


def holed_slab(name, rect, z0, z1, hole, mat, n=112):
    """Slab over rect=(x0, y0, x1, y1) from z0 to z1 with an elliptical hole=(cx, cy, a, b) right through it. Edge points are
    spread along the rectangle (corners exact) and each is paired with the hole point in its direction, so the ring is clean."""
    x0, y0, x1, y1 = rect
    cx, cy, a, b = hole
    corners = [(x1, y0), (x1, y1), (x0, y1), (x0, y0)]
    per = 2 * (x1 - x0) + 2 * (y1 - y0)
    edge, start = [], (x0, y0)
    for c in corners:
        ln = abs(c[0] - start[0]) + abs(c[1] - start[1])
        k = max(1, round(n * ln / per))
        edge += [(start[0] + (c[0] - start[0]) * i / k, start[1] + (c[1] - start[1]) * i / k) for i in range(k)]
        start = c
    m = len(edge)
    ring = []
    for ex, ey in edge:
        th = math.atan2((ey - cy) / b, (ex - cx) / a)
        ring.append((cx + a * math.cos(th), cy + b * math.sin(th)))
    verts = [(x, y, z) for z in (z1, z0) for x, y in edge] + [(x, y, z) for z in (z1, z0) for x, y in ring]
    faces = []
    for i in range(m):
        j = (i + 1) % m
        faces += [[i, j, 2 * m + j, 2 * m + i],                      # top
                  [m + i, 3 * m + i, 3 * m + j, m + j],              # bottom
                  [i, m + i, m + j, j],                              # outer wall
                  [2 * m + i, 2 * m + j, 3 * m + j, 3 * m + i]]      # hole wall
    return mesh(name, verts, faces, [mat])


def book(name, i, mat, loc=(0, 0, 0), rot=(0, 0, 0), size=None):
    """Book i of apt_books.B (size=(t, d, h) overrides its own). Front cover art where apt_books has one."""
    t, d, h = size or K.B[i][7:10]
    x, y = t / 2, d / 2
    spine, colour, pages = K.spine_uv(i), K.colour_uv(i), K.pages_uv(i)
    cover = K.cover_uv(i) if i in K.COVER_RECTS else colour
    # each face: 4 corners in order (u0,v0) (u1,v0) (u1,v1) (u0,v1) of its uv rect
    faces = [([(-x, -y, 0), (x, -y, 0), (x, -y, h), (-x, -y, h)], spine),          # spine, read from the front
             ([(x, -y, 0), (x, y, 0), (x, y, h), (x, -y, h)], cover),              # front cover, spine on its left
             ([(-x, y, 0), (-x, -y, 0), (-x, -y, h), (-x, y, h)], colour),         # back cover
             ([(x, y, 0), (-x, y, 0), (-x, y, h), (x, y, h)], pages),              # fore edge: lines run up
             ([(-x, -y, h), (x, -y, h), (x, y, h), (-x, y, h)], pages),            # top: lines run spine to fore edge
             ([(-x, y, 0), (x, y, 0), (x, -y, 0), (-x, -y, 0)], colour)]
    verts, polys, uvs = [], [], []
    for corners, (u0, v0, u1, v1) in faces:
        polys.append([len(verts) + k for k in range(4)])
        verts += corners
        uvs += [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], polys)
    lay = me.uv_layers.new(name="UVMap")
    for k, uv in enumerate(uvs):
        lay.data[k].uv = uv
    return _obj(name, me, [mat], loc, rot)


def lathe(name, profile, mat, loc=(0, 0, 0), segs=24, rot=(0, 0, 0), mats=None, ring_mat=None):
    """Turn profile [(r, z), ...] (bottom to top; r = 0 closes on the axis) round local Z. ring_mat[j] picks mats[] for the
    band between profile points j and j + 1 (glazed body, steel lid...)."""
    bm = bmesh.new()
    rings = []
    for r, z in profile:
        if r <= 1e-6:
            rings.append([bm.verts.new((0, 0, z))])
        else:
            rings.append([bm.verts.new((r * math.cos(a), r * math.sin(a), z)) for a in (k * math.tau / segs for k in range(segs))])
    for j in range(len(rings) - 1):
        a, b = rings[j], rings[j + 1]
        for k in range(segs):
            if len(a) == 1 and len(b) == 1:
                break
            if len(a) == 1:
                f = bm.faces.new((a[0], b[k], b[(k + 1) % segs]))
            elif len(b) == 1:
                f = bm.faces.new((a[k], a[(k + 1) % segs], b[0]))
            else:
                f = bm.faces.new((a[k], a[(k + 1) % segs], b[(k + 1) % segs], b[k]))
            f.material_index = ring_mat[j] if ring_mat else 0
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return _obj(name, me, mats or [mat], loc, rot)
