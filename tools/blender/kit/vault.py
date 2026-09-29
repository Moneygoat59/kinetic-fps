"""Rail tunnel kit: tunnel_vault, the company's records vault at the end of a line (ends it like tunnel_collapse: no
marker_next). Origin = its entry face (tunnel centre, invert level); it runs along +Y (Godot -Z). Sizes: VAULT_* in kit_dims.
  0 .. VAULT_APPROACH  the line's last 10 m: the track ends at a buffer stop (marker_kit_rail_buffer__v0), a loading dock
                       at walkway height across the whole bore up to the vault wall (steel steps up from the track on the
                       right), the amber main dives into the floor, an emergency pylon at the end of the walkway
                       (marker_pylon_0: the vault's own lamps light the inside). Portal plate LINE 00 // RECORDS.
  the vault wall       VAULT_WALL of concrete, a round doorway with its door swung out onto the dock (vault_door.py).
  the hall             2 * VAULT_HW x 22 m, VAULT_CLEAR high, five bays of deep beams, columns either side of the aisle.
                       Paper files left, drawings right, the tape cage (wire-mesh wall, lower ceiling, a gate left open)
                       at the far end; furniture = kit markers laid out in vault_layout.py; stencils FILES / DRAWINGS /
                       TAPES, the drawings pinned on the right wall, a crack in it bleeding amber into a pool.
Lamps still burn (marker_light_vault* / vaultshadow* / vaultfail*, kit_lights.gd): the only warm light on the line.
"""
import math

import ps1_lib as L
import vault_door
from kit_dims import CAT_D, MAIN_R, MAIN_X, MAIN_Z, TRACK_X, TUN_HW, VAULT_APPROACH, VAULT_BAY, VAULT_CLEAR, VAULT_COL_X, \
    VAULT_DOCK_Y, VAULT_HW, VAULT_Y0, VAULT_Y1, WALK_Z
from kit_lib import _t
from tunnel_lib import TunnelKit, TunnelPath, empty_at, grime, lining_col, ribs, services, shell, track
from vault_layout import CAGE_H, CAGE_Y, FACE, KIT, STACK_X, STACKS, TABLE_TOP

F, C, HW = WALK_Z, WALK_Z + VAULT_CLEAR, VAULT_HW
MAIN_END = 5.0                 # the main leaves the wall here and dives into the floor
LAMP_DROP = 1.5                # hall lamps hang this far under the ceiling


class VaultKit(TunnelKit):
    def __init__(self, name):
        super().__init__(name)
        d = lambda n, f: L.decal_material(n, _t(f))  # noqa: E731
        self.D_DIAL, self.D_VAULT = d("kit_decal_vault_dial", "tun_vault_dial.png"), d("kit_decal_vault", "tun_vault.png")
        self.D_FILES, self.D_DRAW = d("kit_decal_vault_files", "tun_vault_files.png"), d("kit_decal_vault_drawings", "tun_vault_drawings.png")
        self.D_TAPES, self.D_ROWS = d("kit_decal_vault_tapes", "tun_vault_tapes.png"), d("kit_decal_vault_rows", "tun_vault_rows.png")
        self.D_MESH = d("kit_decal_vault_mesh", "tun_vault_mesh.png")
        self.D_BP = {n: d(f"kit_decal_bp_{n}", f"kit_bp_{n}.png") for n in ("tunnel", "junction", "silo", "door")}


def _slab(k, name, x0, x1, y0, y1, z0, z1, mat, col=True, chamfer=0.0):
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    k.parts.append(L.fast_box(name, size, loc, mat, chamfer=chamfer))
    if col:
        k.COL(size, loc)


def _uv(o, u0, v0, u1, v1):
    uv = o.data.uv_layers.active
    for i, p in enumerate(((u0, v0), (u1, v0), (u1, v1), (u0, v1))):
        uv.data[i].uv = p
    return o


