"""v2 helpers for PS1-style buildings: arbitrary-axis pipes, mesh subdivision, and baked vertex-colour AO.
Imported alongside ps1_lib (needs bpy)."""
import math
import random

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

import ps1_lib as L


def tube(name, p0, p1, r, mat=None, verts=8):
    """Cylinder between two arbitrary points (pipes, cables, braces)."""
    a, b = Vector(p0), Vector(p1)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    return L._finish(o, name, mat)


def ball(name, r, loc, mat=None, subdiv=1):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, location=loc, subdivisions=subdiv)
    return L._finish(bpy.context.active_object, name, mat)


def pipe(name, pts, r, mat=None, verts=8, clamps=0.0, clamp_mat=None):
    """Polyline pipe with ball elbows; optional clamp collars roughly every `clamps` metres. Returns the objects."""
    objs = []
    for i in range(len(pts) - 1):
        a, b = Vector(pts[i]), Vector(pts[i + 1])
        objs.append(tube(f"{name}_s{i}", a, b, r, mat, verts))
        if clamps > 0:
            d = (b - a).normalized()
            n = int((b - a).length / clamps)
            for k in range(1, n + 1):
                c = a + (b - a) * (k / (n + 1))
                objs.append(tube(f"{name}_c{i}_{k}", c - d * 0.04, c + d * 0.04, r * 1.4, clamp_mat or mat, verts))
    for i in range(1, len(pts) - 1):
        objs.append(ball(f"{name}_j{i}", r * 1.12, pts[i], mat))
    return objs


def subdivide_by_length(obj, max_len=0.5):
    """Bisect every edge longer than 1.4*max_len (repeatedly) so per-vertex lighting has resolution."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for _ in range(8):
        edges = [e for e in bm.edges if e.calc_length() > max_len * 1.4]
        if not edges:
            break
        bmesh.ops.subdivide_edges(bm, edges=edges, cuts=1, use_grid_fill=True)
    bm.to_mesh(obj.data)
    bm.free()


def bake_ao(obj, occluders=(), samples=28, max_dist=2.6, ground_z=None, skip_prefix="bunker_glow",
            gain=0.8, floor=0.16, power=1.5, chamfer_boost=1.3, seed=7, dirt=0.14, dust=1.1):
    """Bake ambient occlusion + edge highlights into a per-corner colour attribute (PS1-style vertex lighting).
    Rays are cast against obj + occluders (+ an optional ground plane at ground_z). Faces whose material name starts with
    skip_prefix (emissive) stay white. Chamfer faces (normal not axis-aligned) are brightened. gain leaves headroom
    because glTF vertex colours clamp at 1.0."""
    verts, polys = [], []

    def add(o):
        mw = o.matrix_world
        base = len(verts)
        verts.extend([mw @ v.co for v in o.data.vertices])
        polys.extend([tuple(base + i for i in p.vertices) for p in o.data.polygons])

    add(obj)
    for o in occluders:
        add(o)
    if ground_z is not None:
        base = len(verts)
        verts.extend([Vector((-80, -80, ground_z)), Vector((80, -80, ground_z)), Vector((80, 80, ground_z)), Vector((-80, 80, ground_z))])
        polys.append((base, base + 1, base + 2, base + 3))
    bvh = BVHTree.FromPolygons(verts, polys)
    rng = random.Random(seed)
    me = obj.data
    col = me.color_attributes.new("Col", "FLOAT_COLOR", "CORNER")
    me.color_attributes.active_color = col
    mw = obj.matrix_world
    nmat = mw.to_3x3()
    dirs = []
    for i in range(samples):  # cosine-weighted hemisphere, spiral distribution
        u = (i + 0.5) / samples
        r = math.sqrt(u)
        phi = i * 2.399963
        dirs.append((r * math.cos(phi), r * math.sin(phi), math.sqrt(max(0.0, 1.0 - u))))
    for poly in me.polygons:
        n = (nmat @ poly.normal).normalized()
        mi = poly.material_index
        mname = me.materials[mi].name if mi < len(me.materials) and me.materials[mi] else ""
        glow = mname.startswith(skip_prefix)
        t = n.cross(Vector((0, 0, 1)) if abs(n.z) < 0.9 else Vector((1, 0, 0))).normalized()
        bt = n.cross(t)
        rot = rng.uniform(0, math.tau)
        cr, sr = math.cos(rot), math.sin(rot)
        maxc = max(abs(n.x), abs(n.y), abs(n.z))
        for li in poly.loop_indices:
            if glow:
                col.data[li].color = (1, 1, 1, 1)
                continue
            p = mw @ me.vertices[me.loops[li].vertex_index].co + n * 0.03
            occ = 0.0
            for dx, dy, dz in dirs:
                x, y = dx * cr - dy * sr, dx * sr + dy * cr
                hit = bvh.ray_cast(p, t * x + bt * y + n * dz, max_dist)
                if hit[0] is not None:
                    occ += 1.0 - hit[3] / max_dist
            ao = 1.0 - occ / samples
            shade = (floor + (1.0 - floor) * ao ** power) * gain
            if maxc < 0.93:  # chamfer facet: catch light
                shade *= chamfer_boost
            if dirt:  # uneven grime: cheap deterministic pseudo-noise over world position
                q = math.sin(p.x * 3.1 + 1.3) * math.sin(p.y * 2.7 + 0.7) * math.sin(p.z * 3.7 + 2.1)
                shade *= 1.0 - dirt * (0.5 + 0.5 * q)
            if dust != 1.0 and n.z > 0.9:  # dust settles on upward-facing surfaces
                shade *= dust
            shade = min(shade, 1.0)
            col.data[li].color = (shade, shade, shade, 1.0)
