"""Camp kit: the camp of someone lost in the dead forest, run out of food, water and firewood, then left. Shared builder.
CampKit extends the apartment's MessKit (tools/blender/apt/mess_kit.py) for its organic shapes (BLOB, SOFT, CAN-style lathes,
CRUMPLE) and smooth shading, but exports to models/generated/camp_kit/ with the Outpost 73 import hook (dead matte
materials + scripts/props/kit_prop.gd), because these pieces stand outdoors in the forest's fog.
Textures: python tools/blender/camp_textures.py.  Build: tools\\blender.ps1 tools/blender/props/camp_kit.py [name ...]

Conventions (as kit_lib.py): 1 unit = 1 m, origin at the base centre, FRONT faces -Y (Godot +Z), Z up.
Extra shapes:
  BRANCH  a tapering, wandering stick along a polyline with its own UVs (grain along it); goes into the panels
  SURF    a double-sided cloth / sheet over a parametric surface fn(u, v) -> (x, y, z); hole(u, v) cuts tears; body or panels
  STONE   a faceted field stone (a coarse blob, settled into the ground)
Extra node contract (scripts/props/kit_prop.gd): wander_* nodes turn about their local Y, never settling (a compass needle).
"""
import math
import os
import random
import sys

import bmesh
import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "apt"))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
sys.path.insert(0, os.path.join(HERE, ".."))
import kit_lib  # noqa: E402
import ps1_lib as L  # noqa: E402
from kit_lib import glow  # noqa: E402
from mess_kit import MessKit  # noqa: E402

TEX = kit_lib.TEX
OUT_DIR = os.path.join(kit_lib.ROOT, "models", "generated", "camp_kit")
TIN_ROWS = 3                     # camp_textures.TIN_LABELS: one label per row of tex/camp_tins.png
kit_lib.TILES.update({"camp_tarp": 0.9, "camp_bag": 0.5, "camp_lining": 0.4, "camp_stone": 0.45, "camp_pack": 0.35,
                      "camp_char": 0.25, "camp_brush": 0.5, "camp_wood_body": 0.5})


def _t(name):
    return os.path.join(TEX, name)


def wobble(p0, p1, segs=5, amp=0.02, seed=0, sag=0.0):
    """Points from p0 to p1 with a little random wander (and an optional sag at the middle): a natural stick's axis."""
    rng = random.Random(seed)
    a, b = Vector(p0), Vector(p1)
    pts = []
    for i in range(segs + 1):
        t = i / segs
        p = a.lerp(b, t)
        if 0 < i < segs:
            p += Vector((rng.uniform(-amp, amp), rng.uniform(-amp, amp), rng.uniform(-amp, amp) - sag * math.sin(t * math.pi)))
        pts.append(tuple(p))
    return pts


