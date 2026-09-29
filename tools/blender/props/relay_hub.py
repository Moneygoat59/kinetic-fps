"""Relay Hub 00: the routing station every amber well feeds. Same art rules as Outpost 73 (tools/README.md "Theme"): matte
purple-black obsidian concrete, colour only from amber (plus the relay channel colours on the routing wall), unattended 200 years.
Run:  python tools/blender/textures.py; python tools/blender/hub_textures.py   (once)
      tools\\blender.ps1 tools/blender/props/relay_hub.py      ->  models/generated/relay_hub.glb
Blender axes (Z up); front (door) faces -Y, exported to glTF +Z. 1 unit = 1 m. Interior 11.2 x 8.0 m (Outpost 73: 4.4 x 3.8).
Story: three buried mains (wells 73, 02, 03) rise through the floor at the ROUTING WALL, each through a gate valve and a sight
glass, into one header that drops into the SILO main. The relay masts that carried each route's control carrier stand at the
four corners (marker_route_<key>); the player reprograms them at the router console. Exterior: hub_exterior.py.
Interior layout: hub_interior.py.
Nodes: hub_shell (baked vertex AO), hub_decals, hub_screens (hub_scr_map), hub_liquid (hub_amber_liquid always flows,
       hub_flow_<key> flows once that route is online), shell-colonly, door_left / door_right (slide on local X, 1.0 m),
       valve_<key> (route handwheels, origin = wheel centre, turn about local Z), marker_* anchors, marker_kit_<prop>__<n>.
Route keys: "73" (arrival, front-left corner), "02" (rear-left), "03" (rear-right), "00" (silo, front-right).
"""
import math
import os
import sys
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bpy  # noqa: E402
import ps1_lib as L  # noqa: E402
import ps1_ao as AO  # noqa: E402
import hub_exterior as EXT  # noqa: E402
import hub_interior as INT  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
OUT = os.path.join(ROOT, "models", "generated", "relay_hub.glb")
IMPORT_STUB = '[remap]\n\nimporter="scene"\nimporter_version=1\n\n[params]\n\ngltf/embedded_image_handling=3\n'

L.reset()
T = lambda n: os.path.join(TEX, n)  # noqa: E731
M_CON = L.tex_material("hub_concrete", T("concrete.png"))
M_CON_T = L.tex_material("hub_concrete_top", T("concrete_top.png"))
M_FLOOR = L.tex_material("hub_floor", T("floor.png"))
M_MET = L.tex_material("hub_metal", T("metal.png"))
M_MET_D = L.tex_material("hub_metal_dark", T("metal.png"), tint=(0.6, 0.6, 0.62))
M_PLATE = L.tex_material("hub_plate", T("plate.png"))
M_RUST = L.material("hub_rust", (0.05, 0.02, 0.009))
M_CABLE = L.material("hub_cable", (0.012, 0.011, 0.013))
M_HAZ = L.material("hub_hazard", (0.11, 0.02, 0.012))
M_WOOD = L.material("hub_deadwood", (0.02, 0.017, 0.016))
GLOW = lambda n, s=1.1, e=(1.0, 0.2, 0.015): L.tex_material(n, None, tint=(0.05, 0.025, 0.008), emission=e, emission_strength=s)  # noqa: E731
M_AMBER = GLOW("hub_glow_amber")
M_BEACON = GLOW("hub_glow_beacon", 1.4, (1.0, 0.3, 0.03))
S_MAP = L.screen_material("hub_scr_map", T("hub_screen_map_a.png"), 1.1)
LQ_FLOW = L.screen_material("hub_amber_liquid", T("liquid_flow.png"), 1.6)
LQ_POOL = L.emissive_decal_material("hub_amber_pool", T("liquid_pool.png"), 1.1)
ROUTES = ("73", "02", "03", "00")
LQ_ROUTE = {k: L.screen_material(f"hub_flow_{k}", T("liquid_flow.png"), 1.6) for k in ROUTES}
M_LAMP = {k: GLOW(f"hub_glow_lamp_{k}", 0.3, (1.0, 0.45, 0.06)) for k in ROUTES}
D = lambda n, f: L.decal_material(n, T(f))  # noqa: E731
D_DUST, D_PAPERS = D("hub_decal_dust", "decal_dust.png"), D("hub_decal_papers", "decal_papers.png")
D_CRUST, D_CRACK, D_STREAK = D("hub_decal_crust", "decal_amber_crust.png"), D("hub_decal_crack", "decal_crack.png"), D("hub_decal_streaks", "decal_streaks.png")
D_HAZARD, D_WARN, D_STAIN = D("hub_decal_hazard", "decal_hazard.png"), D("hub_decal_warning", "decal_warning.png"), D("hub_decal_stain", "decal_stain.png")
D_DRIPS, D_STENCIL = D("hub_decal_drips_amber", "decal_drips_amber.png"), D("hub_decal_stencil", "hub_stencil.png")
D_NOTES, D_ARROWS = D("hub_decal_notes", "hub_notes.png"), D("hub_decal_arrows", "hub_floor_arrows.png")
D_PLATE = {k: D(f"hub_decal_plate_{k}", f"hub_plate_{k}.png") for k in ROUTES}
TILES = {"hub_metal": 1.0, "hub_metal_dark": 1.0, "hub_plate": 1.0, "hub_rust": 1.0}

