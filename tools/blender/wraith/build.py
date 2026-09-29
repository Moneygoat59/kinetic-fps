"""The night-2 wraith, from the CC0 Human Base Meshes (source.py). Run: tools\\blender.ps1 tools/blender/wraith/build.py
  [-- preview]  (also render shots/wraith_face.png and shots/wraith_body.png in Blender)
-> models/generated/wraith.glb + models/generated/tex/wraith_skin(_n).png
1 load the realistic body and skeleton, fitted          (source)
2 starve the skin onto the bones                        (starve)
3 pose and stretch it: hunched, long, dangling          (pose, rig_groups)
4 open the sockets, cut the lips back, eyes and throat  (face)
5 long wet hair                                         (hair)
6 scale to HEIGHT, decimate, bake skin and normals      (texture, bake)
7 game rig, weights, eye markers, export                (rig_export)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import numpy as np  # noqa: E402
from mathutils import Vector  # noqa: E402

import face  # noqa: E402
import hair  # noqa: E402
import pose  # noqa: E402
import rig_export as R  # noqa: E402
import source  # noqa: E402
import starve  # noqa: E402
import bake  # noqa: E402
import texture  # noqa: E402
import wlib as W  # noqa: E402

OUT = os.path.join(W.ROOT, "models", "generated", "wraith.glb")
HEIGHT = 2.45               # feet (pointed down) to the top of the head, as it hangs
DECIMATE = 0.22             # of the detailed body's faces kept in the game mesh


def rigid(solved, g):
    p, pw, a = (np.array(x) for x in solved[g])
    return lambda pts: pw + (pts - p) @ a.T


def scalp(rest, head_w, eyes):
    """Rest-pose vertices hair grows from: the crown, sides and nape (hair.py parts it round the face); a few strays."""
    ez = sum(e.z for e in eyes) / 2
    ey = sum(e.y for e in eyes) / 2
    head = head_w > 0.8
    crown = head & (rest[:, 2] > ez + 0.035) & (rest[:, 1] > ey + 0.05)      # behind the front (that is dark scalp)
    sides = head & (np.abs(rest[:, 0]) > 0.055) & (rest[:, 2] > ez - 0.03)
    nape = head & (rest[:, 1] > ey + 0.07) & (rest[:, 2] > ez - 0.05)
    front = head & (rest[:, 2] > ez + 0.05) & (rest[:, 1] <= ey + 0.05)
    ok = np.nonzero(crown | sides | nape)[0].tolist()
    strays = np.nonzero(front)[0].tolist()
    return ok + strays[:: max(1, len(strays) * 12 // max(len(ok), 1))]




def main():
    body, bones, eyes = source.load()
    cut_faces, mouth = face.select(body, bones, eyes)
    starve.starve(body, bones)
    rest = np.array([tuple(v.co) for v in body.data.vertices])
    groups, w, piv, solved = pose.pose(body, bones)
    face.cut(body, cut_faces)
    teeth_m = W.mat("wraith_teeth", (0.3, 0.23, 0.13), rough=0.45)
    eye_m = W.mat("wraith_eye", (0.004, 0.003, 0.003), rough=0.05)
    throat_m = W.mat("wraith_throat", (0.035, 0.006, 0.005), rough=0.4)
    hair_m = hair.material(hair.strand_texture())
    head = rigid(solved, "head")
    teeth = []
    for b in bones:
        if b.name.startswith("bone_tooth"):
            upper = b.name.startswith("bone_tooth_u")
            face._pose_obj(b, head if upper else rigid(solved, "jaw"))
            b.data.materials.clear()
            b.data.materials.append(teeth_m)
            W.shade_smooth(b)
            R.weigh_all(b, "head" if upper else "jaw")
            teeth.append(b)
        else:
            bpy.data.objects.remove(b)
    eye_objs, throat, glow = face.extras(eyes, mouth, head, eye_m, throat_m)
    scalp_idx = scalp(rest, w[:, groups.index("head")], eyes)
    mid = (glow[0] + glow[1]) * 0.5
    fwd = Vector(head(np.array([tuple(eyes[0] + Vector((0.0, -1.0, 0.0)))]))[0]) - Vector(head(np.array([tuple(eyes[0])]))[0])
    ez = sum(e.z for e in eyes) / 2
    cap = np.nonzero((w[:, groups.index("head")] > 0.8) & (rest[:, 2] > ez + 0.045))[0].tolist()
    hair_o = hair.build(body, scalp_idx, hair_m, mid + Vector((0.0, 0.07, 0.02)), (mid, fwd.normalized()), cap)
    texture.masks(body, rest, w, groups, eyes, mouth, scalp_idx)
    R.weigh(body, groups, w)
    zs = [v.co.z for v in body.data.vertices]
    k = HEIGHT / (max(zs) - min(zs))
    hips = solved["pelvis"][1]
    off = np.array([hips.x, hips.y, min(zs)])
    xf = lambda pts: (pts - off) * k                                          # noqa: E731
    vxf = lambda v: Vector(xf(np.array(tuple(v))))                            # noqa: E731
    W.transform([body, throat, hair_o] + teeth + eye_objs, xf)
    skin = bpy.data.materials.new("wraith_skin_src")
    skin.use_nodes = True
    texture.skin_shader(skin)
    body.data.materials.clear()
    body.data.materials.append(skin)
    W.shade_smooth(body)
    lo = bake.decimated(body, DECIMATE)
    bake.unwrap(lo, vxf((glow[0] + glow[1]) * 0.5), 0.14 * k)              # the head gets more of the texture
    albedo, normal = bake.bake(body, lo)
    lo.data.materials.clear()
    lo.data.materials.append(bake.game_material("wraith_skin", albedo, normal, rough=0.48))
    bpy.data.objects.remove(body)
    W.activate(teeth[0])
    for t in teeth:
        t.select_set(True)
    bpy.ops.object.join()
    teeth_o = bpy.context.active_object
    teeth_o.name = "wraith_teeth"
    for o in eye_objs + [throat]:
        R.weigh_all(o, "head")
    R.weigh_hair(hair_o, vxf(solved["head"][1]).z)
    rig = R.armature(solved, piv, vxf)
    R.bind(rig, [lo, teeth_o, hair_o, throat] + eye_objs)
    for i, g in enumerate(glow):
        R.marker(rig, f"glow_{'lr'[i]}", vxf(g))
    return lo, rig


if __name__ == "__main__":
    lo, rig = main()
    if "preview" in sys.argv:
        bpy.context.view_layer.update()
        eye = bpy.data.objects["glow_l"].matrix_world.translation.copy()
        print("EXPORT eye", tuple(round(c, 3) for c in eye))
        W.preview("wraith_face", (eye.x + 0.15, eye.y - 0.7, eye.z - 0.02), (eye.x + 0.03, eye.y, eye.z - 0.06), lens=70,
                  samples=40, size=(900, 900), key=(eye.x + 1.0, eye.y - 2.0, eye.z + 1.2))
        W.preview("wraith_body", (1.6, -5.0, 1.3), (0, 0, 1.15), lens=40, samples=24, size=(700, 1000), key=(2, -4, 4))
        for o in [o for o in bpy.data.objects if o.name.startswith("_pv")]:
            bpy.data.objects.remove(o)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True,
                              export_apply=False, export_materials="EXPORT", export_skins=True, export_cameras=False,
                              export_lights=False, export_animations=False)
    faces = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH")
    print(f"EXPORT ok {OUT} objects={len(bpy.data.objects)} faces={faces}")
