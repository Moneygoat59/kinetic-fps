"""Outpost 73 prop kit: shared builder. Every prop is built in a fresh Blender scene and exported to its own .glb.
Look = the bunker's (tools/blender/props/outpost73_bunker.py): same textures, matte near-black violet metal, dark rust, colour only
from amber glow, screens and lamps. Textures: python tools/blender/textures.py and python tools/blender/kit_textures.py.

Conventions (Blender axes, Z up; exported Y-up so Blender -Y = Godot +Z):
  * 1 unit = 1 m, origin at the base centre, FRONT faces -Y (Godot +Z).
  * Wall props (wall=True) have their back on the y = 0 plane: place them against a wall with their +Z pointing into the room.
  * Tabletop props sit at TABLE_TOP on table_steel.  Pipes/barriers snap on a GRID (2 m), pipe centreline at PIPE_Z.
Node contract of each .glb (read by scripts/props/kit_prop.gd):
  body (baked vertex AO), panels (explicit-UV control surfaces), screens (kit_scr_* emissive quads), decals (alpha quads),
  spin_* (turning parts, origin = pivot, turn about local Z = Blender -Y axis), other PIVOT nodes (origin = pivot, driven by a
  prop's own script, e.g. the dosimeter needle), collision-colonly (Godot builds a StaticBody3D),
  marker_light_<kind>* / marker_spot* (light anchors).
"""
import math
import os
import sys

import bmesh
import bpy

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import ps1_ao as AO  # noqa: E402
import ps1_lib as L  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
TEX = os.path.join(ROOT, "models", "generated", "tex")
OUT_DIR = os.path.join(ROOT, "models", "generated", "o73_kit")
IMPORT_SCRIPT = "res://tools/o73_kit_import.gd"
TABLE_TOP = 0.78
GRID = 2.0
PIPE_Z = 0.5
TILES = {"kit_metal": 1.0, "kit_metal_dark": 1.0, "kit_plate": 1.0, "kit_rust": 1.0, "kit_drum": 1.0}
# Godot import settings written next to each new .glb: embed textures (no per-prop PNG copies) and run the kit import hook
IMPORT_STUB = f'[remap]\n\nimporter="scene"\nimporter_version=1\n\n[params]\n\nimport_script/path="{IMPORT_SCRIPT}"\ngltf/embedded_image_handling=3\n'


def _t(name):
    return os.path.join(TEX, name)


def lit_material(name, image_path, strength=0.6):
    """Control surface: albedo AND faint emission from the same image, so lit LEDs glow while dark metal stays dark."""
    m = L.tex_material(name, image_path)
    nt = m.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = next(n for n in nt.nodes if n.type == "TEX_IMAGE")
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
    bsdf.inputs["Emission Strength"].default_value = strength
    return m


def glow(name, rgb, strength=1.2):
    """Emissive lamp/lens: near-black albedo (Godot lights the albedo on top of the emission)."""
    return L.tex_material(name, None, tint=(0.05, 0.025, 0.008), emission=rgb, emission_strength=strength)


