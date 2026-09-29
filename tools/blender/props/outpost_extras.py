"""Outpost variant extras (outpost_variants.py): pieces only some wells have, and the interior mirror used by Outpost 02.
Each builder takes the generator namespace `c` (helpers B, CYL, PIPE, TUBE, COL, DECAL, LIQ_CYL, POOL, CRYSTALS, lists
parts / cols, materials M_* / D_*, dimensions HX, HY, CX, CY, FZ, WIX, WIY) like o73_exterior.build.
Same art rules as Outpost 73 (tools/README.md "Theme"): obsidian, dark rust, colour only from amber, nothing floats."""
import math

import bmesh
import bpy
from mathutils import Matrix, Vector

import ps1_ao as AO
import ps1_lib as L


# ================================================================ interior mirror
def mark(*lists):
    """Remember where each part list is now; mirror_x later flips everything appended after this point."""
    return [(lst, len(lst)) for lst in lists]


def mirror_x(marks, flip_uv=()):
    """Mirror the parts added since `mark` across the x = 0 plane (bakes their transforms). Faces are reversed so they
    still face out; quads in `flip_uv` lists (decals, screens) get their U flipped so text reads the right way round."""
    bpy.context.view_layer.update()
    s = Matrix.Scale(-1.0, 4, (1.0, 0.0, 0.0))
    flip = {id(lst) for lst in flip_uv}
    for lst, start in marks:
        for o in lst[start:]:
            if o.data.users > 1:
                o.data = o.data.copy()
            o.data.transform(s @ o.matrix_world)
            o.matrix_world = Matrix.Identity(4)
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bmesh.ops.reverse_faces(bm, faces=bm.faces[:])
            bm.to_mesh(o.data)
            bm.free()
            if id(lst) in flip:
                for layer in o.data.uv_layers:
                    us = [d.uv.x for d in layer.data]
                    lo, hi = min(us), max(us)
                    for d in layer.data:
                        d.uv.x = lo + hi - d.uv.x
            o.data.update()


# ================================================================ 03: the well overflowed
def flood(c):
    """Interior: amber came up through the floor beside the riser. A wider glowing spill with a crust rim, a floor crack,
    crystal growing out of the rear-left corner and round the riser, the rear-wall sleeve weeping down the plate."""
    fz = c.FZ
    c.POOL("flood_spill", (c.WIX + 0.55, c.WIY - 0.55, fz + 0.034), 2.6, 2.1)
    c.DECAL("flood_crust", (c.WIX + 0.6, c.WIY - 0.6, fz + 0.02), 3.0, 2.6, "+z", c.D_CRUST, up=(0, 1, 0))
    c.DECAL("flood_crack", (-0.35, 0.3, fz + 0.021), 0.55, 1.5, "+z", c.D_CRACK, up=(1, 0.4, 0))
    c.CRYSTALS("flood_cr_corner", -1.95, 1.62, fz, 5, 0.2, 23, 0.9)
    c.CRYSTALS("flood_cr_well", c.WIX, c.WIY, fz, 6, 0.75, 29, 1.0)
    c.DECAL("flood_drips", (0.1, c.CY - 0.058, 1.35), 0.7, 1.9, "-y", c.D_DRIPS)
    c.DECAL("flood_stain_w", (-1.2, c.CY - 0.059, 0.75), 1.3, 1.0, "-y", c.D_STAIN)


def overgrowth(c):
    """Exterior: 200 years of overflow crystallised round the wellhead, over the stalled pump skid and along the rear
    plinth; the spill spread out across the yard."""
    wx, wy = 1.9, 5.6
    c.CRYSTALS("og_wh", wx, wy, 0.0, 8, 1.5, 41, 1.5)
    c.CRYSTALS("og_pad", -0.75, wy, 0.2, 5, 0.55, 43, 0.9)
    c.CRYSTALS("og_plinth", -2.4, c.HY + 0.55, 0.0, 4, 0.35, 47, 1.1)
    c.CRYSTALS("og_pit", 3.6, 6.45, 0.0, 3, 0.25, 53, 0.8)
    c.POOL("og_spill", (wx - 0.9, wy - 1.1, 0.05), 4.4, 3.0)
    c.DECAL("og_crust", (wx - 0.9, wy - 1.2, 0.035), 5.2, 3.6, "+z", c.D_CRUST, up=(0, 1, 0))