def approach(k):
    p = TunnelPath(0.0, VAULT_APPROACH)
    lining_col(k, shell(k, p, walk_skip=[(VAULT_DOCK_Y, VAULT_APPROACH)]))
    ribs(k, p)
    track(k, p, 0.0, VAULT_DOCK_Y)
    services(k, p, left_skip=[(MAIN_END, VAULT_APPROACH)], glass=2.5)
    grime(k, p, seed=5)
    k.PIPE("main_dive", [(MAIN_X, MAIN_END - 0.05, MAIN_Z), (MAIN_X, MAIN_END + 0.3, MAIN_Z), (MAIN_X, MAIN_END + 0.3, -0.3)],
           MAIN_R, k.MET_D, clamps=0.08)
    _slab(k, "dock", -TUN_HW - 0.02, TUN_HW + 0.02, VAULT_DOCK_Y, VAULT_APPROACH, -0.02, F, k.CON_T)
    _slab(k, "dock_coping", -TUN_HW, TUN_HW, VAULT_DOCK_Y - 0.04, VAULT_DOCK_Y + 0.16, F - 0.06, F + 0.01, k.CON_B, col=False)
    k.DECAL("dock_hazard", (0.0, VAULT_DOCK_Y - 0.045, F - 0.18), 2 * TUN_HW - 0.2, 0.22, k.D_HAZARD)
    x0, x1, y0 = 0.62, 1.72, VAULT_DOCK_Y - 1.3                          # steel steps up from the track (a ramp to walk)
    for i in range(4):
        z = F * (i + 1) / 4
        _slab(k, f"tread{i}", x0, x1, y0 + i * 0.325, y0 + (i + 1) * 0.325 + 0.02, z - 0.04, z, k.PLATE, col=False)
    for x in (x0, x1 - 0.05):
        k.B(f"stringer{x}", (0.05, 1.45, 0.08), (x + 0.025, y0 + 0.62, F / 2), k.MET_D, rot=(math.degrees(math.atan2(F, 1.3)), 0, 0))
    k.cols.append(L.ramp("steps_col", x0, x1, y0, VAULT_DOCK_Y, -0.02, 0.0, F, None))
    empty_at(k, "marker_kit_rail_buffer__v0", (TRACK_X, 3.6, 0.0))
    empty_at(k, "marker_pylon_0", (2.35, VAULT_APPROACH - 0.7, F), FACE["-x"])
    k.DECAL("portal_sign", (0.0, VAULT_APPROACH - 0.012, 4.1), 2.2, 0.55, k.D_VAULT)


def hall(k):
    y0, y1 = VAULT_Y0, VAULT_Y1
    _slab(k, "floor", -HW - 0.4, HW + 0.4, y0, y1 + 0.4, F - 0.5, F, k.CON_T)
    _slab(k, "ceiling", -HW - 0.4, HW + 0.4, y0, y1 + 0.4, C, C + 0.5, k.CON_T)
    for s in (-1, 1):
        _slab(k, f"wall{s}", min(s * HW, s * (HW + 0.4)), max(s * HW, s * (HW + 0.4)), y0, y1 + 0.4, F - 0.5, C, k.CON)
    _slab(k, "wall_back", -HW, HW, y1, y1 + 0.4, F - 0.5, C, k.CON)
    for i in range(1, 5):                                                # beams, corbels, columns either side of the aisle
        y = y0 + i * VAULT_BAY
        _slab(k, f"beam{i}", -HW, HW, y - 0.25, y + 0.25, C - 0.6, C, k.CON_B, col=False)
        for s in (-1, 1):
            _slab(k, f"corbel{i}{s}", min(s * (HW - 0.35), s * HW), max(s * (HW - 0.35), s * HW), y - 0.3, y + 0.3, C - 1.4, C - 0.6,
                  k.CON_B, col=False)
            if i < 4:
                _slab(k, f"column{i}{s}", s * VAULT_COL_X - 0.25, s * VAULT_COL_X + 0.25, y - 0.25, y + 0.25, F, C - 0.6, k.CON_B,
                      chamfer=0.04)
                _slab(k, f"plinth{i}{s}", s * VAULT_COL_X - 0.32, s * VAULT_COL_X + 0.32, y - 0.32, y + 0.32, F, F + 0.25, k.CON,
                      col=False)
    for x in (STACK_X - 2.3, STACK_X, STACK_X + 2.3):                    # the stacks' floor rails
        _slab(k, f"rail{x:.1f}", x - 0.03, x + 0.03, STACKS[0] - 0.7, STACKS[-1] + 0.7, F, F + 0.015, k.MET, col=False)
    for i, y in enumerate(STACKS):                                       # row numbers on the floor at the stack ends
        col, row = i % 4, i // 4
        _uv(k.DECAL(f"row{i}", (-2.0, y, F + 0.004), 0.45, 0.45, k.D_ROWS, facing="+z", up=(-1, 0, 0)),
            col / 4, 1 - (row + 1) / 4, (col + 1) / 4, 1 - row / 4)


