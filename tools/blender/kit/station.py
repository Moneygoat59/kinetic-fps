"""Rail tunnel kit: tunnel_station, a platform on the line. Chains like tunnel_straight (origin = entry face, runs along +Y,
marker_next at STA_LEN). Sizes: STA_* in kit_dims.
  0 .. STA_Y0          bore (a plain tunnel stub), then a headwall with the bore's portal through it.
  the cavern           STA_Y0 .. STA_Y1: the bore's left wall carries on (track, amber conductor, drain and main run
                       straight through), the right side widens to STA_XR under an elliptic vault with a rib every
                       STA_RIB. A side platform at walkway height fills it from the edge (a steel nosing over a recess)
                       to the back wall, so the walkway runs straight onto it.
  STA_Y1 .. STA_LEN    headwall, bore; a signal on the left wall where the line leaves.
Fittings: name boards (RECORDS) on the back wall and across the track, a hanging indicator (live screen kit_scr_indicator:
LINE 00 / NO SERVICE, marker_light_indicator), a stopped clock, the way sign at the far end, the driver's STOP board, dead
lamp fittings, an amber seep. Kit markers: benches under the boards, a wall terminal (marker_kit_*); marker_pylon_0 = an
emergency pylon on the platform. Textures: tools/blender/station_textures.py.
"""
import math

import ps1_lib as L
from kit_dims import MAIN_R, MAIN_X, MAIN_Z, STA_EDGE, STA_HEAD, STA_LEN, STA_RECESS, STA_RIB, STA_RISE, STA_SPRING, STA_XR, \
    STA_Y0, STA_Y1, TUN_HW, TUN_LINING, WALK_Z
from kit_lib import _t
from tunnel_lib import TunnelKit, TunnelPath, arch, band, circle, empty_at, grime, lining_col, next_marker, ribs, services, \
    shell, sweep, track
from tunnels import _box

F = WALK_Z
XL, XR = -TUN_HW, STA_XR
XC, HALF = (XL + XR) / 2, (XR - XL) / 2
FACE = {"-y": 0.0, "+x": 90.0, "+y": 180.0, "-x": -90.0}      # kit fronts face -Y: yaw that turns them
BAYS = (6.0, 12.0, 18.0)                                       # name boards (benches under them), between the ribs
SUBDIV, AO_DIST = 0.9, 1.1


class StationKit(TunnelKit):
    def __init__(self, name):
        super().__init__(name)
        d = lambda n, f: L.decal_material(n, _t(f))  # noqa: E731
        self.D_NAME, self.D_WAY = d("kit_decal_station_name", "tun_station_name.png"), d("kit_decal_station_way", "tun_station_way.png")
        self.D_STOP, self.D_CLOCK = d("kit_decal_station_stop", "tun_station_stop.png"), d("kit_decal_station_clock", "tun_station_clock.png")
        self.IND = self.scr("indicator", "tun_indicator_a.png", 1.1)


def profile(d=0.0, z0=0.0, segs=18):
    """The cavern's inner face offset d inward (d < 0: outward): left wall foot, up, over the vault, down to the right foot."""
    a, b = HALF - d, STA_RISE - d
    pts = [(XL + d, z0), (XL + d, STA_SPRING)]
    for i in range(1, segs):
        t = math.pi * (1.0 - i / segs)
        pts.append((XC + a * math.cos(t), STA_SPRING + b * math.sin(t)))
    return pts + [(XR - d, STA_SPRING), (XR - d, z0)]


def vault_z(x):
    u = (x - XC) / HALF
    return STA_SPRING + STA_RISE * math.sqrt(max(1.0 - u * u, 0.0))


def bores(k, p):
    for s0, s1 in ((0.0, STA_Y0), (STA_Y1, STA_LEN)):
        lining_col(k, shell(k, p, s0, s1))
        ribs(k, p, s0, s1)
        services(k, p, s0, s1)


def headwalls(k, p):
    """A wall across the cavern's end with the bore's portal through it, a cast frame round the portal on the platform side."""
    for i, (y0, y1, fy) in enumerate(((STA_Y0 - STA_HEAD, STA_Y0, STA_Y0), (STA_Y1, STA_Y1 + STA_HEAD, STA_Y1 - 0.14))):
        wall = sweep(f"headwall{i}", profile(-TUN_LINING, -0.5), p, y0, y1, k.CON)
        L.cut(wall, sweep(f"cut_bore{i}", arch(-0.01, 0.0), p, y0 - 0.1, y1 + 0.1, None))
        k.parts.append(wall)
        k.COL_COPY(wall)
        k.parts.append(sweep(f"portal{i}", band(-0.01, -0.45, 0.0), p, fy, fy + 0.14, k.CON_B))