class Kit:
    # subclasses (other kits, e.g. tools/blender/apt/apt_lib.py) override where pieces go, their import hook and the AO look
    OUT_DIR = OUT_DIR
    IMPORT_STUB = IMPORT_STUB
    AO = {}

    def shade(self, obj):
        """Normals of a joined node before export. The Outpost 73 kit stays flat-shaded; other kits may smooth."""

    def __init__(self, name):
        L.reset()
        self.name = name
        self.parts, self.panels, self.screens, self.decals, self.cols = [], [], [], [], []
        self.movers, self.markers, self.opts = {}, {}, {}
        self.MET = L.tex_material("kit_metal", _t("metal.png"))
        self.MET_D = L.tex_material("kit_metal_dark", _t("metal.png"), tint=(0.6, 0.6, 0.62))
        self.PLATE = L.tex_material("kit_plate", _t("plate.png"))
        self.DRUM = L.tex_material("kit_drum", _t("metal.png"), tint=(1.0, 0.6, 0.4))     # rust-painted steel
        self.CON = L.tex_material("kit_concrete", _t("concrete.png"))
        self.CON_T = L.tex_material("kit_concrete_top", _t("concrete_top.png"))
        self.CON_B = L.tex_material("kit_concrete_cast", _t("concrete.png"), tint=(0.85, 0.8, 0.64))  # sloped faces catch sky: less violet
        # flat colours are LINEAR while textures are sRGB: keep them this low or they read pale next to the obsidian
        self.RUST = L.material("kit_rust", (0.05, 0.02, 0.009))
        self.WIRE = L.material("kit_wire", (0.09, 0.03, 0.012))
        self.CABLE = L.material("kit_cable", (0.012, 0.011, 0.013))
        self.HAZ = L.material("kit_hazard", (0.11, 0.02, 0.012))
        self.BOX = L.material("kit_cardboard", (0.016, 0.011, 0.006))
        self.OCHRE = L.material("kit_ochre", (0.024, 0.016, 0.003))
        self.AMBER = glow("kit_glow_amber", (1.0, 0.2, 0.015), 1.1)
        self.BLINK = glow("kit_glow_blink", (1.0, 0.3, 0.03), 1.4)
        self.RED = glow("kit_glow_red", (1.0, 0.06, 0.02), 1.2)
        self.GREEN = glow("kit_glow_green", (0.25, 1.0, 0.3), 1.0)
        self.LAMP = glow("kit_glow_lamp", (1.0, 0.55, 0.2), 2.5)
        self.LIQUID = L.screen_material("kit_glow_liquid", _t("liquid_flow.png"), 1.6)
        self.KEYS = L.tex_material("kit_keys", _t("kit_keys.png"))
        self.KEYPAD = L.tex_material("kit_keypad", _t("kit_keypad.png"))
        self.CTRL = lit_material("kit_panel", _t("kit_panel.png"), 0.6)
        self.METER = lit_material("kit_meter", _t("kit_meter_face.png"), 0.9)                       # backlit analog meter
        self.LED = glow("kit_glow_dosi_led", (1.0, 0.35, 0.04), 0.6)       # dosimeter click LED (driven by its script)
        self.LAMP_CH = glow("kit_glow_dosi_lamp", (1.0, 0.55, 0.12), 0.8)  # dosimeter channel lamp (tinted per channel)
        self.PYLON = glow("kit_glow_pylon", (1.0, 0.6, 0.2), 1.2)          # relay mast beacon + band (tinted per channel)
        self.PUDDLE = L.emissive_decal_material("kit_amber_pool", _t("liquid_pool.png"), 1.1)
        d = lambda n, f: L.decal_material(n, _t(f))  # noqa: E731
        self.D_DUST, self.D_STREAK = d("kit_decal_dust", "decal_dust.png"), d("kit_decal_streaks", "decal_streaks.png")
        self.D_STAIN, self.D_HAZARD = d("kit_decal_stain", "decal_stain.png"), d("kit_decal_hazard", "decal_hazard.png")
        self.D_WARN = d("kit_decal_warning", "decal_warning.png")
        self.D_DRIPS, self.D_CRUST = d("kit_decal_drips", "decal_drips_amber.png"), d("kit_decal_crust", "decal_amber_crust.png")
        self.D_PAPERS = d("kit_decal_papers", "decal_papers.png")
        self.D_SUPPLY, self.D_AMBER = d("kit_decal_supply", "kit_decal_supply.png"), d("kit_decal_amber", "kit_decal_amber.png")
        self.D_PLATE = d("kit_decal_plate", "kit_decal_plate.png")
        self.D_SIGN = d("kit_decal_sign", "decal_sign.png")
        self.D_RELAY = d("kit_decal_relay", "kit_decal_relay.png")
        self.D_DOSI, self.D_BOARD = d("kit_decal_dosi", "kit_decal_dosi.png"), d("kit_decal_board", "kit_decal_shadowboard.png")

    # ------------------------------------------------------------ primitives (append to body unless `into` is given)
    def _add(self, o, into):
        (self.parts if into is None else into).append(o)
        return o

    def B(self, name, size, loc, mat, c=0.0, rot=(0, 0, 0), into=None):
        o = L.chamfer_box(name, size, loc, mat, c, rot) if c else L.box(name, size, loc, mat, rot)
        return self._add(o, into)

    def CYL(self, name, r, d, loc, mat, axis="z", v=8, into=None):
        rot = {"z": (0, 0, 0), "x": (0, 90, 0), "y": (90, 0, 0)}[axis]
        return self._add(L.cylinder(name, r, d, loc, mat, v, rot), into)

    def FRUSTUM(self, name, r1, r2, d, loc, mat, axis="y", v=4, into=None):
        """Square (v=4) or round frustum; axis 'y' points the narrow end to +Y (CRT necks, lamp hoods)."""
        o = L.cone(name, r1, r2, d, loc, mat, v)
        o.rotation_mode = "ZXY"   # twist about the cone's own axis first (square faces axis-aligned), then tip it over
        o.rotation_euler = (math.radians(-90 if axis == "y" else 0), 0, math.radians(45 if v == 4 else 0))
        return self._add(o, into)

    def PRISM(self, name, pts, depth, loc, mat, plane="xz", into=None):
        return self._add(L.prism(name, pts, depth, loc, mat, plane=plane), into)

    def PIPE(self, name, pts, r, mat=None, clamps=0.0, verts=8, into=None):
        (self.parts if into is None else into).extend(AO.pipe(name, pts, r, mat or self.MET_D, verts, clamps, self.MET))

    def TUBE(self, name, p0, p1, r, mat=None, verts=6, into=None):
        return self._add(AO.tube(name, p0, p1, r, mat or self.MET_D, verts), into)

    def COL(self, size, loc):
        self.cols.append(L.box(f"col{len(self.cols)}", size, loc, None))

    def COL_CYL(self, r, d, loc, v=10):
        self.cols.append(L.cylinder(f"col{len(self.cols)}", r, d, loc, None, v))

    def COL_COPY(self, obj):
        """Collision from an existing part's shape (sloped / broken solids)."""
        o = obj.copy()
        o.data = obj.data.copy()
        o.data.materials.clear()
        bpy.context.collection.objects.link(o)
        self.cols.append(o)

    def scr(self, name, frame, strength=1.2):
        """Screen material kit_scr_<name>, first frame from tex/<frame>; kit_prop.gd cycles the rest."""
        return L.screen_material(f"kit_scr_{name}", _t(frame), strength)

    def POOL(self, name, center, w, h):
        """Glowing amber puddle on the ground (emissive alpha quad, lives with the decals)."""
        self.decals.append(L.quad(name, center, w, h, "+z", self.PUDDLE, up=(0, 1, 0)))

    def SPIN(self, name, pivot):
        """Parts appended to the returned list become node spin_<name>, origin at `pivot` (kit_prop.gd turns it)."""
        return self.PIVOT(f"spin_{name}", pivot)

    def PIVOT(self, name, pivot):
        """Parts appended to the returned list become their own node `name` with its origin at `pivot` (needles, levers)."""
        self.movers[name] = ([], pivot)
        return self.movers[name][0]

    def LIGHT(self, name, loc):
        self.markers[name] = loc

    def OPT(self, name):
        """Optional part (a railing side, a cover): parts appended to the returned list become node opt_<name>, collision
        added with OPT_COL goes to opt_<name>_col. A placement drops it with a __no_<name> marker suffix (bunker_kit.gd)."""
        self.opts.setdefault(name, ([], []))
        return self.opts[name][0]

    def OPT_COL(self, name, size, loc, rot=(0, 0, 0)):
        self.OPT(name)
        self.opts[name][1].append(L.box(f"opt_{name}_c{len(self.opts[name][1])}", size, loc, None, rot))

    # ------------------------------------------------------------ flat quads: screens, control panels, decals
    def _quad(self, lst, name, center, w, h, facing, mat, up=(0, 0, 1), tilt=0.0):
        """tilt (deg) leans a front (-y) quad's top back, for sloped desks and screens."""
        o = L.quad(name, center, w, h, facing, mat, up)
        if tilt:
            L.rotate_about([o], center, (-tilt, 0, 0))
        lst.append(o)
        return o

    def SCREEN(self, name, center, w, h, mat, facing="-y", tilt=0.0):
        return self._quad(self.screens, name, center, w, h, facing, mat, tilt=tilt)

    def PANEL(self, name, center, w, h, mat, facing="-y", tilt=0.0, up=(0, 0, 1)):
        return self._quad(self.panels, name, center, w, h, facing, mat, up, tilt)

    def DECAL(self, name, center, w, h, mat, facing="-y", up=(0, 0, 1), tilt=0.0):
        return self._quad(self.decals, name, center, w, h, facing, mat, up, tilt)

    def WRAP(self, name, c, r, z0, z1, a0, a1, mat, segs=6):
        """Decal strip wrapped round a vertical cylinder (centre c=(x,y), radius r) from angle a0 to a1 (deg, CCW from +X)."""
        verts, faces, uvs = [], [], []
        for i in range(segs + 1):
            a = math.radians(a0 + (a1 - a0) * i / segs)
            verts += [(c[0] + r * math.cos(a), c[1] + r * math.sin(a), z0), (c[0] + r * math.cos(a), c[1] + r * math.sin(a), z1)]
        for i in range(segs):
            faces.append([2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1])
            uvs += [(i / segs, 0), ((i + 1) / segs, 0), ((i + 1) / segs, 1), (i / segs, 1)]
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], faces)
        uv = me.uv_layers.new(name="UVMap")
        for k, p in enumerate(uvs):
            uv.data[k].uv = p
        o = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(o)
        me.materials.append(mat)
        self.decals.append(o)
        return o

    # ------------------------------------------------------------ finish: join, AO, UVs, export
    def finish(self, wall=False, subdiv=0.3, ao_dist=0.9, ground=True):
        """ground=False: handheld items (no floor contact shadow baked under them)."""
        bpy.context.view_layer.update()
        body = _normal(L.join(self.parts, "body"))
        AO.subdivide_by_length(body, subdiv)
        spins = [_normal(L.join(objs, n), pivot) for n, (objs, pivot) in self.movers.items()]
        spins += [_normal(L.join(objs, f"opt_{n}")) for n, (objs, _c) in self.opts.items() if objs]
        for o in [body] + spins:
            self.shade(o)
        panels = _normal(L.join(self.panels, "panels")) if self.panels else None
        if panels:
            self.shade(panels)
        for o in [body] + spins:
            L.world_uv(o, 2.0, TILES)
        occ = [body] + spins + ([panels] if panels else [])
        backing = _backing_wall() if wall else None
        for o in occ:
            AO.bake_ao(o, [x for x in occ if x is not o] + ([backing] if backing else []), max_dist=ao_dist, ground_z=0.0 if ground else None,
                       skip_prefix="kit_glow", **self.AO)
        if backing:
            bpy.data.objects.remove(backing, do_unlink=True)
        for lst, n in ((self.cols, "collision-colonly"), (self.screens, "screens"), (self.decals, "decals")):
            if lst:
                _normal(L.join(lst, n))
        for n, (_objs, cols) in self.opts.items():
            if cols:
                _normal(L.join(cols, f"opt_{n}_col-colonly"))
        for n, p in self.markers.items():
            L.empty(n, p)
        path = os.path.join(self.OUT_DIR, self.name + ".glb")
        L.export_all(path)
        if not os.path.exists(path + ".import"):
            with open(path + ".import", "w", encoding="utf-8", newline="\n") as f:
                f.write(self.IMPORT_STUB)


def _normal(o, pivot=(0, 0, 0)):
    """A join keeps its first part's transform: bake rotation and put the origin on `pivot`, so every node's rest transform
    is a plain translation (identity for everything but spin_* parts)."""
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    bpy.context.scene.cursor.location = pivot
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return o


def _backing_wall():
    """Temporary wall at y = 0 so wall-mounted props get contact shadow where they meet the wall (removed after the bake)."""
    me = bpy.data.meshes.new("backing")
    me.from_pydata([(-4, 0.001, -1), (4, 0.001, -1), (4, 0.001, 4), (-4, 0.001, 4)], [], [[0, 1, 2, 3]])
    o = bpy.data.objects.new("backing", me)
    bpy.context.collection.objects.link(o)
    return o


def jitter_verts(obj, amount, seed):
    """Dent / warp a part (crushed drum, bent sheet) without moving its bounding box much."""
    L.jitter(obj, amount, seed)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