# ---- dimensions
HX, HY, H = 7.0, 5.4, 4.6          # outer wall planes (half-widths) and wall top
CX, CY = 5.6, 4.0                  # interior half-widths
FZ, CZ = 0.25, 3.6                 # interior floor / ceiling
KZ = FZ + 0.01                     # where kit props stand
DW, DH = 1.0, 2.6                  # door half-width / top (inner opening)
OW, OH = 1.3, 2.95                 # outer reveal half-width / top
YF = -HY + 0.5                     # back plane of the outer reveal; the door leaves sit just behind it
CORNERS = {"73": (-1, -1), "02": (-1, 1), "03": (1, 1), "00": (1, -1)}   # route -> (x sign, y sign) of its corner

parts, cols, door_l, door_r, decals, screens, liquids, proxies = [], [], [], [], [], [], [], []
movers = {}


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


def LIQ_CYL(name, r, d, loc, axis="z", v=10, mat=LQ_FLOW):
    rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
    liquids.append(L.cylinder(name, r, d, loc, mat, v, rot))


def POOL(name, center, w, h):
    liquids.append(L.quad(name, center, w, h, "+z", LQ_POOL, up=(0, 1, 0)))


def CRYSTALS(prefix, cx, cy, z0, count, radius, seed, size=1.0):
    import random
    rng = random.Random(seed)
    for i in range(count):
        a, d = rng.uniform(0, math.tau), rng.uniform(0.3, 1.0) * radius
        h = rng.uniform(0.25, 0.7) * size
        o = L.cone(f"{prefix}{i}", 0.07 * size, 0.008, h, (cx + math.cos(a) * d, cy + math.sin(a) * d, z0 + h / 2), LQ_FLOW, 6)
        o.rotation_euler = (rng.uniform(-0.35, 0.35), rng.uniform(-0.35, 0.35), rng.uniform(0, math.tau))
        liquids.append(o)


def MOVER(name, pivot):
    """Parts appended to the returned list become their own node `name`, origin at `pivot`."""
    movers[name] = ([], pivot)
    return movers[name][0]


def WHEEL(name, center, r, mat, into, axis="y"):
    """Handwheel: 8-segment rim, three spokes, hub. axis = the wheel's axle direction ('y' faces the room, 'z' lies flat)."""
    cx, cy, cz = center
    at = (lambda a, rr: (cx + rr * math.cos(a), cy, cz + rr * math.sin(a))) if axis == "y" else \
        (lambda a, rr: (cx + rr * math.cos(a), cy + rr * math.sin(a), cz))
    for i in range(8):
        TUBE(f"{name}_rim{i}", at(i * math.tau / 8, r), at((i + 1) * math.tau / 8, r), 0.022, mat, 5, into)
    for i in range(3):
        TUBE(f"{name}_spoke{i}", center, at(i * math.tau / 3 + 0.5, r), 0.014, mat, 4, into)
    CYL(f"{name}_hub", 0.045, 0.06, center, M_MET, axis, 8, into)


def slab(name, x0, x1, y0, y1, z0, z1, mat, col=True):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    B(name, size, loc, mat)
    if col:
        COL(name + "_c", size, loc)


# ================================================================ SHELL
slab("floor", -HX, HX, -HY, HY, -1.0, FZ, M_FLOOR)
B("floor_top", (2 * CX, 2 * CY, 0.04), (0, 0, FZ - 0.01), M_FLOOR)
slab("back_wall", -HX, HX, CY, HY, FZ, H, M_CON)
slab("wall_l", -HX, -CX, -CY, CY, FZ, H, M_CON)
slab("wall_r", CX, HX, -CY, CY, FZ, H, M_CON)
slab("ceiling", -CX, CX, -CY, CY, CZ, H, M_CON_T)
slab("front_outer_l", -HX, -OW, -HY, YF, FZ, H, M_CON, col=False)
slab("front_outer_r", OW, HX, -HY, YF, FZ, H, M_CON, col=False)
slab("front_outer_top", -OW, OW, -HY, YF, OH, H, M_CON, col=False)
slab("front_in_l", -HX, -DW, YF, -CY, FZ, H, M_CON)
slab("front_in_r", DW, HX, YF, -CY, FZ, H, M_CON)
slab("front_in_top", -DW, DW, YF, -CY, DH, H, M_CON)
COL("front_out_l_c", (HX - OW, HY + YF, H - FZ), (-(HX + OW) / 2, (-HY + YF) / 2, (H + FZ) / 2))
COL("front_out_r_c", (HX - OW, HY + YF, H - FZ), ((HX + OW) / 2, (-HY + YF) / 2, (H + FZ) / 2))
COL("front_out_top_c", (2 * OW, HY + YF, H - OH), (0, (-HY + YF) / 2, (H + OH) / 2))
for s in (-1, 1):   # chamfered opening corners: the doorway reads octagonal, like Outpost 73
    parts.append(L.prism(f"reveal_ch{s}", [(s * OW, OH - 0.3), (s * OW, OH), (s * (OW - 0.3), OH)], 0.5, (0, -HY, 0), M_CON_T))
    parts.append(L.prism(f"reveal_in{s}", [(s * DW, DH - 0.25), (s * DW, DH), (s * (DW - 0.25), DH)], -YF - CY, (0, YF, 0), M_CON_T))
