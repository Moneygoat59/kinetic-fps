"""Outpost 73 kit: the field dosimeter (the tracker the player carries) and the field-kit wall rack it hangs on.
dosimeter       handheld, no collision (it rides on the camera). Backlit needle meter (node `needle`, pivot at its hub, turns
                about local Z), amber display (kit_scr_dosi; the held device draws a live readout onto it), click LED
                (kit_glow_dosi_led), channel lamp (kit_glow_dosi_lamp), range knob, speaker, Geiger probe clipped to the side.
dosimeter_rack  wall prop: shadow board with three painted outlines, hooks and charging ledges; slots 01 and 02 signed out
                on day 112 and never returned. The bunker hangs its pickup on slot 03 (kit_dims.RACK_*).
"""
import math

from kit_dims import (DOSI_D, DOSI_GRIP_R, DOSI_GRIP_Z, DOSI_H, DOSI_W, METER_C, METER_H, METER_W, NEEDLE_LEN, NEEDLE_PIVOT_Z,
                      RACK_DEVICE_Z, RACK_H, RACK_HOOK_R, RACK_HOOK_Z, RACK_SLOTS, RACK_W, RACK_ZC, BOARD_H, BOARD_W)
from kit_lib import Kit

FY = -DOSI_D / 2 + 0.005     # front face of the body shell (the corner bumpers stand 5 mm proud)


def _frame(k, name, cx, cz, w, h, depth, t, mat):
    """Four bars framing a front-facing window (meter, display)."""
    y = FY - depth / 2
    k.B(f"{name}_t", (w + 2 * t, depth, t), (cx, y, cz + h / 2 + t / 2), mat)
    k.B(f"{name}_b", (w + 2 * t, depth, t), (cx, y, cz - h / 2 - t / 2), mat)
    for s in (-1, 1):
        k.B(f"{name}_{s}", (t, depth, h), (cx + s * (w / 2 + t / 2), y, cz), mat)


def dosimeter():
    k = Kit("dosimeter")
    k.B("shell", (DOSI_W - 0.01, DOSI_D - 0.01, DOSI_H - 0.005), (0, 0, (DOSI_H - 0.005) / 2), k.MET_D, 0.01)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.B(f"bumper{sx}{sy}", (0.022, 0.022, DOSI_H), (sx * (DOSI_W / 2 - 0.011), sy * (DOSI_D / 2 - 0.011), DOSI_H / 2),
                k.CABLE, 0.004)
        k.B(f"handle_foot{sx}", (0.022, 0.03, 0.012), (sx * 0.07, 0, DOSI_H + 0.001), k.MET_D)
    # carry handle with a rubber grip (the rack hook takes the grip)
    k.PIPE("handle", [(-0.07, 0, DOSI_H), (-0.07, 0, DOSI_GRIP_Z), (0.07, 0, DOSI_GRIP_Z), (0.07, 0, DOSI_H)], 0.006, k.MET, verts=6)
    k.CYL("grip", DOSI_GRIP_R, 0.1, (0, 0, DOSI_GRIP_Z), k.CABLE, "x", 8)
    # backlit needle meter
    mx, mz = METER_C
    k.PANEL("meter", (mx, FY - 0.0015, mz), METER_W, METER_H, k.METER)
    _frame(k, "meter_bz", mx, mz, METER_W, METER_H, 0.008, 0.007, k.MET_D)
    needle = k.PIVOT("needle", (mx, FY - 0.004, NEEDLE_PIVOT_Z))
    k.B("needle_bar", (0.0022, 0.0015, NEEDLE_LEN), (mx, FY - 0.004, NEEDLE_PIVOT_Z + NEEDLE_LEN / 2), k.HAZ, into=needle)
    k.CYL("needle_hub", 0.005, 0.004, (mx, FY - 0.0045, NEEDLE_PIVOT_Z), k.CABLE, "y", 8)
    # amber display in a black plastic frame
    k.SCREEN("display", (0.052, FY - 0.0015, 0.095), 0.07, 0.035, k.scr("dosi", "kit_screen_dosi.png", 1.2))
    _frame(k, "disp_bz", 0.052, 0.095, 0.07, 0.035, 0.006, 0.006, k.CABLE)
    # lower row: print strip, range knob, toggle, lamps, speaker
    k.DECAL("print", (mx, FY - 0.0012, 0.0415), 0.085, 0.016, k.D_DOSI)
    k.CYL("knob", 0.013, 0.012, (-0.07, FY - 0.006, 0.021), k.MET, "y", 10)
    k.B("knob_mark", (0.003, 0.004, 0.01), (-0.07, FY - 0.0125, 0.026), k.HAZ)
    k.B("toggle", (0.006, 0.012, 0.014), (-0.04, FY - 0.006, 0.021), k.MET, rot=(20, 0, 0))
    k.B("led", (0.01, 0.004, 0.008), (0.02, FY - 0.002, 0.034), k.LED)
    k.CYL("lamp", 0.006, 0.005, (0.04, FY - 0.0025, 0.034), k.LAMP_CH, "y", 8)
    for i in range(4):
        k.B(f"speaker{i}", (0.032, 0.003, 0.003), (0.07, FY - 0.0015, 0.016 + i * 0.007), k.CABLE)
    # Geiger probe clipped to the right side, coiled lead into the body
    px = DOSI_W / 2 + 0.02
    k.CYL("probe", 0.014, 0.105, (px, 0, 0.068), k.MET_D, "z", 8)
    k.CYL("probe_window", 0.0145, 0.03, (px, 0, 0.09), k.MET, "z", 8)
    k.CYL("probe_cap", 0.015, 0.012, (px, 0, 0.123), k.CABLE, "z", 8)
    for z in (0.035, 0.1):
        k.B(f"clip{z}", (0.016, 0.016, 0.01), (DOSI_W / 2 + 0.006, 0, z), k.MET)
    k.PIPE("lead", [(px, 0, 0.016), (px + 0.004, -0.018, 0.006), (px - 0.008, -0.03, 0.005), (DOSI_W / 2 - 0.004, -0.03, 0.012)],
           0.003, k.CABLE, verts=5)
    k.finish(subdiv=1.0, ao_dist=0.05, ground=False)


