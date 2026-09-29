"""Outpost 73 bunker v5: an amber-extraction well that has run UNATTENDED for 200 years. Matte purple-black obsidian concrete.
Run:  python tools/blender/textures.py   (once)   then   tools\blender.ps1 tools/blender/props/outpost73_bunker.py [02|03]
Out:  models/generated/outpost73_bunker.glb, or a variant's (outpost02_bunker.glb ...): see outpost_variants.py
Blender axes (Z up); front (door) faces -Y, exported to glTF +Z. 1 unit = 1 m.
Nodes: bunker_shell (visual, baked vertex-colour AO), bunker_decals (alpha stencils/stains/notes), bunker_screens (emissive CRT
       quads, materials bunker_scr_* animated by bunker_screens.gd), bunker_liquid (glowing amber: bunker_amber_liquid flows,
       bunker_amber_pool pulses), shell-colonly (Godot builds trimesh collision),
       door_left / door_right (slide on local X, 1.0 m), pump_beam / pump_crank / pump_pitman / pump_rod / pump_bridle (pump jack
       parts, node origin = pivot, animated by bunker_pump.gd), marker_* empties (gameplay anchors, see outpost_bunker.gd),
       marker_kit_<prop>__<n> (position + yaw of an Outpost 73 prop-kit piece; bunker_kit.gd spawns the live prop there).
Interior furniture is the prop kit (tools/blender/kit/): console, desk + CRT + chair, wall keypad, tape mainframe, shelf, drum and
the field-kit rack (marker_pickup = the dosimeter on its slot 03 hook). The shell keeps the fixtures (pipes, cables, vent, well
riser, notes, grille, map screen); KIT lists the placements and
their AO proxies (boxes that darken the floor and walls around each piece during the bake, then are deleted).
Extraction: a pump jack behind the bunker still nods over the wellhead; one line feeds the bunker (well riser in the control
room), the other drops into a valve pit and runs underground to the silo. Exterior parts live in o73_exterior.py.
Decay: broken cornice + rubble, fallen ladder section, dead branch and log, dust, papers, rust, dried-amber crust. Interior 4.4 x 3.8 m, floor z=0.25, ceiling z=2.9, door opening 1.8 x 2.25 m.
"""
import math
import os
import sys
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "kit"))
import bpy  # noqa: E402
import ps1_lib as L  # noqa: E402
import ps1_ao as AO  # noqa: E402
import o73_exterior as EXT  # noqa: E402
import outpost_extras as XT  # noqa: E402
import outpost_variants as VX  # noqa: E402
import kit_dims as KD  # noqa: E402
from kit_lib import TABLE_TOP  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
VKEY, V = VX.pick(L.argv_after_dashes())
OUT = os.path.join(ROOT, "models", "generated", V["out"])

