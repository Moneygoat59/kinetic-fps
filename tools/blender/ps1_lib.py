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
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
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


# ---------------------------------------------------------------- extended helpers (buildings)
def tex_material(name, image_path, tint=(1, 1, 1), roughness=1.0, emission=None, emission_strength=0.0):
    """Material with a nearest-filtered image texture (PS1 look). Optional emission colour/strength."""
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = 0.0  # matte PS1 look, no grazing-angle glints
    if image_path:
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(os.path.abspath(image_path))
        tex.interpolation = "Closest"
        if tint != (1, 1, 1):
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs[0].default_value = 1.0
            mix.inputs[7].default_value = (tint[0], tint[1], tint[2], 1.0)
            nt.links.new(tex.outputs["Color"], mix.inputs[6])
            nt.links.new(mix.outputs[2], bsdf.inputs["Base Color"])
        else:
            nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    else:
        bsdf.inputs["Base Color"].default_value = (tint[0], tint[1], tint[2], 1.0)
    if emission:
        bsdf.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return m


def screen_material(name, image_path, strength=1.0):
    """Emissive screen: black base, emission colour from a nearest-filtered image (CRT content)."""
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (0.01, 0.01, 0.01, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.abspath(image_path))
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def decal_material(name, image_path):
    """Alpha-blended, nearest-filtered decal material (stencils, stains, signs, notes). Exports as glTF alphaMode BLEND."""
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.abspath(image_path))
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    m.surface_render_method = "BLENDED"
    return m


def emissive_decal_material(name, image_path, strength=1.5):
    """Alpha-blended AND emissive (glowing puddles): colour + emission from the image, alpha from its alpha channel."""
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 1.0
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(os.path.abspath(image_path))
    tex.interpolation = "Closest"
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
    bsdf.inputs["Emission Strength"].default_value = strength
    m.surface_render_method = "BLENDED"
    return m


def quad(name, center, w, h, facing, mat, up=(0, 0, 1)):
    """Single quad facing an axis direction ('+x','-x','+y','-y','+z','-z'), UV 0..1 (image top = `up`).
    Used for screens and decals; the image is upright and unmirrored when viewed from the facing side."""
    n = Vector({"+x": (1, 0, 0), "-x": (-1, 0, 0), "+y": (0, 1, 0), "-y": (0, -1, 0), "+z": (0, 0, 1), "-z": (0, 0, -1)}[facing])
    upv = Vector(up)
    if abs(n.dot(upv)) > 0.99:      # floor/ceiling quads: image top points along +Y unless told otherwise
        upv = Vector((0, 1, 0))
    right = (-n).cross(upv).normalized()
    upv = n.cross(right)            # exact orthonormal frame: right x up = n
    c = Vector(center)
    verts = [c - right * w / 2 - upv * h / 2, c + right * w / 2 - upv * h / 2, c + right * w / 2 + upv * h / 2, c - right * w / 2 + upv * h / 2]
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(v) for v in verts], [], [[0, 1, 2, 3]])
    me.update()
    uv = me.uv_layers.new(name="UVMap")
    for i, p in enumerate(((0, 0), (1, 0), (1, 1), (0, 1))):
        uv.data[i].uv = p
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(mat)
    return o


def chamfer_box(name, size, loc, mat=None, c=0.1, rot_deg=(0, 0, 0)):
    o = box(name, size, loc, mat, rot_deg)
    mod = o.modifiers.new("bev", "BEVEL")
    mod.width = c
    mod.segments = 1
    mod.limit_method = "ANGLE"
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier="bev")
    return o


