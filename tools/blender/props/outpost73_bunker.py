"""Outpost 73 bunker: walkable concrete blockhouse (exterior + furnished interior) from the concept sheet.
Run:  tools\\blender.ps1 tools/blender/props/outpost73_bunker.py     (python tools/blender/textures.py first, once)
Out:  models/generated/outpost73_bunker.glb
Blender axes (Z up); front (door) faces -Y, exported to glTF +Z. 1 unit = 1 m.
Nodes: bunker_shell (visual), shell-colonly (Godot builds trimesh collision), door_left / door_right (slide sideways),
       marker_* empties (gameplay anchors).
Footprint 7.4 x 6.8 m, height 4.5 m (+ roof dish), foundation skirt to z=-1. Interior 4.4 x 3.8 m, floor z=0.25, ceiling z=2.9.
Gameplay contract (scripts/bunker/outpost_bunker.gd): door_left/door_right slide on local X (1.0 m); door blocker box 1.8x2.25x0.3 at marker_door_center + (0,1.125,0);
marker_pickup = item hover point; marker_light_* get omni lights.
"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import bpy  # noqa: E402
import ps1_lib as L  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
OUT = os.path.join(ROOT, "models", "generated", "outpost73_bunker.glb")

L.reset()
T = lambda n: os.path.join(TEX, n)  # noqa: E731
M_CON = L.tex_material("bunker_concrete", T("concrete.png"))
M_CON_D = L.tex_material("bunker_concrete_dark", T("concrete.png"), tint=(0.72, 0.70, 0.68))
M_FLOOR = L.tex_material("bunker_floor", T("floor.png"))
M_MET = L.tex_material("bunker_metal", T("metal.png"))
M_MET_D = L.tex_material("bunker_metal_dark", T("metal.png"), tint=(0.55, 0.56, 0.6))
M_RUST = L.material("bunker_rust", (0.2, 0.1, 0.05))
M_HAZ = L.material("bunker_hazard", (0.42, 0.07, 0.04))
M_AMBER = L.tex_material("bunker_glow_amber", None, tint=(0.2, 0.1, 0.03), emission=(1.0, 0.26, 0.02), emission_strength=1.7)
M_GREEN = L.tex_material("bunker_glow_green", None, tint=(0.03, 0.15, 0.06), emission=(0.04, 0.75, 0.12), emission_strength=1.4)
M_STATIC = L.tex_material("bunker_glow_static", None, tint=(0.1, 0.11, 0.12), emission=(0.35, 0.42, 0.5), emission_strength=1.0)

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


def COL(name, size, loc):
    cols.append(L.box(name, size, loc, None))


def slab(name, x0, x1, y0, y1, z0, z1, mat, col=True):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    B(name, size, loc, mat)
    if col:
        COL(name + "_c", size, loc)


# ================================================================ SHELL (walls, floor, ceiling)
slab("floor", -HX, HX, -HY, HY, -1.0, FZ, M_FLOOR)   # extends 1 m below ground so it never floats on slopes
B("floor_top", (2 * CX, 2 * CY, 0.04), (0, 0, FZ - 0.01), M_FLOOR)
slab("back_wall", -HX, HX, CY, HY, FZ, H, M_CON)
slab("wall_l", -HX, -CX, -CY, CY, FZ, H, M_CON)
slab("wall_r", CX, HX, -CY, CY, FZ, H, M_CON)
slab("ceiling", -CX, CX, -CY, CY, CZ, H, M_CON_D)
# front wall: outer layer (reveal, wider opening) + inner layer (door opening)
slab("front_outer_l", -HX, -1.15, -HY, -2.8, FZ, H, M_CON, col=False)
slab("front_outer_r", 1.15, HX, -HY, -2.8, FZ, H, M_CON, col=False)
slab("front_outer_top", -1.15, 1.15, -HY, -2.8, 2.75, H, M_CON, col=False)
slab("front_in_l", -HX, -DW, -2.8, -CY, FZ, H, M_CON)
slab("front_in_r", DW, HX, -2.8, -CY, FZ, H, M_CON)
slab("front_in_top", -DW, DW, -2.8, -CY, DH, H, M_CON)
COL("front_out_l_c", (HX - 1.15, HY - 2.8, H - FZ), (-(HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_r_c", (HX - 1.15, HY - 2.8, H - FZ), ((HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_top_c", (2.3, HY - 2.8, H - 2.75), (0, -(HY + 2.8) / 2, (H + 2.75) / 2))
# chamfered reveal corners + raised frame trim around the door
for s in (-1, 1):
    parts.append(L.prism(f"reveal_ch{s}", [(s * 1.15, 2.45), (s * 1.15, 2.75), (s * 0.85, 2.75)], 0.5, (0, -HY, 0), M_CON_D))
    B(f"trim_post{s}", (0.32, 0.14, 2.9), (s * 1.31, -HY - 0.07, FZ + 1.45), M_CON_D, 0.03)
B("trim_top", (2.9, 0.14, 0.3), (0, -HY - 0.07, 3.0), M_CON_D, 0.03)
# walkable entrance ramp (CharacterBody3D cannot climb a 0.25 m vertical step): 0.25 m rise over 1.3 m (~11 deg)
parts.append(L.ramp("door_ramp", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, M_CON_D))
cols.append(L.ramp("door_ramp_c", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, None))
B("window_housing", (1.9, 0.1, 0.36), (0, -HY - 0.05, 3.42), M_MET_D)
B("window_glow", (1.7, 0.06, 0.2), (0, -HY - 0.11, 3.42), M_AMBER)

# ================================================================ EXTERIOR MASSING
B("plinth_back", (8.2, 0.5, 1.5), (0, 3.55, -0.25), M_CON_D, 0.1)
for sx in (-1, 1):                                      # plinth strips (sides full length, front split at the door)
    B(f"plinth_side{sx}", (0.5, 2 * 3.8, 1.5), (sx * 3.85, 0, -0.25), M_CON_D, 0.1)
    B(f"plinth_front{sx}", (2.9, 0.5, 1.5), (sx * 2.65, -3.55, -0.25), M_CON_D, 0.1)
for sx in (-1, 1):
    for sy in (-1, 1):
        B(f"pilaster{sx}{sy}", (1.65, 1.65, 3.5), (sx * 3.025, sy * 2.725, 2.25), M_CON, 0.24)
        B(f"roof_block{sx}{sy}", (1.8, 1.8, 0.3), (sx * 3.0, sy * 2.7, 4.65), M_CON_D, 0.12)
B("roof_cap", (8.2, 7.6, 0.5), (0, 0, 4.25), M_CON_D, 0.2)
COL("roof_cap_c", (8.2, 7.6, 0.5), (0, 0, 4.25))
# roof comm array
CYL("dish_pedestal", 0.16, 0.7, (1.0, 0.6, 4.85), M_MET_D)
B("dish_mount", (0.5, 0.4, 0.15), (1.0, 0.6, 5.25), M_MET_D)
L.cone("dish", 0.06, 0.78, 0.36, (1.0, 0.55, 5.55), M_MET, 10)
parts.append(bpy.context.active_object)
bpy.context.active_object.rotation_euler = (math.radians(40), 0, 0)
CYL("dish_horn", 0.03, 0.55, (1.0, 0.36, 5.78), M_MET_D, "z", 6).rotation_euler = (math.radians(40), 0, 0)
CYL("antenna_a", 0.025, 1.7, (0.1, 0.9, 5.35), M_MET_D, v=6)
CYL("antenna_b", 0.025, 1.2, (2.0, 0.3, 5.1), M_MET_D, v=6)
B("antenna_base_a", (0.3, 0.3, 0.12), (0.1, 0.9, 4.56), M_MET_D)
B("antenna_base_b", (0.3, 0.3, 0.12), (2.0, 0.3, 4.56), M_MET_D)

# rear: vent, pipes, machine box
B("vent_frame", (1.6, 0.22, 1.6), (-0.9, HY + 0.11, 2.5), M_MET_D, 0.04)
B("vent_dark", (1.3, 0.05, 1.3), (-0.9, HY + 0.24, 2.5), M_CON_D)
for i in range(6):
    B(f"vent_slat{i}", (1.3, 0.07, 0.07), (-0.9, HY + 0.27, 1.95 + i * 0.22), M_MET)
for i, (px, pz) in enumerate(((1.6, 1.95), (1.95, 2.25))):
    CYL(f"pipe_v{i}", 0.11, 4.75 - pz + 0.3, (px, HY + 0.28, (pz - 0.3 + 4.75) / 2), M_MET_D)
    CYL(f"pipe_h{i}", 0.11, px + 0.1, (px / 2 - 0.05, HY + 0.28, pz), M_MET_D, "x")
    parts.append(L.cylinder(f"pipe_elbow{i}", 0.13, 0.26, (px, HY + 0.28, pz), M_MET_D, 8, (0, 90, 0)))
for z in (2.7, 3.5):
    B(f"pipe_bracket{z}", (0.6, 0.14, 0.07), (1.78, HY + 0.2, z), M_MET)
B("rear_machine", (1.5, 0.45, 1.2), (1.5, HY + 0.22, 0.85), M_MET_D, 0.03)
B("rear_machine_panel", (0.7, 0.05, 0.5), (1.5, HY + 0.47, 0.95), M_MET)
CYL("rear_conduit", 0.05, 1.0, (0.3, HY + 0.3, 0.75), M_RUST, v=6)

# right side: ladder to the roof + slit window
for s in (-1, 1):
    CYL(f"ladder_rail{s}", 0.03, 4.4, (4.35, -0.2 + s * 0.28, 2.7), M_MET_D, v=6)
for i in range(14):
    CYL(f"ladder_rung{i}", 0.022, 0.56, (4.35, -0.2, 0.75 + i * 0.32), M_MET, "y", 6)
for z in (1.0, 2.0, 3.0, 3.8):
    for s in (-1, 1):
        B(f"ladder_brk{z}{s}", (0.8, 0.06, 0.06), (3.975, -0.2 + s * 0.28, z), M_MET_D)
B("r_window_housing", (0.1, 1.0, 0.36), (HX + 0.05, -1.25, 3.1), M_MET_D)
B("r_window_glow", (0.06, 0.8, 0.2), (HX + 0.11, -1.25, 3.1), M_AMBER)
B("r_panel", (0.06, 1.1, 1.5), (HX + 0.03, 1.15, 1.5), M_MET_D)

# left side: seams, hatch panel, slit window
B("l_hatch", (0.07, 1.3, 2.0), (-HX - 0.035, -0.9, 1.4), M_MET_D, 0.02)
B("l_panel", (0.06, 1.1, 1.3), (-HX - 0.03, 0.9, 1.2), M_MET_D)
B("l_seam", (0.05, 0.06, 3.3), (-HX - 0.025, 0.1, 2.1), M_CON_D)
B("l_window_housing", (0.1, 1.0, 0.36), (-HX - 0.05, 1.2, 3.1), M_MET_D)
B("l_window_glow", (0.06, 0.8, 0.2), (-HX - 0.11, 1.2, 3.1), M_AMBER)

# ================================================================ BLAST DOOR (two halves, jagged seam)
SEAM = [(0.0, 0.25), (0.12, 0.65), (-0.10, 1.05), (0.12, 1.45), (-0.08, 1.85), (0.10, 2.15), (0.0, DH)]
lp = [(-DW, FZ)] + [(x - 0.015, z) for x, z in SEAM] + [(-DW, DH)]
rp = [(DW, FZ)] + [(x + 0.015, z) for x, z in SEAM] + [(DW, DH)]
dl = L.prism("door_left", lp, 0.3, (0, -2.7, 0), M_MET)
dr = L.prism("door_right", rp[::-1], 0.3, (0, -2.7, 0), M_MET)
door_l.append(dl)
door_r.append(dr)
for s, lst in ((-1, door_l), (1, door_r)):
    B(f"door_handle{s}", (0.08, 0.1, 0.45), (s * 0.28, -2.75, 1.3), M_RUST, into=lst)
    B(f"door_rib{s}", (0.7, 0.05, 0.12), (s * 0.5, -2.72, 0.7), M_MET_D, into=lst)
    B(f"door_rib_b{s}", (0.7, 0.05, 0.12), (s * 0.5, -2.72, 1.9), M_MET_D, into=lst)

# ================================================================ INTERIOR
B("ceiling_housing", (1.5, 0.55, 0.1), (0, 0, CZ - 0.05), M_MET_D)
B("ceiling_light", (1.25, 0.34, 0.05), (0, 0, CZ - 0.11), M_AMBER)
CYL("ceil_pipe_x", 0.09, 4.3, (0, 1.5, 2.68), M_MET_D, "x")
CYL("ceil_pipe_x2", 0.07, 4.3, (0, 1.25, 2.72), M_MET_D, "x")
CYL("ceil_pipe_y", 0.08, 3.7, (-1.95, 0, 2.68), M_MET_D, "y")
for x in (-1.2, 1.2):
    B(f"ceil_brk{x}", (0.08, 0.5, 0.1), (x, 1.4, 2.78), M_MET)
# front wall, left of door: standing console with keyboard slope and green screen
B("con_body", (0.95, 0.6, 1.15), (-1.6, -1.55, FZ + 0.575), M_MET_D, 0.03)
B("con_keys", (0.8, 0.38, 0.06), (-1.6, -1.28, 1.42), M_MET, rot=(-22, 0, 0))
B("con_hood", (0.85, 0.35, 0.55), (-1.6, -1.68, 1.75), M_MET_D, 0.03)
B("con_screen", (0.6, 0.04, 0.38), (-1.6, -1.49, 1.78), M_GREEN)
# front wall, right of door: desk + amber CRT
B("desk_r", (1.05, 0.55, 0.85), (1.6, -1.6, FZ + 0.425), M_MET_D)
B("crt_r", (0.6, 0.5, 0.48), (1.6, -1.62, 1.35), M_MET_D, 0.04)
B("crt_r_screen", (0.44, 0.04, 0.34), (1.6, -1.36, 1.37), M_AMBER)
# rear wall: vent + machinery + vertical pipes
B("int_vent", (1.4, 0.1, 1.4), (-0.9, CY - 0.05, 1.85), M_MET_D)
for i in range(5):
    B(f"int_vent_slat{i}", (1.2, 0.05, 0.06), (-0.9, CY - 0.11, 1.35 + i * 0.25), M_MET)
B("int_machine", (1.3, 0.6, 1.5), (1.0, CY - 0.3, FZ + 0.75), M_MET_D, 0.03)
B("int_machine_top", (1.0, 0.5, 0.3), (1.0, CY - 0.3, FZ + 1.65), M_MET)
B("int_machine_light", (0.12, 0.04, 0.12), (0.6, CY - 0.62, 1.2), M_HAZ)
for i, x in enumerate((0.1, 0.35)):
    CYL(f"int_pipe{i}", 0.08, CZ - FZ, (x, CY - 0.15, (CZ + FZ) / 2), M_MET_D)
# left wall: mesh panel, desk with static CRT
B("int_grille", (0.06, 1.2, 1.4), (-CX + 0.03, 0.5, 1.75), M_MET_D)
for i in range(6):
    B(f"grille_bar{i}", (0.04, 1.2, 0.04), (-CX + 0.07, 0.5, 1.15 + i * 0.22), M_CON_D)
B("desk_l", (0.65, 1.2, 0.8), (-CX + 0.33, -0.55, FZ + 0.4), M_MET_D)
B("crt_l", (0.5, 0.5, 0.44), (-CX + 0.34, -0.55, 1.27), M_MET_D, 0.04)
B("crt_l_screen", (0.04, 0.36, 0.32), (-CX + 0.61, -0.55, 1.29), M_STATIC)
# right wall: generator machinery + hazard sign
B("gen_body", (0.95, 1.6, 1.3), (CX - 0.5, 0.35, FZ + 0.65), M_MET_D, 0.04)
B("gen_top", (0.6, 1.2, 0.35), (CX - 0.5, 0.35, FZ + 1.5), M_MET, 0.03)
CYL("gen_pipe", 0.07, 1.2, (CX - 0.4, -0.7, FZ + 0.6), M_RUST, "y", 6)
B("hazard_sign", (0.04, 0.5, 0.36), (CX - 0.02, -0.55, 1.95), M_HAZ)
# key/dosimeter pedestal
CYL("pedestal", 0.32, 0.95, (0, 0.5, FZ + 0.475), M_MET_D, v=10)
CYL("pedestal_top", 0.38, 0.08, (0, 0.5, FZ + 0.95), M_MET, v=10)

# ================================================================ MARKERS
markers = {"marker_door_center": (0, -2.55, FZ), "marker_spawn_inside": (0, -0.9, FZ), "marker_pickup": (0, 0.5, 1.35),
           "marker_terminal_console": (-1.6, -1.35, 1.5), "marker_terminal_desk": (1.6, -1.35, 1.35),
           "marker_light_ceiling": (0, 0, 2.6), "marker_light_roof": (0, 0, 4.7), "marker_dish": (1.0, 0.55, 5.55),
           "marker_light_front": (0, -3.75, 3.42), "marker_light_side_r": (3.85, -1.25, 3.1), "marker_light_side_l": (-3.85, 1.2, 3.1)}
for n, p in markers.items():
    L.empty(n, p)

# ================================================================ FINALISE: UVs, join, export
bpy.context.view_layer.update()
for o in parts + cols + door_l + door_r:
    if o.type == "MESH":
        mats = [m.name for m in o.data.materials if m]
        L.world_uv(o, 1.0 if mats and "metal" in mats[0] else 2.0)
shell = L.join(parts, "bunker_shell")
col = L.join(cols, "shell-colonly")
dl = L.join(door_l, "door_left")
dr = L.join(door_r, "door_right")
L.export_all(OUT)