def cavern(k, p):
    slab = sweep("cavern_slab", [(XL - TUN_LINING, -0.5), (XR + TUN_LINING, -0.5), (XR + TUN_LINING, 0.0), (XL - TUN_LINING, 0.0)],
                 p, STA_Y0, STA_Y1, k.CON_T)
    lin = sweep("cavern_lining", profile(0.0, -0.02) + list(reversed(profile(-TUN_LINING, -0.02))), p, STA_Y0, STA_Y1, k.CON)
    for o in (slab, lin):
        k.parts.append(o)
        k.COL_COPY(o)
    y = STA_Y0 + STA_RIB
    while y < STA_Y1 - 1.0:
        k.parts.append(sweep(f"cavern_rib{y:.1f}", profile(0.14, 0.0) + list(reversed(profile(-0.05, 0.0))), p, y - 0.18, y + 0.18,
                             k.CON_B))
        y += STA_RIB
    k.parts.append(sweep("main_cavern", circle(MAIN_X, MAIN_Z, MAIN_R, 10), p, STA_Y0, STA_Y1, k.MET_D, step=0.5))
    k.parts.append(sweep("feeder_cavern", circle(XL + 0.12, 3.35, 0.022, 6), p, STA_Y0, STA_Y1, k.CABLE))
    for i in range(3):                                                    # cables along the back wall, over the boards
        k.parts.append(sweep(f"cable_back{i}", circle(XR - 0.12 - 0.05 * i, 3.3 + 0.08 * i, 0.028, 6), p, STA_Y0, STA_Y1, k.CABLE))
    for s in (2.5 + 2.0 * i for i in range(10)):
        k.B(f"main_bracket{s}", (0.34, 0.06, 0.06), (MAIN_X - 0.05, s, MAIN_Z - MAIN_R - 0.03), k.RUST)
        k.B(f"rack{s}", (0.3, 0.05, 0.05), (XR - 0.15, s, 3.24), k.RUST)
        k.B(f"feeder_clip{s}", (0.06, 0.04, 0.1), (XL + 0.05, s, 3.35), k.MET_D)


def platform(k, p):
    y0, y1, nose = STA_Y0, STA_Y1, STA_EDGE + 0.04
    _box(k, "plat_body", STA_EDGE + STA_RECESS, XR + 0.02, y0, y1, -0.02, F - 0.16, k.CON)
    _box(k, "plat_deck", nose, XR + 0.02, y0, y1, F - 0.16, F, k.CON_T)
    _box(k, "plat_nosing", STA_EDGE, nose, y0, y1, F - 0.17, F + 0.004, k.MET_D)
    _box(k, "plat_coping", nose, nose + 0.42, y0, y1, F - 0.01, F + 0.006, k.CON_B, col=False)
    for i in range(int(y1 - y0)):                                         # the line to stand behind
        k.DECAL(f"edge_haz{i}", (nose + 0.6, y0 + i + 0.5, F + 0.004), 1.0, 0.12, k.D_HAZARD, facing="+z", up=(1, 0, 0))
    k.DECAL("recess_dust", (STA_EDGE + 0.1, (y0 + y1) / 2, 0.012), y1 - y0, 0.5, k.D_DUST, facing="+z", up=(1, 0, 0))


def boards(k):
    for i, y in enumerate(BAYS):                                          # RECORDS on the back wall and across the track
        for x, side, z, face in ((XR - 0.03, -1, F + 2.15, "-x"), (XL + 0.03, 1, 2.45, "+x")):
            k.B(f"board{i}{side}", (0.06, 2.5, 0.68), (x, y, z), k.MET_D)
            k.DECAL(f"name{i}{side}", (x + side * 0.032, y, z), 2.4, 0.6, k.D_NAME, facing=face)
        empty_at(k, f"marker_kit_platform_bench__s{i}", (XR - 0.4, y, F), FACE["-x"])
    empty_at(k, "marker_pylon_0", (XR - 0.4, 15.0, F), FACE["-x"])
    empty_at(k, "marker_kit_terminal_wall__s3", (XR, 9.0, F), FACE["-x"])


def _hang(k, name, x, y, z_top, spread):
    for dx in (-spread, spread):
        k.TUBE(f"{name}_rod{dx}", (x + dx, y, z_top), (x + dx, y, vault_z(x + dx) + 0.05), 0.012, k.MET_D, 4)


