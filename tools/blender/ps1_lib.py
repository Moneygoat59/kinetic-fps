"""Helpers for building low-poly PS1-style props in headless Blender and exporting .glb for Godot.

Run a generator:  tools\\blender.ps1 tools/blender/props/example_crate.py
Conventions (match the game's world scale: 1 unit = 1 metre, player ~1.8 m, door ~2.2 m):
  * Y-up on export (glTF standard; Godot imports it as-is), origin at the base centre so props sit on the ground.
  * Flat/vertex-colour materials, no PBR maps, low tri counts (props < ~500 tris).
  * Materials are named; textures are optional 64x64-ish pixel art applied with nearest filtering by the game shader.
"""
import bpy
import bmesh
import math
import os
import sys
from mathutils import Vector


def argv_after_dashes():
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, rgb, roughness=1.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    return m


def _finish(obj, name, mat, smooth=False):
    obj.name = name
    if mat is not None:
        obj.data.materials.append(mat)
    if smooth:
        bpy.ops.object.shade_smooth()
    return obj


def box(name, size, loc=(0, 0, 0), mat=None, rot_deg=(0, 0, 0)):
    """size=(x,y,z) in Blender axes (Z up). loc is the box CENTRE."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=[math.radians(a) for a in rot_deg])
    o = bpy.context.active_object
    o.scale = size
    bpy.ops.object.transform_apply(scale=True, rotation=False)
    return _finish(o, name, mat)


def cylinder(name, radius, depth, loc=(0, 0, 0), mat=None, verts=8, rot_deg=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth, location=loc,
                                        rotation=[math.radians(a) for a in rot_deg])
    return _finish(bpy.context.active_object, name, mat)


def cone(name, r1, r2, depth, loc=(0, 0, 0), mat=None, verts=8):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=depth, location=loc)
    return _finish(bpy.context.active_object, name, mat)


def jitter(obj, amount=0.03, seed=1):
    """Randomly nudge vertices for a hand-made, weathered look."""
    import random
    rng = random.Random(seed)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for v in bm.verts:
        v.co += Vector((rng.uniform(-amount, amount), rng.uniform(-amount, amount), rng.uniform(-amount, amount)))
    bm.to_mesh(obj.data)
    bm.free()


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    bpy.context.active_object.name = name
    return bpy.context.active_object


def ground_origin(obj):
    """Move origin to bottom-centre of the bounding box so the prop sits on y=0 in Godot."""
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    cx = sum(v.x for v in bb) / 8
    cy = sum(v.y for v in bb) / 8
    zmin = min(v.z for v in bb)
    bpy.context.scene.cursor.location = (cx, cy, zmin)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    obj.location = (0, 0, 0)


def tri_count(objs):
    total = 0
    for o in objs:
        dg = bpy.context.evaluated_depsgraph_get()
        m = o.evaluated_get(dg).to_mesh()
        m.calc_loop_triangles()
        total += len(m.loop_triangles)
    return total


def export_glb(path, objs=None):
    """Export selected/all mesh objects to .glb (Y-up). Prints tri count for budgeting."""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    meshes = objs or [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_materials="EXPORT", export_cameras=False, export_lights=False)
    print(f"EXPORT ok {path}  tris={tri_count(meshes)}")
