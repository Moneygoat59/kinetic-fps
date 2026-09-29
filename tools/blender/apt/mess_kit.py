"""The apartment kit's squalor extension: extra materials and shared shapes for the mess pieces (mess_trash.py, mess_home.py).
MessKit is an AptKit with bin-bag plastic, foam, food, mould, cardboard and the apt_mess.png print atlas
(python tools/blender/apt_mess_textures.py; cells in apt_dims.MESS). Same conventions: origin at the base centre, front -Y.
Litter on the floor gets no collision (the walker scuffs through it); bags and boxes get a low box so they are walked round.
"""
import math

from mathutils import Euler, Matrix, Vector

import apt_dims as D
import apt_forms as F
from apt_lib import AptKit, _t
import ps1_lib as L

CAN = [(0, 0.004), (0.026, 0), (0.031, 0.006), (0.033, 0.014), (0.033, 0.106), (0.028, 0.118), (0.027, 0.122), (0, 0.121)]
BOTTLE = [(0, 0), (0.03, 0), (0.032, 0.01), (0.032, 0.15), (0.026, 0.18), (0.014, 0.2), (0.013, 0.215), (0, 0.215)]
BOWL = [(0, 0), (0.04, 0), (0.042, 0.006), (0.075, 0.03), (0.085, 0.06), (0.08, 0.062), (0.066, 0.034), (0.036, 0.012), (0, 0.012)]