L.reset()
T = lambda n: os.path.join(TEX, n)  # noqa: E731
M_CON = L.tex_material("bunker_concrete", T("concrete.png"))
M_CON_T = L.tex_material("bunker_concrete_top", T("concrete_top.png"))
M_FLOOR = L.tex_material("bunker_floor", T("floor.png"))
M_MET = L.tex_material("bunker_metal", T("metal.png"))
M_MET_D = L.tex_material("bunker_metal_dark", T("metal.png"), tint=(0.6, 0.6, 0.62))
M_PLATE = L.tex_material("bunker_plate", T("plate.png"))
# flat colours are LINEAR (glTF baseColorFactor) while the textures are sRGB: keep them this low or they read pale next to
# the near-black obsidian
M_RUST = L.material("bunker_rust", (0.05, 0.02, 0.009))
M_WIRE = L.material("bunker_wire", (0.09, 0.03, 0.012))
M_CABLE = L.material("bunker_cable", (0.012, 0.011, 0.013))
M_HAZ = L.material("bunker_hazard", (0.11, 0.02, 0.012))
M_BOX = L.material("bunker_box", (0.05, 0.035, 0.02))
M_EXT = L.material("bunker_extinguisher", (0.13, 0.014, 0.01))
M_AMBER = L.tex_material("bunker_glow_amber", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.2, 0.015), emission_strength=1.1)
M_BEACON = L.tex_material("bunker_glow_beacon", None, tint=(0.05, 0.025, 0.008), emission=(1.0, 0.3, 0.03), emission_strength=1.4)
M_WOOD = L.material("bunker_deadwood", (0.02, 0.017, 0.016))
S_MAP = L.screen_material("bunker_scr_map" + V["tag"][1:], T(f"screen_map{V['tag'][1:]}_a.png"), 1.1)
LQ_FLOW = L.screen_material("bunker_amber_liquid", T("liquid_flow.png"), 1.6)
LQ_POOL = L.emissive_decal_material("bunker_amber_pool", T("liquid_pool.png"), 1.1)
D_DRIPS = L.decal_material("bunker_decal_drips_amber", T("decal_drips_amber.png"))
D_DUST = L.decal_material("bunker_decal_dust", T("decal_dust.png"))
D_PAPERS = L.decal_material("bunker_decal_papers", T("decal_papers.png"))
D_CRUST = L.decal_material("bunker_decal_crust", T("decal_amber_crust.png"))
D_CRACK = L.decal_material("bunker_decal_crack", T("decal_crack.png"))
D_STREAK = L.decal_material("bunker_decal_streaks", T("decal_streaks.png"))
D_STENCIL = L.decal_material("bunker_decal_stencil", T(f"decal_stencil{V['tag']}.png"))
D_HAZARD = L.decal_material("bunker_decal_hazard", T("decal_hazard.png"))
D_WARN = L.decal_material("bunker_decal_warning", T("decal_warning.png"))
D_STAIN = L.decal_material("bunker_decal_stain", T("decal_stain.png"))
D_NOTES = L.decal_material("bunker_decal_notes", T("decal_notes.png"))
D_SIGN = L.decal_material("bunker_decal_sign", T(f"decal_sign{V['tag']}.png"))
TILES = {"bunker_metal": 1.0, "bunker_metal_dark": 1.0, "bunker_plate": 1.0, "bunker_rust": 1.0}   # metres per texture repeat (default 2.0)

# ---- dimensions
HX, HY, H = 3.6, 3.3, 4.0          # wall planes (half-widths) and wall height
CX, CY = 2.2, 1.9                  # interior cavity half-widths
FZ, CZ = 0.25, 2.9                 # interior floor / ceiling heights
KZ = FZ + 0.01                     # top of floor_top: where prop-kit pieces stand
DW, DH = 0.9, 2.5                  # door half-width, door top

parts, cols, door_l, door_r, decals, screens, liquids = [], [], [], [], [], [], []
movers = {n: ([], p) for n, p in (("pump_beam", (0.3, 5.6, 3.0)), ("pump_crank", (-1.25, 5.6, 0.9)),
                                  ("pump_pitman", (-1.25, 5.6, 2.8)), ("pump_rod", (1.9, 5.6, 2.45)), ("pump_bridle", (1.9, 5.6, 3.0)))}


def B(name, size, loc, mat, c=0.0, rot=(0, 0, 0), into=None):
    o = L.chamfer_box(name, size, loc, mat, c, rot) if c else L.box(name, size, loc, mat, rot)
    (parts if into is None else into).append(o)
    return o


def CYL(name, r, d, loc, mat, axis="z", v=8, into=None):
    rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
    o = L.cylinder(name, r, d, loc, mat, v, rot)
    (parts if into is None else into).append(o)
    return o


def PIPE(name, pts, r, mat=M_MET_D, clamps=0.0, verts=8, into=None):
    (parts if into is None else into).extend(AO.pipe(name, pts, r, mat, verts, clamps, M_MET))


def TUBE(name, p0, p1, r, mat=M_MET_D, verts=6, into=None):
    (parts if into is None else into).append(AO.tube(name, p0, p1, r, mat, verts))


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

