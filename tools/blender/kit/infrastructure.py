"""Outpost 73 kit: modular infrastructure for the forest around the outposts.
Pipes snap on a GRID (2 m cell, origin = cell centre, centreline at PIPE_Z, ports at the cell-edge midpoints):
  pipe_straight  -X port to +X port          pipe_elbow  -X port to front (-Y, Godot +Z) port
  pipe_valve     straight with gate valve + glowing amber sight glass
  pipe_riser     -X port, then bends down into a ground collar (line goes underground), AMBER MAIN marker sign
barrier_concrete / barrier_concrete_broken   2 m obsidian jersey barriers along X, snap end to end
floodlight     tripod work lamp on an amber battery (spot light, failing flicker)
"""
import math

import ps1_lib as L
from kit_lib import GRID, PIPE_Z, Kit

R = 0.13          # pipe radius
H = GRID / 2      # port distance from the cell centre


def _flange(k, name, pos, axis):
    k.CYL(name, 0.19, 0.05, pos, k.MET_D, axis, 10)
    for i in range(6):
        a = i * math.tau / 6 + 0.3
        off = (0.155 * math.cos(a), 0.155 * math.sin(a))
        p = {"x": (pos[0], pos[1] + off[0], pos[2] + off[1]), "y": (pos[0] + off[0], pos[1], pos[2] + off[1])}[axis]
        k.CYL(f"{name}_bolt{i}", 0.014, 0.075, p, k.MET, axis, 6)


def _stand(k, name, x, y, along="x"):
    """Saddle support under a pipe running along `along`: foot plate, post, U saddle hugging the pipe."""
    k.B(f"{name}_foot", (0.3, 0.3, 0.03), (x, y, 0.015), k.MET_D)
    k.B(f"{name}_post", (0.08, 0.08, 0.34), (x, y, 0.2), k.MET_D)
    sx, sy = (0.12, 0.34) if along == "x" else (0.34, 0.12)
    k.B(f"{name}_saddle", (sx, sy, 0.03), (x, y, PIPE_Z - R - 0.015), k.MET_D)
    for s in (-1, 1):
        wing = (x, y + s * (R + 0.015)) if along == "x" else (x + s * (R + 0.015), y)
        k.B(f"{name}_wing{s}", (0.12, 0.03, 0.1) if along == "x" else (0.03, 0.12, 0.1), (wing[0], wing[1], PIPE_Z - 0.07), k.MET_D)


def _pipe_col(k, x0, x1, y0, y1):
    k.COL((x1 - x0, y1 - y0, PIPE_Z + R + 0.02), ((x0 + x1) / 2, (y0 + y1) / 2, (PIPE_Z + R + 0.02) / 2))


def pipe_straight():
    k = Kit("pipe_straight")
    k.PIPE("run", [(-H, 0, PIPE_Z), (H, 0, PIPE_Z)], R, clamps=0.65)
    for s in (-1, 1):
        _flange(k, f"fl{s}", (s * (H - 0.025), 0, PIPE_Z), "x")
        _stand(k, f"st{s}", s * 0.5, 0)
    k.DECAL("stain", (0.85, 0.05, 0.004), 0.9, 0.9, k.D_STAIN, facing="+z", up=(0, 1, 0))
    _pipe_col(k, -H, H, -0.2, 0.2)
    k.finish(ao_dist=0.5)


def pipe_elbow():
    k = Kit("pipe_elbow")
    k.PIPE("run", [(-H, 0, PIPE_Z), (-0.25, 0, PIPE_Z), (0, -0.25, PIPE_Z), (0, -H, PIPE_Z)], R, clamps=0.6)
    _flange(k, "fl_x", (-(H - 0.025), 0, PIPE_Z), "x")
    _flange(k, "fl_y", (0, -(H - 0.025), PIPE_Z), "y")
    _stand(k, "st_x", -0.625, 0, "x")
    _stand(k, "st_y", 0, -0.625, "y")
    _pipe_col(k, -H, 0.2, -0.2, 0.2)
    _pipe_col(k, -0.2, 0.2, -H, 0.0)
    k.finish(ao_dist=0.5)


