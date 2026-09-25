"""Outpost 73 bunker v4: an ABANDONED amber-extraction well. Obsidian-black concrete, a century of decay, machinery still pumping.
Run:  python tools/blender/textures.py   (once)   then   tools\\blender.ps1 tools/blender/props/outpost73_bunker.py
Out:  models/generated/outpost73_bunker.glb
Blender axes (Z up); front (door) faces -Y, exported to glTF +Z. 1 unit = 1 m.
Nodes: bunker_shell (visual, baked vertex-colour AO), bunker_decals (alpha stencils/stains/notes), bunker_screens (emissive CRT
       quads, materials bunker_scr_* animated by bunker_screens.gd), bunker_liquid (glowing amber: bunker_amber_liquid flows,
       bunker_amber_pool pulses), shell-colonly (Godot builds trimesh collision),
       door_left / door_right (slide on local X, 1.0 m), marker_* empties (gameplay anchors, see outpost_bunker.gd).
Extraction: wellhead casing + collar behind the bunker, two amber-filled pipes to the roof, a well riser in the control room.
Decay: broken cornice + rubble, damaged ladder and mast, dust, cobwebs, papers, rust and dried-amber crust, amber crystal growths.
Exterior: deliberately low-detail concrete mass (chamfered corner blocks, one plinth, one cornice, one door frame); the
detail comes from the concrete texture and decals. Interior 4.4 x 3.8 m, floor z=0.25, ceiling z=2.9, door opening 1.8 x 2.25 m.
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
M_CON = L.tex_material("bunker_concrete", T("concrete.png"))
M_CON_T = L.tex_material("bunker_concrete_top", T("concrete_top.png"))
M_FLOOR = L.tex_material("bunker_floor", T("floor.png"))
M_MET = L.tex_material("bunker_metal", T("metal.png"))
M_MET_D = L.tex_material("bunker_metal_dark", T("metal.png"), tint=(0.6, 0.6, 0.62))
M_PLATE = L.tex_material("bunker_plate", T("plate.png"))
M_RUST = L.material("bunker_rust", (0.2, 0.1, 0.05))
M_WIRE = L.material("bunker_wire", (0.32, 0.11, 0.04))
M_CABLE = L.material("bunker_cable", (0.03, 0.03, 0.028))
M_HAZ = L.material("bunker_hazard", (0.42, 0.07, 0.04))
M_BOX = L.material("bunker_box", (0.20, 0.14, 0.08))
M_EXT = L.material("bunker_extinguisher", (0.32, 0.04, 0.03))
M_AMBER = L.tex_material("bunker_glow_amber", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.2, 0.015), emission_strength=1.1)
S_TERM = L.screen_material("bunker_scr_term", T("screen_term_a.png"), 1.3)
S_SCAN = L.screen_material("bunker_scr_scan", T("screen_scan_a.png"), 1.2)
S_STATIC = L.screen_material("bunker_scr_static", T("screen_static.png"), 0.8)
S_MAP = L.screen_material("bunker_scr_map", T("screen_map_a.png"), 1.1)
S_GEN = L.screen_material("bunker_scr_gen", T("screen_gen_a.png"), 1.0)
LQ_FLOW = L.screen_material("bunker_amber_liquid", T("liquid_flow.png"), 1.6)
LQ_POOL = L.emissive_decal_material("bunker_amber_pool", T("liquid_pool.png"), 1.1)
D_DRIPS = L.decal_material("bunker_decal_drips_amber", T("decal_drips_amber.png"))
D_DUST = L.decal_material("bunker_decal_dust", T("decal_dust.png"))
D_WEB = L.decal_material("bunker_decal_cobweb", T("decal_cobweb.png"))
D_PAPERS = L.decal_material("bunker_decal_papers", T("decal_papers.png"))
D_CRUST = L.decal_material("bunker_decal_crust", T("decal_amber_crust.png"))
D_CRACK = L.decal_material("bunker_decal_crack", T("decal_crack.png"))
D_STREAK = L.decal_material("bunker_decal_streaks", T("decal_streaks.png"))
D_STENCIL = L.decal_material("bunker_decal_stencil", T("decal_stencil.png"))
D_HAZARD = L.decal_material("bunker_decal_hazard", T("decal_hazard.png"))
D_WARN = L.decal_material("bunker_decal_warning", T("decal_warning.png"))
D_STAIN = L.decal_material("bunker_decal_stain", T("decal_stain.png"))
D_NOTES = L.decal_material("bunker_decal_notes", T("decal_notes.png"))
TILES = {"bunker_metal": 1.0, "bunker_metal_dark": 1.0, "bunker_plate": 1.0}   # metres per texture repeat (default 2.0)

# ---- dimensions
HX, HY, H = 3.6, 3.3, 4.0          # wall planes (half-widths) and wall height
CX, CY = 2.2, 1.9                  # interior cavity half-widths
FZ, CZ = 0.25, 2.9                 # interior floor / ceiling heights
DW, DH = 0.9, 2.5                  # door half-width, door top

parts, cols, door_l, door_r, decals, screens, liquids = [], [], [], [], [], [], []


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


def DECAL(name, center, w, h, facing, mat, up=(0, 0, 1)):
    decals.append(L.quad(name, center, w, h, facing, mat, up))


def SCREEN(name, center, w, h, facing, mat):
    screens.append(L.quad(name, center, w, h, facing, mat))


def LIQ_CYL(name, r, d, loc, axis="z", v=10):
    """Glowing amber cylinder (sight-glass sleeve / well surface / cap). Lives in the bunker_liquid node (flow animated at runtime)."""
    rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
    liquids.append(L.cylinder(name, r, d, loc, LQ_FLOW, v, rot))


def POOL(name, center, w, h):
    """Glowing amber puddle lying on a floor/ground plane."""
    liquids.append(L.quad(name, center, w, h, "+z", LQ_POOL, up=(0, 1, 0)))


def CRYSTALS(prefix, cx, cy, z0, count, radius, seed, size=1.0):
    """Cluster of amber crystal spikes growing out of a surface (glowing, lightly tilted)."""
    import random
    rng = random.Random(seed)
    for i in range(count):
        a, d = rng.uniform(0, math.tau), rng.uniform(0.3, 1.0) * radius
        h = rng.uniform(0.25, 0.7) * size
        o = L.cone(f"{prefix}{i}", 0.07 * size, 0.008, h, (cx + math.cos(a) * d, cy + math.sin(a) * d, z0 + h / 2), LQ_FLOW, 6)
        o.rotation_euler = (rng.uniform(-0.35, 0.35), rng.uniform(-0.35, 0.35), rng.uniform(0, math.tau))
        liquids.append(o)


def slab(name, x0, x1, y0, y1, z0, z1, mat, col=True):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    B(name, size, loc, mat)
    if col:
        COL(name + "_c", size, loc)


# ================================================================ SHELL (walls, floor, ceiling, door reveal)
slab("floor", -HX, HX, -HY, HY, -1.0, FZ, M_FLOOR)   # extends 1 m below ground so it never floats on slopes
B("floor_top", (2 * CX, 2 * CY, 0.04), (0, 0, FZ - 0.01), M_FLOOR)
slab("back_wall", -HX, HX, CY, HY, FZ, H, M_CON)
slab("wall_l", -HX, -CX, -CY, CY, FZ, H, M_CON)
slab("wall_r", CX, HX, -CY, CY, FZ, H, M_CON)
slab("ceiling", -CX, CX, -CY, CY, CZ, H, M_CON_T)
slab("front_outer_l", -HX, -1.15, -HY, -2.8, FZ, H, M_CON, col=False)
slab("front_outer_r", 1.15, HX, -HY, -2.8, FZ, H, M_CON, col=False)
slab("front_outer_top", -1.15, 1.15, -HY, -2.8, 2.75, H, M_CON, col=False)
slab("front_in_l", -HX, -DW, -2.8, -CY, FZ, H, M_CON)
slab("front_in_r", DW, HX, -2.8, -CY, FZ, H, M_CON)
slab("front_in_top", -DW, DW, -2.8, -CY, DH, H, M_CON)
COL("front_out_l_c", (HX - 1.15, HY - 2.8, H - FZ), (-(HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_r_c", (HX - 1.15, HY - 2.8, H - FZ), ((HX + 1.15) / 2, -(HY + 2.8) / 2, (H + FZ) / 2))
COL("front_out_top_c", (2.3, HY - 2.8, H - 2.75), (0, -(HY + 2.8) / 2, (H + 2.75) / 2))
for s in (-1, 1):   # chamfered opening corners so the doorway reads octagonal
    parts.append(L.prism(f"reveal_ch{s}", [(s * 1.15, 2.45), (s * 1.15, 2.75), (s * 0.85, 2.75)], 0.5, (0, -HY, 0), M_CON_T))
    parts.append(L.prism(f"reveal_in{s}", [(s * DW, 2.25), (s * DW, DH), (s * 0.65, DH)], 0.9, (0, -2.8, 0), M_CON_T))
parts.append(L.arch_ring("frame_a", L.arch_pts(1.6, 3.15, 0.5), L.arch_pts(1.15, 2.75, 0.3), 0.28, (0, -HY - 0.28, 0), M_CON_T))   # the one exterior frame
parts.append(L.arch_ring("frame_in", L.arch_pts(1.3, 2.9, 0.42), L.arch_pts(DW, DH, 0.25), 0.14, (0, -CY, 0), M_MET_D))
# walkable entrance ramp (CharacterBody3D cannot climb a 0.25 m vertical step): 0.25 m rise over 1.3 m (~11 deg)
parts.append(L.ramp("door_ramp", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, M_CON_T))
cols.append(L.ramp("door_ramp_c", -1.15, 1.15, -HY - 1.3, -HY, -1.0, 0.0, FZ, None))

# ================================================================ EXTERIOR: plain concrete mass
B("plinth_back", (8.3, 0.35, 1.4), (0, HY + 0.175, -0.3), M_CON_T, 0.1)
for sx in (-1, 1):
    B(f"plinth_side{sx}", (0.35, 7.3, 1.4), (sx * 3.775, 0, -0.3), M_CON_T, 0.1)
    B(f"plinth_front{sx}", (2.75, 0.35, 1.4), (sx * 2.575, -HY - 0.175, -0.3), M_CON_T, 0.1)
    for sy in (-1, 1):
        B(f"corner{sx}{sy}", (1.5, 1.5, 3.6), (sx * 2.97, sy * 2.67, 2.2), M_CON, 0.3)
B("cornice_a", (6.2, 7.6, 0.5), (-1.0, 0, 4.25), M_CON_T, 0.25)              # front-right corner has broken away
B("cornice_b", (2.0, 5.7, 0.5), (3.1, 0.95, 4.25), M_CON_T, 0.25)
COL("cornice_a_c", (6.2, 7.6, 0.5), (-1.0, 0, 4.25))
COL("cornice_b_c", (2.0, 5.7, 0.5), (3.1, 0.95, 4.25))
for i, (bx, by) in enumerate(((2.6, -1.85), (3.2, -1.9), (3.8, -1.85), (2.1, -2.3), (2.1, -3.0))):   # exposed rusted rebar
    TUBE(f"rebar{i}", (bx, by, 4.35), (bx + 0.1 * (i % 2), by - 0.45 - 0.1 * i, 4.55 + 0.1 * (i % 3)), 0.018, M_RUST, 5)
B("rubble_a", (1.4, 1.1, 0.5), (3.7, -4.8, 0.3), M_CON_T, 0.15, rot=(8, -12, 25))      # fallen cornice chunks
B("rubble_b", (0.8, 0.7, 0.4), (2.7, -4.4, 0.22), M_CON_T, 0.1, rot=(-10, 15, -30))
B("rubble_c", (0.5, 0.4, 0.3), (4.3, -4.2, 0.16), M_CON_T, 0.08, rot=(20, 5, 60))
B("rubble_d", (0.35, 0.3, 0.25), (3.0, -5.3, 0.13), M_CON_T, 0.06, rot=(-5, 25, 10))
B("rubble_e", (0.45, 0.35, 0.28), (3.9, -3.85, 0.4), M_CON_T, 0.06, rot=(15, -10, 35))
B("win_brow_f", (2.3, 0.2, 0.1), (0, -HY - 0.1, 3.72), M_CON_T, 0.02)          # front slit window: glow + brow only
B("win_glow_f", (1.9, 0.05, 0.2), (0, -HY + 0.005, 3.42), M_AMBER)
B("win_brow_r", (0.2, 0.9, 0.1), (HX + 0.1, -1.25, 3.42), M_CON_T, 0.02)       # side slits
B("win_glow_r", (0.05, 0.7, 0.2), (HX - 0.005, -1.25, 3.12), M_AMBER)
B("win_brow_l", (0.2, 0.9, 0.1), (-HX - 0.1, 1.2, 3.42), M_CON_T, 0.02)
B("win_glow_l", (0.05, 0.7, 0.2), (-HX + 0.005, 1.2, 3.12), M_AMBER)
# roof comm mast (silhouette only)
CYL("dish_pedestal", 0.25, 0.5, (1.0, 0.6, 4.75), M_MET_D, v=8)
L.cone("dish", 0.08, 0.8, 0.35, (1.0, 0.4, 5.2), M_MET, 8)
parts.append(bpy.context.active_object)
bpy.context.active_object.rotation_euler = (math.radians(74), 0, math.radians(22))   # dish has sagged on its mount
TUBE("antenna_lo", (0.2, 0.9, 4.5), (0.2, 0.9, 5.3), 0.025)
TUBE("antenna_hi", (0.2, 0.9, 5.3), (0.85, 1.35, 5.65), 0.022)                           # bent over
# rear: one louvered vent plate and two straight pipes
B("vent_plate", (1.7, 0.1, 1.7), (-0.9, HY + 0.05, 2.5), M_MET_D, 0.03)
for i in range(6):
    B(f"vent_slat{i}", (1.4, 0.07, 0.09), (-0.9, HY + 0.13, 1.95 + i * 0.22), M_MET, rot=(25, 0, 0))
# ---- extraction wellhead behind the bunker: casing + collar in the ground, two amber pipes to the wall and up to the roof
WX, WY = 1.9, 5.6
CYL("wh_collar", 0.95, 1.4, (WX, WY, -0.3), M_CON_T, v=12)                       # z -1.0 .. 0.4
CYL("wh_casing", 0.5, 1.3, (WX, WY, 1.05), M_MET_D, v=10)                        # z 0.4 .. 1.7
CYL("wh_flange_lo", 0.62, 0.08, (WX, WY, 0.9), M_MET, v=10)
CYL("wh_flange_hi", 0.62, 0.08, (WX, WY, 1.7), M_MET, v=10)
LIQ_CYL("wh_glow", 0.36, 0.05, (WX, WY, 1.76), "z", 10)                          # amber surface in the casing mouth
PIPE("pipe_a", [(1.75, 5.3, 1.3), (1.75, HY + 0.15, 1.3), (1.75, HY + 0.15, 4.85)], 0.1, M_MET_D)
PIPE("pipe_b", [(2.05, 5.3, 0.9), (2.05, HY + 0.15, 0.9), (2.05, HY + 0.15, 4.85)], 0.1, M_MET_D)
for px, pz in ((1.75, 1.3), (2.05, 0.9)):
    TUBE(f"valve_stem{px}", (px, 4.4, pz + 0.1), (px, 4.4, pz + 0.5), 0.03, M_MET, 6)
    CYL(f"valve_wheel{px}", 0.17, 0.03, (px, 4.4, pz + 0.52), M_MET_D, v=8)
    for y in (4.0, 4.85):
        LIQ_CYL(f"sleeve_h{px}{y}", 0.118, 0.28, (px, y, pz), "y")
    for z in (2.5, 3.7):
        LIQ_CYL(f"sleeve_v{px}{z}", 0.118, 0.3, (px, HY + 0.15, z), "z")
    LIQ_CYL(f"pipe_cap{px}", 0.13, 0.08, (px, HY + 0.15, 4.9), "z")
COL("wh_col", (1.9, 1.9, 2.8), (WX, WY, 0.4))
CRYSTALS("wh_cr", WX, WY, 0.4, 6, 0.75, 5, 1.1)                                     # amber growth around the casing base
CRYSTALS("wh_cr_top", WX, WY, 1.7, 3, 0.35, 8, 0.7)
POOL("spill_wh", (WX, WY, 0.045), 4.4, 4.4)
DECAL("crust_wh", (WX, WY, 0.03), 3.6, 3.6, "+z", D_CRUST, up=(0, 1, 0))
DECAL("drips_amber_a", (1.9, HY + 0.012, 1.0), 1.0, 1.6, "+y", D_DRIPS)
# left: one hatch. right: ladder to the roof
B("l_hatch", (0.1, 1.4, 2.0), (-HX - 0.05, -0.9, 1.35), M_MET_D, 0.03)
CYL("l_handle", 0.04, 0.4, (-HX - 0.16, -0.4, 1.3), M_MET, v=6)
for s in (-1, 1):
    TUBE(f"ladder_rail{s}", (4.75, -0.2 + s * 0.28, 2.3), (4.75, -0.2 + s * 0.28, 5.0), 0.03)                 # lower half has rotted away
    TUBE(f"ladder_fallen{s}", (4.5, -2.6 + s * 0.14, 0.06), (4.9, -0.5 + s * 0.14, 0.12), 0.03)
for i in range(6, 13):
    CYL(f"ladder_rung{i}", 0.022, 0.56, (4.75, -0.2, 0.95 + i * 0.32), M_MET, "y", 6)
for y in (-2.2, -1.7, -1.2, -0.8):
    CYL(f"ladder_fallen_rung{y}", 0.022, 0.5, (4.7, y, 0.09), M_MET, "x", 6)
for z in (1.2, 2.4, 3.4):
    for s in (-1, 1):
        B(f"ladder_brk{z}{s}", (1.15, 0.06, 0.06), (HX + 0.575, -0.2 + s * 0.28, z), M_MET_D)

# ---- exterior decals: stencil lettering, radiation sign, rain/dirt streaks (offset 1.2 cm off the wall)
DECAL("stencil_r", (HX + 0.012, 1.15, 2.2), 1.05, 1.575, "+x", D_STENCIL)
DECAL("sign_l", (-HX - 0.012, 0.55, 1.6), 0.6, 0.8, "-x", D_WARN)
DECAL("streak_r", (HX + 0.012, -1.25, 2.0), 1.0, 2.0, "+x", D_STREAK)
DECAL("streak_l", (-HX - 0.012, 1.45, 2.0), 0.9, 2.0, "-x", D_STREAK)
DECAL("streak_b1", (-0.9, HY + 0.012, 0.85), 1.5, 1.5, "+y", D_STREAK)
DECAL("streak_b2", (0.55, HY + 0.012, 2.6), 0.8, 1.7, "+y", D_STREAK)
DECAL("crack_f", (1.92, -HY - 0.012, 1.9), 0.5, 1.0, "-y", D_CRACK)
DECAL("crack_l", (-HX - 0.012, 1.75, 1.6), 0.4, 1.2, "-x", D_CRACK)
DECAL("crack_r", (HX + 0.012, 1.7, 1.1), 0.4, 1.2, "+x", D_CRACK)

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

# ================================================================ INTERIOR
LZ0, LZ1 = FZ, CZ     # steel lining panels on the interior wall faces
B("lin_l", (0.05, 3.8, LZ1 - LZ0), (-CX + 0.025, 0, (LZ0 + LZ1) / 2), M_PLATE)
B("lin_r", (0.05, 3.8, LZ1 - LZ0), (CX - 0.025, 0, (LZ0 + LZ1) / 2), M_PLATE)
B("lin_b", (4.4, 0.05, LZ1 - LZ0), (0, CY - 0.025, (LZ0 + LZ1) / 2), M_PLATE)
for s in (-1, 1):
    B(f"lin_f{s}", (1.3, 0.05, DH - LZ0), (s * 1.55, -CY + 0.025, (LZ0 + DH) / 2), M_PLATE)
B("lin_f_top", (1.8, 0.05, LZ1 - DH), (0, -CY + 0.025, (DH + LZ1) / 2), M_PLATE)
# ceiling: recessed light, cross beams, clamped pipes to the left corner, hanging cables
B("ceiling_housing", (1.6, 0.6, 0.12), (0, 0, CZ - 0.06), M_MET_D, 0.03)
B("ceiling_light", (1.3, 0.36, 0.05), (0, 0, CZ - 0.13), M_AMBER)
for y in (-0.9, 0.9):
    B(f"ceil_beam{y}", (4.4, 0.16, 0.14), (0, y, CZ - 0.07), M_CON_T, 0.02)
PIPE("ceil_pipe_a", [(CX - 0.05, -1.62, 2.66), (-2.05, -1.62, 2.66), (-2.05, -1.62, FZ + 0.05)], 0.09, clamps=0.9)
PIPE("ceil_pipe_b", [(CX - 0.05, -1.4, 2.72), (-1.8, -1.4, 2.72), (-1.8, -1.4, 1.1)], 0.075, clamps=0.9)
PIPE("ceil_pipe_rear", [(CX - 0.05, 1.5, 2.68), (-CX + 0.05, 1.5, 2.68)], 0.09, clamps=0.9)
PIPE("ceil_cable", [(2.1, -1.8, 2.82), (1.95, -1.0, 2.62), (2.1, -0.1, 2.78), (1.95, 0.7, 2.58)], 0.035, mat=M_CABLE, verts=5)
PIPE("ceil_cable2", [(-2.1, 0.2, 2.84), (-1.6, 0.6, 2.66), (-1.1, 0.3, 2.8), (-0.6, 0.9, 2.62)], 0.03, mat=M_CABLE, verts=5)
TUBE("hang_cable_a", (0.9, 0.9, 2.72), (0.95, 0.9, 2.05), 0.02, M_CABLE, 5)
TUBE("hang_cable_b", (-0.7, -0.9, 2.72), (-0.72, -0.9, 2.2), 0.02, M_WIRE, 5)
# front wall, left of door: wedge console (tapered kiosk), sloped keyboard, scan monitor
parts.append(L.prism("con_wedge", [(-1.5, FZ), (-1.1, FZ), (-0.85, 1.05), (-1.65, 1.05)], 0.9, (-2.0, 0, 0), M_MET_D, plane="yz"))
B("con_keys", (0.85, 0.42, 0.06), (-1.55, -1.02, 1.12), M_MET, rot=(-22, 0, 0))
B("con_hood", (0.9, 0.4, 0.6), (-1.55, -1.45, 1.42), M_MET_D, 0.04)
SCREEN("scr_scan", (-1.55, -1.245, 1.46), 0.66, 0.42, "+y", S_SCAN)
for i in range(6):
    B(f"con_key{i}", (0.09, 0.07, 0.03), (-1.85 + i * 0.12, -1.03, 1.14), M_CABLE, rot=(-22, 0, 0))
# front wall, right of door: desk terminal with the amber status screen, chair, mug
B("desk_r", (1.05, 0.55, 0.85), (1.6, -1.6, FZ + 0.425), M_MET_D, 0.03)
B("crt_r", (0.6, 0.5, 0.48), (1.6, -1.62, 1.35), M_MET_D, 0.05)
SCREEN("scr_term", (1.6, -1.365, 1.37), 0.46, 0.35, "+y", S_TERM)
B("keys_r", (0.5, 0.22, 0.04), (1.6, -1.25, 1.12), M_MET, rot=(8, 0, 0))
for i, x in enumerate((1.95, 2.03)):
    B(f"btn_r{i}", (0.05, 0.05, 0.03), (x, -1.32, 1.14), M_HAZ)
CYL("mug", 0.04, 0.09, (1.25, -1.5, 1.145), M_MET, v=8)
B("chair_seat", (0.42, 0.42, 0.05), (1.35, -0.7, 0.48), M_MET_D, 0.02, rot=(90, 0, 20))       # toppled onto its back
B("chair_back", (0.42, 0.05, 0.42), (1.28, -0.98, 0.29), M_MET_D, 0.02, rot=(90, 0, 20))
CYL("chair_post", 0.03, 0.42, (1.4, -0.45, 0.5), M_MET, "y", 6)
B("chair_base", (0.5, 0.06, 0.05), (1.45, -0.24, 0.5), M_MET, rot=(0, 0, 20))
# rear wall: louver box vent, clamped elbow pipes, wired cabinet, extinguisher
B("int_vent", (1.5, 0.3, 1.5), (-0.9, CY - 0.15, 1.95), M_MET_D, 0.08)
for i in range(6):
    B(f"int_slat{i}", (1.24, 0.08, 0.09), (-0.9, CY - 0.32, 1.42 + i * 0.21), M_MET, rot=(-28, 0, 0))
B("int_machine", (1.3, 0.6, 1.5), (1.0, CY - 0.3, FZ + 0.75), M_MET_D, 0.04)
B("int_machine_open", (0.7, 0.05, 0.7), (1.0, CY - 0.62, 0.95), M_CON)
for i, x in enumerate((0.8, 1.0, 1.2)):
    TUBE(f"int_wire{i}", (x, CY - 0.66, 1.3), (x + 0.05 * (i - 1), CY - 0.66, 0.65), 0.018, M_WIRE, 5)
B("int_machine_top", (1.0, 0.5, 0.3), (1.0, CY - 0.3, FZ + 1.65), M_MET, 0.03)
B("int_machine_light", (0.12, 0.04, 0.12), (0.55, CY - 0.62, 1.45), M_HAZ)
PIPE("int_pipe_a", [(0.1, CY - 0.15, 2.55), (0.1, CY - 0.15, FZ + 0.05)], 0.08, clamps=0.9)
PIPE("int_pipe_b", [(0.35, CY - 0.15, 2.4), (0.35, CY - 0.15, 1.5)], 0.08, clamps=0.9)
PIPE("int_elbow", [(-0.15, CY - 0.4, 2.35), (0.45, CY - 0.4, 2.35), (0.45, CY - 0.4, 1.9)], 0.07, clamps=0.9)
CYL("extinguisher", 0.07, 0.42, (2.0, CY - 0.13, 0.62), M_EXT, v=8)
CYL("extinguisher_neck", 0.03, 0.1, (2.0, CY - 0.13, 0.88), M_MET, v=6)
B("extinguisher_brk", (0.2, 0.05, 0.05), (2.0, CY - 0.06, 0.7), M_MET_D)
# left wall: pin board with notes, mesh grille, desk with static CRT
B("notes_board", (0.05, 1.3, 0.85), (-CX + 0.075, -0.6, 2.05), M_MET_D)
B("int_grille", (0.06, 1.2, 1.2), (-CX + 0.06, 0.8, 1.7), M_MET_D)
for i in range(5):
    B(f"grille_bar{i}", (0.04, 1.2, 0.04), (-CX + 0.1, 0.8, 1.2 + i * 0.22), M_CON_T)
B("desk_l", (0.65, 1.2, 0.8), (-CX + 0.36, -0.55, FZ + 0.4), M_MET_D, 0.03)
B("crt_l", (0.5, 0.5, 0.44), (-CX + 0.37, -0.55, 1.27), M_MET_D, 0.05)
SCREEN("scr_static", (-CX + 0.625, -0.55, 1.29), 0.38, 0.34, "+x", S_STATIC)
# right wall: generator with LCD, map screen, warning sign
B("gen_body", (0.95, 1.6, 1.3), (CX - 0.52, 0.35, FZ + 0.65), M_MET_D, 0.05)
B("gen_top", (0.6, 1.2, 0.35), (CX - 0.52, 0.35, FZ + 1.5), M_MET, 0.03)
SCREEN("scr_gen", (CX - 0.825, 0.35, 1.72), 0.52, 0.26, "-x", S_GEN)
PIPE("gen_pipe", [(CX - 0.4, -0.7, FZ + 0.6), (CX - 0.4, -1.3, FZ + 0.6), (CX - 0.4, -1.3, FZ + 0.05)], 0.06, mat=M_RUST, clamps=0.8)
B("map_frame", (0.06, 1.25, 0.85), (CX - 0.075, -0.85, 2.05), M_MET_D, 0.02)
SCREEN("scr_map", (CX - 0.108, -0.85, 2.05), 1.12, 0.7, "-x", S_MAP)
# storage: crates and a barrel in the rear-left corner
WIX, WIY = -1.25, 1.05                                                          # the well riser (rear-left)
CYL("well_collar", 0.62, 0.4, (WIX, WIY, FZ + 0.2), M_MET_D, v=12)
CYL("well_rim", 0.66, 0.06, (WIX, WIY, FZ + 0.4), M_MET, v=12)
LIQ_CYL("well_liquid", 0.5, 0.02, (WIX, WIY, FZ + 0.3), "z", 16)
for i in range(5):                                                               # grating over the glowing surface
    dx = -0.4 + i * 0.2
    B(f"well_bar{i}", (0.04, 2 * math.sqrt(0.6 ** 2 - dx ** 2), 0.03), (WIX + dx, WIY, FZ + 0.42), M_MET)
PIPE("well_riser", [(WIX, WIY, FZ + 0.4), (WIX, WIY, 2.45), (WIX, 1.5, 2.68)], 0.13, clamps=0.9)   # feeds the ceiling line
for z in (0.95, 1.7):
    LIQ_CYL(f"well_sleeve{z}", 0.16, 0.3, (WIX, WIY, z), "z")
COL("well_col", (1.3, 1.3, 0.45), (WIX, WIY, FZ + 0.225))
CRYSTALS("well_cr", WIX, WIY, FZ + 0.4, 5, 0.5, 11, 0.8)
POOL("spill_in", (WIX, WIY, FZ + 0.03), 2.0, 2.0)
DECAL("crust_in", (WIX, WIY, FZ + 0.02), 2.2, 2.2, "+z", D_CRUST, up=(0, 1, 0))
CYL("barrel", 0.27, 0.8, (-0.45, 1.5, FZ + 0.4), M_RUST, v=10)                  # amber drum
CYL("barrel_band", 0.285, 0.05, (-0.45, 1.5, FZ + 0.55), M_MET_D, v=10)
for z in (1.0, 1.9):
    LIQ_CYL(f"int_sleeve{z}", 0.095, 0.26, (0.1, CY - 0.15, z), "z")
# key/dosimeter pedestal
CYL("pedestal", 0.32, 0.95, (0, 0.5, FZ + 0.475), M_MET_D, v=10)
CYL("pedestal_top", 0.38, 0.08, (0, 0.5, FZ + 0.95), M_MET, v=10)

# ---- interior decals (floor decals at slightly different heights so they never z-fight)
DECAL("hazard_door", (0, -1.6, FZ + 0.022), 1.8, 0.225, "+z", D_HAZARD, up=(0, 1, 0))
DECAL("stain_f1", (0.9, -0.3, FZ + 0.014), 1.2, 1.2, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_f2", (-1.0, 0.3, FZ + 0.016), 1.5, 1.5, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_f3", (0.2, 1.3, FZ + 0.018), 1.0, 1.0, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_wr", (CX - 0.06, 1.2, 1.3), 1.0, 1.0, "-x", D_STAIN)
DECAL("stain_wl", (-CX + 0.06, 1.5, 1.2), 0.9, 0.9, "+x", D_STAIN)
DECAL("stain_wb", (-1.9, CY - 0.06, 0.9), 0.8, 0.8, "-y", D_STAIN)
DECAL("drip_vent", (-0.9, CY - 0.06, 0.95), 1.3, 1.2, "-y", D_STREAK)
DECAL("notes", (-CX + 0.106, -0.6, 2.05), 1.25, 0.62, "+x", D_NOTES)
DECAL("dust_f1", (-0.3, -0.9, FZ + 0.011), 2.2, 2.2, "+z", D_DUST, up=(0, 1, 0))
DECAL("dust_f2", (1.5, 0.9, FZ + 0.012), 1.5, 1.5, "+z", D_DUST, up=(0, 1, 0))
DECAL("papers_f", (1.0, -0.5, FZ + 0.03), 1.0, 1.0, "+z", D_PAPERS, up=(0, 1, 0))
DECAL("web_rr", (CX - 0.055, 1.6, 2.6), 0.6, 0.6, "-x", D_WEB)
DECAL("web_fl", (-CX + 0.055, -1.6, 2.6), 0.6, 0.6, "+x", D_WEB)
DECAL("web_bl", (-1.9, CY - 0.055, 2.6), 0.6, 0.6, "-y", D_WEB)
DECAL("sign_gen", (CX - 0.058, 0.35, 2.4), 0.42, 0.56, "-x", D_WARN)

# ================================================================ MARKERS
markers = {"marker_door_center": (0, -2.55, FZ), "marker_spawn_inside": (0, -0.9, FZ), "marker_pickup": (0, 0.5, 1.35),
           "marker_terminal_console": (-1.55, -1.24, 1.5), "marker_terminal_desk": (1.6, -1.36, 1.35),
           "marker_light_ceiling": (0, 0, 2.6), "marker_light_roof": (0, 0, 5.0), "marker_dish": (1.0, 0.4, 5.2),
           "marker_light_well": (WIX, WIY, FZ + 0.75), "marker_light_wellhead": (WX, WY, 2.3),
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
L.join(decals, "bunker_decals")
L.join(screens, "bunker_screens")
L.join(liquids, "bunker_liquid")
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