def tanks(c):
    """Two horizontal amber storage tanks on concrete saddles beside the right wall: they took the overflow when the pump
    stalled, fed from the valve pit, and weep at the seams. Tank axis along Y."""
    y0, zc, r, ln = 1.3, 1.02, 0.72, 3.2
    for i, x in enumerate((5.35, 6.95)):
        c.CYL(f"tank{i}", r, ln, (x, y0, zc), c.M_MET_D, "y", 14)
        for s in (-1, 1):
            c.CYL(f"tank{i}_cap{s}", r - 0.06, 0.16, (x, y0 + s * (ln / 2 + 0.08), zc), c.M_MET_D, "y", 14)
            c.CYL(f"tank{i}_band{s}", r + 0.015, 0.07, (x, y0 + s * 1.0, zc), c.M_RUST, "y", 14)
            c.B(f"tank{i}_saddle{s}", (1.1, 0.35, 0.55), (x, y0 + s * 1.0, 0.2), c.M_CON_T, 0.05)
        c.CYL(f"tank{i}_manway", 0.2, 0.14, (x, y0 + 0.6, zc + r + 0.04), c.M_MET, "z", 10)
        c.CYL(f"tank{i}_lid", 0.23, 0.04, (x, y0 + 0.6, zc + r + 0.12), c.M_MET_D, "z", 10)
        gx, gy = x + 0.42, y0 - ln / 2 - 0.26                                            # level gauge on the front cap
        for z in (0.55, 1.45):
            c.TUBE(f"tank{i}_gauge_stub{z}", (gx, gy + 0.1, z), (gx, gy - 0.02, z), 0.025, c.M_MET, 6)
        c.LIQ_CYL(f"tank{i}_gauge", 0.035, 0.95, (gx, gy - 0.02, 1.0), "z", 6)
        c.DECAL(f"tank{i}_drips", (x - 0.2, y0 - ln / 2 - 0.165, 0.95), 0.7, 0.9, "-y", c.D_DRIPS)
        c.POOL(f"tank{i}_pool", (x, y0 - 0.4, 0.04 + 0.004 * i), 1.8, 2.4)
    c.PIPE("tank_link", [(5.35, y0 + ln / 2 + 0.16, 1.45), (5.35, y0 + ln / 2 + 0.45, 1.45), (6.95, y0 + ln / 2 + 0.45, 1.45),
                         (6.95, y0 + ln / 2 + 0.16, 1.45)], 0.07, clamps=0.9)
    # fill line: out of the valve pit, along the yard, into the first tank's rear cap
    c.PIPE("tank_fill", [(4.15, 5.4, -0.3), (4.15, 5.4, 0.55), (5.35, 5.4, 0.55), (5.35, y0 + ln / 2 + 0.16, 0.55)], 0.08,
           clamps=0.9)
    c.TUBE("tank_fill_valve_stem", (5.35, 4.4, 0.63), (5.35, 4.4, 0.95), 0.025, c.M_MET, 6)
    c.CYL("tank_fill_valve_wheel", 0.15, 0.03, (5.35, 4.4, 0.97), c.M_MET_D, v=8)
    c.LIQ_CYL("tank_fill_glass", 0.098, 0.26, (5.35, 3.85, 0.55), "y")
    c.CRYSTALS("tank_cr0", 5.35, y0 - 1.0, 0.0, 4, 0.55, 31, 0.9)
    c.CRYSTALS("tank_cr1", 6.95, y0 + 1.0, 0.0, 3, 0.5, 37, 0.8)
    c.DECAL("tank_crust", (6.15, y0 - 0.2, 0.03), 3.4, 3.2, "+z", c.D_CRUST, up=(0, 1, 0))
    c.COL("tanks_c", (3.1, 3.7, 1.8), (6.15, y0, 0.9))