# ================================================================ EXTERIOR (o73_exterior.py): roof, ladder, hatch, rubble, dish,
# beacon, pump yard and the buried amber main to the silo
EXT.build(types.SimpleNamespace(**{k: v for k, v in globals().items() if not k.startswith("__")}))

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

# ================================================================ INTERIOR (mirrored in X for variants with V["mirror"])
inner = XT.mark(parts, cols, decals, screens, liquids)
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
PIPE("ceil_pipe_b", [(CX - 0.05, -1.4, 2.72), (-1.8, -1.4, 2.72), (-1.8, -1.4, KZ + 1.6)], 0.075, clamps=0.9)   # into the console
PIPE("ceil_pipe_rear", [(CX - 0.05, 1.5, 2.68), (-CX + 0.05, 1.5, 2.68)], 0.09, clamps=0.9)
PIPE("ceil_cable", [(2.1, -1.8, 2.82), (1.95, -1.0, 2.62), (2.1, -0.1, 2.78), (1.95, 0.7, 2.58)], 0.035, mat=M_CABLE, verts=5)
PIPE("ceil_cable2", [(-2.18, 0.2, 2.87), (-1.6, 0.6, 2.66), (-1.1, 0.3, 2.88), (-0.6, 0.9, 2.62)], 0.03, mat=M_CABLE, verts=5)
TUBE("hang_cable_a", (0.9, 0.9, 2.8), (0.95, 0.9, 2.05), 0.02, M_CABLE, 5)
TUBE("hang_cable_b", (-0.7, -0.9, 2.8), (-0.72, -0.9, 2.2), 0.02, M_WIRE, 5)
# rear wall: louver box vent, clamped elbow pipes, extinguisher
B("int_vent", (1.5, 0.3, 1.5), (-0.9, CY - 0.15, 1.95), M_MET_D, 0.08)
for i in range(6):
    B(f"int_slat{i}", (1.24, 0.08, 0.09), (-0.9, CY - 0.32, 1.42 + i * 0.21), M_MET, rot=(-28, 0, 0))
PIPE("int_pipe_a", [(0.1, CY - 0.15, 2.55), (0.1, CY - 0.15, FZ + 0.05)], 0.08, clamps=0.9)
PIPE("int_pipe_b", [(0.35, CY - 0.15, 2.4), (0.35, CY - 0.15, 1.5)], 0.08, clamps=0.9)
PIPE("int_elbow", [(-0.3, CY - 0.4, 2.35), (0.45, CY - 0.4, 2.35), (0.45, CY - 0.4, FZ + 0.05)], 0.07, clamps=0.9)   # vent -> floor
CYL("extinguisher", 0.07, 0.42, (2.0, CY - 0.13, 0.62), M_EXT, v=8)
CYL("extinguisher_neck", 0.03, 0.1, (2.0, CY - 0.13, 0.88), M_MET, v=6)
B("extinguisher_brk", (0.2, 0.05, 0.05), (2.0, CY - 0.06, 0.7), M_MET_D)
# left wall: pin board with notes (above the kit console), mesh grille
B("notes_board", (0.05, 1.3, 0.85), (-CX + 0.075, -0.6, 2.25), M_MET_D)
B("int_grille", (0.06, 0.8, 1.2), (-CX + 0.06, 1.0, 1.7), M_MET_D)          # narrowed: the field-kit rack hangs beside it
for i in range(5):
    B(f"grille_bar{i}", (0.04, 0.8, 0.04), (-CX + 0.1, 1.0, 1.2 + i * 0.22), M_CON_T)
# right wall: map screen (the kit desk sits under it, the kit mainframe behind)
B("map_frame", (0.06, 1.25, 0.85), (CX - 0.075, -0.85, 2.05), M_MET_D, 0.02)
SCREEN("scr_map", (CX - 0.108, -0.85, 2.05), 1.12, 0.7, "-x", S_MAP)
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
for z in (1.0, 1.9):
    LIQ_CYL(f"int_sleeve{z}", 0.095, 0.26, (0.1, CY - 0.15, z), "z")

