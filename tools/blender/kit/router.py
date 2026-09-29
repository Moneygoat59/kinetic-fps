"""Outpost 73 kit: terminal_router, the relay-routing console of Relay Hub 00 (programs a relay route's carrier).
Wide floor console: sloped control deck with four big route keys (kit_glow_route_1..4, tinted per channel at runtime), a key
strip label, keyboard and a large leaning screen (kit_scr_route: the placeholder frame; scripts/hub/hub_console_view.gd renders
the live routing table onto it with PixelScreen). Stack light, cables into the floor. Front faces -Y (Godot +Z).
"""
import math

from kit_lib import Kit, glow, _t
import ps1_lib as L

W = 2.0                                  # body width
PROF = [(-0.36, 0.0), (0.42, 0.0), (0.42, 1.78), (0.22, 1.78), (0.10, 1.02), (-0.46, 0.92), (-0.46, 0.84), (-0.36, 0.76)]
SCR_LO, SCR_HI = (0.10, 1.02), (0.22, 1.78)     # leaning screen face (y, z)
DECK_LO, DECK_HI = (-0.46, 0.92), (0.10, 1.02)  # sloped deck face (y, z)
KEY_X = (-0.66, -0.36, -0.06, 0.24)             # route keys 1..4 (R-73, R-02, R-03, R-00)


def _on_face(lo, hi, v, off):
    """Point on a sloped face (y, z) at fraction v from lo to hi, pushed `off` metres out of the front."""
    dy, dz = hi[0] - lo[0], hi[1] - lo[1]
    n = math.hypot(dy, dz)
    ny, nz = -dz / n, dy / n
    return lo[0] + dy * v + ny * off, lo[1] + dz * v + nz * off


