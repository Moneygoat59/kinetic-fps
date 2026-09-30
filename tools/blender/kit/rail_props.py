"""Rail tunnel kit: things that stand on the line. Built with TunnelKit (tunnel_lib.py): its violet emergency glow and paint.
emergency_pylon  the line's emergency post, the underground cousin of the relay mast (relay.py): concrete foot, steel post,
                 a violet-painted call cabinet (EMERGENCY plate, handset on its hook, pull handle, status lamp), a glowing
                 band and a caged beacon on top (material kit_glow_emergency: EmergencyPylon re-tints and drives it),
                 a feeder tap cable up and back into the wall. Fits a tunnel_refuge niche (2.25 m tall, 0.5 x 0.45 m).
                 Origin = base centre, front -Y (Godot +Z). marker_beacon = lamp centre.
rail_buffer      a buffer stop for the end of a track: beam with two buffers and hazard stripes, raked struts back along
                 the rails, a dead lamp. Origin = track centre on the invert, front (buffers) -Y; the rails run on under it.
platform_bench   a station bench (tunnel_station): perforated steel seat and back on two cast-iron frames, bolted to the
                 platform. 1.8 x 0.6 m, seat at 0.45. Origin = base centre, front -Y (sit facing the track).
"""
import math

from kit_dims import GAUGE
from tunnel_lib import TunnelKit

POST_TOP = 1.95


def emergency_pylon():
    k = TunnelKit("emergency_pylon")
    k.B("foot", (0.5, 0.44, 0.14), (0, 0.02, 0.07), k.CON_T, 0.02)
    k.DECAL("foot_haz", (0, -0.2, 0.07), 0.46, 0.1, k.D_HAZARD)
    k.B("post", (0.15, 0.15, POST_TOP - 0.14), (0, 0.08, (POST_TOP + 0.14) / 2), k.MET_D)
    cy, cz = -0.06, 1.2                                             # call cabinet on the post's front
    k.B("cabinet", (0.4, 0.22, 0.56), (0, cy, cz), k.VIOLET, 0.015)
    k.B("seam", (0.004, 0.005, 0.5), (0.0, cy - 0.111, cz), k.CABLE)
    for s in (-1, 1):
        k.B(f"hinge{s}", (0.02, 0.03, 0.07), (s * 0.2, cy - 0.1, cz + s * 0.18), k.RUST)
    k.DECAL("plate", (0.0, cy - 0.112, cz + 0.1), 0.3, 0.225, k.D_EMERG)
    k.B("status", (0.04, 0.012, 0.03), (0.14, cy - 0.114, cz + 0.24), k.EMERG)
    k.B("pull", (0.18, 0.05, 0.035), (0.0, cy - 0.135, cz - 0.19), k.RUST)
    for s in (-1, 1):
        k.B(f"pull_arm{s}", (0.02, 0.04, 0.02), (s * 0.08, cy - 0.115, cz - 0.19), k.RUST)
    k.B("hook", (0.03, 0.08, 0.03), (-0.22, cy - 0.02, cz + 0.14), k.MET)        # the handset, hung on the side
    k.B("handset", (0.06, 0.07, 0.22), (-0.235, cy - 0.04, cz + 0.02), k.CABLE, 0.01)
    coil = [(-0.235, cy - 0.04, cz - 0.09)] + [(-0.23 + 0.02 * math.sin(i * 2.1), cy - 0.02, cz - 0.12 - 0.04 * i) for i in range(4)]
    coil += [(-0.19, cy, cz - 0.27)]
    k.PIPE("cord", coil, 0.008, k.CABLE, verts=4)
    k.PIPE("conduit", [(0.12, cy + 0.06, cz - 0.28), (0.12, cy + 0.06, 0.14)], 0.022)
    k.B("band", (0.19, 0.19, 0.13), (0, 0.08, 1.62), k.EMERG)                      # the glowing collar
    for z in (1.545, 1.695):
        k.B(f"band_rim{z}", (0.21, 0.21, 0.025), (0, 0.08, z), k.MET)
    k.CYL("lamp_base", 0.1, 0.06, (0, 0.08, POST_TOP + 0.03), k.MET_D, v=10)
    k.CYL("lens", 0.07, 0.18, (0, 0.08, POST_TOP + 0.15), k.EMERG, v=10)
    for i in range(4):
        a = math.radians(45 + 90 * i)
        x, y = 0.09 * math.cos(a), 0.08 + 0.09 * math.sin(a)
        k.TUBE(f"cage{i}", (x, y, POST_TOP + 0.05), (x, y, POST_TOP + 0.26), 0.008, k.MET)
    k.CYL("lamp_cap", 0.105, 0.03, (0, 0.08, POST_TOP + 0.27), k.MET_D, v=10)
    k.PIPE("feeder_tap", [(0.0, 0.14, POST_TOP - 0.1), (0.0, 0.22, POST_TOP - 0.1), (0.0, 0.26, POST_TOP + 0.2)], 0.012, k.CABLE,
           verts=5)
    k.LIGHT("marker_beacon", (0, 0.08, POST_TOP + 0.15))
    k.COL((0.5, 0.44, POST_TOP), (0, 0.02, POST_TOP / 2))
    k.finish(subdiv=0.2, ao_dist=0.5)


