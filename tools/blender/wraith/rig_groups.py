"""Which skeleton parts move together (groups), how they chain (PARENT), and where each one turns (its pivot, a joint found
from the bone meshes themselves). Used by pose.py (skinning the starved body) and the exported game rig.
"""
import numpy as np
from mathutils import Vector

FINGERS = ("thumb", "index", "middle", "ring", "little")
SIDES = ("L", "R")


def group_of(bone):
    """Skeleton part name (bone_<name>) -> group name."""
    n = bone[5:]
    side = n[-1] if n[-2:] in (".L", ".R") else ""
    if n in ("skull",) or n.startswith("tooth_u") or n in ("spine_cervical_c1", "spine_cervical_c2"):
        return "head"
    if n == "mandible" or n.startswith("tooth_l"):
        return "jaw"
    if "cervical" in n:
        return "neck"
    if "thoracic" in n or n == "ripcage":
        return "chest"
    if n in ("spine_lumbar_l1", "spine_lumbar_l1.5", "spine_lumbar_l2", "spine_lumbar_l2.5"):
        return "belly"
    if "lumbar" in n or n in ("sacral", "coccygeal", "hip"):
        return "pelvis"
    if "clavicle" in n or "scapula" in n:
        return "shoulder." + side
    if "humerus" in n:
        return "upperarm." + side
    if "radius" in n or "ulna" in n:
        return "forearm." + side
    if "femur" in n or "patella" in n:
        return "thigh." + side
    if "tibula" in n or "fibula" in n:
        return "shin." + side
    for f in FINGERS:
        for k, seg in (("proximal", 1), ("middle", 2), ("distal", 3)):
            if n.startswith(f"{k}.{f}."):
                return f"f{seg}_{f}.{side}"
    if "hand_center" in n or "metacarpal" in n:
        return "hand." + side
    return "foot." + side                                                    # tarsals, metatarsals, toes


def parent_of(g):
    base, side = (g.split(".") + [""])[:2]
    s = "." + side if side else ""
    table = {"pelvis": None, "belly": "pelvis", "chest": "belly", "neck": "chest", "head": "neck", "jaw": "head",
             "shoulder": "chest", "upperarm": "shoulder" + s, "forearm": "upperarm" + s, "hand": "forearm" + s,
             "thigh": "pelvis", "shin": "thigh" + s, "foot": "shin" + s}
    if base in table:
        return table[base]
    seg, finger = base.split("_")                                          # f2_index -> f1_index, f1_index -> hand
    return f"f{int(seg[1]) - 1}_{finger}{s}" if seg != "f1" else "hand" + s


def parent_in(g, groups):
    """Nearest ancestor that exists (the thumb has no middle phalanx: its tip hangs off the first)."""
    p = parent_of(g)
    while p is not None and p not in groups:
        p = parent_of(p)
    return p


def order(groups):
    """Parents before children."""
    out, left = [], set(groups)
    while left:
        for g in sorted(left):
            p = parent_in(g, groups)
            if p is None or p in out:
                out.append(g)
                left.discard(g)
    return out


def _pts(objs):
    return np.array([tuple(v.co) for o in objs for v in o.data.vertices])


def _ends(p):
    """Both ends of a long part: mean of the 3 % of points furthest each way along its main axis."""
    c = p.mean(0)
    axis = np.linalg.svd(p - c, full_matrices=False)[2][0]
    t = (p - c) @ axis
    lo, hi = np.quantile(t, [0.03, 0.97])
    return p[t <= lo].mean(0), p[t >= hi].mean(0)


def pivots(parts):
    """parts: group -> [bone objects]. Returns group -> (pivot, far end) as Vectors: the joint it turns about, and the
    point it reaches toward (for its axis)."""
    out = {}
    named = {o.name[5:]: o for objs in parts.values() for o in objs}
    cen = lambda n: Vector(_pts([named[n]]).mean(0))                       # noqa: E731
    out["pelvis"] = (cen("hip"), cen("spine_lumbar_l3"))
    out["belly"] = (cen("spine_lumbar_l3"), cen("spine_thoracic_t12"))
    out["chest"] = (cen("spine_thoracic_t12"), cen("spine_cervical_c7"))
    out["neck"] = (cen("spine_cervical_c7"), cen("spine_cervical_c1"))
    head_top = Vector(_pts([named["skull"]])[:, 2].max() * np.array([0, 0, 1]) + _pts([named["skull"]]).mean(0) * [1, 1, 0])
    out["head"] = (cen("spine_cervical_c1"), head_top)
    mand = _pts([named["mandible"]])
    back = mand[mand[:, 1] > np.quantile(mand[:, 1], 0.85)]
    hinge = back[back[:, 2] > np.quantile(back[:, 2], 0.7)].mean(0)
    out["jaw"] = (Vector((0.0, hinge[1], hinge[2])), Vector(mand[mand[:, 1].argmin()]))
    for g in order(list(parts)):
        if g in out:
            continue
        objs = parts[g]
        a, b = (Vector(e) for e in _ends(_pts(objs)))
        par = out.get(parent_in(g, parts), (None, None))[0]
        ref = par if par is not None else Vector(_pts(objs).mean(0))
        if g.startswith("shoulder"):
            ref = Vector((0.0, ref.y, ref.z))                                # the clavicle turns at its inner end
        near, far = (a, b) if (a - ref).length < (b - ref).length else (b, a)
        if g.startswith("foot"):
            near = out[parent_of(g)][1]                                      # the ankle, not the heel
        out[g] = (near, far)
    return out