# ---- interior decals (floor decals at slightly different heights so they never z-fight)
DECAL("hazard_door", (0, -1.6, FZ + 0.022), 1.8, 0.225, "+z", D_HAZARD, up=(0, 1, 0))
DECAL("stain_f1", (0.9, -0.3, FZ + 0.014), 1.2, 1.2, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_f2", (-1.0, 0.3, FZ + 0.016), 1.5, 1.5, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_f3", (0.2, 1.3, FZ + 0.018), 1.0, 1.0, "+z", D_STAIN, up=(0, 1, 0))
DECAL("stain_wr", (CX - 0.06, 1.2, 1.3), 1.0, 1.0, "-x", D_STAIN)
DECAL("stain_wl", (-CX + 0.06, 1.5, 1.2), 0.9, 0.9, "+x", D_STAIN)
DECAL("stain_wb", (-1.9, CY - 0.06, 0.9), 0.8, 0.8, "-y", D_STAIN)
DECAL("drip_vent", (-0.9, CY - 0.06, 0.95), 1.3, 1.2, "-y", D_STREAK)
DECAL("notes", (-CX + 0.106, -0.6, 2.25), 1.25, 0.62, "+x", D_NOTES)
DECAL("dust_f1", (-0.3, -0.9, FZ + 0.011), 2.2, 2.2, "+z", D_DUST, up=(0, 1, 0))
DECAL("dust_f2", (1.5, 0.9, FZ + 0.012), 1.5, 1.5, "+z", D_DUST, up=(0, 1, 0))
DECAL("papers_f", (1.0, -0.5, FZ + 0.03), 1.0, 1.0, "+z", D_PAPERS, up=(0, 1, 0))
DECAL("sign_rad", (CX - 0.058, 1.45, 1.95), 0.42, 0.56, "-x", D_WARN)
if "flood" in V["extras"]:
    XT.flood(types.SimpleNamespace(**{k: v for k, v in globals().items() if not k.startswith("__")}))
if V["mirror"]:
    XT.mirror_x(inner, flip_uv=(decals, screens))

# ================================================================ MARKERS
markers = {"marker_door_center": (0, -2.55, FZ), "marker_spawn_inside": (0, -0.9, FZ),
           "marker_terminal_console": (-1.86, -0.98, 1.59), "marker_terminal_desk": (1.53, -0.95, 1.41),
           "marker_light_ceiling": (0, 0, 2.6), "marker_light_roof": (*V["beacon"], 5.33), "marker_dish": (1.0, 0.42, 5.12),
           "marker_light_well": (WIX, WIY, FZ + 0.75), "marker_light_wellhead": (EXT.WX + 0.6, EXT.WY - 0.9, 2.2),
           "marker_pump": (-1.25, 5.6, 1.1), "marker_light_pit": (EXT.PX, EXT.PY, 0.1),
           "marker_light_front": (0, -3.95, 3.42), "marker_light_side_r": (4.05, -1.25, 3.1), "marker_light_side_l": (-4.05, 1.2, 3.1)}
INNER_MARKERS = ("marker_terminal_console", "marker_terminal_desk", "marker_light_well")
for n, p in markers.items():
    L.empty(n, (-p[0], p[1], p[2]) if V["mirror"] and n in INNER_MARKERS else p)