def cage(k):
    """The tape cage: a low wall, steel posts and wire mesh under a solid header, a lower ceiling behind, the gate open."""
    y, yb, top = CAGE_Y, VAULT_Y1, F + CAGE_H
    _slab(k, "cage_ceiling", -HW, HW, y + 0.1, yb, top, top + 0.2, k.CON_T, col=False)
    _slab(k, "cage_header", -HW, HW, y - 0.1, y + 0.1, top, C - 0.6, k.CON, col=False)
    posts = [-HW + 0.04] + [-HW + 1.3 * i for i in range(1, 6)] + [-1.05]
    posts += [-x for x in reversed(posts)]
    for s in (-1, 1):
        _slab(k, f"cage_wall{s}", min(s * HW, s * 1.1), max(s * HW, s * 1.1), y - 0.1, y + 0.1, F, F + 0.9, k.CON)
        k.COL((HW - 1.0, 0.2, CAGE_H), (s * (HW + 1.0) / 2, y, F + CAGE_H / 2))
    for i, x in enumerate(posts):
        z0 = F if abs(x) < 1.1 else F + 0.9
        _slab(k, f"post{i}", x - 0.04, x + 0.04, y - 0.04, y + 0.04, z0, top, k.MET_D, col=False)
    _slab(k, "gate_head", -1.05, 1.05, y - 0.04, y + 0.04, F + 2.4, F + 2.46, k.MET_D, col=False)
    _slab(k, "cage_rail", -HW, HW, y - 0.05, y + 0.05, top - 0.08, top, k.MET_D, col=False)
    for a, b in zip(posts, posts[1:]):                                   # mesh between the posts, both faces
        z0 = F + 2.46 if a == -1.05 else F + 0.9
        if b - a < 0.2 or (a < -4.0 < b):                                # one panel torn out
            continue
        w, h = b - a - 0.08, top - 0.08 - z0
        for side in (-1, 1):
            _uv(k.DECAL(f"mesh{a:.1f}{side}", ((a + b) / 2, y + side * 0.012, z0 + h / 2), w, h, k.D_MESH,
                        facing="+y" if side > 0 else "-y"), 0, 0, w / 0.5, h / 0.5)
    k.DECAL("tapes", (0.0, y - 0.106, (top + C - 0.6) / 2), 2.4, 0.6, k.D_TAPES)
    leaf = []                                                            # the gate, swung into the cage
    for name, size, loc in (("gate_l", (0.05, 0.05, 2.3), (-0.95, y, F + 1.2)), ("gate_r", (0.05, 0.05, 2.3), (0.95, y, F + 1.2)),
                            ("gate_t", (1.9, 0.05, 0.05), (0.0, y, F + 2.33)), ("gate_b", (1.9, 0.05, 0.05), (0.0, y, F + 0.08))):
        leaf.append(k.B(name, size, loc, k.MET_D))
    for side in (-1, 1):
        leaf.append(_uv(k.DECAL(f"gate_mesh{side}", (0.0, y + side * 0.012, F + 1.2), 1.85, 2.2, k.D_MESH,
                                facing="+y" if side > 0 else "-y"), 0, 0, 1.85 / 0.5, 2.2 / 0.5))
    col = L.box("gate_col", (1.9, 0.08, 2.3), (0.0, y, F + 1.2), None)
    k.cols.append(col)
    import bpy
    bpy.context.view_layer.update()
    L.rotate_about(leaf + [col], (1.05, y, 0.0), (0, 0, -78))


def lamps(k):
    """Hanging lamp housings (glass lit, or dead), flush strips in the cage; the light markers under them."""
    hung = [(0.0, 13.4, "vault"), (0.0, 17.8, "vaultshadow"), (0.0, 22.2, "vaultshadow"), (0.0, 26.6, None),
            (STACK_X, 17.8, "vault"), (STACK_X, 26.6, "vaultfail"), (5.6, 16.0, "vault"), (5.6, 22.2, "vault")]
    for i, (x, y, kind) in enumerate(hung):
        z = C - LAMP_DROP
        for dy in (-0.55, 0.55):
            k.TUBE(f"lamp_chain{i}{dy}", (x, y + dy, z + 0.07), (x, y + dy, C), 0.012, k.RUST, 4)
        _slab(k, f"lamp{i}", x - 0.18, x + 0.18, y - 0.7, y + 0.7, z, z + 0.14, k.MET_D, col=False)
        _slab(k, f"lamp_glass{i}", x - 0.13, x + 0.13, y - 0.64, y + 0.64, z - 0.02, z, k.LAMP if kind else k.GLASS_DEAD, col=False)
        if kind:
            k.LIGHT(f"marker_light_{kind}_{i}", (x, y, z - 0.35))
    for i, x in enumerate((0.0, -5.5)):
        _slab(k, f"cage_lamp{i}", x - 0.6, x + 0.6, 30.85, 31.15, F + CAGE_H - 0.08, F + CAGE_H, k.LAMP, col=False)
        k.LIGHT(f"marker_light_vault_c{i}", (x, 31.0, F + CAGE_H - 0.3))


