"""Outpost 73 kit: relay_pylon, a mast of the old outpost relay network (the chain the field dosimeter follows).
Footing of obsidian concrete (reaches below ground so slopes never show a gap), tapered steel mast with climbing rungs,
equipment cabinet with the FIELD ACTIVE plate (the mast's field is the stalker safe zone), dipole cross-arms, a glowing band
and a caged beacon lamp (material kit_glow_pylon: nuclear_pylon.gd tints and pulses it per channel), three guy wires.
Node marker_beacon = lamp centre (the script hangs its light there).
"""
import math

from kit_lib import Kit

M0, M1 = 0.62, 5.8                 # mast foot / top heights
S0, S1 = 0.37, 0.17                # mast side length at foot / top
GUY_R, GUY_Z = 3.2, 4.4            # guy anchor radius, height the wires leave the mast


def _half(z):
    """Half side of the tapered mast at height z."""
    return (S0 + (S1 - S0) * (z - M0) / (M1 - M0)) / 2


def relay_pylon():
    k = Kit("relay_pylon")
    k.CYL("footing", 0.85, 1.0, (0, 0, 0.0), k.CON_B, v=8)                          # z -0.5 .. 0.5
    k.CYL("cap", 0.7, 0.12, (0, 0, 0.56), k.CON_T, v=8)
    k.WRAP("haz", (0, 0), 0.862, 0.12, 0.26, 0, 360, k.D_HAZARD, 16)
    k.FRUSTUM("mast", S0 / math.sqrt(2) * 1.0, S1 / math.sqrt(2) * 1.0, M1 - M0, (0, 0, (M0 + M1) / 2), k.MET_D, axis="z")
    for i, z in enumerate(x * 0.45 + 1.0 for x in range(9)):                     # staple rungs up the +x face
        hx = _half(z)
        k.PIPE(f"rung{i}", [(hx - 0.01, -0.09, z), (hx + 0.07, -0.09, z), (hx + 0.07, 0.09, z), (hx - 0.01, 0.09, z)], 0.011,
               k.MET, verts=5)
    # equipment cabinet on the front face, conduit into the footing
    cy = -_half(1.5) - 0.14
    k.B("cabinet", (0.5, 0.28, 0.75), (0, cy, 1.5), k.MET_D, 0.02)
    for i in range(4):
        k.B(f"louvre{i}", (0.36, 0.02, 0.025), (0, cy - 0.14, 1.22 + i * 0.05), k.CABLE, rot=(-25, 0, 0))
    k.B("handle", (0.03, 0.03, 0.12), (0.19, cy - 0.155, 1.55), k.RUST)
    k.B("status", (0.05, 0.012, 0.03), (-0.17, cy - 0.143, 1.8), k.PYLON)
    k.DECAL("plate", (0, cy - 0.1425, 1.62), 0.26, 0.195, k.D_RELAY)
    k.PIPE("conduit", [(0.14, cy + 0.02, 1.12), (0.14, cy + 0.02, 0.62)], 0.03)
    # glow band (the old pylon's collar), cross-arm with dipoles, beacon lamp
    k.CYL("band", _half(3.0) + 0.05, 0.14, (0, 0, 3.0), k.PYLON, v=8)
    for z in (2.9, 3.1):
        k.CYL(f"band_rim{z}", _half(3.0) + 0.07, 0.03, (0, 0, z + (0.085 if z > 3 else -0.085)), k.MET, v=8)
    k.B("arm", (1.45, 0.08, 0.08), (0, 0, 5.0), k.MET)
    for s in (-1, 1):
        k.TUBE(f"dipole{s}", (s * 0.66, 0, 4.55), (s * 0.66, 0, 5.6), 0.02, k.MET)
        for z in (4.8, 5.2):
            k.CYL(f"insul{s}{z}", 0.04, 0.035, (s * 0.66, 0, z), k.CABLE, v=8)
    k.CYL("lamp_base", 0.16, 0.08, (0, 0, M1 + 0.04), k.MET_D, v=10)
    k.CYL("lens", 0.12, 0.3, (0, 0, M1 + 0.23), k.PYLON, v=10)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        k.TUBE(f"cage{i}", (0.15 * math.cos(a), 0.15 * math.sin(a), M1 + 0.08), (0.15 * math.cos(a), 0.15 * math.sin(a), M1 + 0.4),
               0.01, k.MET)
    k.CYL("lamp_cap", 0.17, 0.04, (0, 0, M1 + 0.42), k.MET_D, v=10)
    k.TUBE("rod", (0, 0, M1 + 0.44), (0, 0, M1 + 0.95), 0.012, k.MET)
    # guy wires to half-buried anchors (front two splay out, one behind)
    for i, deg in enumerate((-30, 210, 90)):
        a = math.radians(deg)
        ax, ay = GUY_R * math.cos(a), GUY_R * math.sin(a)
        k.B(f"anchor{i}", (0.34, 0.34, 1.0), (ax, ay, -0.3), k.CON_B, 0.04, rot=(0, 0, deg))
        k.TUBE(f"eye{i}", (ax, ay, 0.2), (ax, ay, 0.3), 0.03, k.RUST)
        hz = _half(GUY_Z)
        k.TUBE(f"guy{i}", (hz * math.cos(a), hz * math.sin(a), GUY_Z), (ax, ay, 0.3), 0.008, k.CABLE, 4)
    k.LIGHT("marker_beacon", (0, 0, M1 + 0.23))
    k.COL_CYL(0.86, 1.0, (0, 0, 0.0), v=8)
    k.COL((S0, S0, M1 - M0), (0, 0, (M0 + M1) / 2))
    k.COL((0.5, 0.28, 0.75), (0, cy, 1.5))
    k.finish(ao_dist=0.9)


PROPS = {"relay_pylon": relay_pylon}
