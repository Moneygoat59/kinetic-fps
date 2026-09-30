"""Poses and stretches the starved body by linear-blend skinning about the skeleton's own joints (rig_groups.py).
weights(): each skin vertex belongs to the bone part nearest it, blended across the joints by smoothing over the mesh.
pose(): per group a rotation (aim: point its axis along a world direction; rot: local euler degrees after its parent; curl:
degrees about its hand's knuckle line) and a stretch along its own axis; children follow their parent's moved joint.
"""
import math

import numpy as np
from mathutils import Euler, Matrix, Vector
from mathutils.bvhtree import BVHTree

import rig_groups as G

# the wraith: spine hunched, neck thrust out and long, the head cocked back up to stare; shoulders slumped forward, long
# arms hanging a little forward with long curled fingers, legs dangling, feet pointed at the ground
SPEC = {
    "belly": {"rot": (12, 0, 0), "stretch": 1.15},
    "chest": {"rot": (22, 0, 0), "stretch": 1.05},
    "neck": {"rot": (36, 0, 0), "stretch": 1.5},
    "head": {"rot": (-44, 13, -7)},
    "shoulder.L": {"rot": (0, 10, -12)}, "shoulder.R": {"rot": (0, -10, 12)},
    "upperarm.L": {"aim": (0.14, -0.28, -1), "stretch": 1.15}, "upperarm.R": {"aim": (-0.14, -0.28, -1), "stretch": 1.15},
    "forearm.L": {"aim": (0.07, -0.5, -1), "stretch": 1.4}, "forearm.R": {"aim": (-0.07, -0.5, -1), "stretch": 1.4},
    "hand.L": {"aim": (0.03, -0.35, -1), "stretch": 1.2}, "hand.R": {"aim": (-0.03, -0.35, -1), "stretch": 1.2},
    "thigh.L": {"aim": (0.06, -0.25, -1), "stretch": 1.1}, "thigh.R": {"aim": (-0.06, -0.25, -1), "stretch": 1.1},
    "shin.L": {"aim": (0.04, 0.2, -1), "stretch": 1.1}, "shin.R": {"aim": (-0.04, 0.2, -1), "stretch": 1.1},
    "foot.L": {"aim": (0.0, -0.3, -1)}, "foot.R": {"aim": (0.0, -0.3, -1)},
}
CURL = {1: (20, 1.5), 2: (32, 1.6), 3: (26, 1.5)}          # finger segment -> (curl degrees, stretch)
THUMB_CURL = 0.4


def _spec(g):
    s = dict(SPEC.get(g, {}))
    if g[0] == "f" and g[1].isdigit():
        seg = int(g[1])
        ang, k = CURL[seg]
        ang *= THUMB_CURL if "thumb" in g else 1.0
        s = {"curl": -ang if g.endswith(".L") else ang, "stretch": k}
    return s


def weights(body, bones, iters=14):
    groups = sorted(set(G.group_of(b.name) for b in bones))
    gi = {g: i for i, g in enumerate(groups)}
    verts, tris, tg = [], [], []
    for b in bones:
        b.data.calc_loop_triangles()
        base = len(verts)
        verts.extend(v.co.copy() for v in b.data.vertices)
        k = gi[G.group_of(b.name)]
        for t in b.data.loop_triangles:
            tris.append(tuple(base + i for i in t.vertices))
            tg.append(k)
    tree = BVHTree.FromPolygons(verts, tris)
    n = len(body.data.vertices)
    w = np.zeros((n, len(groups)), np.float32)
    for i, v in enumerate(body.data.vertices):
        idx = tree.find_nearest(v.co)[2]
        w[i, tg[idx]] = 1.0
    e = np.array([ed.vertices[:] for ed in body.data.edges], dtype=np.int64)
    deg = np.bincount(e.ravel(), minlength=n).astype(np.float32)[:, None]
    for _ in range(iters):
        acc = np.zeros_like(w)
        np.add.at(acc, e[:, 0], w[e[:, 1]])
        np.add.at(acc, e[:, 1], w[e[:, 0]])
        w = 0.5 * w + 0.5 * acc / np.maximum(deg, 1.0)
    return groups, w / np.maximum(w.sum(1, keepdims=True), 1e-6)


def solve(groups, piv):
    """group -> (rest pivot p, posed pivot pw, A) with posed x = pw + A (x - p); A = world rotation x stretch."""
    rot, out = {}, {}
    for g in G.order(groups):
        p, far = piv[g]
        axis = (far - p).normalized()
        par = G.parent_in(g, groups)
        rp = rot.get(par, Matrix.Identity(3))
        pw = p if par not in out else out[par][1] + out[par][2] @ (p - out[par][0])
        s = _spec(g)
        if "aim" in s:
            r = axis.rotation_difference(Vector(s["aim"]).normalized()).to_matrix()
        elif "curl" in s:
            side = g[-1]
            knuckles = (piv[f"f1_little.{side}"][0] - piv[f"f1_index.{side}"][0]).normalized()
            r = rp @ Matrix.Rotation(math.radians(s["curl"]), 3, knuckles)
        else:
            r = rp @ Euler([math.radians(a) for a in s.get("rot", (0, 0, 0))]).to_matrix()
        k = s.get("stretch", 1.0)
        stretch = Matrix.Identity(3) + (k - 1.0) * Matrix([[axis[i] * axis[j] for j in range(3)] for i in range(3)])
        rot[g] = r
        out[g] = (p, pw, r @ stretch)
    return out


def apply(points, groups, w, solved):
    """Skin an (n, 3) array of rest points."""
    res = np.zeros_like(points)
    for i, g in enumerate(groups):
        col = w[:, i]
        live = col > 1e-4
        if not live.any():
            continue
        p, pw, a = solved[g]
        moved = np.array(pw) + (points[live] - np.array(p)) @ np.array(a).T
        res[live] += col[live, None] * moved
    return res


def relax(body, rest, new, limit=1.6, rings=3, iters=14):
    """Where posing stretched or crushed the skin past `limit` (armpits, shoulders, groin), smooth it back out."""
    e = np.array([ed.vertices[:] for ed in body.data.edges], dtype=np.int64)
    ratio = np.linalg.norm(new[e[:, 0]] - new[e[:, 1]], axis=1) / np.maximum(
        np.linalg.norm(rest[e[:, 0]] - rest[e[:, 1]], axis=1), 1e-7)
    bad = np.zeros(len(new), bool)
    torn = np.abs(np.log(np.maximum(ratio, 1e-6))) > math.log(limit)
    bad[e[torn].ravel()] = True
    for _ in range(rings):
        grow = bad.copy()
        grow[e[bad[e[:, 0]], 1]] = True
        grow[e[bad[e[:, 1]], 0]] = True
        bad = grow
    deg = np.bincount(e.ravel(), minlength=len(new)).astype(np.float64)[:, None]
    for _ in range(iters):
        acc = np.zeros_like(new)
        np.add.at(acc, e[:, 0], new[e[:, 1]])
        np.add.at(acc, e[:, 1], new[e[:, 0]])
        new[bad] = 0.5 * new[bad] + 0.5 * (acc / np.maximum(deg, 1.0))[bad]
    return new


def pose(body, bones):
    parts = {}
    for b in bones:
        parts.setdefault(G.group_of(b.name), []).append(b)
    groups, w = weights(body, bones)
    piv = G.pivots(parts)
    solved = solve(groups, piv)
    pts = np.array([tuple(v.co) for v in body.data.vertices])
    new = relax(body, pts, apply(pts, groups, w, solved))
    body.data.vertices.foreach_set("co", new.ravel())
    body.data.update()
    return groups, w, piv, solved