class MessKit(AptKit):
    def __init__(self, name):
        super().__init__(name)
        tm = L.tex_material
        self.BAG = L.material("apt_sheen_bag", (0.012, 0.012, 0.014))                     # black bin bag
        self.BAG_W = L.material("apt_sheen_bag_white", (0.62, 0.62, 0.6))                  # kitchen bag
        self.TIE = L.material("apt_gloss_tie", (0.45, 0.03, 0.02))                         # red drawstring
        self.FOIL = L.material("apt_sheen_foil", (0.6, 0.45, 0.08))
        self.TIN = L.material("apt_sheen_tin", (0.5, 0.51, 0.53))                          # can ends
        self.BOTTLE = L.material("apt_glass_bottle", (0.7, 0.8, 0.85))
        self.BOTTLE.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.35
        self.BOTTLE.surface_render_method = "BLENDED"
        self.FOAM = L.material("apt_foam", (0.55, 0.54, 0.5))                              # takeout clamshell, grubby
        self.PAPER_D = L.material("apt_paper_dirty", (0.5, 0.48, 0.42))                      # paper that has lain for weeks
        self.PBOX = L.material("apt_pizza_card", (0.62, 0.55, 0.42))                        # box card, outside
        self.SHIP = L.material("apt_ship_card", (0.36, 0.24, 0.12))                         # shipping carton
        self.TAPE = L.material("apt_sheen_tape", (0.5, 0.36, 0.18))
        self.FOOD = L.material("apt_food", (0.3, 0.12, 0.03))                               # dried sauce, crust
        self.RICE = L.material("apt_rice", (0.72, 0.68, 0.55))
        self.COFFEE = L.material("apt_gloss_coffee", (0.03, 0.012, 0.004))
        self.MOULD = L.material("apt_mould", (0.28, 0.32, 0.22))
        self.ROT = L.material("apt_rot", (0.09, 0.035, 0.012))                              # rotten apple skin
        self.PAPER_Y = L.material("apt_paper_yellow", (0.8, 0.7, 0.35))
        self.PRINT = tm("apt_hi_mess", _t("apt_mess.png"))                                   # print atlas (filtered)
        f = lambda n, tint: tm(n, _t("apt_fabric.png"), tint=tint)  # noqa: E731
        self.CLOTH = [f("apt_fabric_grey", (0.42, 0.42, 0.43)), f("apt_fabric_denim", (0.2, 0.28, 0.42)),
                      f("apt_fabric_maroon", (0.38, 0.1, 0.1)), f("apt_fabric_black", (0.07, 0.07, 0.08)),
                      f("apt_fabric_olive", (0.3, 0.3, 0.18)), self.LINEN]

    # ------------------------------------------------------------ grouping
    def mark(self):
        """Snapshot of every part list: PLACE(mark, ...) moves what was built after it as one rigid group."""
        return {id(lst): len(lst) for lst in self._lists()}

    def PLACE(self, mark, loc=(0, 0, 0), rot=(0, 0, 0), pivot=(0, 0, 0)):
        """Rotate (deg) the group built since `mark` about `pivot`, then move it by loc. Uses each object's own transform
        (matrix_basis, always current), so it is safe before any depsgraph update."""
        pv = Vector(pivot)
        m = Matrix.Translation(Vector(loc) + pv) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4() @ Matrix.Translation(-pv)
        for lst in self._lists():
            for o in lst[mark.get(id(lst), 0):]:
                o.matrix_basis = m @ o.matrix_basis

    def _lists(self):
        return [self.parts, self.panels, self.decals, self.glass_parts, self.noshadow, self.cols]

    # ------------------------------------------------------------ shared shapes
    def PRINT_QUAD(self, name, center, w, h, cell, facing="+z", up=(0, 1, 0), into=None):
        """A printed face (box lid, label, envelope) from a named apt_mess.png cell; into the panels (keeps its UVs)."""
        return self.QUAD_UV(name, center, w, h, facing, self.PRINT, D.mess_uv(cell, 0.02), up, into=self.panels if into is None else into)

    def PRINT_GRID(self, name, w, h, cell, height, n=8):
        """A printed face that follows a curved top (a puffed bag): an n x n grid over w x h centred on the origin, each
        vertex lifted to height(x, y). Up is +y in the image. Into the panels."""
        import bpy
        verts, faces, uvs = [], [], []
        u0, v0, u1, v1 = D.mess_uv(cell, 0.02)
        for j in range(n + 1):
            for i in range(n + 1):
                x, y = (i / n - 0.5) * w, (j / n - 0.5) * h
                verts.append((x, y, height(x, y)))
        for j in range(n):
            for i in range(n):
                a = j * (n + 1) + i
                faces.append([a, a + 1, a + n + 2, a + n + 1])
                for di, dj in ((0, 0), (1, 0), (1, 1), (0, 1)):
                    uvs.append((u0 + (i + di) / n * (u1 - u0), v0 + (j + dj) / n * (v1 - v0)))
        me = bpy.data.meshes.new(name)
        me.from_pydata(verts, [], faces)
        lay = me.uv_layers.new(name="UVMap")
        for k, uv in enumerate(uvs):
            lay.data[k].uv = uv
        me.materials.append(self.PRINT)
        o = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(o)
        self.panels.append(o)
        return o

    def CAN_AT(self, name, loc, cell, rot=(0, 0, 0), crush=0.0, seed=0):
        """A soda can with its printed wrap, turned by rot (deg) about its own base centre, then moved to loc. crush > 0
        dents and squashes it (a can stepped on)."""
        body = F.lathe(name, CAN, self.TIN, segs=16)
        wrap = self.WRAP_UV(name + "_wrap", (0, 0), 0.0333, 0.016, 0.104, 0, 360, self.PRINT, D.mess_uv(cell, 0.02), segs=14)
        self.parts.append(body)
        m = Matrix.Translation(Vector(loc)) @ Euler([math.radians(a) for a in rot]).to_matrix().to_4x4()
        if crush:
            m = m @ Matrix.Diagonal((1.0 + crush * 0.3, 1.0 - crush * 0.35, 1.0 - crush * 0.45, 1.0))
        for o in (body, wrap):
            if crush:                                                  # the same dents on body and wrap: the print stays on
                for v in o.data.vertices:
                    a = math.atan2(v.co.y, v.co.x)
                    k = 1.0 - crush * 0.16 * (0.5 + 0.5 * math.sin(3 * a + v.co.z * 70 + seed))
                    v.co.x *= k
                    v.co.y *= k
            o.data.transform(m)
        return body

    def CRUMPLE(self, name, loc, r, mat=None, seed=0):
        """A crumpled paper ball (or tissue): coarse and hard-creased."""
        return self.BLOB(name, (r * 2, r * 1.9, r * 1.7), loc, mat or self.PAPER_D, seed=seed, lumps=0.4, lump_freq=2.6, subdiv=2)

    def SHEET(self, name, loc, w, h, cell, yaw=0.0, curl=0.01, seed=0):
        """A loose printed sheet (receipt, flyer, envelope) lying on the floor, its edges curling up a little."""
        o = self.PRINT_QUAD(name, (0, 0, 0), w, h, cell)
        for v in o.data.vertices:
            v.co.z += curl * (0.6 + 0.4 * math.sin(seed + v.co.x * 20))
        o.rotation_euler = (0, 0, math.radians(yaw))
        o.location = loc
        return o