class CampKit(MessKit):
    OUT_DIR = OUT_DIR
    IMPORT_STUB = kit_lib.IMPORT_STUB
    AO = {"dirt": 0.05, "gain": 0.9, "floor": 0.25, "dust": 1.0, "chamfer_boost": 1.0}

    def __init__(self, name):
        super().__init__(name)
        tm = L.tex_material
        self.TARP = tm("camp_tarp", _t("camp_tarp.png"))
        self.BAGC = tm("camp_bag", _t("camp_bag.png"))
        self.LINING = tm("camp_lining", _t("camp_bag.png"), tint=(0.42, 0.5, 0.48))       # flannel inside, grey-green
        self.WOOD = tm("camp_wood", _t("camp_wood.png"))                                    # sticks (own UVs, BRANCH)
        self.WOOD_B = tm("camp_wood_body", _t("camp_wood.png"))                            # world-projected (brush, shavings)
        self.BRUSH = tm("camp_brush", _t("camp_wood.png"), tint=(0.5, 0.45, 0.4))
        self.CHAR = tm("camp_char", _t("camp_char.png"))
        self.STONE_M = tm("camp_stone", _t("camp_stone.png"))
        self.PACK = tm("camp_pack", _t("camp_pack.png"))
        self.CORD = tm("camp_cord", _t("camp_cord.png"))
        self.LABELS = tm("camp_tins", _t("camp_tins.png"))
        self.MAP = tm("camp_map", _t("camp_map.png"))
        self.TALLY = tm("camp_tally", _t("camp_tally.png"))
        self.TIN_M = L.material("camp_tin", (0.22, 0.22, 0.23))                           # dull tinplate
        self.SOOTED = L.material("camp_tin_sooted", (0.02, 0.018, 0.017))                  # blackened in the fire
        self.PLASTIC_B = L.material("camp_plastic", (0.012, 0.012, 0.013))
        self.STRAP = L.material("camp_strap", (0.02, 0.02, 0.018))
        self.RED_P = L.material("camp_red", (0.3, 0.02, 0.015))
        self.PALE = L.material("camp_pale", (0.55, 0.5, 0.42))                             # fresh-cut wood, shavings
        self.TORCH_LENS = glow("kit_glow_torch", (1.0, 0.8, 0.5), 0.7)
        self.D_ASH = L.decal_material("camp_decal_ash", _t("camp_ash.png"))
        self.D_SOOT = L.decal_material("camp_decal_soot", _t("camp_soot.png"))

    # ------------------------------------------------------------ organic shapes
    def BRANCH(self, name, pts, r0, r1, mat=None, verts=6, seed=0, into=None):
        """Tapering stick through pts (radius r0 at the first point, r1 at the last), rings jittered so it never reads as a
        pipe, capped both ends. UV u runs round it, v along it (0.5 m per repeat), so the grain follows the stick."""
        rng = random.Random(seed)
        bm = bmesh.new()
        uv = bm.loops.layers.uv.new("UVMap")
        pv = [Vector(p) for p in pts]
        n = len(pv)
        rings, along, dist = [], [], 0.0
        prev_a = None
        for i, p in enumerate(pv):
            t = (pv[min(i + 1, n - 1)] - pv[max(i - 1, 0)]).normalized()
            if prev_a is None:
                ref = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
                a = t.cross(ref).normalized()
            else:                                                          # carry the frame along: no twisting
                a = (prev_a - t * prev_a.dot(t)).normalized()
            prev_a = a
            b = t.cross(a).normalized()
            if i:
                dist += (p - pv[i - 1]).length
            along.append(dist)
            r = r0 + (r1 - r0) * i / (n - 1)
            ring = []
            for k in range(verts):
                th = k * math.tau / verts
                j = 1.0 + rng.uniform(-0.12, 0.12)
                ring.append(bm.verts.new(p + (a * math.cos(th) + b * math.sin(th)) * r * j))
            rings.append(ring)
        for i in range(n - 1):
            for k in range(verts):
                k2 = (k + 1) % verts
                f = bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
                for loop, (u, v) in zip(f.loops, ((k, along[i]), (k + 1, along[i]), (k + 1, along[i + 1]), (k, along[i + 1]))):
                    loop[uv].uv = (u / verts, v / 0.5)
        for ring, flip in ((rings[0], True), (rings[-1], False)):
            f = bm.faces.new(list(reversed(ring)) if flip else ring)
            for loop in f.loops:
                loop[uv].uv = (0.5 + 0.02 * loop.vert.co.x, 0.02 * loop.vert.co.y)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(o)
        me.materials.append(mat or self.WOOD)
        (self.panels if into is None else into).append(o)
        return o

    def SURF(self, name, fn, nu, nv, mat, hole=None, thick=0.008, uv=None, back=None, into=None):
        """Double-sided sheet over fn(u, v) for u, v in [0, 1] on an nu x nv grid. hole(u, v) -> True drops that cell (tears,
        a missing corner). The back is the front pulled `thick` along the surface normal, in `back` (default: mat). The front
        faces the way (d fn/du) x (d fn/dv) points. uv=(su, sv) gives it its own UVs (u * su, v * sv) and puts it in the
        panels; otherwise it goes in the body (world-projected like the rest)."""
        bm = bmesh.new()
        lay = bm.loops.layers.uv.new("UVMap")
        grid = [[Vector(fn(i / nu, j / nv)) for i in range(nu + 1)] for j in range(nv + 1)]
        norms = [[Vector((0, 0, 1))] * (nu + 1) for _ in range(nv + 1)]
        for j in range(nv + 1):
            for i in range(nu + 1):
                du = grid[j][min(i + 1, nu)] - grid[j][max(i - 1, 0)]
                dv = grid[min(j + 1, nv)][i] - grid[max(j - 1, 0)][i]
                c = du.cross(dv)
                norms[j][i] = c.normalized() if c.length > 1e-9 else Vector((0, 0, 1))
        front = [[bm.verts.new(grid[j][i]) for i in range(nu + 1)] for j in range(nv + 1)]
        back = [[bm.verts.new(grid[j][i] - norms[j][i] * thick) for i in range(nu + 1)] for j in range(nv + 1)]
        su, sv = uv or (1.0, 1.0)
        for j in range(nv):
            for i in range(nu):
                if hole and hole((i + 0.5) / nu, (j + 0.5) / nv):
                    continue
                cells = (((i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)), False), (((i, j + 1), (i + 1, j + 1), (i + 1, j), (i, j)), True)
                for corners, is_back in cells:
                    src = back if is_back else front
                    f = bm.faces.new([src[cj][ci] for ci, cj in corners])
                    f.material_index = 1 if (is_back and back) else 0
                    for loop, (ci, cj) in zip(f.loops, corners):
                        loop[lay].uv = (ci / nu * su, cj / nv * sv)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(o)
        me.materials.append(mat)
        if back:
            me.materials.append(back)
        (into if into is not None else (self.panels if uv else self.parts)).append(o)
        return o

    def STONE(self, name, size, loc, seed=0, sink=0.3, rot=(0, 0, 0), into=None):
        """Field stone, faceted and lumpy, `sink` of its height below the ground (loc = where it sits, z ignored)."""
        z = size[2] * (0.5 - sink)
        return self.BLOB(name, size, (loc[0], loc[1], z), self.STONE_M, seed=seed, lumps=0.22, lump_freq=1.3, settle=0.3, subdiv=2,
                         rot=rot, into=into)

    def CORD_LINE(self, name, pts, r=0.004):
        return self.BRANCH(name, pts, r, r, self.CORD, verts=5, seed=len(pts))

    def LASH(self, name, center, axis, r, turns=3, width=0.05):
        """Cord wrapped round a pole at `center` (pole along `axis`, radius r): a few turns side by side."""
        ax = Vector(axis).normalized()
        ref = Vector((0, 0, 1)) if abs(ax.z) < 0.9 else Vector((1, 0, 0))
        a = ax.cross(ref).normalized()
        b = ax.cross(a)
        pts = []
        steps = turns * 8
        for s in range(steps + 1):
            th = s * math.tau / 8
            off = ax * (width * (s / steps - 0.5))
            pts.append(tuple(Vector(center) + off + (a * math.cos(th) + b * math.sin(th)) * (r + 0.004)))
        return self.CORD_LINE(name, pts, 0.0035)


def tin_profile(r=0.037, h=0.105):
    """An opened food tin (lathe profile): rolled bottom seam, two rib bands, the cut rim, the inside wall down to the floor."""
    return [(0, 0.004), (r - 0.004, 0), (r + 0.001, 0.004), (r + 0.001, 0.01), (r, 0.012), (r, 0.03), (r - 0.0015, 0.034), (r, 0.038),
            (r, h - 0.036), (r - 0.0015, h - 0.032), (r, h - 0.028), (r, h - 0.006), (r + 0.001, h - 0.004), (r + 0.001, h),
            (r - 0.003, h), (r - 0.003, 0.012), (0, 0.012)]
