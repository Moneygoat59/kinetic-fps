"""Starves the base body onto its skeleton: every skin vertex is pulled toward the nearest bone surface (plus SKIN metres of
skin), by how much depending on which bone that is (PULL). Skin sinks between the ribs and into the sockets and cheeks, the
nose falls in to the nasal hole, the lips shrink back onto the teeth, the belly caves in under the ribs, the limbs thin to
bone and cord. Then a light smoothing pass takes the bone's own hard edges out of the skin.
"""
import bmesh
import numpy as np
from mathutils import Vector
import bpy
from mathutils.bvhtree import BVHTree

SKIN = 0.0035
REACH = 0.14                           # metres inward a skin vertex looks for bone
HOLLOW = 0.07                          # most a boneless part (the belly) sinks
EXTREMITY = 0.012                      # hands and feet sink at most this much
HEAD_REACH = 0.09                      # radially, into the sockets and the nasal hole
HEAD_Z = 1.48                          # above this (the neck up, in the fitted body) the depth is smoothed more
# first matching key in the bone's name -> pull 0..1 (1 = skin right on the bone)
PULL = [("skull", 0.85), ("mandible", 0.85), ("tooth", 0.85), ("ripcage", 0.96), ("clavicle", 0.95), ("scapula", 0.9), ("thoracic", 0.9), ("cervical", 0.72),
        ("lumbar", 0.5), ("sacral", 0.8), ("coccygeal", 0.8), ("hip", 0.85), ("humerus", 0.78), ("radius", 0.82),
        ("ulna", 0.82), ("femur", 0.72), ("tibula", 0.85), ("fibula", 0.8), ("patella", 0.9)]
PULL_DEFAULT = 0.45                    # hands, feet: knuckle and tendon


def smoothstep(e0, e1, x):
    t = max(0.0, min(1.0, (x - e0) / (e1 - e0)))
    return t * t * (3.0 - 2.0 * t)


def _pull_for(name):
    for key, w in PULL:
        if key in name:
            return w
    return PULL_DEFAULT


def _bone_tree(bones):
    """One BVH over every bone, and for each of its triangles the pull of the bone it came from."""
    verts, tris, pulls = [], [], []
    for b in bones:
        me = b.data
        me.calc_loop_triangles()
        base = len(verts)
        verts.extend(v.co.copy() for v in me.vertices)
        w = _pull_for(b.name)
        for t in me.loop_triangles:
            tris.append(tuple(base + i for i in t.vertices))
            pulls.append(w)
    return BVHTree.FromPolygons(verts, tris), pulls


def _smooth_field(bm, d, iters, head_extra):
    """Laplacian-smooth a per-vertex scalar over the mesh (numpy); `head_extra` more passes above HEAD_Z (the face folds
    easily: its bones are thin and the depth under neighbouring vertices jumps)."""
    e = np.array([(ed.verts[0].index, ed.verts[1].index) for ed in bm.edges], dtype=np.int64)
    z = np.array([v.co.z for v in bm.verts])
    deg = np.bincount(e.ravel(), minlength=len(d)).astype(np.float64)
    head = (z > HEAD_Z).astype(np.float64)
    for k in range(iters + head_extra):
        acc = np.zeros(len(d))
        np.add.at(acc, e[:, 0], d[e[:, 1]])
        np.add.at(acc, e[:, 1], d[e[:, 0]])
        mean = acc / np.maximum(deg, 1.0)
        w = 0.5 if k < iters else 0.5 * head
        d = d * (1.0 - w) + mean * w
    return d


def starve(body, bones, iters=10, head_extra=24):
    """Deflate along each vertex normal: cast inward to the bone under it and sink by pull x (depth - SKIN), that depth field
    smoothed first. Moving along the normal (not to the nearest bone point) keeps the skin one smooth sheet: no facets, no
    webs between the limbs. Where nothing is under the skin (the belly: only the spine, far behind) it sinks at most HOLLOW."""
    tree, pulls = _bone_tree(bones)
    skull = next(b for b in bones if "skull" in b.name)
    xs, ys, zs = zip(*(v.co for v in skull.data.vertices))
    centre = Vector(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2 + 0.01, (min(zs) + max(zs)) / 2))
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.normal_update()
    bm.verts.ensure_lookup_table()
    d = np.zeros(len(bm.verts))
    dirs = []
    for i, v in enumerate(bm.verts):
        radial = (centre - v.co).normalized()                                  # the head sinks toward the skull's centre:
        h = smoothstep(HEAD_Z - 0.05, HEAD_Z + 0.03, v.co.z)                   # rays from one point never cross, so the
        n = (-v.normal).lerp(radial, h).normalized()                           # face cannot fold over itself
        dirs.append(n)
        loc, nrm, idx, depth = tree.ray_cast(v.co - n * 0.002, n, REACH if h < 0.5 else HEAD_REACH)
        if loc is None:
            loc, nrm, idx, depth = tree.find_nearest(v.co)
            if loc is None:
                continue
            depth = min(depth, HOLLOW)
        if pulls[idx] == PULL_DEFAULT:
            depth = min(depth, EXTREMITY)                                      # fingertips and toes would cave in
        d[i] = max(depth - SKIN, 0.0) * pulls[idx]
    d = _smooth_field(bm, d, iters, head_extra)
    for i, v in enumerate(bm.verts):
        v.co += dirs[i] * d[i]
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()
    return body


def hide(objs):
    for o in objs:
        o.hide_render = True
