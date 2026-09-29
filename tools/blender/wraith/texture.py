"""The wraith's skin as a node shader (baked onto the game mesh by bake.py, with a normal map so the ribs, the face and
every tendon survive the decimation). The albedo is procedural, not paint:
  sallow grey skin mottled yellow and bruise-blue, pores; dark violet veins; black in every crease (AO); paler over bone
  masks per vertex (colour attribute "masks", masks()): R scalp (dark, the hair's roots), G blood (dried, round the mouth,
  running down the chin, on the fingertips), B grime (feet, shins, hands), A sockets (near black round the eyes)
"""
import bpy
import numpy as np



def masks(body, rest, w, groups, eyes, mouth, scalp_idx, iters=6):
    n = len(rest)
    m = np.zeros((n, 4), np.float32)
    m[scalp_idx, 0] = 1.0
    d_mouth = np.linalg.norm((rest - np.array(mouth)) * [1.0, 1.4, 1.0], axis=1)
    drip = (np.abs(rest[:, 0]) < 0.035) & (rest[:, 2] < mouth.z) & (rest[:, 2] > mouth.z - 0.16) & (rest[:, 1] < mouth.y + 0.05)
    lane = (np.sin(rest[:, 0] * 380.0) * np.sin(rest[:, 0] * 157.0 + 1.3)) > 0.35    # a few runs, not a sheet
    fall = np.clip(1.0 - (mouth.z - rest[:, 2]) / 0.16, 0.0, 1.0)
    tips = sum(w[:, groups.index(g)] for g in groups if g.startswith("f3_"))
    m[:, 1] = np.maximum.reduce([np.clip(1.4 - d_mouth / 0.035, 0, 1), drip * lane * fall, np.clip(tips * 1.2, 0, 0.8)])
    hands = sum(w[:, groups.index(g)] for g in groups if g.startswith(("hand", "f1_", "f2_", "f3_")))
    m[:, 2] = np.maximum(np.clip((0.55 - rest[:, 2]) / 0.4, 0, 1), hands * 0.6)
    d_eye = np.min([np.linalg.norm(rest - np.array(e), axis=1) for e in eyes], axis=0)
    m[:, 3] = np.clip(1.0 - (d_eye - 0.012) / 0.022, 0, 1)
    e = np.array([ed.vertices[:] for ed in body.data.edges], dtype=np.int64)
    deg = np.bincount(e.ravel(), minlength=n).astype(np.float32)[:, None]
    for _ in range(iters):
        acc = np.zeros_like(m)
        np.add.at(acc, e[:, 0], m[e[:, 1]])
        np.add.at(acc, e[:, 1], m[e[:, 0]])
        m = 0.5 * m + 0.5 * acc / np.maximum(deg, 1.0)
    attr = body.data.color_attributes.new("masks", "FLOAT_COLOR", "POINT")
    attr.data.foreach_set("color", m.ravel())


def _n(nt, kind, **props):
    node = nt.nodes.new(kind)
    for k, v in props.items():
        if k.startswith("in_"):
            node.inputs[k[3:].replace("_", " ")].default_value = v
        else:
            setattr(node, k, v)
    return node


def _mix(nt, a, b, fac, blend="MIX"):
    mx = _n(nt, "ShaderNodeMix", data_type="RGBA", blend_type=blend)
    nt.links.new(fac, mx.inputs["Factor"])
    for sock, v in ((mx.inputs[6], a), (mx.inputs[7], b)):
        if isinstance(v, tuple):
            sock.default_value = (*v, 1.0)
        else:
            nt.links.new(v, sock)
    return mx.outputs[2]


