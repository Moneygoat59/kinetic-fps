"""Apartment kit: shared builder (extends the Outpost 73 Kit: same primitives, node contract, AO bake and export).
Every piece is built in a fresh Blender scene and exported to models/generated/apt_kit/<name>.glb with an import stub that runs
tools/apt_kit_import.gd (material look by name prefix + scripts/apartment/apt_prop.gd on the root).
Textures: python tools/blender/apt_textures.py.  Build: tools\\blender.ps1 tools/blender/props/apt_kit.py [name ...]

Conventions (as kit_lib.py): origin at the base centre, FRONT faces -Y (Godot +Z), wall pieces (wall=True) have their back on y = 0.
Extra node contract read by apt_prop.gd:
  pivot_leaf              door leaf, origin on the hinge axis (AptDoor swings it about local Z = Godot Y)
  hand_h / hand_m / hand_s clock hands, origin on the spindle, turning about local Z = Blender -Y axis (AptClock ticks them)
  glass                   transparent panes (never cast shadows)
  noshadow                lamp shades and other parts round a light that must not swallow it (never cast shadows)
  marker_use_<id>         an interaction point (AptUse: CHECK LOCKS, CHECK STOVE, SLEEP...; table in scripts/apartment/apt_uses.gd)
  turn_* / lift_* / flip_* PIVOT nodes (origin on the turning axis) that a check works (AptCheck; scripts/apartment/apt_check_moves.gd)
  marker_light_<kind>     warm practical lights (kinds in scripts/props/kit_lights.gd: lamp, bulb, vanity, strip, fridge)
Material name prefixes read by scripts/apartment/apt_look.gd: apt_gloss_* (porcelain, plastic, tv), apt_mirror, apt_glass*,
anything else dead matte. kit_glow_* are emissive (skipped by the AO bake).
"""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, os.path.join(HERE, ".."))
import kit_lib  # noqa: E402
import ps1_lib as L  # noqa: E402
from kit_lib import Kit, glow  # noqa: E402,F401

import apt_dims as D  # noqa: E402
import apt_shapes as SH  # noqa: E402

ROOT = kit_lib.ROOT
TEX = kit_lib.TEX
OUT_DIR = os.path.join(ROOT, "models", "generated", "apt_kit")
IMPORT_SCRIPT = "res://tools/apt_kit_import.gd"
IMPORT_STUB = kit_lib.IMPORT_STUB.replace(kit_lib.IMPORT_SCRIPT, IMPORT_SCRIPT)
# metres per texture repeat (world-projected UVs, per material)
kit_lib.TILES.update({"apt_wood": 0.6, "apt_wood_dark": 0.6, "apt_wood_light": 0.6, "apt_fabric_sofa": 0.2, "apt_fabric_chair": 0.2,
                      "apt_fabric_cream": 0.2, "apt_fabric_rust": 0.2, "apt_canvas": 0.08, "apt_linen": 0.6, "apt_duvet": 0.6, "apt_knit": 0.3,
                      "apt_counter": 0.6, "apt_steel": 0.5, "apt_paint_white": 1.0, "apt_cabinet": 1.0, "apt_towel": 0.35,
                      "apt_curtain": 0.5, "apt_tile_bath": 0.6, "apt_tile_subway": 0.6})


def _t(name):
    return os.path.join(TEX, name)


def glass(name, rgb=(0.8, 0.9, 1.0), alpha=0.18):
    m = L.material(name, rgb, 0.1)
    m.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = alpha
    m.surface_render_method = "BLENDED"
    return m


SMOOTH_ANGLE = 38.0          # degrees: finer curves shade smooth (Gouraud), sharper corners stay hard
MIN_VERTS = 12               # round parts never look like octagons (cylinders); lamp shades, pots, bowls: MIN_VERTS_CONE
MIN_VERTS_CONE = 16