def rail_buffer():
    k = TunnelKit("rail_buffer")
    g = GAUGE / 2
    k.B("beam", (2.3, 0.34, 0.42), (0, 0, 0.95), k.MET_D, 0.02)
    k.DECAL("beam_haz", (0, -0.176, 0.95), 2.2, 0.36, k.D_HAZARD)
    for s in (-1, 1):
        x = s * 0.85
        k.CYL(f"plunger{s}", 0.12, 0.42, (x, -0.38, 0.95), k.MET, "y", 10)
        k.CYL(f"sleeve{s}", 0.16, 0.2, (x, -0.24, 0.95), k.MET_D, "y", 10)
        k.CYL(f"head{s}", 0.22, 0.06, (x, -0.62, 0.95), k.RUST, "y", 12)
        k.B(f"upright{s}", (0.14, 0.14, 0.8), (s * g, 0.05, 0.5), k.RUST)
        k.TUBE(f"strut{s}", (s * g, 0.15, 0.85), (s * g, 1.75, 0.24), 0.055, k.RUST, 6)
        k.B(f"sole{s}", (0.2, 1.95, 0.05), (s * g, 0.85, 0.225), k.RUST)
        for y in (0.2, 0.9, 1.6):
            k.B(f"clamp{s}{y}", (0.26, 0.08, 0.08), (s * g, y, 0.21), k.MET_D)
    k.CYL("lamp", 0.08, 0.1, (0.0, -0.05, 1.21), k.GLASS_DEAD, v=10)
    k.CYL("lamp_hood", 0.1, 0.03, (0.0, -0.05, 1.28), k.MET_D, v=10)
    k.COL((2.3, 0.4, 1.2), (0, -0.05, 0.6))
    k.COL((0.1, 1.7, 0.8), (-g, 0.95, 0.4))
    k.COL((0.1, 1.7, 0.8), (g, 0.95, 0.4))
    k.finish(subdiv=0.25, ao_dist=0.6)


def platform_bench():
    k = TunnelKit("platform_bench")
    w, sz = 1.8, 0.45
    for s in (-1, 1):                                              # cast frames: a foot, a leg, the seat arm, the back
        x = s * (w / 2 - 0.12)
        k.B(f"foot{s}", (0.08, 0.56, 0.05), (x, 0.0, 0.025), k.MET_D)
        k.B(f"leg{s}", (0.06, 0.06, sz - 0.05), (x, -0.06, sz / 2), k.MET_D)
        k.B(f"arm{s}", (0.06, 0.48, 0.05), (x, -0.02, sz - 0.02), k.MET_D)
        k.B(f"back_post{s}", (0.06, 0.05, 0.5), (x, 0.24, sz + 0.2), k.MET_D, rot=(-12, 0, 0))
        for dy in (-0.2, 0.2):
            k.CYL(f"bolt{s}{dy}", 0.018, 0.02, (x, dy, 0.055), k.RUST, v=6)
    for i in range(4):                                             # seat and back: perforated plate in strips
        k.B(f"seat{i}", (w, 0.1, 0.025), (0.0, -0.2 + 0.115 * i, sz + 0.01), k.PLATE)
    for i in range(3):
        z = sz + 0.12 + 0.13 * i
        k.B(f"back{i}", (w, 0.025, 0.1), (0.0, 0.2 + 0.028 * (z - sz) / 0.13, z), k.PLATE, rot=(-12, 0, 0))
    k.COL((w, 0.52, sz + 0.02), (0.0, 0.0, (sz + 0.02) / 2))
    k.COL((w, 0.12, 0.45), (0.0, 0.26, sz + 0.25))
    k.finish(subdiv=0.2, ao_dist=0.4)


PROPS = {"emergency_pylon": emergency_pylon, "rail_buffer": rail_buffer, "platform_bench": platform_bench}