def dressing(k):
    y0, y1, fl = VAULT_Y0, VAULT_Y1, F + 0.003
    k.DECAL("inner_sign", (0.0, y0 + 0.006, 4.4), 2.6, 0.65, k.D_VAULT, facing="+y")
    k.DECAL("files", (-HW + 0.006, 21.0, 4.3), 2.8, 0.7, k.D_FILES, facing="+x")
    k.DECAL("drawings", (HW - 0.006, 16.2, 4.3), 3.2, 0.8, k.D_DRAW, facing="-x")
    for i, (bp, y, z, w, h) in enumerate((("tunnel", 12.8, 2.3, 1.1, 0.75), ("silo", 14.3, 2.5, 0.75, 1.1), ("junction", 15.8, 2.2, 1.1, 0.75),
                                          ("door", 17.3, 2.45, 1.1, 0.75), ("tunnel", 18.8, 2.25, 1.0, 0.68), ("junction", 20.1, 2.6, 0.9, 0.6))):
        k.DECAL(f"pinned{i}", (HW - 0.006 - 0.003 * (i % 2), y, z), w, h, k.D_BP[bp], facing="-x", up=(0, 0.06 * (i % 3 - 1), 1))
    top = F + TABLE_TOP + 0.004                                          # drawings spread over the layout tables
    k.DECAL("spread0", (5.6, 21.9, top), 1.1, 0.75, k.D_BP["silo"], facing="+z", up=(0.1, 1, 0))
    k.DECAL("spread1", (5.5, 23.1, top + 0.002), 1.1, 0.75, k.D_BP["door"], facing="+z", up=(-1, 0.15, 0))
    for i, (x, y, w, h) in enumerate(((-5.8, 20.5, 6.0, 15.0), (6.4, 20.0, 4.0, 16.0), (-6.0, 30.6, 3.0, 2.0))):   # not the aisle
        k.DECAL(f"dust{i}", (x, y, fl + 0.001 * i), w, h, k.D_DUST, facing="+z")
    k.DECAL("stain", (1.2, 13.6, fl + 0.005), 1.5, 1.5, k.D_STAIN, facing="+z")
    k.DECAL("papers0", (-1.1, 18.6, fl + 0.006), 1.4, 1.4, k.D_PAPERS, facing="+z", up=(0.5, 1, 0))
    k.DECAL("papers1", (-5.0, y0 + CAT_D + 0.7, fl + 0.006), 1.2, 1.2, k.D_PAPERS, facing="+z", up=(-0.3, 1, 0))
    k.B("fallen_box", (0.36, 0.28, 0.26), (-1.35, 18.95, F + 0.13), k.BOX, rot=(0, 0, 31))
    k.B("fallen_lid", (0.38, 0.3, 0.04), (-0.8, 18.3, F + 0.02), k.BOX, rot=(0, 0, -12))
    for i, (x, y, z, face) in enumerate(((-HW + 0.005, 13.5, 4.6, "+x"), (-HW + 0.005, 25.5, 4.4, "+x"), (HW - 0.005, 27.0, 4.5, "-x"),
                                         (-4.0, y1 - 0.005, 2.2, "-y"))):
        k.DECAL(f"streak{i}", (x, y, z), 1.6, 2.6, k.D_STREAK, facing=face)
    k.DECAL("crack", (HW - 0.005, 24.08, 4.6), 0.7, 1.1, k.D_CRACK, facing="-x")      # amber bleeding through the wall
    k.DECAL("drips", (HW - 0.007, 24.08, 2.9), 0.7, 2.6, k.D_DRIPS, facing="-x")
    k.POOL("pool", (HW - 0.5, 24.08, fl + 0.007), 0.9, 0.7)
    k.DECAL("crust", (HW - 0.3, 24.08, fl + 0.008), 0.5, 0.6, k.D_CRUST, facing="+z")
    k.LIGHT("marker_light_amber_leak", (HW - 0.45, 24.08, F + 0.3))


def furnish(k):
    for i, row in enumerate(KIT):
        prop, x, y, facing = row[:4]
        z = row[4] if len(row) > 4 else 0.0
        flags = row[5] if len(row) > 5 else ""
        empty_at(k, f"marker_kit_{prop}__v{i}{flags}", (x, y, F + z), FACE[facing])


def tunnel_vault():
    k = VaultKit("tunnel_vault")
    approach(k)
    vault_door.doorway(k)
    vault_door.leaf(k)
    hall(k)
    cage(k)
    lamps(k)
    dressing(k)
    furnish(k)
    k.finish(subdiv=0.9, ao_dist=1.2)


PROPS = {"tunnel_vault": tunnel_vault}
