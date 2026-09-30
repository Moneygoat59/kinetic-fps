"""Apartment shell builder: turns a floor plan written as data into a walkable interior .glb (tools/blender/props/apartment.py is
one plan; another flat = another data file). Blender axes (Z up), metres; exported Y-up so Blender (x, y, z) = Godot (x, z, -y).

Plan vocabulary:
  room(name, x0, y0, x1, y1, wall, floor, ...)   clear interior rectangle. Each room gets its own 7 cm wall skins OUTSIDE the
                     rectangle (two rooms 14 cm apart share a partition), floor, ceiling, baseboard and crown.
  opening(x0, y0, x1, y1, z0, z1)                a hole through every skin (and the envelope) inside that box: doors, windows,
                     arches. z0 == 0 openings get a threshold; arch=True ones get linings.
  envelope(t)        thick outer walls, floor and roof slab round everything (keeps the sun out except through the windows).
  band(...)          a tile / splash band proud of a wall.    decal(...)  alpha quad (tape, tallies, pencil lines).
  piece(name, x, y, z, yaw, flags, proxy)         marker_kit_<name>__<n>[__flag...] (AptKit piece spawned there at runtime) plus an
                     optional AO proxy box so floor and walls darken around it in the bake.
  view(...)          emissive backdrop quad outside a window (never casts shadows).   marker(name, loc, yaw)  gameplay anchors.
Rooms also export marker_room_<name> (centre; scale = half extents) for reflection probes / GI bounds.
"""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
import apt_dims as D  # noqa: E402
import apt_lib  # noqa: E402
import ps1_ao as AO  # noqa: E402
import ps1_lib as L  # noqa: E402

SKIN = D.WALL_T / 2
TILES = {"apt_shell_floor_wood": 1.0, "apt_shell_checker": 1.2, "apt_shell_hex": 0.5, "apt_shell_tile_bath": 0.6,
         "apt_shell_tile_subway": 0.6, "apt_shell_ceiling": 1.0}


