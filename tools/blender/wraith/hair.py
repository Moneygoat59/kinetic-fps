"""Long wet black hair as hair cards (how games do hair): ribbons carrying a generated texture of many fine strands with
alpha (strand_texture), each following a strand curve rooted on the scalp. A curve leaves the scalp along its normal, curves
over and falls; it is kept off the body (BVH), so it lies over the skull and shoulders and hangs round the face. The cards
are wide at the root and taper, turned to face out from the head; an inner layer is denser than the outer.
build(body, scalp, m, head_centre) -> the hair object (UVs: u across the card, v root 0 -> tip 1).
"""
import math
import os
import random

import bmesh
import bpy
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

import wlib as W

CARDS = 300
LENGTH = (0.4, 0.9)
STEP = 0.024
WIDTH = (0.009, 0.02)       # at the root
FACE_R = 0.085              # hair is kept this far out from the line straight out of the face
PART_LEN = 0.22             # ... for this far in front of it
CAP_CARDS = 55              # slicked back over the crown
CAP_LENGTH = (0.25, 0.5)
GAP = 0.005                 # hair keeps this far off the skin
TEX = os.path.join(W.ROOT, "models", "generated", "tex", "wraith_hair.png")


def strand_texture(path=TEX, w=256, h=1024, seed=3):
    """A wet clump: fine dark strands packed in the middle of the card, fraying out to its edges and thinning to the tip."""
    rng = np.random.default_rng(seed)
    rgba = np.zeros((h, w, 4), np.float32)
    v = np.linspace(0.0, 1.0, h)[:, None]
    for _ in range(300):
        x0 = np.clip(rng.normal(0.5, 0.2), 0.03, 0.97) * w                 # clumped: dense in the middle, frayed out
        end = rng.uniform(0.6, 1.0) - abs(x0 / w - 0.5) * 0.5          # the outer strands end sooner
        wave = rng.uniform(1.0, 5.0) * np.sin(v * rng.uniform(4, 11) + rng.uniform(0, 6.3))
        xs = x0 + wave + (v - 0.5) * rng.uniform(-10, 10)
        width = rng.uniform(0.7, 1.6)
        d = np.abs(np.arange(w)[None, :] - xs)
        a = np.clip(1.0 - d / width, 0.0, 1.0) * (v < end) * np.clip((end - v) / 0.12, 0.0, 1.0)
        shade = rng.uniform(0.015, 0.07)
        rgba[..., :3] = np.where(a[..., None] > rgba[..., 3:4], shade, rgba[..., :3])
        rgba[..., 3] = np.maximum(rgba[..., 3], a * rng.uniform(0.6, 1.0))
    edge = np.clip(np.minimum(np.arange(w), w - 1 - np.arange(w)) / (w * 0.12), 0.0, 1.0)[None, :]
    rgba[..., 3] *= edge
    img = bpy.data.images.new("wraith_hair", w, h, alpha=True)
    img.pixels.foreach_set(np.flipud(rgba).ravel())                          # Blender images start at the bottom row
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    return img


def _part(p, face):
    """Keep hair out of a tube running forward from the face (eyes, mouth), so it hangs either side like a curtain."""
    eyes, fwd = face
    rel = p - eyes
    along = rel.dot(fwd)
    if along < -0.03 or along > PART_LEN:
        return p
    radial = rel - fwd * along
    radial.z *= 0.6                                                           # an oval: longer than it is wide
    if radial.length >= FACE_R:
        return p
    out = radial.normalized() if radial.length > 1e-4 else Vector((1.0, 0.0, 0.0))
    return eyes + fwd * along + out * FACE_R


def _strand(root, normal, length, tree, rng, face, start=None):
    pts = [root + normal * GAP]
    d = (start if start is not None else normal).copy()
    phase = rng.random() * 6.28
    n = max(4, int(length / STEP))
    for k in range(n):
        t = k / n
        g = min(1.0, 0.08 + t * 1.8)
        d = (d * (1.0 - g) + Vector((0.0, 0.0, -1.0)) * g).normalized()
        wave = Vector((math.sin(phase + t * 9.0), math.cos(phase * 1.3 + t * 7.0), 0.0)) * 0.005
        p = _part(pts[-1] + d * STEP + wave, face)
        loc, nrm, _, _ = tree.find_nearest(p)
        if loc is not None and (p - loc).dot(nrm) < GAP:
            p = loc + nrm * GAP
        pts.append(p)
    return pts


def _card(bm, uv, pts, width, centre):
    rows = []
    for i, p in enumerate(pts):
        t = i / (len(pts) - 1)
        tan = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        out = p - centre
        out.z = 0.0
        side = tan.cross(out.normalized() if out.length > 1e-4 else Vector((0.0, -1.0, 0.0))).normalized()
        half = width * (1.0 - 0.7 * t) * 0.5
        rows.append((bm.verts.new(p - side * half), bm.verts.new(p + side * half), t))
    for (a0, a1, t0), (b0, b1, t1) in zip(rows, rows[1:]):
        f = bm.faces.new((a0, a1, b1, b0))
        for loop, co in zip(f.loops, ((0.0, 1 - t0), (1.0, 1 - t0), (1.0, 1 - t1), (0.0, 1 - t1))):
            loop[uv].uv = co


def build(body, scalp, m, centre, face, cap=(), seed=5):
    """scalp: vertex indices of `body` hair grows from; centre: the head's centre (cards face away from it);
    face: (between the eyes, face forward) - the hair parts round it."""
    rng = random.Random(seed)
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    verts = body.data.vertices
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    for i in range(CARDS):
        v = verts[rng.choice(scalp)]
        inner = i < CARDS // 3                                                 # a close, dense layer first
        pts = _strand(v.co.copy(), v.normal.copy(), rng.uniform(*LENGTH) * (0.9 if inner else 1.0), tree, rng, face)
        _card(bm, uv, pts, rng.uniform(*WIDTH) * (1.3 if inner else 1.0), centre)
    back = -face[1]
    back.z = 0.0
    back.normalize()
    for _ in range(CAP_CARDS if cap else 0):                                # wet hair plastered back over the skull
        v = verts[rng.choice(cap)]
        start = (v.normal * 0.15 + back).normalized()
        pts = _strand(v.co.copy(), v.normal.copy(), rng.uniform(*CAP_LENGTH), tree, rng, face, start)
        _card(bm, uv, pts, rng.uniform(*WIDTH), centre)
    me = bpy.data.meshes.new("hair")
    bm.to_mesh(me)
    bm.free()
    o = W.link("wraith_hair", me)
    o.data.materials.append(m)
    W.shade_smooth(o)
    return o


def material(img):
    m = bpy.data.materials.new("wraith_hair")
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = img
    nt.links.new(t.outputs["Color"], b.inputs["Base Color"])
    nt.links.new(t.outputs["Alpha"], b.inputs["Alpha"])
    b.inputs["Roughness"].default_value = 0.6
    b.inputs["Specular IOR Level"].default_value = 0.25
    m.use_backface_culling = False
    return m
