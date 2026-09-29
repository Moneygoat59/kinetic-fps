"""Shared helpers for the wraith generator (tools/blender/wraith/build.py): objects, modifiers, flat materials, preview
renders. Blender axes: Z up, the figure faces -Y.
"""
import os

import bpy
import numpy as np
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
SHOTS = os.path.join(ROOT, "shots")


def link(name, me):
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    return o


def activate(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def apply_all(o):
    activate(o)
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)
















def shade_smooth(o):
    for p in o.data.polygons:
        p.use_smooth = True


def mat(name, rgb, rough=0.6, sss=0.0, metal=0.0, emit=None, emit_strength=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1.0)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    b.inputs["Subsurface Weight"].default_value = sss
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1.0)
        b.inputs["Emission Strength"].default_value = emit_strength
    return m


def preview(name, cam_loc, look_at, lens=50, size=(900, 900), samples=48, key=(2.0, -3.0, 3.5), world=0.05):
    """Cycles still to shots/<name>.png: a soft cold key, a rim from behind, dim sky."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = True
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.film_transparent = False
    if sc.world is None:
        sc.world = bpy.data.worlds.new("w")
    sc.world.use_nodes = True
    sc.world.node_tree.nodes["Background"].inputs["Color"].default_value = (world, world * 1.05, world * 1.15, 1)
    for n in [o for o in bpy.data.objects if o.name.startswith("_pv")]:
        bpy.data.objects.remove(n)
    cam = bpy.data.objects.new("_pv_cam", bpy.data.cameras.new("_pv_cam"))
    cam.data.lens = lens
    cam.data.clip_start = 0.01
    sc.collection.objects.link(cam)
    cam.location = cam_loc
    d = Vector(look_at) - Vector(cam_loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    sc.camera = cam
    for nm, loc, energy, color, sz in (("_pv_key", key, 260.0, (0.8, 0.86, 1.0), 1.2),
                                        ("_pv_rim", (-1.5, 3.0, 3.2), 380.0, (0.6, 0.7, 1.0), 0.8)):
        ld = bpy.data.lights.new(nm, "AREA")
        ld.energy = energy
        ld.color = color
        ld.size = sz
        lo = bpy.data.objects.new(nm, ld)
        sc.collection.objects.link(lo)
        lo.location = loc
        lo.rotation_euler = (Vector(look_at) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    os.makedirs(SHOTS, exist_ok=True)
    sc.render.filepath = os.path.join(SHOTS, name + ".png")
    bpy.ops.render.render(write_still=True)
    print(f"EXPORT preview {sc.render.filepath}")


def transform(objs, xf):
    """Move every vertex of `objs` through xf ((n, 3) points -> (n, 3) points)."""
    for o in objs:
        pts = np.array([tuple(v.co) for v in o.data.vertices])
        o.data.vertices.foreach_set("co", xf(pts).ravel())
        o.data.update()
