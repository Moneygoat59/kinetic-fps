"""Outpost 73 kit: the route key. Each well's relay handshake key, left in its open steel case on the desk beside the relay
CRT; the hub's router will not bring a dry route back online without it (Outposts 02 / 03 hand it to the player).
route_key  tabletop, 0.3 x 0.2 m case, lid standing open. Node `key` (the key itself, amber-coded bow, lies in the foam;
           the pickup frees it), status lamp kit_glow_key (tinted in the route's channel colour and blinked by
           scripts/bunker/bunker_key.gd). No collision (it sits on table_steel).
"""
from kit_lib import Kit, glow
import ps1_lib as L

W, D, H = 0.3, 0.2, 0.045        # case tray
KZ = H + 0.01                    # top of the foam: the key lies here


def route_key():
    k = Kit("route_key")
    lamp = glow("kit_glow_key", (1.0, 0.55, 0.12), 1.2)
    k.B("tray", (W, D, H), (0, 0, H / 2), k.MET_D, 0.006)
    k.B("foam", (W - 0.03, D - 0.03, 0.012), (0, 0, H + 0.004), k.CABLE)
    k.B("latch", (0.04, 0.012, 0.02), (0, -D / 2 - 0.004, H - 0.012), k.MET)
    k.CYL("lamp", 0.008, 0.008, (0.1, -D / 2 - 0.003, H * 0.5), lamp, "y", 8)
    k.B("lamp_bezel", (0.026, 0.004, 0.022), (0.1, -D / 2 - 0.001, H * 0.5), k.MET)
    lid = [L.box("lid", (W, D, 0.018), (0, 0, H + 0.009), k.MET_D),
           L.box("lid_rib", (W - 0.06, 0.02, 0.008), (0, -D / 2 + 0.03, H + 0.022), k.MET),
           L.box("lid_haz", (W - 0.02, 0.012, 0.002), (0, 0.02, H - 0.0005), k.HAZ)]       # inside face, hazard strip
    L.rotate_about(lid, (0, D / 2, H), (-104, 0, 0))                                        # standing open, leaning back
    k.parts.extend(lid)
    for x in (-0.09, 0.09):
        k.CYL(f"hinge{x}", 0.007, 0.04, (x, D / 2, H), k.MET, "x", 6)
    key = k.PIVOT("key", (0, 0, KZ))
    k.B("key_bow", (0.05, 0.038, 0.012), (-0.06, 0, KZ + 0.006), k.MET, 0.003, into=key)
    k.B("key_code", (0.03, 0.018, 0.003), (-0.06, 0, KZ + 0.0125), k.AMBER, into=key)          # amber-coded grip
    k.CYL("key_collar", 0.012, 0.02, (-0.026, 0, KZ + 0.006), k.MET_D, "x", 8, into=key)
    k.B("key_shaft", (0.085, 0.014, 0.008), (0.026, 0, KZ + 0.005), k.MET, into=key)
    for i, x in enumerate((0.046, 0.062)):
        k.B(f"key_bit{i}", (0.01, 0.008, 0.008), (x, 0.01, KZ + 0.005), k.MET, into=key)
    k.CYL("key_ring", 0.012, 0.004, (-0.094, 0, KZ + 0.004), k.MET_D, "z", 8, into=key)
    k.B("key_tag", (0.04, 0.026, 0.003), (-0.12, 0.012, KZ + 0.002), k.RUST, into=key)
    k.DECAL("dust", (0.02, -0.02, KZ + 0.0015), W - 0.04, D - 0.04, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.finish(subdiv=0.1, ao_dist=0.08)


PROPS = {f.__name__: f for f in (route_key,)}