def prism(name, pts_xz, depth, loc=(0, 0, 0), mat=None, plane="xz"):
    """Extrude a polygon drawn in the XZ plane (list of (x,z)) along +Y by `depth`. loc offsets the whole prism.
    plane="yz": points are (y,z) and the extrusion runs along +X (side-profile solids such as wedge consoles)."""
    n = len(pts_xz)
    if plane == "yz":
        verts = [(0.0, y, z) for y, z in pts_xz] + [(depth, y, z) for y, z in pts_xz]
    else:
        verts = [(x, 0.0, z) for x, z in pts_xz] + [(x, depth, z) for x, z in pts_xz]
    faces = [list(range(n))[::-1], list(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append([i, j, n + j, n + i])
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.location = loc
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if mat:
        me.materials.append(mat)
    return o


def arch_pts(w, top, chamfer, base=0.25):
    """Open arch outline (XZ): up the left side, chamfered top corners, down the right side."""
    return [(-w, base), (-w, top - chamfer), (-w + chamfer, top), (w - chamfer, top), (w, top - chamfer), (w, base)]


def arch_ring(name, outer, inner, depth, loc=(0, 0, 0), mat=None):
    """Solid band between two open polylines (same point count, XZ plane), extruded along +Y by `depth`
    (door frames). Local y=0 is the face that should point outward."""
    n = len(outer)
    verts = ([(x, 0.0, z) for x, z in outer] + [(x, 0.0, z) for x, z in inner]
             + [(x, depth, z) for x, z in outer] + [(x, depth, z) for x, z in inner])
    o0, i0, o1, i1 = 0, n, 2 * n, 3 * n
    faces = []
    for k in range(n - 1):
        faces += [[o0 + k, o0 + k + 1, i0 + k + 1, i0 + k], [o1 + k, i1 + k, i1 + k + 1, o1 + k + 1],
                  [o0 + k, o1 + k, o1 + k + 1, o0 + k + 1], [i0 + k, i0 + k + 1, i1 + k + 1, i1 + k]]
    faces += [[o0, i0, i1, o1], [o0 + n - 1, o1 + n - 1, i1 + n - 1, i0 + n - 1]]
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    o.location = loc
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if mat:
        me.materials.append(mat)
    return o


def world_uv(obj, tile=2.0, tile_by_mat=None):
    """Box-project UVs from world coordinates so textures keep a constant texel density on every face.
    tile = metres per texture repeat; tile_by_mat maps material name -> tile for per-material density."""
    me = obj.data
    tile_by_mat = tile_by_mat or {}
    bm = bmesh.new()
    bm.from_mesh(me)
    uv = bm.loops.layers.uv.verify()
    mw = obj.matrix_world
    for f in bm.faces:
        n = (mw.to_3x3() @ f.normal)
        ax = max(range(3), key=lambda i: abs(n[i]))
        mat = me.materials[f.material_index] if f.material_index < len(me.materials) else None
        t = tile_by_mat.get(mat.name if mat else "", tile)
        for l in f.loops:
            p = mw @ l.vert.co
            u, v = [(p.y, p.z), (p.x, p.z), (p.x, p.y)][ax]
            l[uv].uv = (u / t, v / t)
    bm.to_mesh(me)
    bm.free()


def empty(name, loc):
    e = bpy.data.objects.new(name, None)
    e.empty_display_type = "ARROWS"
    e.location = loc
    bpy.context.collection.objects.link(e)
    return e


def export_all(path):
    """Export every object in the scene (meshes + empties) as .glb."""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_materials="EXPORT", export_cameras=False, export_lights=False,
                              export_vertex_color="ACTIVE", export_active_vertex_color_when_no_material=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    print(f"EXPORT ok {path}  objects={len(bpy.context.scene.objects)} tris={tri_count(meshes)}")


def ramp(name, x0, x1, y0, y1, z_bottom, z_at_y0, z_at_y1, mat=None):
    """Wedge solid: x0..x1 wide, y0..y1 long, flat bottom at z_bottom, top surface sloping from z_at_y0 to z_at_y1 (walkable ramp)."""
    v = [(x0, y0, z_bottom), (x0, y1, z_bottom), (x0, y1, z_at_y1), (x0, y0, z_at_y0),
         (x1, y0, z_bottom), (x1, y1, z_bottom), (x1, y1, z_at_y1), (x1, y0, z_at_y0)]
    f = [[0, 1, 2, 3], [7, 6, 5, 4], [0, 4, 5, 1], [3, 2, 6, 7], [0, 3, 7, 4], [1, 5, 6, 2]]
    me = bpy.data.meshes.new(name)
    me.from_pydata(v, [], f)
    me.update()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    if mat:
        me.materials.append(mat)
    return o