def fittings(k):
    x, y, z = 3.3, 9.0, F + 2.85                                          # indicator: a box, a screen each way
    k.B("indicator", (1.7, 0.3, 0.5), (x, y, z), k.MET_D, 0.02)
    for face, dy in (("-y", -0.152), ("+y", 0.152)):
        k.SCREEN(f"indicator_{face}", (x, y + dy, z), 1.44, 0.36, k.IND, facing=face)
    k.LIGHT("marker_light_indicator", (x, y - 0.6, z - 0.3))
    _hang(k, "indicator", x, y, z + 0.25, 0.6)
    x, y, z = 3.3, 15.0, F + 2.95                                         # the clock, double faced
    k.CYL("clock", 0.3, 0.14, (x, y, z), k.MET_D, "y", 16)
    for face, dy in (("-y", -0.072), ("+y", 0.072)):
        k.DECAL(f"clock_{face}", (x, y + dy, z), 0.56, 0.56, k.D_CLOCK, facing=face)
    _hang(k, "clock", x, y, z + 0.3, 0.0)
    x, y, z = 3.6, 21.0, F + 2.7                                          # straight on for the records
    k.B("way", (1.95, 0.06, 0.5), (x, y, z), k.MET_D)
    k.DECAL("way_sign", (x, y - 0.032, z), 1.9, 0.475, k.D_WAY)
    _hang(k, "way", x, y, z + 0.25, 0.8)
    x, y = STA_EDGE + 0.3, STA_Y1 - 0.7                                   # the driver's STOP board
    k.TUBE("stop_post", (x, y, F), (x, y, F + 1.2), 0.03, k.MET_D, 6)
    k.B("stop", (0.28, 0.03, 0.42), (x, y, F + 1.4), k.MET_D)
    k.DECAL("stop_face", (x, y - 0.016, F + 1.4), 0.26, 0.39, k.D_STOP)
    x, y = XL + 0.25, STA_Y1 - 0.4                                        # the exit signal: three dead lenses
    k.B("signal_arm", (0.4, 0.08, 0.08), (x - 0.1, y, 2.9), k.RUST)
    k.B("signal", (0.32, 0.22, 0.86), (x + 0.1, y, 2.9), k.MET_D, 0.02)
    for i, dz in enumerate((-0.26, 0.0, 0.26)):
        k.CYL(f"lens{i}", 0.08, 0.03, (x + 0.1, y - 0.12, 2.9 + dz), k.GLASS_DEAD, "y", 10)
        k.B(f"hood{i}", (0.2, 0.12, 0.02), (x + 0.1, y - 0.17, 2.99 + dz), k.MET_D)
    for row, lx in enumerate((2.2, 5.0)):                                 # dead lamp fittings
        for i in range(7):
            ly, lz = STA_Y0 + 1.5 + STA_RIB * i, F + 3.2
            k.B(f"fitting{row}{i}", (0.26, 1.3, 0.1), (lx, ly, lz), k.MET_D)
            k.B(f"fitting_glass{row}{i}", (0.2, 1.2, 0.02), (lx, ly, lz - 0.06), k.GLASS_DEAD)
            _hang(k, f"fitting{row}{i}", lx, ly, lz + 0.05, 0.0)


def dressing(k, p):
    grime(k, p, 0.0, STA_Y0, seed=2)
    grime(k, p, STA_Y1, STA_LEN, seed=3)
    for i, (x, y, w, h) in enumerate(((3.9, 5.0, 4.5, 6.0), (4.2, 12.5, 4.0, 5.0), (3.6, 19.0, 4.8, 5.5))):
        k.DECAL(f"plat_dust{i}", (x, y, F + 0.008 + 0.001 * i), w, h, k.D_DUST, facing="+z")
    k.DECAL("papers", (2.4, 13.4, F + 0.012), 1.3, 1.3, k.D_PAPERS, facing="+z", up=(0.4, 1, 0))
    for i, (x, y, z, face) in enumerate(((XR - 0.005, 3.2, 4.2, "-x"), (XR - 0.005, 16.8, 4.4, "-x"), (XL + 0.005, 9.0, 4.1, "+x"),
                                         (XL + 0.005, 20.9, 4.3, "+x"))):
        k.DECAL(f"streak{i}", (x, y, z), 1.6, 2.6, k.D_STREAK, facing=face)
    k.DECAL("crack", (XR - 0.006, 20.3, 3.0), 0.8, 1.2, k.D_CRACK, facing="-x")       # amber seeping through the back wall
    k.DECAL("drips", (XR - 0.008, 20.3, 1.9), 0.6, 1.8, k.D_DRIPS, facing="-x")
    k.POOL("seep", (XR - 0.45, 20.3, F + 0.014), 0.8, 0.6)
    k.LIGHT("marker_light_amber_seep", (XR - 0.4, 20.3, F + 0.3))


def tunnel_station():
    k = StationKit("tunnel_station")
    p = TunnelPath(0.0, STA_LEN)
    bores(k, p)
    headwalls(k, p)
    cavern(k, p)
    platform(k, p)
    track(k, p)
    boards(k)
    fittings(k)
    dressing(k, p)
    next_marker(k, p)
    k.finish(subdiv=SUBDIV, ao_dist=AO_DIST)


PROPS = {"tunnel_station": tunnel_station}