class AptKit(Kit):
    OUT_DIR = OUT_DIR
    IMPORT_STUB = IMPORT_STUB
    AO = {"dirt": 0.025, "gain": 0.9, "floor": 0.32, "dust": 1.0, "chamfer_boost": 1.15}

    def __init__(self, name):
        super().__init__(name)
        tm = L.tex_material
        self.glass_parts, self.noshadow = [], []
        self.WOOD = tm("apt_wood", _t("apt_wood.png"))
        self.WOOD_D = tm("apt_wood_dark", _t("apt_wood.png"), tint=(0.55, 0.5, 0.48))
        self.WOOD_L = tm("apt_wood_light", _t("apt_wood_light.png"))
        self.WHITE = tm("apt_paint_white", _t("apt_paint.png"), tint=(0.95, 0.93, 0.89))
        self.CAB = tm("apt_cabinet", _t("apt_paint.png"), tint=(0.62, 0.7, 0.62))            # sage kitchen fronts
        self.SOFA = tm("apt_fabric_sofa", _t("apt_fabric.png"), tint=(0.36, 0.5, 0.56))      # dusty teal
        self.CHAIR = tm("apt_fabric_chair", _t("apt_fabric.png"), tint=(0.8, 0.6, 0.3))      # mustard
        self.CREAM = tm("apt_fabric_cream", _t("apt_fabric.png"), tint=(0.92, 0.88, 0.8))
        self.RUSTF = tm("apt_fabric_rust", _t("apt_fabric.png"), tint=(0.72, 0.38, 0.26))    # terracotta
        self.LINEN = tm("apt_linen", _t("apt_linen.png"), tint=(0.96, 0.95, 0.92))
        self.DUVET = tm("apt_duvet", _t("apt_linen.png"), tint=(0.66, 0.74, 0.8))
        self.KNIT = tm("apt_knit", _t("apt_knit.png"), tint=(0.96, 0.92, 0.84))
        self.COUNTER = tm("apt_counter", _t("apt_counter.png"))
        self.STEEL = tm("apt_steel", _t("apt_steel.png"))
        self.TOWEL = tm("apt_towel", _t("apt_towel.png"))
        self.CURTAIN = tm("apt_curtain", _t("apt_curtain.png"))
        self.TILE_B = tm("apt_tile_bath", _t("apt_tile_bath.png"))
        self.TILE_S = tm("apt_tile_subway", _t("apt_tile_subway.png"))
        self.RUG = tm("apt_rug", _t("apt_rug.png"))
        self.ART = tm("apt_art", _t("apt_art.png"))
        self.RX = tm("apt_gloss_rx", _t("apt_rx.png"))
        self.CANS = tm("apt_cans", _t("apt_cans.png"))
        self.ORG = tm("apt_gloss_organizer", _t("apt_organizer.png"))
        self.CLOCK = tm("apt_clock", _t("apt_clock.png"))
        self.TV = tm("apt_gloss_tv", _t("apt_tv.png"))
        self.BOOKS = tm("apt_hi_books", _t("apt_books.png"))                                # hi-res, filtered (apt_look.gd)
        self.CANVAS = tm("apt_canvas", _t("apt_fabric.png"), tint=(0.11, 0.15, 0.27))           # sneaker canvas, navy
        self.PORC = L.material("apt_gloss_porcelain", (0.86, 0.86, 0.84))
        self.RUBBER = L.material("apt_gloss_rubber", (0.78, 0.76, 0.72))                      # sneaker soles and toe caps
        self.LEATHER = L.material("apt_gloss_leather", (0.11, 0.045, 0.018))                  # polished brown
        self.SOLE = L.material("apt_sole", (0.018, 0.016, 0.015))
        self.ENAMEL = L.material("apt_gloss_enamel", (0.78, 0.7, 0.52))                      # cream toaster, mugs
        self.APPLE = L.material("apt_gloss_apple", (0.42, 0.03, 0.02))
        self.PLASTIC = L.material("apt_gloss_plastic", (0.8, 0.79, 0.76))
        self.BLACK = L.material("apt_gloss_black", (0.02, 0.02, 0.022))
        self.CHROME = L.material("apt_gloss_chrome", (0.55, 0.56, 0.58))
        self.PILL = L.material("apt_gloss_pill", (0.75, 0.26, 0.02))                          # amber pharmacy plastic
        self.CAP = L.material("apt_gloss_cap", (0.9, 0.9, 0.88))
        self.PAPER = L.material("apt_paper", (0.85, 0.84, 0.8))
        self.CARD = L.material("apt_card", (0.42, 0.3, 0.18))
        self.CORD = L.material("apt_cord", (0.03, 0.03, 0.03))
        self.GREEN = L.material("apt_leaf", (0.08, 0.2, 0.07))
        self.SOIL = L.material("apt_soil", (0.05, 0.03, 0.02))
        self.BRASS = L.material("apt_gloss_brass", (0.55, 0.38, 0.12))
        self.MIRROR = L.material("apt_mirror", (0.9, 0.9, 0.9), 0.05)
        self.GLASS = glass("apt_glass")
        self.WATER = glass("apt_glass_water", (0.75, 0.88, 0.95), 0.35)
        self.SHADE = glow("kit_glow_shade", (1.0, 0.66, 0.36), 0.75)                            # lit lamp shade
        self.BULB = glow("kit_glow_bulb", (1.0, 0.85, 0.6), 3.0)
        self.LED_R = glow("kit_glow_led_red", (1.0, 0.1, 0.05), 1.5)
        self.ALARM = self.scr("alarm", "apt_alarm_a.png", 1.4)
        d = lambda n, f: L.decal_material(n, _t(f))  # noqa: E731
        self.D_TAPE, self.D_TAPE_B = d("apt_decal_tape", "apt_tape.png"), d("apt_decal_tape_blue", "apt_tape_blue.png")
        self.D_TALLY, self.D_PENCIL = d("apt_decal_tally", "apt_tally.png"), d("apt_decal_pencil", "apt_pencil.png")
        self.D_LABELS = d("apt_decal_labels", "apt_labels.png")

    # ------------------------------------------------------------ soft and round shapes (apt_shapes.py)
    def CYL(self, name, r, d, loc, mat, axis="z", v=8, into=None):
        return super().CYL(name, r, d, loc, mat, axis, max(v, MIN_VERTS), into)

    def FRUSTUM(self, name, r1, r2, d, loc, mat, axis="y", v=4, into=None):
        return super().FRUSTUM(name, r1, r2, d, loc, mat, axis, v if v == 4 else max(v, MIN_VERTS_CONE), into)

    def SOFT(self, name, size, loc, mat, r=0.04, puff=0.0, axis="+z", step=0.06, rot=(0, 0, 0), into=None):
        """Upholstery / bedding / rounded porcelain: rounded box, optional puff (see apt_shapes.soft_box)."""
        return self._add(SH.soft_box(name, size, loc, mat, r, puff, axis, step, rot), into)

    def BLOB(self, name, size, loc, mat, into=None, **kw):
        """Organic lump (bags, heaps, food, crumpled paper): see apt_shapes.blob for the shaping arguments."""
        return self._add(SH.blob(name, size, loc, mat, **kw), into)

    def DISC(self, name, center, r, mat, segs=32, uv=(0.0, 0.0, 1.0, 1.0)):
        """Round image face facing -y (clock dial). Goes into the panels (keeps its UVs)."""
        o = SH.disc(name, center, r, mat, segs, uv)
        self.panels.append(o)
        return o

    def PLEATS(self, name, x0, x1, y, z0, z1, depth, folds, mat, into=None):
        return self._add(SH.pleats(name, x0, x1, y, z0, z1, depth, folds, mat), into)

    def shade(self, obj):
        """Gouraud where the surface curves, hard where faces meet at more than SMOOTH_ANGLE."""
        me = obj.data
        for poly in me.polygons:
            poly.use_smooth = True
        me.set_sharp_from_angle(angle=math.radians(SMOOTH_ANGLE))

    # ------------------------------------------------------------ atlas-mapped quads and wraps
    def QUAD_UV(self, name, center, w, h, facing, mat, uv, up=(0, 0, 1), into=None):
        """Quad showing the sub-rect uv=(u0, v0, u1, v1) of mat's image (atlases: labels, art, rx)."""
        o = L.quad(name, center, w, h, facing, mat, up)
        u0, v0, u1, v1 = uv
        lay = o.data.uv_layers[0]
        for i, (u, v) in enumerate(((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
            lay.data[i].uv = (u, v)
        (self.decals if into is None else into).append(o)
        return o

    def LABEL(self, word, center, w=0.07, facing="-y", up=(0, 0, 1)):
        """Label-maker tape strip (black, white caps) from the apt_labels.png atlas."""
        return self.QUAD_UV(f"lbl_{word}_{len(self.decals)}", center, w, w * 12 / 64, facing, self.D_LABELS, D.label_uv(word), up)

    def WRAP_UV(self, name, c, r, z0, z1, a0, a1, mat, uv, segs=6, into=None):
        """Band round a vertical cylinder showing the uv sub-rect (pharmacy labels, can labels). Goes into the panels (the
        body's UVs are world-projected at finish, panels keep theirs)."""
        o = self.WRAP(name, c, r, z0, z1, a0, a1, mat, segs)
        self.decals.remove(o)
        u0, v0, u1, v1 = uv
        lay = o.data.uv_layers[0]
        for d in lay.data:
            d.uv = (u0 + d.uv[0] * (u1 - u0), v0 + d.uv[1] * (v1 - v0))
        (self.panels if into is None else into).append(o)
        return o

    def GLASS_B(self, name, size, loc, mat=None, rot=(0, 0, 0)):
        """Transparent pane / tumbler: own `glass` node, never casts shadows (so window light passes)."""
        return self.B(name, size, loc, mat or self.GLASS, rot=rot, into=self.glass_parts)

    def USE(self, use_id, loc):
        """Interaction point marker_use_<id> (scripts/apartment/apt_uses.gd holds the prompt and behaviour)."""
        self.markers[f"marker_use_{use_id}"] = loc

    def finish(self, wall=False, subdiv=0.3, ao_dist=0.6, ground=True, shift=None):
        """shift=(dx, dy, dz): move the whole piece first (built centred, but its back belongs on y = 0)."""
        if shift:
            objs = self.parts + self.panels + self.screens + self.decals + self.cols + self.glass_parts + self.noshadow
            objs += [o for lst, _p in self.movers.values() for o in lst]
            for o in objs:
                o.location = (o.location[0] + shift[0], o.location[1] + shift[1], o.location[2] + shift[2])
            self.movers = {n: (lst, tuple(a + b for a, b in zip(p, shift))) for n, (lst, p) in self.movers.items()}
            self.markers = {n: tuple(a + b for a, b in zip(p, shift)) for n, p in self.markers.items()}
        bpy.context.view_layer.update()
        for lst, node in ((self.glass_parts, "glass"), (self.noshadow, "noshadow")):
            if lst:
                self.shade(kit_lib._normal(L.join(lst, node)))
        super().finish(wall, subdiv, ao_dist, ground)