# ================================================================ 02: the tree that took the dish
def tree(c):
    """A dead tree came down from behind the rear-left corner: its root plate tore out of the ground, the trunk crushed
    the corner (the variant's roof break) and lies across the roof toward the front-right, where it swept the dish off."""
    dirt = L.material("bunker_dirt", (0.016, 0.012, 0.01))
    a, b = Vector((-7.2, 6.4, 0.25)), Vector((-3.2, 2.85, 4.28))
    pts = [a, b, Vector((0.2, -0.25, 4.76)), Vector((2.5, -2.3, 4.7)), Vector((3.55, -3.3, 4.62))]
    for i, rad in enumerate((0.3, 0.27, 0.21, 0.13)):
        c.TUBE(f"trunk{i}", tuple(pts[i]), tuple(pts[i + 1]), rad, c.M_WOOD, 8)
    c.TUBE("trunk_tip", tuple(pts[4]), (3.9, -3.55, 4.58), 0.08, c.M_WOOD, 6)                   # snapped top
    u = (b - a).normalized()
    v1 = u.cross(Vector((0, 0, 1))).normalized()
    v2 = v1.cross(u)
    plate = AO.tube("root_plate", a - u * 0.5, a - u * 0.12, 1.15, dirt, 10)                   # torn-up root plate
    L.jitter(plate, 0.1, 61)
    c.parts.append(plate)
    for k in range(7):                                                                          # roots out of the plate
        ang = k * math.tau / 7 + 0.3
        rim = a - u * 0.3 + (v1 * math.cos(ang) + v2 * math.sin(ang)) * 0.95
        tip = rim + (v1 * math.cos(ang) + v2 * math.sin(ang)) * 0.55 - u * 0.25
        tip.z = min(tip.z, -0.05) if k % 2 else tip.z
        c.TUBE(f"root{k}", tuple(rim), tuple(tip), 0.06 - 0.004 * k, c.M_WOOD, 5)
    for i, (t, seg, off, rad) in enumerate(((0.7, 0, (-0.6, -1.1, 1.3), 0.07), (0.55, 1, (-0.85, -1.6, 0.03), 0.06),
                                            (0.5, 2, (0.2, 0.85, 1.1), 0.06), (0.3, 2, (0.95, 1.35, -0.16), 0.05),
                                            (0.2, 3, (0.7, 0.8, 0.32), 0.045))):
        p0 = pts[seg].lerp(pts[seg + 1], t)                                                     # dead limbs
        p1 = p0 + Vector(off)
        c.TUBE(f"limb{i}", tuple(p0), tuple(p1), rad, c.M_WOOD, 5)
        c.TUBE(f"twig{i}", tuple(p1), tuple(p1 + Vector((0.25, -0.2, 0.3 if off[2] > 0.5 else 0.02))), rad * 0.45, c.M_WOOD, 4)
    hole = a - Vector((u.x, u.y, 0)).normalized() * 1.1
    c.DECAL("tree_hole", (hole.x, hole.y, 0.013), 2.6, 2.6, "+z", c.D_STAIN, up=(0, 1, 0))
    c.DECAL("tree_dust", (-0.6, 0.4, 4.516), 2.4, 2.4, "+z", c.D_DUST, up=(0, 1, 0))
    c.cols.append(AO.tube("tree_c", tuple(a), tuple(b), 0.3, None, 6))
    c.cols.append(AO.tube("root_plate_c", tuple(a - u * 0.5), tuple(a - u * 0.12), 1.1, None, 8))


def fallen_dish(c):
    """The comm dish the tree swept off the roof: tipped on its rim by the front-right corner, bowl to the sky, the torn
    mount stub dug into the ground, its feed cable still hanging over the cornice from the pedestal."""
    import o73_exterior as EXT
    dish = EXT.dish_parts(c, Vector((0, 0, 0)))
    L.rotate_about(dish, (0, 0, 0), (24, 0, 45))
    zmin = min((o.matrix_world @ v.co).z for o in dish for v in o.data.vertices)        # the rim rests on the ground
    stub = AO.tube("dish_stub", (0, 0, 0), (0, 0, -0.6), 0.05, c.M_MET_D, 6)          # torn mount, dug into the soil
    L.rotate_about([stub], (0, 0, 0), (24, 0, 45))
    dish.append(stub)
    hub = Vector((5.3, -4.3, -zmin - 0.04))
    move = Matrix.Translation(hub)
    for o in dish:
        o.matrix_world = move @ o.matrix_world
    c.parts.extend(dish)
    c.PIPE("dish_cable", [(1.0, 0.36, 4.52), (3.35, -2.95, 4.52), (3.86, -3.5, 4.52), (4.02, -3.66, 4.3),
                          (4.3, -3.9, 1.6), (hub.x - 0.12, hub.y + 0.05, hub.z + 0.1)], 0.02, mat=c.M_CABLE, verts=4)
    c.DECAL("dish_scrape", (4.55, -3.5, 0.013), 1.6, 1.6, "+z", c.D_DUST, up=(0, 1, 0))
    c.COL("dish_c", (1.3, 1.3, 1.1), (hub.x, hub.y, 0.55))