parts.append(L.arch_ring("frame_a", L.arch_pts(OW + 0.5, OH + 0.45, 0.55), L.arch_pts(OW, OH, 0.3), 0.3, (0, -HY - 0.3, 0), M_CON_T))
parts.append(L.arch_ring("frame_in", L.arch_pts(DW + 0.4, DH + 0.4, 0.45), L.arch_pts(DW, DH, 0.25), 0.14, (0, -CY, 0), M_MET_D))
parts.append(L.ramp("door_ramp", -OW, OW, -HY - 1.4, -HY, -1.0, 0.0, FZ, M_CON_T))
cols.append(L.ramp("door_ramp_c", -OW, OW, -HY - 1.4, -HY, -1.0, 0.0, FZ, None))

# ================================================================ BLAST DOOR (two leaves, jagged seam, chamfered tops)
SEAM = [(0.0, FZ), (0.12, 0.7), (-0.10, 1.12), (0.12, 1.52), (-0.08, 1.95), (0.10, 2.3), (0.0, DH)]
lp = [(-DW, FZ)] + [(x - 0.015, z) for x, z in SEAM] + [(-DW + 0.28, DH), (-DW, DH - 0.28)]
rp = [(DW, FZ)] + [(x + 0.015, z) for x, z in SEAM] + [(DW - 0.28, DH), (DW, DH - 0.28)]
door_l.append(L.prism("door_left", lp, 0.3, (0, YF + 0.1, 0), M_MET))
door_r.append(L.prism("door_right", rp[::-1], 0.3, (0, YF + 0.1, 0), M_MET))
for s, lst in ((-1, door_l), (1, door_r)):
    B(f"door_handle{s}", (0.08, 0.1, 0.45), (s * 0.3, YF + 0.05, 1.3), M_RUST, into=lst)
    for z in (0.7, 1.4, 2.1):
        B(f"door_rib{s}{z}", (0.72, 0.05, 0.12), (s * 0.56, YF + 0.08, z), M_MET_D, into=lst)
    for k in range(5):
        B(f"door_bolt{s}{k}", (0.06, 0.05, 0.06), (s * (0.2 + k * 0.16), YF + 0.08, 2.42), M_MET, into=lst)
    B(f"door_haz{s}", (DW - 0.05, 0.02, 0.1), (s * DW / 2, YF + 0.085, 0.45), M_HAZ, into=lst)

# ================================================================ INTERIOR + EXTERIOR (share this module's helpers and materials)
ns = types.SimpleNamespace(**{k: v for k, v in globals().items() if not k.startswith("__")})
INT.build(ns)
EXT.build(ns)

# ================================================================ FINALISE: join, subdivide, UVs, baked AO, export
bpy.context.view_layer.update()
shell = L.join(parts, "hub_shell")
AO.subdivide_by_length(shell, 0.9)
col = L.join(cols, "shell-colonly")
dl_obj = L.join(door_l, "door_left")
dr_obj = L.join(door_r, "door_right")
L.join(decals, "hub_decals")
L.join(screens, "hub_screens")
L.join(liquids, "hub_liquid")
movs = [(L.join(objs, name), pivot) for name, (objs, pivot) in movers.items()]
for o, _p in movs:        # a join inherits its first part's rotation: bake it so the node rest pose is identity
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
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
AO.bake_ao(shell, [dl_obj, dr_obj] + movs + proxies, ground_z=0.0, skip_prefix="hub_glow")
for o in proxies:
    bpy.data.objects.remove(o, do_unlink=True)
AO.bake_ao(dl_obj, [shell, dr_obj], ground_z=0.0, skip_prefix="hub_glow")
AO.bake_ao(dr_obj, [shell, dl_obj], ground_z=0.0, skip_prefix="hub_glow")
for o in movs:
    AO.bake_ao(o, [shell], ground_z=0.0, skip_prefix="hub_glow")
L.export_all(OUT)
if not os.path.exists(OUT + ".import"):
    with open(OUT + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write(IMPORT_STUB)
