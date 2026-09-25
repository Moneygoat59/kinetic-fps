"""Outpost 73 bunker v2: walkable dark-basalt blockhouse (exterior + furnished interior) from the concept sheet.
Run:  python tools/blender/textures.py   (once)   then   tools\\blender.ps1 tools/blender/props/outpost73_bunker.py
Out:  models/generated/outpost73_bunker.glb
Blender axes (Z up); front (door) faces -Y, exported to glTF +Z. 1 unit = 1 m.
Nodes: bunker_shell (visual, baked vertex-colour AO), shell-colonly (Godot builds trimesh collision),
       door_left / door_right (slide on local X, 1.0 m), marker_* empties (gameplay anchors, see outpost_bunker.gd).
Footprint 8.9 x 8.3 m at the plinth, 4.95 m tall (+ roof dish), foundation skirt to z=-1.
Interior 4.4 x 3.8 m, floor z=0.25, ceiling z=2.9. Door opening 1.8 x 2.25 m (blocker box in outpost_bunker.gd).
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import bpy  # noqa: E402
import ps1_lib as L  # noqa: E402
import ps1_ao as AO  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
OUT = os.path.join(ROOT, "models", "generated", "outpost73_bunker.glb")

L.reset()
T = lambda n: os.path.join(TEX, n)  # noqa: E731
M_BAS = L.tex_material("bunker_basalt", T("basalt.png"))
M_BAS_S = L.tex_material("bunker_basalt_smooth", T("basalt_smooth.png"))
M_FLOOR = L.tex_material("bunker_floor", T("floor.png"))
M_MET = L.tex_material("bunker_metal", T("metal.png"))
M_MET_D = L.tex_material("bunker_metal_dark", T("metal.png"), tint=(0.6, 0.6, 0.62))
M_PLATE = L.tex_material("bunker_plate", T("plate.png"))
M_RUST = L.material("bunker_rust", (0.2, 0.1, 0.05))
M_WIRE = L.material("bunker_wire", (0.32, 0.11, 0.04))
M_CABLE = L.material("bunker_cable", (0.03, 0.03, 0.028))
M_HAZ = L.material("bunker_hazard", (0.42, 0.07, 0.04))
M_AMBER = L.tex_material("bunker_glow_amber", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.2, 0.015), emission_strength=1.1)
M_GREEN = L.tex_material("bunker_glow_green", None, tint=(0.01, 0.05, 0.02), emission=(0.04, 0.7, 0.1), emission_strength=0.9)
M_STATIC = L.tex_material("bunker_glow_static", None, tint=(0.02, 0.022, 0.025), emission=(0.12, 0.15, 0.2), emission_strength=0.45)
TILES = {"bunker_metal": 1.0, "bunker_metal_dark": 1.0, "bunker_plate": 1.0}   # metres per texture repeat (default 2.0)

# ---- dimensions
HX, HY, H = 3.6, 3.3, 4.0          # wall planes (half-widths) and wall height
CX, CY = 2.2, 1.9                  # interior cavity half-widths
FZ, CZ = 0.25, 2.9                 # interior floor / ceiling heights
DW, DH = 0.9, 2.5                  # door half-width, door top

parts, cols, door_l, door_r = [], [], [], []


def B(name, size, loc, mat, c=0.0, rot=(0, 0, 0), into=None):
    o = L.chamfer_box(name, size, loc, mat, c, rot) if c else L.box(name, size, loc, mat, rot)
    (parts if into is None else into).append(o)
    return o


def CYL(name, r, d, loc, mat, axis="z", v=8, into=None):
    rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
    o = L.cylinder(name, r, d, loc, mat, v, rot)
    (parts if into is None else into).append(o)
    return o


def PIPE(name, pts, r, mat=M_MET_D, clamps=0.0, verts=8):
    parts.extend(AO.pipe(name, pts, r, mat, verts, clamps, M_MET))


def TUBE(name, p0, p1, r, mat=M_MET_D, verts=6):
    parts.append(AO.tube(name, p0, p1, r, mat, verts))


def COL(name, size, loc):
    cols.append(L.box(name, size, loc, None))


def slab(name, x0, x1, y0, y1, z0, z1, mat, col=True):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    B(name, size, loc, mat)
    if col:
        COL(name + "_c", size, loc)


def window(name, axis, pos, z, length, glow_mat=M_AMBER):
    """Recessed slit window with a raised surround. axis 'y': on a front/rear wall (long side along X);
    'x': on a side wall (long side along Y). pos = wall-plane coordinate (signed, outward = sign)."""
    s = 1 if pos > 0 else -1
    hl = length / 2
    if axis == "y":
        B(f"{name}_t", (length + 0.4, 0.16, 0.14), (0, pos, z + 0.2), M_MET_D, 0.02)
        B(f"{name}_b", (length + 0.4, 0.16, 0.14), (0, pos, z - 0.2), M_MET_D, 0.02)
        for sx in (-1, 1):
            B(f"{name}_e{sx}", (0.16, 0.16, 0.26), (sx * (hl + 0.1), pos, z), M_MET_D, 0.02)
        B(f"{name}_g", (length, 0.05, 0.2), (0, pos + s * 0.005, z), glow_mat)
    else:
        B(f"{name}_t", (0.16, length + 0.4, 0.14), (pos, 0, z + 0.2), M_MET_D, 0.02)
        B(f"{name}_b", (0.16, length + 0.4, 0.14), (pos, 0, z - 0.2), M_MET_D, 0.02)
        for sy in (-1, 1):
            B(f"{name}_e{sy}", (0.16, 0.16, 0.26), (pos, sy * (hl + 0.1), z), M_MET_D, 0.02)
        B(f"{name}_g", (0.05, length, 0.2), (pos + s * 0.005, 0, z), glow_mat)


# ================================================================ SHELL (walls, floor, ceiling, door reveal)
slab("floor", -HX, HX, -HY, HY, -1.0, FZ, M_FLOOR)   # extends 1 m below ground so it never floats on slopes
B("floor_top", (2 * CX, 2 * CY, 0.04), (0, 0, FZ - 0.01), M_FLOOR)
slab("back_wall", -HX, HX, CY, HY, FZ, H, M_BAS)
slab("wall_l", -HX, -CX, -CY, CY, FZ, H, M_BAS)
slab("wall_r", CX, HX, -CY, CY, FZ, H, M_BAS)
slab("ceiling", -CX, CX, -CY, CY, CZ, H, M_BAS_S)
# front wall: outer layer (wider reveal) + inner layer (door opening)
slab("front_outer_l", -HX, -1.15, -HY, -2.8, FZ, H, M_BAS, col=False)
slab("front_outer_r", 1.15, HX, -HY, -2.8, FZ, H, M_BAS, col=False)
slab("front_outer_top", -1.15, 1.15, -HY, -2.8, 2.75, H, M_BAS, col=False)
slab("front_in_l", -HX, -DW, -2.8, -CY, FZ, H, M_BAS)
slab("front_in_r", DW, HX, -2.8, -CY, FZ, H, M_BAS)
slab("front_in_top", -DW, DW, -2.8, -CY, DH, H, M_BAS)
COL("front_out_l_c", (HX - 1.15, HY - 2.8, H - FZ), (-(HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_r_c", (HX - 1.15, HY - 2.8, H - FZ), ((HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_top_c", (2.3, HY - 2.8, H - 2.75), (0, -(HY + 2.8) / 2, (H + 2.75) / 2))
for s in (-1, 1):   # chamfered opening corners (outer reveal + inner door opening) so the frame reads octagonal
    parts.append(L.prism(f"reveal_ch{s}", [(s * 1.15, 2.45), (s * 1.15, 2.75), (s * 0.85, 2.75)], 0.5, (0, -HY, 0), M_BAS_S))
    parts.append(L.prism(f"reveal_in{s}", [(s * DW, 2.25), (s * DW, DH), (s * 0.65, DH)], 0.9, (0, -2.8, 0), M_BAS_S))
# octagonal stepped door frame (exterior) and lighter interior frame
parts.append(L.arch_ring("frame_a", L.arch_pts(1.65, 3.2, 0.5), L.arch_pts(1.4, 2.95, 0.42), 0.24, (0, -HY - 0.24, 0), M_BAS_S))
parts.append(L.arch_ring("frame_b", L.arch_pts(1.4, 2.95, 0.42), L.arch_pts(1.15, 2.75, 0.3), 0.12, (0, -HY - 0.12, 0), M_BAS_S))
parts.append(L.arch_ring("frame_in", L.arch_pts(1.3, 2.9, 0.42), L.arch_pts(DW, DH, 0.25), 0.14, (0, -CY, 0), M_MET_D))
# walkable entrance ramp (CharacterBody3D cannot climb a 0.25 m vertical step): 0.25 m rise over 1.3 m (~11 deg)
parts.append(L.ramp("door_ramp", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, M_BAS_S))
cols.append(L.ramp("door_ramp_c", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, None))
window("win_front", "y", -HY, 3.42, 1.9)
B("win_brow", (2.6, 0.24, 0.1), (0, -HY - 0.12, 3.78), M_BAS_S, 0.03)

# ================================================================ EXTERIOR MASSING (plinth, stepped pilasters, cornice)
B("plinth_back", (8.9, 0.85, 1.5), (0, HY + 0.425, -0.25), M_BAS_S, 0.1)
for sx in (-1, 1):
    B(f"plinth_side{sx}", (0.85, 8.3, 1.5), (sx * 4.025, 0, -0.25), M_BAS_S, 0.1)
    B(f"plinth_front{sx}", (3.25, 0.85, 1.5), (sx * 2.825, -HY - 0.425, -0.25), M_BAS_S, 0.1)
    for sy in (-1, 1):
        B(f"boot{sx}{sy}", (2.0, 2.0, 0.5), (sx * 3.2, sy * 2.9, 0.75), M_BAS_S, 0.18)
        B(f"pilaster{sx}{sy}", (1.7, 1.7, 2.55), (sx * 3.15, sy * 2.85, 2.275), M_BAS, 0.26)
        B(f"pcap{sx}{sy}", (2.0, 2.0, 0.55), (sx * 3.2, sy * 2.9, 3.725), M_BAS_S, 0.2)
        B(f"roof_block{sx}{sy}", (2.2, 2.2, 0.5), (sx * 3.2, sy * 2.9, 4.7), M_BAS_S, 0.2)
B("cornice", (8.8, 8.2, 0.45), (0, 0, 4.225), M_BAS_S, 0.2)
COL("cornice_c", (8.8, 8.2, 0.45), (0, 0, 4.225))
B("roof_slab", (5.6, 5.0, 0.2), (0, 0, 4.55), M_BAS_S, 0.08)
B("seam_back", (4.6, 0.05, 0.07), (0, HY + 0.02, 1.75), M_MET_D)   # steel band seams between the pilasters
B("seam_l", (0.05, 4.0, 0.07), (-HX - 0.02, 0, 1.75), M_MET_D)
B("seam_r", (0.05, 4.0, 0.07), (HX + 0.02, 0, 1.75), M_MET_D)

# roof comm array
B("dish_base", (1.5, 1.5, 0.18), (1.0, 0.6, 4.74), M_BAS_S, 0.05)
B("dish_pedestal", (0.7, 0.6, 0.8), (1.0, 0.6, 5.23), M_MET_D, 0.06)
L.cone("dish", 0.08, 0.95, 0.42, (1.0, 0.3, 5.85), M_MET, 12)
parts.append(bpy.context.active_object)
bpy.context.active_object.rotation_euler = (math.radians(40), 0, 0)
d40 = (0.0, -math.sin(math.radians(40)), math.cos(math.radians(40)))
TUBE("dish_feed", (1.0, 0.3, 5.85), (1.0 + d40[0] * 0.8, 0.3 + d40[1] * 0.8, 5.85 + d40[2] * 0.8), 0.03)
TUBE("antenna_a", (0.2, 0.9, 4.83), (0.2, 0.9, 6.3), 0.025)
TUBE("antenna_b", (2.05, 0.35, 4.83), (2.05, 0.35, 5.8), 0.025)
B("antenna_base_a", (0.3, 0.3, 0.14), (0.2, 0.9, 4.75), M_MET_D, 0.02)
B("antenna_base_b", (0.3, 0.3, 0.14), (2.05, 0.35, 4.75), M_MET_D, 0.02)
B("roof_hatch", (1.0, 1.0, 0.18), (-2.2, -0.4, 4.74), M_BAS_S, 0.04)
CYL("roof_vent", 0.13, 0.45, (-1.3, 1.5, 4.88), M_MET_D, v=8)
CYL("roof_vent_cap", 0.2, 0.06, (-1.3, 1.5, 5.13), M_MET, v=8)

# rear: louvered vent box, elbowed clamped pipes, machine cabinet, dangling cable
B("vent_box", (1.9, 0.42, 1.9), (-0.9, HY + 0.21, 2.6), M_MET_D, 0.09)
B("vent_dark", (1.5, 0.05, 1.5), (-0.9, HY + 0.43, 2.6), M_BAS)
for i in range(7):
    B(f"vent_slat{i}", (1.44, 0.09, 0.1), (-0.9, HY + 0.47, 1.98 + i * 0.21), M_MET, rot=(28, 0, 0))
PIPE("pipe_a", [(0.05, HY + 0.3, 2.15), (1.75, HY + 0.3, 2.15), (1.75, HY + 0.3, 4.85)], 0.11, clamps=1.1)
PIPE("pipe_b", [(0.05, HY + 0.3, 2.5), (2.08, HY + 0.3, 2.5), (2.08, HY + 0.3, 4.85)], 0.11, clamps=1.1)
B("pipe_cap_a", (0.3, 0.3, 0.1), (1.75, HY + 0.3, 4.9), M_MET, 0.03)
B("pipe_cap_b", (0.3, 0.3, 0.1), (2.08, HY + 0.3, 4.9), M_MET, 0.03)
B("rear_machine", (3.0, 0.5, 1.15), (0.3, HY + 0.25, 1.05), M_MET_D, 0.06)
B("rear_machine_panel", (0.9, 0.08, 0.7), (1.1, HY + 0.54, 1.05), M_MET, 0.03)
B("rear_machine_hatch", (0.9, 0.06, 0.55), (-0.5, HY + 0.53, 1.0), M_MET, 0.02)
PIPE("rear_cable", [(-0.95, HY + 0.3, 1.62), (-0.98, HY + 0.32, 0.9), (-0.9, HY + 0.3, 0.45)], 0.035, mat=M_WIRE, verts=5)

# right side: ladder to the roof, window, panels
for s in (-1, 1):
    TUBE(f"ladder_rail{s}", (4.75, -0.2 + s * 0.28, 0.75), (4.75, -0.2 + s * 0.28, 5.0), 0.03)
for i in range(13):
    CYL(f"ladder_rung{i}", 0.022, 0.56, (4.75, -0.2, 0.95 + i * 0.32), M_MET, "y", 6)
for z in (1.2, 2.4, 3.4):
    for s in (-1, 1):
        B(f"ladder_brk{z}{s}", (1.15, 0.06, 0.06), (HX + 0.575, -0.2 + s * 0.28, z), M_MET_D)
window("win_r", "x", HX, 3.1, 0.8)
B("r_panel", (0.08, 1.1, 1.5), (HX + 0.04, 1.35, 1.5), M_MET_D, 0.03)
B("r_panel_box", (0.14, 0.5, 0.5), (HX + 0.07, -1.5, 0.9), M_MET_D, 0.04)

# left side: hatch with hinges/handle, louvers, window
B("l_hatch", (0.12, 1.5, 2.1), (-HX - 0.06, -0.9, 1.4), M_MET_D, 0.03)
CYL("l_handle", 0.04, 0.45, (-HX - 0.18, -0.35, 1.3), M_MET, v=6)
for z in (0.6, 2.2):
    CYL(f"l_hinge{z}", 0.05, 0.22, (-HX - 0.1, -1.7, z), M_MET, v=6)
for i in range(3):
    B(f"l_louver{i}", (0.07, 0.7, 0.07), (-HX - 0.035, 1.2, 0.85 + i * 0.16), M_MET)
window("win_l", "x", -HX, 3.1, 0.8)

# ================================================================ BLAST DOOR (two leaves, jagged seam, chamfered top corners)
SEAM = [(0.0, FZ), (0.12, 0.65), (-0.10, 1.05), (0.12, 1.45), (-0.08, 1.85), (0.10, 2.15), (0.0, DH)]
lp = [(-DW, FZ)] + [(x - 0.015, z) for x, z in SEAM] + [(-DW + 0.25, DH), (-DW, DH - 0.25)]
rp = [(DW, FZ)] + [(x + 0.015, z) for x, z in SEAM] + [(DW - 0.25, DH), (DW, DH - 0.25)]
door_l.append(L.prism("door_left", lp, 0.3, (0, -2.7, 0), M_MET))
door_r.append(L.prism("door_right", rp[::-1], 0.3, (0, -2.7, 0), M_MET))
for s, lst in ((-1, door_l), (1, door_r)):
    B(f"door_handle{s}", (0.08, 0.1, 0.45), (s * 0.28, -2.75, 1.3), M_RUST, into=lst)
    for z in (0.7, 1.9):
        B(f"door_rib{s}{z}", (0.62, 0.05, 0.12), (s * 0.52, -2.72, z), M_MET_D, into=lst)
    for k in range(4):
        B(f"door_bolt{s}{k}", (0.06, 0.05, 0.06), (s * (0.2 + k * 0.17), -2.72, 2.3), M_MET, into=lst)
    for z in (0.55, 1.95):
        CYL(f"door_hinge{s}{z}", 0.05, 0.16, (s * 0.86, -2.72, z), M_MET, v=6, into=lst)

# ================================================================ INTERIOR
# steel lining panels on the interior wall faces (plate texture)
LZ0, LZ1 = FZ, CZ
B("lin_l", (0.05, 3.8, LZ1 - LZ0), (-CX + 0.025, 0, (LZ0 + LZ1) / 2), M_PLATE)
B("lin_r", (0.05, 3.8, LZ1 - LZ0), (CX - 0.025, 0, (LZ0 + LZ1) / 2), M_PLATE)
B("lin_b", (4.4, 0.05, LZ1 - LZ0), (0, CY - 0.025, (LZ0 + LZ1) / 2), M_PLATE)
for s in (-1, 1):
    B(f"lin_f{s}", (1.3, 0.05, DH - LZ0), (s * 1.55, -CY + 0.025, (LZ0 + DH) / 2), M_PLATE)
B("lin_f_top", (1.8, 0.05, LZ1 - DH), (0, -CY + 0.025, (DH + LZ1) / 2), M_PLATE)
# ceiling: recessed light, cross beams, clamped pipes running to the left corner, cable bundle
B("ceiling_housing", (1.6, 0.6, 0.12), (0, 0, CZ - 0.06), M_MET_D, 0.03)
B("ceiling_light", (1.3, 0.36, 0.05), (0, 0, CZ - 0.13), M_AMBER)
for y in (-0.9, 0.9):
    B(f"ceil_beam{y}", (4.4, 0.16, 0.14), (0, y, CZ - 0.07), M_BAS_S, 0.02)
PIPE("ceil_pipe_a", [(CX - 0.05, -1.62, 2.66), (-2.05, -1.62, 2.66), (-2.05, -1.62, FZ + 0.05)], 0.09, clamps=0.9)
PIPE("ceil_pipe_b", [(CX - 0.05, -1.4, 2.72), (-1.8, -1.4, 2.72), (-1.8, -1.4, 1.1)], 0.075, clamps=0.9)
PIPE("ceil_pipe_rear", [(CX - 0.05, 1.5, 2.68), (-CX + 0.05, 1.5, 2.68)], 0.09, clamps=0.9)
PIPE("ceil_cable", [(2.1, -1.8, 2.82), (1.95, -1.0, 2.62), (2.1, -0.1, 2.78), (1.95, 0.7, 2.58)], 0.035, mat=M_CABLE, verts=5)
# front wall, left of door: wedge terminal console (tapered kiosk) with sloped keyboard + green screen
parts.append(L.prism("con_wedge", [(-1.5, FZ), (-1.1, FZ), (-0.85, 1.05), (-1.65, 1.05)], 0.9, (-2.0, 0, 0), M_MET_D, plane="yz"))
B("con_keys", (0.85, 0.42, 0.06), (-1.55, -1.02, 1.12), M_MET, rot=(-22, 0, 0))
B("con_hood", (0.9, 0.4, 0.6), (-1.55, -1.45, 1.42), M_MET_D, 0.04)
B("con_screen", (0.62, 0.04, 0.4), (-1.55, -1.24, 1.46), M_GREEN)
B("con_grille", (0.06, 0.9, 1.1), (-CX + 0.08, -1.0, 1.85), M_MET_D)
for i in range(5):
    B(f"con_grille_bar{i}", (0.04, 0.9, 0.04), (-CX + 0.11, -1.0, 1.4 + i * 0.22), M_BAS_S)
# front wall, right of door: desk terminal (CRT + keyboard + red buttons)
B("desk_r", (1.05, 0.55, 0.85), (1.6, -1.6, FZ + 0.425), M_MET_D, 0.03)
B("crt_r", (0.6, 0.5, 0.48), (1.6, -1.62, 1.35), M_MET_D, 0.05)
B("crt_r_screen", (0.44, 0.04, 0.34), (1.6, -1.36, 1.37), M_AMBER)
B("keys_r", (0.5, 0.22, 0.04), (1.6, -1.25, 1.12), M_MET, rot=(8, 0, 0))
for i, x in enumerate((1.95, 2.03)):
    B(f"btn_r{i}", (0.05, 0.05, 0.03), (x, -1.32, 1.14), M_HAZ)
# rear wall: louver box vent, clamped elbow pipes, wired machinery cabinet
B("int_vent", (1.5, 0.3, 1.5), (-0.9, CY - 0.15, 1.95), M_MET_D, 0.08)
for i in range(6):
    B(f"int_slat{i}", (1.24, 0.08, 0.09), (-0.9, CY - 0.32, 1.42 + i * 0.21), M_MET, rot=(-28, 0, 0))
B("int_machine", (1.3, 0.6, 1.5), (1.0, CY - 0.3, FZ + 0.75), M_MET_D, 0.04)
B("int_machine_open", (0.7, 0.05, 0.7), (1.0, CY - 0.62, 0.95), M_BAS)
for i, x in enumerate((0.8, 1.0, 1.2)):
    TUBE(f"int_wire{i}", (x, CY - 0.66, 1.3), (x + 0.05 * (i - 1), CY - 0.66, 0.65), 0.018, M_WIRE, 5)
B("int_machine_top", (1.0, 0.5, 0.3), (1.0, CY - 0.3, FZ + 1.65), M_MET, 0.03)
B("int_machine_light", (0.12, 0.04, 0.12), (0.55, CY - 0.62, 1.45), M_HAZ)
PIPE("int_pipe_a", [(0.1, CY - 0.15, 2.55), (0.1, CY - 0.15, FZ + 0.05)], 0.08, clamps=0.9)
PIPE("int_pipe_b", [(0.35, CY - 0.15, 2.4), (0.35, CY - 0.15, 1.5)], 0.08, clamps=0.9)
PIPE("int_elbow", [(-0.15, CY - 0.4, 2.35), (0.45, CY - 0.4, 2.35), (0.45, CY - 0.4, 1.9)], 0.07, clamps=0.9)
# left wall: mesh panel, desk with static CRT
B("int_grille", (0.06, 1.2, 1.4), (-CX + 0.06, 0.5, 1.75), M_MET_D)
for i in range(6):
    B(f"grille_bar{i}", (0.04, 1.2, 0.04), (-CX + 0.1, 0.5, 1.15 + i * 0.22), M_BAS_S)
B("desk_l", (0.65, 1.2, 0.8), (-CX + 0.36, -0.55, FZ + 0.4), M_MET_D, 0.03)
B("crt_l", (0.5, 0.5, 0.44), (-CX + 0.37, -0.55, 1.27), M_MET_D, 0.05)
B("crt_l_screen", (0.04, 0.36, 0.32), (-CX + 0.64, -0.55, 1.29), M_STATIC)
# right wall: generator machinery + hazard sign
B("gen_body", (0.95, 1.6, 1.3), (CX - 0.52, 0.35, FZ + 0.65), M_MET_D, 0.05)
B("gen_top", (0.6, 1.2, 0.35), (CX - 0.52, 0.35, FZ + 1.5), M_MET, 0.03)
PIPE("gen_pipe", [(CX - 0.4, -0.7, FZ + 0.6), (CX - 0.4, -1.3, FZ + 0.6), (CX - 0.4, -1.3, FZ + 0.05)], 0.06, mat=M_RUST, clamps=0.8)
B("hazard_sign", (0.04, 0.5, 0.36), (CX - 0.07, -0.55, 1.95), M_HAZ)
# key/dosimeter pedestal
CYL("pedestal", 0.32, 0.95, (0, 0.5, FZ + 0.475), M_MET_D, v=10)
CYL("pedestal_top", 0.38, 0.08, (0, 0.5, FZ + 0.95), M_MET, v=10)

# ================================================================ MARKERS
markers = {"marker_door_center": (0, -2.55, FZ), "marker_spawn_inside": (0, -0.9, FZ), "marker_pickup": (0, 0.5, 1.35),
           "marker_terminal_console": (-1.55, -1.24, 1.5), "marker_terminal_desk": (1.6, -1.36, 1.35),
           "marker_light_ceiling": (0, 0, 2.6), "marker_light_roof": (0, 0, 5.2), "marker_dish": (1.0, 0.3, 5.85),
           "marker_light_front": (0, -3.95, 3.42), "marker_light_side_r": (4.05, -1.25, 3.1), "marker_light_side_l": (-4.05, 1.2, 3.1)}
for n, p in markers.items():
    L.empty(n, p)

# ================================================================ FINALISE: join, subdivide, UVs, baked AO, export
bpy.context.view_layer.update()
shell = L.join(parts, "bunker_shell")
AO.subdivide_by_length(shell, 0.85)
col = L.join(cols, "shell-colonly")
dl_obj = L.join(door_l, "door_left")
dr_obj = L.join(door_r, "door_right")
for o in (shell, col):    # join keeps the first part's origin; move it to the world origin so node transforms are identity
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
bpy.context.view_layer.update()
for o in (shell, col, dl_obj, dr_obj):
    L.world_uv(o, 2.0, TILES)
AO.bake_ao(shell, [dl_obj, dr_obj], ground_z=0.0)
AO.bake_ao(dl_obj, [shell, dr_obj], ground_z=0.0)
AO.bake_ao(dr_obj, [shell, dl_obj], ground_z=0.0)
L.export_all(OUT)