def terminal_router():
    k = Kit("terminal_router")
    k.PRISM("body", PROF, W, (-W / 2, 0, 0), k.PLATE, plane="yz")
    for s in (-1, 1):
        k.PRISM(f"cheek{s}", PROF, 0.05, (s * (W / 2 + 0.025) - 0.025, 0, 0), k.MET_D, plane="yz")
    k.B("visor", (W + 0.1, 0.3, 0.05), (0, 0.3, 1.805), k.MET_D, 0.015)
    k.B("kick", (W, 0.03, 0.1), (0, -0.365, 0.05), k.CABLE)
    for i, x in enumerate((-0.55, 0.55)):
        k.B(f"door{i}", (0.8, 0.02, 0.5), (x, -0.37, 0.43), k.MET_D, 0.008)
        k.B(f"handle{i}", (0.14, 0.03, 0.025), (x + 0.28, -0.39, 0.6), k.RUST)
    k.DECAL("plate", (0, -0.3815, 0.6), 0.2, 0.075, k.D_PLATE)
    k.DECAL("haz", (0, -0.3815, 0.135), W, 0.05, k.D_HAZARD)
    # leaning screen with bezel
    tilt = math.degrees(math.atan2(SCR_HI[0] - SCR_LO[0], SCR_HI[1] - SCR_LO[1]))
    sy, sz = _on_face(SCR_LO, SCR_HI, 0.5, 0.004)
    k.SCREEN("scr", (0, sy, sz), 1.2, 0.64, k.scr("route", "kit_screen_route.png", 1.2), tilt=tilt)
    for name, v in (("bz_t", 0.935), ("bz_b", 0.065)):
        y, z = _on_face(SCR_LO, SCR_HI, v, 0.015)
        k.B(name, (1.32, 0.03, 0.05), (0, y, z), k.MET_D, rot=(-tilt, 0, 0))
    for s in (-1, 1):
        y, z = _on_face(SCR_LO, SCR_HI, 0.5, 0.015)
        k.B(f"bz_s{s}", (0.05, 0.03, 0.72), (s * 0.635, y, z), k.MET_D, rot=(-tilt, 0, 0))
    for s in (-1, 1):                                                              # side monitors' blank covers
        y, z = _on_face(SCR_LO, SCR_HI, 0.5, 0.01)
        k.B(f"cover{s}", (0.26, 0.02, 0.5), (s * 0.84, y, z), k.MET_D, 0.01, rot=(-tilt, 0, 0))
        for j in range(4):
            k.B(f"vent{s}{j}", (0.2, 0.012, 0.02), (s * 0.84, y - 0.012, z - 0.15 + j * 0.1), k.CABLE, rot=(-tilt, 0, 0))
    # sloped deck: control panel, four route keys with their label strip, keyboard, selector knob, e-stop
    slope = math.degrees(math.atan2(DECK_HI[1] - DECK_LO[1], DECK_HI[0] - DECK_LO[0]))
    cy, cz = _on_face(DECK_LO, DECK_HI, 0.5, 0.002)
    k.PANEL("deck", (-0.2, cy, cz), 1.5, 0.52, k.CTRL, facing="+z", tilt=-slope, up=(0, 1, 0))
    k.PANEL("keys", (0.72, cy - 0.06, cz - 0.01), 0.44, 0.19, k.KEYS, facing="+z", tilt=-slope, up=(0, 1, 0))
    ky, kz = _on_face(DECK_LO, DECK_HI, 0.62, 0.03)
    ly, lz = _on_face(DECK_LO, DECK_HI, 0.3, 0.004)
    lbl = L.decal_material("kit_decal_route_keys", _t("kit_route_keys.png"))
    k.DECAL("key_labels", (-0.21, ly, lz), 1.2, 0.075, lbl, facing="+z", up=(0, 1, 0), tilt=-slope)
    for i, x in enumerate(KEY_X):
        k.B(f"key_ring{i}", (0.2, 0.2, 0.03), (x, ky + 0.01, kz - 0.02), k.MET, 0.01, rot=(slope, 0, 0))
        k.B(f"key{i}", (0.15, 0.15, 0.05), (x, ky, kz), glow(f"kit_glow_route_{i + 1}", (1.0, 0.45, 0.06), 0.4), 0.012,
            rot=(slope, 0, 0))
    ny, nz = _on_face(DECK_LO, DECK_HI, 0.75, 0.03)
    k.CYL("knob", 0.06, 0.05, (0.62, ny, nz), k.MET_D, v=10)
    k.B("knob_mark", (0.012, 0.05, 0.012), (0.62, ny - 0.03, nz + 0.03), k.AMBER)
    k.CYL("estop", 0.04, 0.05, (0.9, -0.36, 0.9), k.HAZ, v=10)
    k.CYL("estop_ring", 0.05, 0.02, (0.9, -0.36, 0.88), k.MET, v=10)
    for i in range(3):
        k.B(f"toggle{i}", (0.02, 0.02, 0.05), (0.56 + i * 0.05, -0.34, 0.93), k.MET, rot=(-slope - 20, 0, 0))
    k.B("lamp_power", (0.04, 0.012, 0.025), (-0.85, -0.44, 0.9), k.AMBER)
    k.B("lamp_tx", (0.04, 0.012, 0.025), (-0.77, -0.44, 0.9), k.BLINK)
    # stack light on the back corner, cables into the floor
    k.CYL("stack_pole", 0.015, 0.14, (-0.9, 0.3, 1.9), k.MET, v=6)
    k.CYL("stack_lamp", 0.04, 0.08, (-0.9, 0.3, 2.01), k.BLINK, v=10)
    k.CYL("stack_cap", 0.045, 0.015, (-0.9, 0.3, 2.058), k.MET, v=10)
    for i, x in enumerate((-0.6, -0.5, 0.5)):
        k.PIPE(f"cable{i}", [(x, 0.42, 0.3 + i * 0.1), (x, 0.55, 0.22), (x - 0.04, 0.62, 0.02), (x - 0.1, 0.95, 0.02)],
               0.028, k.CABLE, verts=6)
    k.DECAL("streak", (W / 2 + 0.051, 0.1, 0.55), 0.5, 0.9, k.D_STREAK, facing="+x")
    k.DECAL("dust", (0, 0.3, 1.832), W, 0.28, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.LIGHT("marker_light_screen", (0, -0.6, 1.4))
    # collision: the body up to the deck's front edge, and a block behind the screen; the deck stays open so the aim ray
    # reaches the route keys (scripts/hub/hub_router_keys.gd puts a hit area on each key cap)
    k.COL((W + 0.1, 0.9, DECK_LO[1]), (0, 0.0, DECK_LO[1] / 2))
    k.COL((W + 0.1, 0.45 - DECK_HI[0], 1.8 - DECK_LO[1]), (0, (DECK_HI[0] + 0.45) / 2, (1.8 + DECK_LO[1]) / 2))
    k.finish()


PROPS = {"terminal_router": terminal_router}