def pipe_valve():
    k = Kit("pipe_valve")
    k.PIPE("run", [(-H, 0, PIPE_Z), (H, 0, PIPE_Z)], R)
    for s in (-1, 1):
        _flange(k, f"fl{s}", (s * (H - 0.025), 0, PIPE_Z), "x")
    # gate valve: body, bonnet, stem, red handwheel
    vx = -0.25
    k.B("valve", (0.3, 0.36, 0.36), (vx, 0, PIPE_Z), k.MET_D, 0.03)
    for dx in (-0.17, 0.17):
        k.CYL(f"valve_fl{dx}", 0.19, 0.04, (vx + dx, 0, PIPE_Z), k.MET_D, "x", 10)
    k.CYL("bonnet", 0.07, 0.24, (vx, 0, PIPE_Z + 0.3), k.MET_D, v=8)
    k.TUBE("stem", (vx, 0, PIPE_Z + 0.42), (vx, 0, PIPE_Z + 0.55), 0.02, k.MET)
    ring = [(vx + 0.2 * math.cos(a * math.tau / 12), 0.2 * math.sin(a * math.tau / 12), PIPE_Z + 0.55) for a in range(13)]
    k.PIPE("wheel", ring, 0.016, k.HAZ, verts=6)
    for i in range(3):
        a = i * math.tau / 3
        k.TUBE(f"spoke{i}", (vx, 0, PIPE_Z + 0.55), (vx + 0.2 * math.cos(a), 0.2 * math.sin(a), PIPE_Z + 0.55), 0.012, k.HAZ)
    k.CYL("hub", 0.035, 0.05, (vx, 0, PIPE_Z + 0.55), k.MET, v=8)
    # sight glass: glowing amber sleeve between two flanges, tie rods across
    gx = 0.5
    k.CYL("glass", 0.136, 0.26, (gx, 0, PIPE_Z), k.LIQUID, "x", 12)
    for dx in (-0.15, 0.15):
        k.CYL(f"glass_fl{dx}", 0.18, 0.05, (gx + dx, 0, PIPE_Z), k.MET_D, "x", 10)
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        p = (0.16 * math.cos(a), PIPE_Z + 0.16 * math.sin(a))
        k.TUBE(f"rod{i}", (gx - 0.15, p[0], p[1]), (gx + 0.15, p[0], p[1]), 0.01, k.MET)
    _stand(k, "st_l", -0.72, 0)
    _stand(k, "st_r", 0.86, 0)
    k.LIGHT("marker_light_amber", (gx, -0.35, PIPE_Z))
    _pipe_col(k, -H, H, -0.2, 0.2)
    k.finish(ao_dist=0.5)


def pipe_riser():
    k = Kit("pipe_riser")
    k.PIPE("run", [(-H, 0, PIPE_Z), (-0.3, 0, PIPE_Z), (0, 0, PIPE_Z - 0.3), (0, 0, -0.3)], R, clamps=0.5)
    _flange(k, "fl", (-(H - 0.025), 0, PIPE_Z), "x")
    _stand(k, "st", -0.62, 0)
    k.B("collar", (0.5, 0.5, 0.16), (0, 0, 0.06), k.CON_T, 0.03)
    k.TUBE("post", (0.35, -0.35, 0.0), (0.35, -0.35, 0.95), 0.025, k.RUST)
    k.B("sign", (0.34, 0.015, 0.26), (0.35, -0.37, 0.84), k.MET_D)
    k.DECAL("sign_face", (0.35, -0.3805, 0.84), 0.32, 0.24, k.D_SIGN)
    k.DECAL("crust", (0.0, 0.0, 0.004), 1.1, 1.1, k.D_CRUST, facing="+z", up=(0, 1, 0))
    _pipe_col(k, -H, 0.25, -0.25, 0.25)
    k.finish(ao_dist=0.5)


PROFILE = [(-0.30, 0.0), (0.30, 0.0), (0.30, 0.08), (0.12, 0.25), (0.08, 0.80), (-0.08, 0.80), (-0.12, 0.25), (-0.30, 0.08)]


