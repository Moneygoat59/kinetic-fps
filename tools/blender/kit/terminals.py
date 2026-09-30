"""Outpost 73 kit: terminals. All still powered after 200 years; screens cycle frames at runtime (kit_prop.gd).
terminal_crt       tabletop CRT + keyboard + drive unit (sits on table_steel at TABLE_TOP); amber relay log
terminal_console   floor-standing wedge console: sloped control deck, leaning screen, stack light; green motion sweep
terminal_wall      wall-mounted bulkhead keypad terminal with conduits (wall prop); amber seal status / ACCESS DENIED
terminal_mainframe tall tape cabinet: two spinning reels, lamp row, tape LCD
"""
import math

import ps1_lib as L
from kit_lib import Kit


def _bezel(k, cx, cz, w, h, y, t=0.04, d=0.035, mat=None):
    """Four bars framing a -y facing screen of size w x h centred at (cx, cz); front of the bars at y - d."""
    mat = mat or k.MET_D
    yc = y - d / 2
    k.B("bz_t", (w + 2 * t, d, t), (cx, yc, cz + h / 2 + t / 2), mat)
    k.B("bz_b", (w + 2 * t, d, t), (cx, yc, cz - h / 2 - t / 2), mat)
    for s in (-1, 1):
        k.B(f"bz_{s}", (t, d, h), (cx + s * (w / 2 + t / 2), yc, cz), mat)


