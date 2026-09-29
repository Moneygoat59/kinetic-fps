"""Floating-part check for a Blender prop generator: runs it up to its first L.join(), then reports every visual part that
touches nothing (no other part within 1.2 cm, not inside another part, not on the ground plane z = 0).
Run:  tools\\blender.ps1 tools/blender/contact_check.py tools/blender/props/outpost73_bunker.py
Reads the generator's module-level lists `parts` (or `surf` + `bore`: missile_silo.py), `liquids`, `door_l`, `door_r` and
the optional `movers` dict."""
import os
import sys
from collections import deque

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ps1_lib as L  # noqa: E402

EPS = 0.012


class _Stop(Exception):
    pass


def _stop(*_a, **_k):
    raise _Stop()


def _items(g):
    groups = {"shell": g.get("parts", []) + g.get("surf", []) + g.get("bore", []), "liquid": g.get("liquids", []),
              "door": g.get("door_l", []) + g.get("door_r", [])}
    for name, (objs, _pivot) in g.get("movers", {}).items():
        groups[name] = objs
    out = []
    for grp, objs in groups.items():
        for o in objs:
            vs = [o.matrix_world @ v.co for v in o.data.vertices]
            lo = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
            hi = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
            bvh = BVHTree.FromPolygons(vs, [list(p.vertices) for p in o.data.polygons])
            out.append({"n": o.name, "g": grp, "vs": vs, "bvh": bvh, "lo": lo, "hi": hi})
    return out


def _gap(a, b):
    """Smallest vertex->surface distance between a and b; negative if a vertex of one lies inside the other."""
    best = 1e9
    for x, y in ((a, b), (b, a)):
        for v in x["vs"]:
            hit = y["bvh"].find_nearest(v)
            if hit[0] is None:
                continue
            if (v - hit[0]).dot(hit[1]) < 0 and hit[3] < 0.5:
                return -hit[3]
            best = min(best, hit[3])
    return 0.0 if a["bvh"].overlap(b["bvh"]) else best


def _near(a, b, pad):
    return all(a["lo"][i] - pad <= b["hi"][i] and b["lo"][i] - pad <= a["hi"][i] for i in range(3))


def main():
    gen = os.path.abspath(L.argv_after_dashes()[0])
    L.join = _stop
    g = {"__file__": gen, "__name__": "__main__"}
    try:
        exec(compile(open(gen, encoding="utf-8").read(), gen, "exec"), g)
    except _Stop:
        pass
    bpy.context.view_layer.update()
    items = _items(g)
    n = len(items)
    adj = [[] for _ in range(n)]
    for i in range(n):
        for j in range(i + 1, n):
            if _near(items[i], items[j], EPS) and _gap(items[i], items[j]) <= EPS:
                adj[i].append(j)
                adj[j].append(i)
    seen = {i for i, it in enumerate(items) if it["lo"].z <= EPS}
    queue = deque(seen)
    while queue:
        for j in adj[queue.popleft()]:
            if j not in seen:
                seen.add(j)
                queue.append(j)
    for i, it in enumerate(items):
        if i not in seen:
            print("FLOAT %-8s %-28s z=[%.2f, %.2f]" % (it["g"], it["n"], it["lo"].z, it["hi"].z))
    print("CONTACT parts=%d connected=%d floating=%d" % (n, len(seen), n - len(seen)))


main()
