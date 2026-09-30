"""Apartment kit: writing things (origin at the base centre, front -Y = the reader's side).
journal_open   A5-ish notebook lying open, cloth cover, both page stacks curving up out of the gutter, a pen resting on the
               right page. The spread is ONE `panels` quad strip (material apt_journal_page, UV u 0..0.5 left page, 0.5..1
               right page, v up = away from the reader) so AptJournal can draw the handwriting live into a SubViewport.
               The pen is its own node `pen` with its origin at the nib (AptJournal writes with it). marker_use_journal.
"""
import bpy

import ps1_lib as L
from apt_lib import AptKit

PW, PH = 0.12, 0.17            # one page (m)
COVER_T = 0.003                # board thickness
BASE = 0.0105                  # page surface height at the flat of the page
SEGS = 8                       # strips across each page (the curve out of the gutter)
PEN_TIP = (0.1, 0.066)         # (x, y) of the resting nib on the right page


def page_z(t):
    """Height of the page surface at t = 0 (gutter) .. 1 (outer edge): dips into the gutter, rises, flattens."""
    return BASE - 0.003 + 0.006 * (1.0 - (1.0 - t) ** 2.5) - 0.001 * t


def _page(name, side, mat, lst, u0, u1):
    """Curved page surface for one side (-1 left, +1 right), UV-mapped to its half of the spread image."""
    verts, faces, uvs = [], [], []
    for i in range(SEGS + 1):
        t = i / SEGS
        x, z = side * t * PW, page_z(t)
        verts += [(x, -PH / 2, z), (x, PH / 2, z)]
    for i in range(SEGS):
        a, b = 2 * i, 2 * i + 2
        faces.append([a, b, b + 1, a + 1] if side > 0 else [a, a + 1, b + 1, b])
    for f in faces:
        for vi in f:
            t = (vi // 2) / SEGS
            u = u0 + (u1 - u0) * (t if side > 0 else 1.0 - t)
            uvs.append((u, float(vi % 2)))
    return _mesh(name, verts, faces, mat, lst, uvs)


def _stack(name, side, mat, lst):
    """The block of pages under a surface: follows the curve on top, straight down to the cover on the three open sides."""
    verts, faces = [], []
    for i in range(SEGS + 1):
        t = i / SEGS
        x, z = side * t * PW, page_z(t) - 0.0006
        verts += [(x, -PH / 2, z), (x, PH / 2, z), (x, -PH / 2, COVER_T), (x, PH / 2, COVER_T)]
    for i in range(SEGS):
        a, b = 4 * i, 4 * i + 4
        faces += [[a, b, b + 1, a + 1], [a, a + 2, b + 2, b], [a + 1, b + 1, b + 3, a + 3]]
    e = 4 * SEGS
    faces.append([e, e + 2, e + 3, e + 1])
    if side < 0:
        faces = [f[::-1] for f in faces]
    return _mesh(name, verts, faces, mat, lst)


def _mesh(name, verts, faces, mat, lst, uvs=None):
    me = bpy.data.meshes.new(name)
    me.from_pydata(verts, [], faces)
    me.update()
    if uvs:
        lay = me.uv_layers.new(name="UVMap")
        for k, p in enumerate(uvs):
            lay.data[k].uv = p
    o = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(o)
    me.materials.append(mat)
    lst.append(o)
    return o


def journal_open():
    k = AptKit("journal_open")
    cover = L.material("apt_journal_cover", (0.2, 0.07, 0.05))                   # oxblood cloth
    page = L.material("apt_journal_page", (0.9, 0.87, 0.78))                      # replaced live by AptJournal
    k.B("cover", (2 * PW + 0.012, PH + 0.008, COVER_T), (0, 0, COVER_T / 2), cover, 0.001)
    k.CYL("spine", 0.004, PH + 0.006, (0, 0, 0.002), cover, axis="y", v=12)
    k.B("ribbon", (0.005, 0.05, 0.0005), (0.004, -PH / 2 - 0.02, 0.0005), k.RUSTF)
    for side in (-1, 1):
        _stack(f"stack{side}", side, k.PAPER, k.parts)
    _page("page_l", -1, page, k.panels, 0.0, 0.5)
    _page("page_r", 1, page, k.panels, 0.5, 1.0)
    x, y = PEN_TIP
    z = page_z(x / PW) + 0.0042
    pen = k.PIVOT("pen", (x, y, z))
    k.FRUSTUM("nib", 0.0034, 0.0006, 0.012, (x, y - 0.006, z), k.CHROME, axis="y", v=12, into=pen)
    k.CYL("barrel", 0.0042, 0.1, (x, y - 0.062, z), k.BLACK, axis="y", v=12, into=pen)
    k.CYL("grip", 0.0045, 0.022, (x, y - 0.024, z), k.CORD, axis="y", v=12, into=pen)
    k.CYL("end", 0.0038, 0.006, (x, y - 0.115, z), k.CHROME, axis="y", v=12, into=pen)
    k.B("clip", (0.0016, 0.04, 0.0012), (x, y - 0.09, z + 0.0048), k.CHROME, into=pen)
    k.USE("journal", (0, 0, 0.02))
    k.finish(subdiv=0.03, ao_dist=0.04)


PROPS = {f.__name__: f for f in (journal_open,)}