def dosimeter_rack():
    k = Kit("dosimeter_rack")
    k.B("plate", (RACK_W, 0.025, RACK_H), (0, -0.0125, RACK_ZC), k.MET_D, 0.006)
    for s in (-1, 1):
        k.B(f"rail{s}", (RACK_W + 0.02, 0.035, 0.025), (0, -0.0175, RACK_ZC + s * RACK_H / 2), k.MET)
    k.DECAL("board", (0, -0.0255, RACK_ZC), BOARD_W, BOARD_H, k.D_BOARD)
    for i, sx in enumerate(RACK_SLOTS):
        k.B(f"hook_mount{i}", (0.03, 0.006, 0.03), (sx, -0.028, RACK_HOOK_Z), k.MET_D)
        k.TUBE(f"hook{i}", (sx, -0.025, RACK_HOOK_Z), (sx, -0.095, RACK_HOOK_Z), RACK_HOOK_R, k.MET)
        k.TUBE(f"hook_tip{i}", (sx, -0.095, RACK_HOOK_Z), (sx, -0.095, RACK_HOOK_Z + 0.022), RACK_HOOK_R, k.MET)
        k.B(f"ledge{i}", (0.21, 0.05, 0.01), (sx, -0.05, RACK_DEVICE_Z - 0.006), k.MET_D)
        for dx in (-0.04, 0.04):
            k.B(f"contact{i}{dx}", (0.01, 0.008, 0.004), (sx + dx, -0.05, RACK_DEVICE_Z - 0.0005), k.MET)
        k.B(f"lamp{i}", (0.022, 0.01, 0.016), (sx + 0.075, -0.03, RACK_ZC - 0.07), k.AMBER if i == 2 else k.RED)
    k.PIPE("conduit", [(-0.36, -0.03, RACK_ZC - RACK_H / 2), (-0.36, -0.03, 0.08)], 0.02, clamps=0.4)
    k.B("floor_box", (0.1, 0.07, 0.08), (-0.36, -0.035, 0.04), k.MET, 0.008)
    k.DECAL("dust", (0, -0.0175, RACK_ZC + RACK_H / 2 + 0.0135), RACK_W, 0.035, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((RACK_W + 0.02, 0.1, RACK_H + 0.03), (0, -0.05, RACK_ZC))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.3)


PROPS = {f.__name__: f for f in (dosimeter, dosimeter_rack)}