def _barrier(name, broken):
    k = Kit(name)
    body = k.PRISM("body", PROFILE, GRID, (-H, 0, 0), k.CON_B, plane="yz")
    L.cut(body, L.box("scupper", (0.34, 0.8, 0.14), (0, 0, 0.0)))                 # drain slot under the middle
    if broken:
        jag = [(0.38, 0.95), (0.5, 0.7), (0.62, 0.74), (0.7, 0.5), (0.84, 0.46), (0.9, 0.28), (1.1, 0.22), (1.1, 0.95)]
        L.cut(body, L.prism("break", jag, 0.8, (0, -0.4, 0)))
        for i, (a, b) in enumerate((((0.55, -0.03, 0.55), (0.68, -0.07, 0.86)), ((0.75, 0.03, 0.35), (0.98, 0.08, 0.55)),
                                     ((0.62, 0.0, 0.45), (0.8, 0.01, 0.64)))):
            k.TUBE(f"rebar{i}", a, b, 0.01, k.RUST, 5)
        for i, (x, y, s) in enumerate(((0.88, -0.42, 0.14), (0.9, 0.42, 0.12), (0.7, -0.45, 0.1))):
            chunk = k.B(f"chunk{i}", (s, s * 1.2, s), (x, y, s / 2), k.CON_B, rot=(0, 0, 25 * i))
            L.jitter(chunk, 0.02, i)
    for x in ((-0.6,) if broken else (-0.6, 0.6)):
        k.PIPE(f"loop{x}", [(x - 0.06, 0, 0.79), (x - 0.06, 0, 0.86), (x + 0.06, 0, 0.86), (x + 0.06, 0, 0.79)], 0.012, k.RUST, verts=5)
    tilt = math.degrees(math.atan2(0.04, 0.55))
    for s in (-1, 1):
        y = s * (0.12 - (0.62 - 0.25) * 0.04 / 0.55 + 0.003)
        k.DECAL(f"haz{s}", (-0.05, y, 0.62), 1.8, 0.14, k.D_HAZARD, facing="-y" if s < 0 else "+y", tilt=tilt * -s)
    k.DECAL("streak", (-0.5, -0.1068, 0.5), 0.7, 0.46, k.D_STREAK, tilt=tilt)            # 2 mm proud of the stripe
    k.DECAL("dust", (-0.1 if broken else 0, 0, 0.802), 1.6 if broken else 1.9, 0.16, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL_COPY(body)
    k.finish(ao_dist=0.6)


def barrier_concrete():
    _barrier("barrier_concrete", False)


def barrier_concrete_broken():
    _barrier("barrier_concrete_broken", True)


def floodlight():
    k = Kit("floodlight")
    for i, a in enumerate((90, 210, 330)):
        foot = (0.45 * math.cos(math.radians(a)), 0.45 * math.sin(math.radians(a)), 0.0)
        k.TUBE(f"leg{i}", (0, 0, 0.9), foot, 0.018, k.MET_D)
        k.B(f"pad{i}", (0.06, 0.06, 0.02), (foot[0], foot[1], 0.01), k.MET)
    k.CYL("collar", 0.045, 0.1, (0, 0, 0.9), k.MET_D, v=8)
    k.TUBE("pole", (0, 0, 0.85), (0, 0, 1.56), 0.022, k.MET)
    k.B("yoke", (0.38, 0.03, 0.03), (0, 0, 1.56), k.MET_D)
    for s in (-1, 1):
        k.B(f"arm{s}", (0.02, 0.03, 0.16), (s * 0.18, 0, 1.63), k.MET_D)
        k.CYL(f"pin{s}", 0.02, 0.05, (s * 0.165, 0, 1.68), k.MET, "x", 6)
    head = []
    k.B("housing", (0.30, 0.2, 0.22), (0, 0, 1.68), k.MET_D, 0.02, into=head)
    k.B("lens", (0.24, 0.012, 0.16), (0, -0.104, 1.68), k.LAMP, into=head)
    for x in (-0.06, 0.0, 0.06):
        k.B(f"guard{x}", (0.01, 0.01, 0.17), (x, -0.116, 1.68), k.MET, into=head)
    k.B("visor", (0.32, 0.09, 0.015), (0, -0.13, 1.8), k.MET_D, into=head)
    for i in range(4):
        k.B(f"fin{i}", (0.26, 0.04, 0.01), (0, 0.12, 1.6 + i * 0.05), k.MET_D, into=head)
    L.rotate_about(head, (0, 0, 1.68), (18, 0, 0))                                    # aimed down at the ground ahead
    k.parts.extend(head)
    k.PIPE("cable", [(0.03, 0.12, 1.6), (0.03, 0.035, 1.45), (0.03, 0.035, 0.95), (0.2, 0.25, 0.012), (0.55, 0.55, 0.012),
                     (0.83, 0.5, 0.012)], 0.012, k.CABLE, verts=5)
    k.B("battery", (0.26, 0.18, 0.2), (0.96, 0.5, 0.1), k.MET_D, 0.012)
    k.B("window", (0.12, 0.01, 0.05), (0.96, 0.407, 0.12), k.LIQUID)
    k.PIPE("bat_handle", [(0.88, 0.5, 0.2), (0.88, 0.5, 0.25), (1.04, 0.5, 0.25), (1.04, 0.5, 0.2)], 0.01, verts=5)
    k.DECAL("bat_label", (0.96, 0.5, 0.2025), 0.1, 0.1, k.D_AMBER, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_spot", (0, -0.13, 1.645))
    k.COL((0.14, 0.14, 1.8), (0, 0, 0.9))
    k.COL((0.26, 0.18, 0.2), (0.96, 0.5, 0.1))
    k.finish(subdiv=0.25, ao_dist=0.5)


PROPS = {f.__name__: f for f in (pipe_straight, pipe_elbow, pipe_valve, pipe_riser, barrier_concrete, barrier_concrete_broken,
                                 floodlight)}
