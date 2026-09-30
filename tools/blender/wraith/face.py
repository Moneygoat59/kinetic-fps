"""The wraith's face, after starve.py drew the skin onto the skull: the lids are cut back so the sockets gape, with a small
wet black eye sunk in each; the lips are cut away so the teeth show to the roots, with a dark throat behind them.
select() picks the faces on the REST body (before starve / pose move it); cut() deletes them once it is posed; extras()
adds the eyes and throat, posed with the head (pose.apply) and returns them with the eye centres (the glow markers).
"""
import bmesh
import bpy
import numpy as np
from mathutils import Vector

import wlib as W

LID = 0.0135              # lids this close to the eyeball's centre are cut away
MOUTH = (0.027, 0.017)    # half-width, half-height of the lips cut away round the teeth
EYE_R = 0.0075
EYE_SINK = 0.03           # the eye sits this much deeper than the old eyeball's centre


def mouth_centre(bones):
    up = [v.co for b in bones if b.name.startswith("bone_tooth_u") for v in b.data.vertices]
    lo = [v.co for b in bones if b.name.startswith("bone_tooth_l") for v in b.data.vertices]
    front = min(c.y for c in up)
    bite = (min(c.z for c in up) + max(c.z for c in lo)) * 0.5
    return Vector((0.0, front, bite))


def select(body, bones, eyes):
    mc = mouth_centre(bones)
    lids, lips = [], []
    for f in body.data.polygons:
        c = f.center
        if any((c - e).length < LID for e in eyes):
            lids.append(f.index)
        elif c.y < mc.y + 0.006 and (c.x / MOUTH[0]) ** 2 + ((c.z - mc.z) / MOUTH[1]) ** 2 < 1.0:
            lips.append(f.index)
    return lids + lips, mc


def cut(body, faces):
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[bm.faces[i] for i in faces], context="FACES_ONLY")    # keep vertex indices
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()


def _ball(name, centre, radii, m, segs=16):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segs, v_segments=segs // 2 + 2, radius=1.0)
    bmesh.ops.scale(bm, vec=radii, verts=bm.verts)
    bmesh.ops.translate(bm, vec=centre, verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    o = W.link(name, me)
    o.data.materials.append(m)
    W.shade_smooth(o)
    return o


def extras(eyes, mc, head_xf, eye_m, throat_m):
    """head_xf(points (n,3)) -> posed points. Returns ([eye objects], throat, [posed eye fronts])."""
    back = Vector((0.0, EYE_SINK, 0.0))
    objs, fronts = [], []
    for i, e in enumerate(eyes):
        c = e + back
        o = _ball(f"eyeball_{'lr'[i]}", c, (EYE_R, EYE_R, EYE_R), eye_m)
        _pose_obj(o, head_xf)
        objs.append(o)
        fronts.append(Vector(head_xf(np.array([tuple(c - Vector((0.0, EYE_R, 0.0)))]))[0]))
    throat = _ball("throat", mc + Vector((0.0, 0.03, 0.0)), (0.024, 0.03, 0.022), throat_m, 12)
    _pose_obj(throat, head_xf)
    return objs, throat, fronts


def _pose_obj(o, xf):
    pts = np.array([tuple(v.co) for v in o.data.vertices])
    o.data.vertices.foreach_set("co", xf(pts).ravel())
    o.data.update()