# ================================================================ PROP KIT (live pieces spawned at runtime by scripts/bunker/bunker_kit.gd)
# (prop, x, y, z above the floor, yaw deg, AO proxy (size, local centre) or None). Kit props face local -Y at yaw 0 like the
# bunker; yaw turns counter-clockwise seen from above. Floor props stand on floor_top (KZ), 1 cm above FZ.
RACK_X, RACK_Y = -CX + 0.05, 0.07                                                               # rack back on the lining face
KIT = [
    ("terminal_console", -1.79, -0.98, 0.0, 90, ((1.04, 0.77, 1.6), (0, -0.035, 0.8))),         # left wall, faces the room
    ("table_steel", 1.70, -0.92, 0.0, -90, ((1.6, 0.9, 0.78), (0, 0, 0.39))),                  # right wall under the map
    ("terminal_crt", 1.72, -0.95, 0.78, -90, None),
    ("amber_cell", 1.62, -0.28, 0.78, 20, None),
    ("chair_steel", 0.95, -0.95, 0.0, 70, None),                                                # pushed back from the desk
    ("terminal_wall", 1.74, -CY + 0.05, 0.0, 180, ((0.6, 0.3, 0.8), (0, -0.15, 1.47))),          # front wall, right of the door
    ("terminal_mainframe", 1.78, 0.6, 0.0, -90, ((0.94, 0.74, 1.98), (0, 0, 0.99))),            # right wall, rear
    ("shelf_rack", 1.15, CY - 0.275, 0.0, 0, ((1.2, 0.45, 1.9), (0, 0, 0.95))),                # rear wall, right of the pipes
    ("drum_amber", -0.3, 1.52, 0.0, 0, ((0.58, 0.58, 0.89), (0, 0, 0.445))),                   # beside the well
    ("dosimeter_rack", RACK_X, RACK_Y, 0.0, 90, None),                                          # left wall, by the notes
]
KIT = VX.kit(V, KIT, CX)
if V["pickup"] == "dosimeter":
    # the dosimeter pickup hangs on the rack's slot 03 hook (kit_dims), facing the room like the rack (yaw 90: local -Y -> +X)
    L.empty("marker_pickup", (RACK_X - KD.RACK_DEVICE_Y, RACK_Y + KD.RACK_SLOTS[2], KZ + KD.RACK_DEVICE_Z)).rotation_euler = (0, 0, math.radians(90))
else:   # route key case on the desk beside the relay CRT (the desk is on the left wall when the interior is mirrored)
    kx, ky, kyaw = VX.ROUTE_KEY
    ms = -1 if V["mirror"] else 1
    L.empty("marker_pickup", (ms * kx, ky, KZ + TABLE_TOP)).rotation_euler = (0, 0, math.radians(ms * kyaw))
proxies = []
for i, (prop, kx, ky, kz, yaw, proxy) in enumerate(KIT):
    L.empty(f"marker_kit_{prop}__{i}", (kx, ky, KZ + kz)).rotation_euler = (0, 0, math.radians(yaw))
    if proxy:
        (size, (lx, ly, lz)), ca, sa = proxy, math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
        proxies.append(L.box(f"kit_proxy{i}", size, (kx + lx * ca - ly * sa, ky + lx * sa + ly * ca, KZ + kz + lz), None, (0, 0, yaw)))

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
movs = [(L.join(objs, name), pivot) for name, (objs, pivot) in movers.items()]
for o, _p in movs:        # a join inherits its first part's rotation (tubes are rotated): bake it so the node rest pose is identity
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
# join keeps the first part's origin: shell/collision go to the world origin (identity node transforms), pump parts to their
# pivot so Godot can rotate / move each node about it
for o, pivot in [(shell, (0, 0, 0)), (col, (0, 0, 0))] + movs:
    bpy.context.scene.cursor.location = pivot
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
bpy.context.view_layer.update()
movs = [o for o, _p in movs]
for o in [shell, col, dl_obj, dr_obj] + movs:
    L.world_uv(o, 2.0, TILES)
AO.bake_ao(shell, [dl_obj, dr_obj] + movs + proxies, ground_z=0.0)
for o in proxies:
    bpy.data.objects.remove(o, do_unlink=True)
AO.bake_ao(dl_obj, [shell, dr_obj], ground_z=0.0)
AO.bake_ao(dr_obj, [shell, dl_obj], ground_z=0.0)
for o in movs:
    AO.bake_ao(o, [shell] + [m for m in movs if m is not o], ground_z=0.0)
L.export_all(OUT)
