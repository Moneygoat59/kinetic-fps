"""Missile Silo 00: the bore every amber route ends at. Something impossibly large left it: a 112 m wide shaft whose floor
nobody sees from the rim, six cap petals (each a 46 m slab) blown open around it, soot up the walls. Same art rules as Outpost 73
(tools/README.md "Theme"): matte purple-black obsidian, colour only from amber, 200 years unattended.
Run:  python tools/blender/textures.py; python tools/blender/silo_textures.py; python tools/blender/server_textures.py;
      python tools/blender/lift_textures.py; python tools/blender/lift_fixtures.py  (once)
      tools\\blender.ps1 tools/blender/props/missile_silo.py      ->  models/generated/missile_silo.glb
Blender axes (Z up); origin = bore centre at apron level; front (approach, stair head) faces -Y, exported to glTF +Z.
Parts: silo_rim.py (apron, lip, petal hinges, petals, rams), silo_bore.py (lining, rails, girders, mains, arms, fallen
petal), silo_tower.py (stair tower + mid-level gantry), silo_room.py (level 09 launch control room, kit markers),
silo_servers.py (the data room off launch control's left wall: server racks, the operator console), silo_hall.py (tunnel, generator hall shell), silo_lift.py (freight lift down to the hall), silo_generator.py (the
generators and the amber conduit), silo_pit.py (the bore floor, the door, tunnel and stair down to it from the hall),
silo_vent.py (the open vent duct in the hall's far end wall).
Nodes: silo_surface (outside: normal fog), silo_bore (inside: AbyssFog darkens it with depth), silo_decals /
       silo_bore_decals, silo_liquid (amber mains, always flowing), silo_screens (silo_scr_launch, PixelScreen at runtime),
       silo_hall + silo_hall_decals (generator hall, tunnel, lift shaft: their own AbyssFog look), silo_gen (generators),
       silo_gen_liquid (their amber), silo_lift_cab / silo_lift_cab_art / silo_lift_gate_* (the lift's moving parts: SiloLift),
       silo_lift_wreck (the crash's debris at the lift's foot, hidden until SiloLift.wreck()),
       silo-colonly, marker_* anchors (lights, launch console, approach), marker_kit_<prop>__<n>.
"""
import math
import os
import sys
import time
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bmesh  # noqa: E402
import bpy  # noqa: E402
import ps1_lib as L  # noqa: E402
import ps1_ao as AO  # noqa: E402
import silo_rim as RIM  # noqa: E402
import silo_bore as BORE  # noqa: E402
import silo_tower as TOWER  # noqa: E402
import silo_room as ROOM  # noqa: E402
import silo_servers as SERVERS  # noqa: E402
import silo_hall as HALL  # noqa: E402
import silo_lift as LIFT  # noqa: E402
import silo_generator as GEN  # noqa: E402
import silo_pit as PIT  # noqa: E402
import silo_vent as VENT  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
OUT = os.path.join(ROOT, "models", "generated", "missile_silo.glb")
IMPORT_STUB = '[remap]\n\nimporter="scene"\nimporter_version=1\n\n[params]\n\ngltf/embedded_image_handling=3\n'