def terminal_crt():
    k = Kit("terminal_crt")
    k.B("plinth", (0.40, 0.36, 0.05), (0, 0.04, 0.025), k.MET_D, 0.012)
    k.B("neck", (0.18, 0.16, 0.04), (0, 0.04, 0.07), k.MET)
    k.B("housing", (0.56, 0.34, 0.50), (0, -0.02, 0.34), k.MET_D, 0.03)          # front face y = -0.19, z 0.09..0.59
    k.FRUSTUM("tube", 0.29, 0.15, 0.22, (0, 0.26, 0.35), k.MET_D)                # tapering CRT neck behind the housing
    k.B("rear_cap", (0.19, 0.03, 0.19), (0, 0.38, 0.35), k.MET)
    _bezel(k, 0, 0.37, 0.40, 0.30, -0.19)
    k.SCREEN("scr", (0, -0.192, 0.37), 0.40, 0.30, k.scr("log", "kit_screen_log_a.png", 1.3))
    k.B("visor", (0.56, 0.09, 0.025), (0, -0.23, 0.585), k.MET_D)
    for i, x in enumerate((0.13, 0.19)):
        k.CYL(f"knob{i}", 0.018, 0.03, (x, -0.2, 0.135), k.MET, "y", 8)
    k.B("power", (0.03, 0.01, 0.018), (-0.19, -0.195, 0.135), k.AMBER)
    k.DECAL("plate", (-0.05, -0.1935, 0.135), 0.11, 0.04, k.D_PLATE)
    for i in range(4):
        k.B(f"vent{i}", (0.012, 0.2, 0.014), (0.283, 0.0, 0.42 + i * 0.035), k.MET)
    # keyboard wedge in front of the monitor, keycap texture on its sloped top
    k.PRISM("kb", [(-0.46, 0.0), (-0.24, 0.0), (-0.24, 0.06), (-0.46, 0.035)], 0.50, (-0.25, 0, 0), k.MET_D, plane="yz")
    slope = math.degrees(math.atan2(0.025, 0.22))
    k.PANEL("keys", (0, -0.35, 0.049), 0.46, 0.19, k.KEYS, facing="+z", tilt=-slope, up=(0, 1, 0))
    # drive unit with two slots and an activity lamp
    k.B("drive", (0.20, 0.30, 0.14), (0.43, 0.02, 0.07), k.MET_D, 0.012)
    for z in (0.05, 0.095):
        k.B(f"slot{z}", (0.14, 0.006, 0.012), (0.43, -0.13, z), k.CABLE)
    k.B("drive_lamp", (0.02, 0.008, 0.012), (0.505, -0.132, 0.12), k.BLINK)
    k.PIPE("cable", [(0.08, 0.36, 0.2), (0.12, 0.4, 0.012), (0.3, 0.38, 0.012), (0.43, 0.2, 0.012)], 0.012, k.CABLE, verts=5)
    k.CYL("mug", 0.04, 0.09, (-0.43, -0.18, 0.045), k.MET, v=8)
    k.B("mug_handle", (0.012, 0.035, 0.05), (-0.475, -0.18, 0.05), k.MET)
    k.DECAL("papers", (-0.36, 0.12, 0.004), 0.32, 0.32, k.D_PAPERS, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_light_screen", (0, -0.5, 0.38))
    k.COL((0.82, 0.62, 0.6), (0.13, 0.07, 0.3))
    k.COL((0.5, 0.22, 0.06), (0, -0.35, 0.03))
    k.finish(subdiv=0.2, ao_dist=0.5)


def terminal_console():
    k = Kit("terminal_console")
    prof = [(-0.30, 0.0), (0.35, 0.0), (0.35, 1.55), (0.12, 1.55), (0.02, 1.10), (-0.42, 1.00), (-0.42, 0.93), (-0.30, 0.85)]
    k.PRISM("body", prof, 0.96, (-0.48, 0, 0), k.PLATE, plane="yz")
    for s in (-1, 1):
        k.PRISM(f"cheek{s}", prof, 0.04, (s * 0.50 - 0.02, 0, 0), k.MET_D, plane="yz")
    k.B("visor", (1.04, 0.24, 0.05), (0, 0.06, 1.575), k.MET_D, 0.015)
    k.B("kick", (0.96, 0.03, 0.10), (0, -0.30, 0.05), k.CABLE)
    k.B("door", (0.72, 0.02, 0.52), (0, -0.305, 0.45), k.MET_D, 0.008)
    k.B("handle", (0.14, 0.03, 0.025), (0.24, -0.325, 0.62), k.RUST)
    k.DECAL("plate", (-0.2, -0.3165, 0.62), 0.16, 0.06, k.D_PLATE)
    k.DECAL("haz", (0, -0.3165, 0.135), 0.96, 0.05, k.D_HAZARD)
    # leaning screen: face from (y, z) = (0.02, 1.10) up to (0.12, 1.55)
    tilt = math.degrees(math.atan2(0.10, 0.45))
    d, n = (0.217, 0.976), (-0.976, 0.217)
    at = lambda v, off: (0.07 + d[0] * v + n[0] * off, 1.325 + d[1] * v + n[1] * off)  # noqa: E731
    sy, sz = at(0.0, 0.004)
    k.SCREEN("scr", (0, sy, sz), 0.62, 0.36, k.scr("radar", "kit_screen_radar_0.png", 1.2), tilt=tilt)
    for name, v, w, h in (("bz_t", 0.2, 0.7, 0.04), ("bz_b", -0.2, 0.7, 0.04)):
        y, z = at(v, 0.015)
        k.B(name, (w, 0.03, h), (0, y, z), k.MET_D, rot=(-tilt, 0, 0))
    for s in (-1, 1):
        y, z = at(0.0, 0.015)
        k.B(f"bz_s{s}", (0.04, 0.03, 0.44), (s * 0.33, y, z), k.MET_D, rot=(-tilt, 0, 0))
    # sloped control deck: face from (-0.42, 1.00) up to (0.02, 1.10)
    slope = math.degrees(math.atan2(0.10, 0.44))
    k.PANEL("deck", (0, -0.201, 1.054), 0.8, 0.36, k.CTRL, facing="+z", tilt=-slope, up=(0, 1, 0))
    k.CYL("estop", 0.035, 0.05, (0.43, -0.3, 1.03), k.HAZ, v=10)
    k.CYL("estop_ring", 0.045, 0.02, (0.43, -0.3, 1.01), k.MET, v=10)
    for i in range(3):
        k.B(f"toggle{i}", (0.02, 0.02, 0.05), (-0.44 + i * 0.03, -0.12, 1.08), k.MET, rot=(-slope - 20, 0, 0))
    # stack light on the back corner, cables to the floor
    k.CYL("stack_pole", 0.015, 0.12, (0.4, 0.25, 1.61), k.MET, v=6)
    k.CYL("stack_lamp", 0.035, 0.07, (0.4, 0.25, 1.705), k.BLINK, v=10)
    k.CYL("stack_cap", 0.04, 0.015, (0.4, 0.25, 1.745), k.MET, v=10)
    for i, x in enumerate((-0.3, -0.22)):
        k.PIPE(f"cable{i}", [(x, 0.30, 0.35 + i * 0.1), (x, 0.42, 0.25), (x - 0.05, 0.5, 0.02), (x - 0.15, 0.9, 0.02)], 0.025,
               k.CABLE, verts=6)
    k.DECAL("streak", (0.5205, 0.1, 0.55), 0.5, 0.9, k.D_STREAK, facing="+x")
    k.DECAL("dust", (0, 0.06, 1.602), 1.0, 0.24, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_light_green", (0, -0.5, 1.3))
    k.COL((1.04, 0.77, 1.6), (0, -0.035, 0.8))
    k.finish()


def terminal_wall():
    k = Kit("terminal_wall")
    k.B("mount", (0.66, 0.03, 0.92), (0, -0.015, 1.45), k.MET_D, 0.01)
    k.B("housing", (0.56, 0.20, 0.74), (0, -0.13, 1.47), k.PLATE, 0.03)            # front face y = -0.23
    _bezel(k, 0, 1.62, 0.40, 0.30, -0.23)
    k.SCREEN("scr", (0, -0.232, 1.62), 0.40, 0.30, k.scr("seal", "kit_screen_seal_a.png", 1.3))
    k.B("visor", (0.56, 0.1, 0.025), (0, -0.27, 1.835), k.MET_D)
    k.B("keypad", (0.18, 0.06, 0.22), (-0.12, -0.26, 1.26), k.MET_D, 0.01)
    k.PANEL("keys", (-0.12, -0.2915, 1.26), 0.13, 0.17, k.KEYPAD)
    k.B("slot", (0.12, 0.02, 0.02), (0.12, -0.235, 1.3), k.CABLE)
    k.B("lamp_seal", (0.03, 0.01, 0.03), (0.08, -0.236, 1.2), k.RED)
    k.B("lamp_act", (0.03, 0.01, 0.03), (0.16, -0.236, 1.2), k.BLINK)
    k.DECAL("plate", (0.12, -0.2342, 1.38), 0.15, 0.056, k.D_PLATE)
    k.DECAL("haz", (0, -0.0315, 1.035), 0.62, 0.06, k.D_HAZARD)
    # conduits: one down the wall to a floor box, one up and back into the wall
    k.PIPE("cond_dn", [(0.2, -0.05, 1.1), (0.2, -0.05, 0.1)], 0.03, clamps=0.45)
    k.B("floor_box", (0.14, 0.09, 0.12), (0.2, -0.045, 0.06), k.MET, 0.01)
    k.PIPE("cond_up", [(-0.2, -0.05, 1.84), (-0.2, -0.05, 2.2), (-0.2, 0.0, 2.2)], 0.03, clamps=0.4)
    k.DECAL("streak", (0, -0.2318, 1.3), 0.5, 0.5, k.D_STREAK)
    k.LIGHT("marker_light_screen", (0, -0.5, 1.6))
    k.COL((0.6, 0.3, 0.8), (0, -0.15, 1.47))
    k.finish(wall=True, subdiv=0.25, ao_dist=0.6)


def _reel(k, x, pack):
    """Tape reel on the recess back wall; `pack` = radius of the wound tape. Joined into spin_<side> about its hub."""
    side = "l" if x < 0 else "r"
    k.CYL(f"spindle_{side}", 0.02, 0.03, (x, -0.29, 1.5), k.MET, "y", 8)          # fixed axle into the recess back wall
    lst = k.SPIN(f"reel_{side}", (x, -0.30, 1.5))
    k.CYL(f"flange_{side}", 0.15, 0.012, (x, -0.296, 1.5), k.MET, "y", 14, into=lst)
    k.CYL(f"pack_{side}", pack, 0.02, (x, -0.305, 1.5), k.CABLE, "y", 14, into=lst)
    k.CYL(f"hub_{side}", 0.04, 0.04, (x, -0.31, 1.5), k.MET, "y", 8, into=lst)
    for i in range(3):
        a = math.radians(i * 120)
        k.B(f"spoke_{side}{i}", (0.024, 0.006, 0.11), (x + 0.095 * math.sin(a), -0.318, 1.5 + 0.095 * math.cos(a)), k.MET,
            rot=(0, i * 120, 0), into=lst)


def terminal_mainframe():
    k = Kit("terminal_mainframe")
    body = k.B("body", (0.9, 0.7, 1.92), (0, 0, 0.98), k.PLATE, 0.02)            # front face y = -0.35
    L.cut(body, L.box("recess", (0.76, 0.14, 0.62), (0, -0.35, 1.48)))          # reel window, back wall at y = -0.28
    k.B("plinth", (0.86, 0.66, 0.06), (0, 0, 0.03), k.CABLE)
    k.B("cap", (0.94, 0.74, 0.05), (0, 0, 1.955), k.MET_D, 0.015)
    k.B("win_t", (0.8, 0.03, 0.03), (0, -0.36, 1.805), k.MET_D)
    k.B("win_b", (0.8, 0.03, 0.03), (0, -0.36, 1.155), k.MET_D)
    for s in (-1, 1):
        k.B(f"win_{s}", (0.03, 0.03, 0.62), (s * 0.395, -0.36, 1.48), k.MET_D)
    _reel(k, -0.19, 0.12)
    _reel(k, 0.19, 0.07)
    k.B("head", (0.1, 0.05, 0.06), (0, -0.305, 1.27), k.MET)
    k.B("win_lamp", (0.6, 0.02, 0.015), (0, -0.29, 1.77), k.AMBER)                # strip lamp lighting the reels
    k.TUBE("tape_l", (-0.19, -0.312, 1.38), (-0.05, -0.312, 1.28), 0.004, k.CABLE, 4)
    k.TUBE("tape_r", (0.05, -0.312, 1.28), (0.19, -0.312, 1.43), 0.004, k.CABLE, 4)
    # control strip: lamp row (some blink), toggles, tape LCD
    for i in range(8):
        mat = (k.BLINK, k.AMBER, k.AMBER, k.GREEN)[i % 4] if i != 5 else k.BLINK
        k.B(f"lamp{i}", (0.035, 0.01, 0.025), (-0.33 + i * 0.06, -0.352, 1.06), mat)
        if i < 6:
            k.B(f"sw{i}", (0.015, 0.02, 0.03), (-0.33 + i * 0.06, -0.36, 0.99), k.MET)
    k.SCREEN("lcd", (0.28, -0.3535, 1.02), 0.18, 0.09, k.scr("tape", "kit_screen_tape_a.png", 1.0))
    k.B("lcd_frame", (0.21, 0.01, 0.12), (0.28, -0.347, 1.02), k.CABLE)
    # lower doors: seam, handles, louvre vent
    k.B("seam", (0.006, 0.006, 0.7), (0, -0.352, 0.58), k.CABLE)
    for s in (-1, 1):
        k.B(f"handle{s}", (0.025, 0.03, 0.14), (s * 0.05, -0.365, 0.66), k.RUST)
    for i in range(5):
        k.B(f"slat{i}", (0.7, 0.02, 0.025), (0, -0.355, 0.14 + i * 0.045), k.MET_D, rot=(-28, 0, 0))
    k.DECAL("plate", (-0.25, -0.3535, 0.86), 0.2, 0.075, k.D_PLATE)
    k.DECAL("streak", (0.451, 0.0, 1.2), 0.6, 1.1, k.D_STREAK, facing="+x")
    k.DECAL("dust", (0, 0, 1.982), 0.9, 0.7, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_light_screen", (0, -0.6, 1.1))
    k.COL((0.94, 0.74, 1.98), (0, 0, 0.99))
    k.finish(ao_dist=0.7)


PROPS = {f.__name__: f for f in (terminal_crt, terminal_console, terminal_wall, terminal_mainframe)}
