"""Baking the wraith's skin (texture.py's shader) from the detailed posed body onto the lighter game mesh (build.py):
unwrap() gives it fresh UVs with the head blown up so the face gets a big share of the texture; bake() writes the albedo and
a tangent normal map (models/generated/tex/wraith_skin(_n).png); game_material() is what the .glb carries.
"""
import os

import bmesh
import bpy
import numpy as np

import wlib as W

SIZE = 2048
TEX_DIR = os.path.join(W.ROOT, "models", "generated", "tex")


def _target(lo, name, colour):
    img = bpy.data.images.new(name, SIZE, SIZE, alpha=False, float_buffer=False)
    if not colour:
        img.colorspace_settings.name = "Non-Color"
    m = lo.data.materials[0]
    node = m.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = img
    m.node_tree.nodes.active = node
    return img, node


def bake(hi, lo, samples=16):
    """hi's emission (skin_shader) -> albedo, hi's surface -> tangent normals, both onto lo's UVs. Returns the image paths."""
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = samples
    sc.cycles.use_denoising = False
    bk = sc.render.bake
    bk.use_selected_to_active = True
    bk.cage_extrusion = 0.025
    bk.max_ray_distance = 0.08
    bk.margin = 8
    W.activate(lo)
    hi.select_set(True)
    os.makedirs(TEX_DIR, exist_ok=True)
    paths = []
    for name, kind, colour in (("wraith_skin", "EMIT", True), ("wraith_skin_n", "NORMAL", False)):
        img, node = _target(lo, name, colour)
        bpy.ops.object.bake(type=kind)
        img.filepath_raw = os.path.join(TEX_DIR, name + ".png")
        img.file_format = "PNG"
        img.save()
        lo.data.materials[0].node_tree.nodes.remove(node)
        paths.append(img.filepath_raw)
    return paths


def game_material(name, albedo, normal, rough=0.5):
    """What the .glb carries: albedo + normal map (Godot's WraithView builds its own shader from these textures)."""
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    b.inputs["Roughness"].default_value = rough
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = bpy.data.images.load(albedo)
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    tn = nt.nodes.new("ShaderNodeTexImage")
    tn.image = bpy.data.images.load(normal)
    tn.image.colorspace_settings.name = "Non-Color"
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nt.links.new(tn.outputs["Color"], nm.inputs["Color"])
    nt.links.new(nm.outputs["Normal"], b.inputs["Normal"])
    return m


def unwrap(lo, head_c, head_r, boost=2.6):
    """Fresh UVs for the game mesh (the base mesh's are spread over UDIM tiles). The head is blown up while it unwraps,
    so its islands, and so the face, get several times their share of the texture; then put back."""
    co = np.zeros(len(lo.data.vertices) * 3)
    lo.data.vertices.foreach_get("co", co)
    pts = co.reshape(-1, 3)
    c = np.array(head_c)
    d = np.linalg.norm(pts - c, axis=1)
    f = np.interp(d, [head_r, head_r * 1.6], [boost, 1.0])
    lo.data.vertices.foreach_set("co", (c + (pts - c) * f[:, None]).ravel())
    lo.data.update()
    while lo.data.uv_layers:
        lo.data.uv_layers.remove(lo.data.uv_layers[0])
    lo.data.uv_layers.new(name="UVMap")
    W.activate(lo)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=1.4, island_margin=0.002, area_weight=0.6)
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=0.002)
    bpy.ops.object.mode_set(mode="OBJECT")
    uv = np.zeros(len(lo.data.loops) * 2)                                     # the packer leaves half the square empty:
    lo.data.uv_layers.active.data.foreach_get("uv", uv)                       # stretch the layout to fill it
    uv = uv.reshape(-1, 2)
    lo_, hi_ = uv.min(0), uv.max(0)
    uv = (uv - lo_) / np.maximum(hi_ - lo_, 1e-6) * 0.996 + 0.002
    lo.data.uv_layers.active.data.foreach_set("uv", uv.ravel())
    lo.data.vertices.foreach_set("co", co)
    lo.data.update()


def decimated(hi, ratio):
    """The game mesh: a copy of the detailed body keeping `ratio` of its faces (vertex groups and UVs survive)."""
    lo = hi.copy()
    lo.data = hi.data.copy()
    lo.name = "wraith_body"
    bpy.context.collection.objects.link(lo)
    mod = lo.modifiers.new("dec", "DECIMATE")
    mod.ratio = ratio
    W.apply_all(lo)
    bm = bmesh.new()
    bm.from_mesh(lo.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(lo.data)
    bm.free()
    return lo