L.reset()
T = lambda n: os.path.join(TEX, n)  # noqa: E731
M_CON = L.tex_material("silo_concrete", T("concrete.png"))
M_CON_T = L.tex_material("silo_concrete_top", T("concrete_top.png"))
M_BASALT = L.tex_material("silo_lining", T("concrete.png"), tint=(0.8, 0.8, 0.85))
M_MET = L.tex_material("silo_metal", T("metal.png"))
M_MET_D = L.tex_material("silo_metal_dark", T("metal.png"), tint=(0.55, 0.55, 0.58))
M_PLATE = L.tex_material("silo_plate", T("plate.png"))
M_FLOOR = L.tex_material("silo_floor", T("floor.png"))
M_RUST = L.material("silo_rust", (0.05, 0.02, 0.009))
M_RUST_D = L.material("silo_rust_dark", (0.025, 0.011, 0.006))
M_SOOT = L.material("silo_soot", (0.006, 0.005, 0.006))
M_HAZ = L.material("silo_hazard", (0.11, 0.02, 0.012))
M_HAZ_T = L.tex_material("silo_lift_hazard", T("lift_hazard.png"))         # tileable stripes: gate kick plates, cage sills
M_CABLE = L.material("silo_cable", (0.012, 0.011, 0.013))
GLOW = lambda n, s=1.1, e=(1.0, 0.2, 0.015): L.tex_material(n, None, tint=(0.05, 0.025, 0.008), emission=e, emission_strength=s)  # noqa: E731
M_LAMP = GLOW("silo_glow_lamp", 1.2, (1.0, 0.45, 0.08))
M_BEACON = GLOW("silo_glow_beacon", 1.4, (1.0, 0.3, 0.03))
M_KEY = GLOW("silo_glow_key", 1.0, (1.0, 0.35, 0.04))
S_LAUNCH = L.screen_material("silo_scr_launch", T("screen_term_a.png"), 1.1)
S_MAP = L.screen_material("silo_scr_map", T("screen_map_a.png"), 0.9)
LQ_FLOW = L.screen_material("silo_amber_liquid", T("liquid_flow.png"), 1.6)
D = lambda n, f: L.decal_material(n, T(f))  # noqa: E731
D_SOOT, D_STENCIL, D_DEPTH = D("silo_decal_soot", "silo_soot.png"), D("silo_decal_stencil", "silo_stencil.png"), D("silo_decal_depth", "silo_depth.png")
D_WARN, D_STREAK, D_CRACK = D("silo_decal_warning", "silo_warning.png"), D("silo_decal_streaks", "decal_streaks.png"), D("silo_decal_crack", "decal_crack.png")
D_DUST, D_PAPERS = D("silo_decal_dust", "decal_dust.png"), D("silo_decal_papers", "decal_papers.png")
D_CRUST, D_STAIN, D_HAZARD = D("silo_decal_crust", "decal_amber_crust.png"), D("silo_decal_stain", "decal_stain.png"), D("silo_decal_hazard", "decal_hazard.png")
D_SIGN = D("silo_decal_sign", "decal_sign.png")
D_DATA = D("silo_decal_data", "silo_sign_data.png")         # tools/blender/server_textures.py
TILES = {"silo_metal": 1.0, "silo_metal_dark": 1.0, "silo_plate": 1.0, "silo_rust": 1.0, "silo_concrete": 3.0,
         "silo_concrete_top": 3.0, "silo_lining": 4.0, "silo_lift_hazard": 1.0}

# ---- dimensions (metres)
R = 56.0                  # bore radius (inner face of the lining)
RL = 59.0                 # lining outer face
RA = 78.0                 # apron outer edge (terrain beyond)
TOP = 0.05                # apron / lip walk surface
LIP = 1.3                 # parapet height above TOP
FRONT = -90.0             # approach direction (deg): stair head, bridge, lip gap
GAP = 1.15                # half-angle (deg) of the lip gap at the front: just the 2 m bridge (catwalk_2m) wide
LEVEL = 4.0               # height of one stair flight
GZ = TOP - 9 * LEVEL      # level 09 (-36 m): landing 9, gantry deck, launch control
FLOOR = GZ - HALL.LIFT_DROP - PIT.DEPTH   # bore floor (-136 m, silo_pit.py): 16 m under the generator hall; from the rim AbyssFog
                          # is black long before it

surf, bore, cols, dec_out, dec_in, liquids, screens, proxies = [], [], [], [], [], [], [], []
gen_liquid = []           # generator hall amber (silo_generator.py): own node, world UVs so SiloGenerators can scroll it
gen = []                  # the generators themselves (silo_generator.py): own node, not AO-baked
hall, hall_dec = [], []   # generator hall shell, tunnel, stair frame, conduit (silo_hall.py, silo_generator.py) + decals
fine = []                 # (object, max edge length): subdivided before joining so vertex AO has resolution


def polar(r, deg, z=0.0):
    a = math.radians(deg)
    return (r * math.cos(a), r * math.sin(a), z)


def B(name, size, loc, mat, c=0.0, rot=(0, 0, 0), into=None):
    o = L.fast_box(name, size, loc, mat, rot, c)
    (surf if into is None else into).append(o)
    return o


def ABOX(name, r, deg, size, zc, mat, into=None, c=0.0, tilt=0.0):
    """Box at radius r, angle deg: size = (tangential, radial, height), centred at height zc. tilt = lean outward (deg)."""
    return B(name, size, polar(r, deg, zc), mat, c, (tilt, 0, deg - 90), into)


