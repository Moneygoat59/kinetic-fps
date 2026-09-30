"""The game rig: a light armature at the posed joints (its rest pose IS the wraith's pose) and skin weights folded down from
the posing groups (every finger into its hand). Godot drives: head (twitch), jaw (the scream), arm_l / arm_r (reach, the
grip), and could drive the rest. Bone names are the contract with scripts/world/wraith/wraith_view.gd.
"""
import bpy
import numpy as np
from mathutils import Vector

import rig_groups as G

BONES = [  # game bone, parent, posing groups folded into it
    ("hips", None, ["pelvis"]), ("spine", "hips", ["belly"]), ("chest", "spine", ["chest"]),
    ("neck", "chest", ["neck"]), ("head", "neck", ["head"]), ("jaw", "head", ["jaw"]),
] + [b for s, x in (("L", "l"), ("R", "r")) for b in (
    (f"shoulder_{x}", "chest", [f"shoulder.{s}"]), (f"arm_{x}", f"shoulder_{x}", [f"upperarm.{s}"]),
    (f"forearm_{x}", f"arm_{x}", [f"forearm.{s}"]),
    (f"hand_{x}", f"forearm_{x}", [f"hand.{s}"] + [f"f{k}_{f}.{s}" for k in (1, 2, 3) for f in G.FINGERS]),
    (f"thigh_{x}", "hips", [f"thigh.{s}"]), (f"shin_{x}", f"thigh_{x}", [f"shin.{s}"]),
    (f"foot_{x}", f"shin_{x}", [f"foot.{s}"]))]


def posed(solved, piv, g, xf):
    p, pw, a = solved[g]
    far = pw + a @ (piv[g][1] - p)
    return xf(pw), xf(far)


def armature(solved, piv, xf):
    """xf: rest-scale posed point -> final (scaled, grounded) point."""
    arm = bpy.data.armatures.new("wraith_rig")
    o = bpy.data.objects.new("wraith_rig", arm)
    bpy.context.collection.objects.link(o)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode="EDIT")
    for name, parent, groups in BONES:
        head, tail = posed(solved, piv, groups[0], xf)
        if (tail - head).length < 0.02:
            tail = head + Vector((0.0, 0.0, 0.05))
        eb = arm.edit_bones.new(name)
        eb.head, eb.tail = head, tail
        if parent:
            eb.parent = arm.edit_bones[parent]
    bpy.ops.object.mode_set(mode="OBJECT")
    return o


def weigh(obj, groups, w):
    """Vertex groups on `obj` from the posing weights (n x len(groups)), folded per BONES."""
    for name, _, gs in BONES:
        cols = [groups.index(g) for g in gs if g in groups]
        if not cols:
            continue
        v = w[:, cols].sum(1)
        vg = obj.vertex_groups.new(name=name)
        for i in np.nonzero(v > 0.01)[0]:
            vg.add([int(i)], float(v[i]), "REPLACE")


def weigh_all(obj, bone):
    vg = obj.vertex_groups.new(name=bone)
    vg.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")


def weigh_hair(obj, head_z, drop=0.6):
    """Roots follow the head; the lengths hang more and more from the chest."""
    hv = obj.vertex_groups.new(name="head")
    cv = obj.vertex_groups.new(name="chest")
    for v in obj.data.vertices:
        t = min(max((head_z - v.co.z) / drop, 0.0), 1.0) * 0.7
        hv.add([v.index], 1.0 - t, "REPLACE")
        cv.add([v.index], t, "REPLACE")


def bind(rig, objs):
    for o in objs:
        o.parent = rig
        mod = o.modifiers.new("rig", "ARMATURE")
        mod.object = rig


def marker(rig, name, pos):
    """An empty at a point on the head (the eyes' glow sits on these). Parented to the rig object, not a bone: Godot's
    WraithView hangs it on a BoneAttachment3D of `head` at runtime."""
    e = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(e)
    e.location = pos
    e.parent = rig
    return e
