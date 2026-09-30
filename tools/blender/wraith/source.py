"""Loads the CC0 Human Base Meshes bundle (Blender Studio, tools/asset_src/, not committed: get it with
tools/blender/wraith/README section in tools/README.md) and hands the wraith builder its raw parts, all in one space:
  eyes   the centres of its two eyeballs (the eyeballs themselves are dropped)
  body   the realistic male body, multires applied at SUBDIV (UVs kept), feet on z = 0, facing -Y
  bones  every skeleton part, fitted inside the body (uniform scale by height, centred), one object per part; the skull
         split into bone_skull (cranium), bone_mandible and bone_tooth_u* / bone_tooth_l*
"""
import os

import bpy
from mathutils import Vector

import wlib as W

BUNDLE = os.path.join(W.ROOT, "tools", "asset_src", "human-base-meshes-bundle-v1.4.1", "human_base_meshes_bundle.blend")
BODY = "GEO-body_male_realistic"
SKELETON = "Skeleton - Realistic"
SUBDIV = 2
BONE_SUBDIV = 1


def _bounds(objs):
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    return (Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)]))


def load():
    if not os.path.exists(BUNDLE):
        raise SystemExit(f"missing {BUNDLE}: download human-base-meshes-bundle-v1.4.1.zip from blender.org (see tools/README.md)")
    bpy.ops.wm.open_mainfile(filepath=BUNDLE)
    body = bpy.data.objects[BODY]
    bones = [o for o in bpy.data.collections[SKELETON].objects if o.type == "MESH"]
    eyes = [bpy.data.objects[BODY + ".eye.L"], bpy.data.objects[BODY + ".eye.R"]]
    keep = set([body] + bones + eyes)
    world = {o.name: o.matrix_world.copy() for o in keep}                   # before unparenting drops the parents' transforms
    for o in list(bpy.data.objects):
        if o not in keep:
            bpy.data.objects.remove(o)
    scene = bpy.context.scene
    for o in keep:
        if o.name not in scene.collection.objects:
            scene.collection.objects.link(o)
        o.parent = None
        o.matrix_world = world[o.name]
        if o.data.users > 1:
            o.data = o.data.copy()                                             # the bundle shares meshes between assets
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    mr = body.modifiers[0]
    mr.levels = SUBDIV
    mr.render_levels = SUBDIV
    W.apply_all(body)
    for b in bones:
        for m in b.modifiers:
            if m.type == "SUBSURF":
                m.levels = BONE_SUBDIV
        W.apply_all(b)
        W.activate(b)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    eye_pts = [sum((e.matrix_world @ v.co for v in e.data.vertices), Vector()) / len(e.data.vertices) for e in eyes]
    for e in eyes:
        bpy.data.objects.remove(e)
    W.activate(body)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bmin, bmax = _bounds([body])
    smin, smax = _bounds(bones)
    k = (bmax.z - bmin.z) / (smax.z - smin.z)
    bc = (bmin + bmax) * 0.5
    sc = (smin + smax) * 0.5
    for o in [body]:
        for v in o.data.vertices:
            v.co = Vector((v.co.x - bc.x, v.co.y - bc.y, v.co.z - bmin.z))
        o.data.update()
    for b in bones:
        for v in b.data.vertices:
            v.co = Vector(((v.co.x - sc.x) * k, (v.co.y - sc.y) * k, (v.co.z - smin.z) * k))
        b.name = b.name.replace("GEO-skeletion.", "bone_")
        b.data.update()
    body.name = "body"
    _split_skull(next(b for b in bones if b.name == "bone_skull"))
    eye_pts = [Vector((p.x - bc.x, p.y - bc.y, p.z - bmin.z)) for p in eye_pts]
    return body, [o for o in bpy.data.objects if o.name.startswith("bone_")], eye_pts


def _split_skull(skull):
    """The skull comes as 32 loose parts: cranium, mandible, 30 teeth. Split them (the cranium keeps the name) so the jaw
    can be its own part: bone_mandible, bone_tooth_u* (upper row, on the cranium), bone_tooth_l* (lower, on the jaw)."""
    W.activate(skull)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    parts = sorted([o for o in bpy.data.objects if o.name.startswith("bone_skull")], key=lambda o: -len(o.data.vertices))
    cz = lambda o: sum(v.co.z for v in o.data.vertices) / len(o.data.vertices)   # noqa: E731
    parts[0].name = "bone_skull"
    parts[1].name = "bone_mandible"
    teeth = parts[2:]
    mid = sorted(cz(t) for t in teeth)[len(teeth) // 2]
    for i, t in enumerate(teeth):
        t.name = f"bone_tooth_{'u' if cz(t) >= mid else 'l'}{i:02d}"