class Shell:
    def __init__(self, name, ceiling=D.CEILING):
        L.reset()
        self.name, self.H = name, ceiling
        self.solid, self.decals, self.cols, self.views, self.proxies = [], [], [], [], []
        self.rooms, self.openings, self.pieces = [], [], 0
        t = lambda f: os.path.join(apt_lib.TEX, f)  # noqa: E731
        self.tex = t
        self.WHITE = L.tex_material("apt_shell_trim", t("apt_paint.png"), tint=(0.96, 0.94, 0.9))
        self.CEIL = L.tex_material("apt_shell_ceiling", t("apt_ceiling.png"), tint=(0.97, 0.95, 0.92))
        self.SADDLE = L.tex_material("apt_shell_saddle", t("apt_wood.png"))

    # ------------------------------------------------------------ materials
    def paint(self, name, tint):
        return L.tex_material(f"apt_shell_paint_{name}", self.tex("apt_paint.png"), tint=tint)

    def surface(self, name, image, tint=(1, 1, 1)):
        return L.tex_material(f"apt_shell_{name}", self.tex(image), tint=tint)

    # ------------------------------------------------------------ plan
    def room(self, name, x0, y0, x1, y1, wall, floor, crown=True, base=True):
        self.rooms.append(dict(name=name, x0=x0, y0=y0, x1=x1, y1=y1, wall=wall, floor=floor, crown=crown, base=base))

    def opening(self, x0, y0, x1, y1, z0, z1, arch=False):
        self.openings.append(dict(x0=min(x0, x1), y0=min(y0, y1), x1=max(x0, x1), y1=max(y0, y1), z0=z0, z1=z1, arch=arch))

    def _box(self, name, lo, hi, mat, col=True):
        size = tuple(h - l for l, h in zip(lo, hi))
        if min(size) <= 1e-4:
            return None
        o = L.box(name, size, tuple((l + h) / 2 for l, h in zip(lo, hi)), mat)
        self.solid.append(o)
        if col:
            self.cols.append(o)
        return o

    def _slab(self, name, lo, hi, mat, axis, split=None, upper=None):
        """Wall slab from lo to hi with every opening that crosses it cut out (axis = the direction the wall runs, 0 = x, 1 = y).
        split=(z, mat_below): paint above z, `mat_below` under it (wainscot / tile)."""
        a0, a1 = lo[axis], hi[axis]
        cuts = []
        for op in self.openings:
            o0, o1 = (op["x0"], op["x1"]) if axis == 0 else (op["y0"], op["y1"])
            p0, p1 = (op["y0"], op["y1"]) if axis == 0 else (op["x0"], op["x1"])
            q0, q1 = (lo[1], hi[1]) if axis == 0 else (lo[0], hi[0])
            if p1 > q0 + 1e-4 and p0 < q1 - 1e-4 and o1 > a0 and o0 < a1:
                cuts.append((max(o0, a0), min(o1, a1), op["z0"], op["z1"]))
        cuts.sort()
        spans, at = [], a0
        for c0, c1, z0, z1 in cuts:
            spans.append((at, c0, lo[2], hi[2]))
            spans += [(c0, c1, lo[2], z0), (c0, c1, z1, hi[2])]
            at = c1
        spans.append((at, a1, lo[2], hi[2]))
        for i, (s0, s1, z0, z1) in enumerate(spans):
            if s1 - s0 < 1e-4 or z1 - z0 < 1e-4:
                continue
            for zz0, zz1, mat in ((z0, min(z1, split[0]), split[1]), (max(z0, split[0]), z1, mat)) if split else ((z0, z1, mat),):
                l, h = list(lo), list(hi)
                l[axis], h[axis], l[2], h[2] = s0, s1, zz0, zz1
                self._box(f"{name}_{i}_{zz0:.2f}", l, h, mat)
        return cuts

    def _room_skins(self, r):
        s, H = SKIN, self.H
        split = r.get("split")
        sides = (("s", (r["x0"] - s, r["y0"] - s, 0), (r["x1"] + s, r["y0"], H), 0, (0, 1)),
                 ("n", (r["x0"] - s, r["y1"], 0), (r["x1"] + s, r["y1"] + s, H), 0, (0, -1)),
                 ("w", (r["x0"] - s, r["y0"], 0), (r["x0"], r["y1"], H), 1, (1, 0)),
                 ("e", (r["x1"], r["y0"], 0), (r["x1"] + s, r["y1"], H), 1, (-1, 0)))
        for tag, lo, hi, axis, inward in sides:
            cuts = self._slab(f"{r['name']}_{tag}", lo, hi, r["wall"], axis, split)
            face = hi if inward[axis ^ 1] > 0 else lo                                          # inner face coordinate
            self._trim(r, tag, lo, hi, axis, inward, face, cuts)
        self._box(f"{r['name']}_floor", (r["x0"], r["y0"], -0.02), (r["x1"], r["y1"], 0.0), r["floor"])
        self._box(f"{r['name']}_ceiling", (r["x0"] - s, r["y0"] - s, H), (r["x1"] + s, r["y1"] + s, H + 0.02), self.CEIL)

    def _trim(self, r, tag, lo, hi, axis, inward, face, cuts):
        """Baseboard (skips floor openings) and crown along one skin's inner face."""
        other = axis ^ 1
        f = face[other]
        d = inward[other]
        a0, a1 = lo[axis] + (SKIN if axis == 0 else 0), hi[axis] - (SKIN if axis == 0 else 0)
        runs, at = [], a0
        for c0, c1, z0, _z1 in cuts:
            if z0 <= 0.01:
                runs.append((at, c0))
                at = c1
        runs.append((at, a1))
        for i, (b0, b1) in enumerate(runs):
            for kind, z0, z1, depth in (("base", 0.0, D.BASE_H, 0.015),) if r["base"] else ():
                lo2, hi2 = [0, 0, z0], [0, 0, z1]
                lo2[axis], hi2[axis] = b0, b1
                lo2[other], hi2[other] = sorted((f, f + d * depth))
                self._box(f"{r['name']}_{tag}_{kind}{i}", lo2, hi2, self.WHITE, col=False)
        if r["crown"]:
            lo2, hi2 = [0, 0, self.H - 0.06], [0, 0, self.H]
            lo2[axis], hi2[axis] = a0, a1
            lo2[other], hi2[other] = sorted((f, f + d * 0.04))
            self._box(f"{r['name']}_{tag}_crown", lo2, hi2, self.WHITE, col=False)

    def split(self, room, z, mat):
        """Wainscot: `mat` on every wall of `room` below z (bathroom tile)."""
        next(r for r in self.rooms if r["name"] == room)["split"] = (z, mat)

    def band(self, name, lo, hi, mat):
        self._box(name, lo, hi, mat, col=False)

    def envelope(self, t=D.EXT_T - SKIN):
        xs = [r["x0"] for r in self.rooms] + [r["x1"] for r in self.rooms]
        ys = [r["y0"] for r in self.rooms] + [r["y1"] for r in self.rooms]
        x0, x1, y0, y1 = min(xs) - SKIN, max(xs) + SKIN, min(ys) - SKIN, max(ys) + SKIN
        H, E = self.H, self.WHITE
        self._slab("env_s", (x0 - t, y0 - t, -0.3), (x1 + t, y0, H + 0.3), E, 0)
        self._slab("env_n", (x0 - t, y1, -0.3), (x1 + t, y1 + t, H + 0.3), E, 0)
        self._slab("env_w", (x0 - t, y0, -0.3), (x0, y1, H + 0.3), E, 1)
        self._slab("env_e", (x1, y0, -0.3), (x1 + t, y1, H + 0.3), E, 1)
        self._box("env_floor", (x0 - t, y0 - t, -0.3), (x1 + t, y1 + t, -0.02), E)
        self._box("env_roof", (x0 - t, y0 - t, H + 0.02), (x1 + t, y1 + t, H + 0.3), E)
        self.bounds = (x0 - t, y0 - t, x1 + t, y1 + t)

    def _openings_finish(self):
        for i, op in enumerate(self.openings):
            if op["z0"] <= 0.01:                                                                  # threshold / saddle
                self._box(f"saddle{i}", (op["x0"], op["y0"], -0.02), (op["x1"], op["y1"], 0.004), self.SADDLE)
            if op["arch"]:
                along_x = op["x1"] - op["x0"] > op["y1"] - op["y0"]
                for s in (0, 1):
                    lo = [op["x0"], op["y0"], op["z0"]]
                    hi = [op["x1"], op["y1"], op["z1"]]
                    a = 0 if along_x else 1
                    if s == 0:
                        hi[a] = lo[a] + 0.02
                    else:
                        lo[a] = hi[a] - 0.02
                    self._box(f"arch_lining{i}{s}", lo, hi, self.WHITE, col=False)
                self._box(f"arch_head{i}", (op["x0"], op["y0"], op["z1"] - 0.02), (op["x1"], op["y1"], op["z1"]), self.WHITE, col=False)

    # ------------------------------------------------------------ dressing
    def decal(self, name, image, center, w, h, facing, up=(0, 0, 1)):
        mat = bpy.data.materials.get(f"apt_decal_{image}") or L.decal_material(f"apt_decal_{image}", self.tex(f"apt_{image}.png"))
        self.decals.append(L.quad(name, center, w, h, facing, mat, up))

    def piece(self, name, x, y, z=0.0, yaw=0.0, flags=(), proxy=None, roll=0.0):
        e = L.empty("__".join([f"marker_kit_{name}", str(self.pieces)] + list(flags)), (x, y, z))
        e.rotation_euler = (0, math.radians(roll), math.radians(yaw))
        if proxy:
            (sx, sy, sz), (lx, ly, lz) = proxy
            ca, sa = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
            self.proxies.append(L.box(f"proxy{self.pieces}", (sx, sy, sz), (x + lx * ca - ly * sa, y + lx * sa + ly * ca, z + lz), None,
                                      (0, 0, yaw)))
        self.pieces += 1

    def mess(self, name, x, y, z=0.0, yaw=0.0):
        """A squalor piece: marker_mess_<name>__<n>, spawned only on the mornings the flat has gone to squalor (AptSqualor renames
        it to a marker_kit_ before furnishing); an empty otherwise. No AO proxy: the clean flat's baked light must not show it."""
        L.empty(f"marker_mess_{name}__{self.pieces}", (x, y, z)).rotation_euler = (0, 0, math.radians(yaw))
        self.pieces += 1

    def marker(self, name, loc, yaw=0.0):
        L.empty(name, loc).rotation_euler = (0, 0, math.radians(yaw))

    def view(self, name, center, w, h, facing, strength=1.4):
        mat = bpy.data.materials.get("apt_view") or L.screen_material("apt_view", self.tex("apt_view.png"), strength)
        self.views.append(L.quad(name, center, w, h, facing, mat))

    # ------------------------------------------------------------ build
    def finish(self, ao_samples=20):
        for r in self.rooms:
            self._room_skins(r)
        self._openings_finish()
        bpy.context.view_layer.update()
        cols = [o.copy() for o in self.cols]
        for o in cols:
            o.data = o.data.copy()
            o.data.materials.clear()
            bpy.context.collection.objects.link(o)
        shell = apt_lib.kit_lib._normal(L.join(self.solid, "shell"))
        AO.subdivide_by_length(shell, 0.3)
        L.world_uv(shell, 1.0, TILES)
        AO.bake_ao(shell, self.proxies, samples=ao_samples, max_dist=1.2, ground_z=None, skip_prefix="kit_glow",
                   dirt=0.02, gain=0.95, floor=0.3, dust=1.0, chamfer_boost=1.0)
        for p in self.proxies:
            bpy.data.objects.remove(p, do_unlink=True)
        apt_lib.kit_lib._normal(L.join(cols, "collision-colonly"))
        if self.decals:
            apt_lib.kit_lib._normal(L.join(self.decals, "decals"))
        for i, v in enumerate(self.views):
            v.name = f"view_{i}"
        for r in self.rooms:
            e = L.empty(f"marker_room_{r['name']}", ((r["x0"] + r["x1"]) / 2, (r["y0"] + r["y1"]) / 2, self.H / 2))
            e.scale = ((r["x1"] - r["x0"]) / 2, (r["y1"] - r["y0"]) / 2, self.H / 2)
        path = os.path.join(apt_lib.ROOT, "models", "generated", self.name + ".glb")
        L.export_all(path)
        if not os.path.exists(path + ".import"):
            with open(path + ".import", "w", encoding="utf-8", newline="\n") as f:
                f.write(apt_lib.IMPORT_STUB)