def skin_shader(m):
    """Emission = the albedo, so an EMIT bake captures exactly it."""
    nt = m.node_tree
    nt.nodes.clear()
    L = nt.links.new
    co = _n(nt, "ShaderNodeTexCoord").outputs["Object"]
    mottle = _n(nt, "ShaderNodeTexNoise", **{"in_Scale": 9.0, "in_Detail": 6.0})
    L(co, mottle.inputs["Vector"])
    bruise = _n(nt, "ShaderNodeTexNoise", **{"in_Scale": 3.5, "in_Detail": 3.0, "in_Distortion": 0.6})
    L(co, bruise.inputs["Vector"])
    pores = _n(nt, "ShaderNodeTexNoise", **{"in_Scale": 260.0, "in_Detail": 2.0})
    L(co, pores.inputs["Vector"])
    warp = _n(nt, "ShaderNodeTexNoise", **{"in_Scale": 6.0, "in_Detail": 2.0})
    L(co, warp.inputs["Vector"])
    vwarp = _n(nt, "ShaderNodeVectorMath", operation="MULTIPLY_ADD")
    L(warp.outputs["Color"], vwarp.inputs[0])
    vwarp.inputs[1].default_value = (0.12, 0.12, 0.12)
    L(co, vwarp.inputs[2])
    veins = _n(nt, "ShaderNodeTexVoronoi", feature="DISTANCE_TO_EDGE", **{"in_Scale": 16.0})
    L(vwarp.outputs[0], veins.inputs["Vector"])
    vmask = _n(nt, "ShaderNodeMapRange", **{"in_From_Min": 0.0, "in_From_Max": 0.03, "in_To_Min": 0.4, "in_To_Max": 0.0})
    L(veins.outputs["Distance"], vmask.inputs["Value"])
    patchy = _n(nt, "ShaderNodeMapRange", **{"in_From_Min": 0.5, "in_From_Max": 0.62, "in_To_Min": 0.0, "in_To_Max": 1.0})
    L(bruise.outputs["Fac"], patchy.inputs["Value"])                                   # veins only show in patches
    vpatch = _n(nt, "ShaderNodeMath", operation="MULTIPLY")
    L(vmask.outputs[0], vpatch.inputs[0])
    L(patchy.outputs[0], vpatch.inputs[1])
    ao = _n(nt, "ShaderNodeAmbientOcclusion", samples=24, **{"in_Distance": 0.035})
    geo = _n(nt, "ShaderNodeNewGeometry")
    edge = _n(nt, "ShaderNodeMapRange", **{"in_From_Min": 0.5, "in_From_Max": 0.62, "in_To_Min": 0.0, "in_To_Max": 0.35})
    L(geo.outputs["Pointiness"], edge.inputs["Value"])
    attr = _n(nt, "ShaderNodeAttribute", attribute_name="masks")
    sep = _n(nt, "ShaderNodeSeparateColor")
    L(attr.outputs["Color"], sep.inputs["Color"])
    c = _mix(nt, (0.44, 0.43, 0.39), (0.47, 0.42, 0.3), mottle.outputs["Fac"])           # sallow
    c = _mix(nt, c, (0.3, 0.31, 0.37), bruise.outputs["Fac"], "DARKEN")                  # bruised in places
    c = _mix(nt, c, (0.36, 0.33, 0.3), pores.outputs["Fac"], "MULTIPLY")
    c = _mix(nt, c, (0.62, 0.61, 0.57), edge.outputs[0])                                  # pale over bone
    c = _mix(nt, c, (0.17, 0.13, 0.22), vpatch.outputs[0])                                # veins
    c = _mix(nt, c, (0.2, 0.17, 0.12), sep.outputs["Blue"])                               # grime
    c = _mix(nt, c, (0.07, 0.012, 0.008), sep.outputs["Green"])                          # dried blood, near black
    c = _mix(nt, c, (0.028, 0.026, 0.025), sep.outputs["Red"])                            # the scalp under the hair
    c = _mix(nt, c, (0.015, 0.012, 0.012), attr.outputs["Alpha"])                        # sockets
    aof = _n(nt, "ShaderNodeMapRange", **{"in_From_Min": 0.2, "in_From_Max": 1.0, "in_To_Min": 0.15, "in_To_Max": 1.0})
    L(ao.outputs["AO"], aof.inputs["Value"])
    grey = _n(nt, "ShaderNodeCombineColor")
    for i in range(3):
        L(aof.outputs[0], grey.inputs[i])
    c = _mix(nt, c, grey.outputs[0], _one(nt), "MULTIPLY")
    em = _n(nt, "ShaderNodeEmission")
    L(c, em.inputs["Color"])
    out = _n(nt, "ShaderNodeOutputMaterial")
    L(em.outputs[0], out.inputs["Surface"])


def _one(nt):
    v = _n(nt, "ShaderNodeValue")
    v.outputs[0].default_value = 1.0
    return v.outputs[0]