def CYL(name, r, d, loc, mat, axis="z", v=8, into=None, rot=None):
    rr = rot or {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
    o = L.fast_cylinder(name, r, d, loc, mat, v, rr)
    (surf if into is None else into).append(o)
    return o


def TUBE(name, p0, p1, r, mat=M_MET_D, verts=6, into=None):
    o = L.fast_tube(name, p0, p1, r, mat, verts)
    (surf if into is None else into).append(o)
    return o


def COL(name, size, loc, rot=(0, 0, 0)):
    cols.append(L.fast_box(name, size, loc, None, rot))


def ACOL(name, r, deg, size, zc):
    COL(name, size, polar(r, deg, zc), (0, 0, deg - 90))


def DECAL(name, center, w, h, facing, mat, up=(0, 0, 1), inside=False, into=None):
    (into if into is not None else dec_in if inside else dec_out).append(L.quad(name, center, w, h, facing, mat, up))


def ring(name, r0, r1, zs, a0, a1, segs, mat, into=None, top_out=None, sub=None):
    """Solid annulus sector r0..r1 between angles a0..a1 (deg). zs = ascending z levels of the inner face (extra rings give
    vertex lighting resolution); the outer face spans zs[0]..zs[-1] (or zs[-1]..top_out: a sloped top, e.g. a skirt)."""
    bm = bmesh.new()
    full = abs((a1 - a0) - 360.0) < 1e-6
    n = segs if full else segs + 1
    top1 = zs[-1] if top_out is None else top_out
    inner, outer = [], []
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * i / segs)
        ca, sa = math.cos(a), math.sin(a)
        inner.append([bm.verts.new((r0 * ca, r0 * sa, z)) for z in zs])
        outer.append([bm.verts.new((r1 * ca, r1 * sa, zs[0])), bm.verts.new((r1 * ca, r1 * sa, top1))])
    for i in range(segs):
        j = (i + 1) % n
        for k in range(len(zs) - 1):
            bm.faces.new((inner[i][k], inner[i][k + 1], inner[j][k + 1], inner[j][k]))
        bm.faces.new((outer[i][0], outer[j][0], outer[j][1], outer[i][1]))
        bm.faces.new((inner[i][-1], outer[i][1], outer[j][1], inner[j][-1]))
        bm.faces.new((inner[i][0], inner[j][0], outer[j][0], outer[i][0]))
    if not full:
        for e in (0, n - 1):
            bm.faces.new([outer[e][0], outer[e][1]] + inner[e][::-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(mat)
    (surf if into is None else into).append(o)
    if sub:
        fine.append((o, sub))
    return o


def empty(name, loc, yaw=0.0):
    L.empty(name, loc).rotation_euler = (0, 0, math.radians(yaw))


# ================================================================ BUILD
ns = types.SimpleNamespace(**{k: v for k, v in globals().items() if not k.startswith("__")})
T0 = time.time()
for part in (RIM, BORE, TOWER, ROOM, SERVERS, HALL, LIFT, GEN, PIT, VENT):
    part.build(ns)
    print(f"TIME {part.__name__} {time.time() - T0:.1f}s")
empty("marker_center", (0, 0, TOP))
empty("marker_approach", polar(92.0, FRONT, TOP))


# ================================================================ FINALISE: subdivide, join, UVs, baked AO, export
def finish(objs, name, bake=None, uv=True):
    if not objs:
        return None
    o = L.join(objs, name)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)   # a join inherits its first part's rotation
    bpy.context.scene.cursor.location = (0, 0, 0)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    if uv:
        L.world_uv(o, 2.0, TILES)
    if bake is not None:
        AO.bake_ao(o, bake, samples=14, max_dist=5.0, skip_prefix="silo_glow", floor=0.2)
    return o


bpy.context.view_layer.update()
for o, length in fine:
    AO.subdivide_by_length(o, length)
proxy_objs = list(proxies)
print(f"TIME subdivide {time.time() - T0:.1f}s")
surf_o = finish(surf, "silo_surface", [])
print(f"TIME surface {time.time() - T0:.1f}s")
bore_o = finish(bore, "silo_bore", [surf_o] + proxy_objs)
print(f"TIME bore {time.time() - T0:.1f}s")
for o in proxy_objs:
    bpy.data.objects.remove(o, do_unlink=True)
finish(cols, "silo-colonly")
hall_o = finish(hall, "silo_hall", [])
print(f"TIME hall {time.time() - T0:.1f}s")
finish(hall_dec, "silo_hall_decals", uv=False)
finish(gen_liquid, "silo_gen_liquid")
finish(gen, "silo_gen")
for lift_name, lift_objs in ns.lift.items():                 # the cage and its gates move: one node each
    finish(lift_objs, lift_name, uv=lift_name != "silo_lift_cab_art")   # the cage's art keeps its own 0..1 UVs
finish(ns.lift_dec, "silo_lift_wreck_decals", uv=False)
for objs, name in ((dec_out, "silo_decals"), (dec_in, "silo_bore_decals"), (liquids, "silo_liquid"), (screens, "silo_screens")):
    if objs:
        finish(objs, name, uv=False)
L.export_all(OUT)
if not os.path.exists(OUT + ".import"):
    with open(OUT + ".import", "w", encoding="utf-8", newline="\n") as f:
        f.write(IMPORT_STUB)
