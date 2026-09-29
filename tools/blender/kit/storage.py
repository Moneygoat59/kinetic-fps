"""Outpost 73 kit: storage. Stackable steel crates, a leaking amber drum, a portable amber cell (the world's energy source).
crate_large  0.9 x 0.65 x 0.6 supply crate, stencilled; flat lid, stacks on itself
crate_small  0.55 x 0.42 x 0.4 amber-hazard case; stacks on crate_large
drum_amber   200 L drum seeping glowing amber into a puddle (light pulses)
amber_cell   0.6 m caged glass cell of glowing amber with a carry handle (light pulses)
"""
from kit_lib import Kit, jitter_verts


def _crate(name, w, d, h, label):
    k = Kit(name)
    k.B("shell", (w - 0.04, d - 0.04, h - 0.04), (0, 0, h / 2), k.MET_D, 0.01)
    k.B("band_b", (w, d, 0.04), (0, 0, 0.02), k.MET)
    k.B("band_t", (w, d, 0.04), (0, 0, h - 0.02), k.MET)
    for sx in (-1, 1):
        for sy in (-1, 1):
            k.B(f"corner{sx}{sy}", (0.05, 0.05, h), (sx * (w / 2 - 0.025), sy * (d / 2 - 0.025), h / 2), k.MET)
        k.B(f"handle{sx}", (0.02, 0.18, 0.035), (sx * (w / 2 + 0.01), 0, h * 0.72), k.RUST)
        for sy in (-1, 1):
            k.B(f"handle_mount{sx}{sy}", (0.02, 0.025, 0.06), (sx * (w / 2 + 0.005), sy * 0.08, h * 0.72), k.MET_D)
        k.B(f"latch{sx}", (0.05, 0.02, 0.06), (sx * w / 4, -d / 2 - 0.005, h - 0.08), k.RUST)
    k.B("rib", (w - 0.12, d + 0.01, 0.03), (0, 0, h / 2), k.MET_D)
    front = -d / 2 + 0.017
    if label == "supply":
        k.DECAL("label", (0, front, h * 0.45), w * 0.65, w * 0.325, k.D_SUPPLY)
    else:
        k.DECAL("label", (0, front, h * 0.3), 0.2, 0.2, k.D_AMBER)
        k.DECAL("haz", (0, -d / 2 - 0.003, h - 0.02), w * 0.5, 0.034, k.D_HAZARD)
    k.DECAL("dust", (0, 0, h + 0.002), w, d, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((w, d, h), (0, 0, h / 2))
    k.finish(ao_dist=0.5)


def crate_large():
    _crate("crate_large", 0.9, 0.65, 0.6, "supply")


def crate_small():
    _crate("crate_small", 0.55, 0.42, 0.4, "amber")


def drum_amber():
    k = Kit("drum_amber")
    body = k.CYL("body", 0.28, 0.86, (0, 0, 0.45), k.DRUM, v=14)
    jitter_verts(body, 0.007, 3)                                                   # dents
    for z in (0.015, 0.875):
        k.CYL(f"rim{z}", 0.29, 0.03, (0, 0, z), k.MET_D, v=14)
    for z in (0.31, 0.6):
        k.CYL(f"hoop{z}", 0.292, 0.025, (0, 0, z), k.MET_D, v=14)
    k.CYL("lid", 0.265, 0.012, (0, 0, 0.886), k.MET, v=14)
    k.CYL("bung", 0.03, 0.02, (0.15, 0.06, 0.896), k.MET, v=8)
    k.CYL("vent", 0.02, 0.02, (-0.14, -0.08, 0.896), k.MET, v=6)
    k.WRAP("label", (0, 0), 0.284, 0.34, 0.57, -68, -22, k.D_AMBER, 4)
    k.WRAP("drips", (0, 0), 0.2845, 0.03, 0.29, -112, -78, k.D_DRIPS, 3)             # seeping from the lower seam
    k.DECAL("crust", (0.02, -0.3, 0.003), 1.0, 1.0, k.D_CRUST, facing="+z", up=(0, 1, 0))
    k.POOL("pool", (0.03, -0.38, 0.006), 0.7, 0.55)
    k.LIGHT("marker_light_amber", (0.03, -0.42, 0.12))
    k.COL_CYL(0.295, 0.89, (0, 0, 0.445))
    k.finish(ao_dist=0.5)


def amber_cell():
    k = Kit("amber_cell")
    for z in (0.03, 0.47):
        k.CYL(f"cap{z}", 0.12, 0.06, (0, 0, z), k.MET_D, v=10)
    k.CYL("core", 0.085, 0.38, (0, 0, 0.25), k.LIQUID, v=10)
    for z in (0.07, 0.43):
        k.CYL(f"collar{z}", 0.095, 0.02, (0, 0, z), k.MET, v=10)
    for i in range(4):
        x, y = ((0.074, 0.074), (-0.074, 0.074), (-0.074, -0.074), (0.074, -0.074))[i]
        k.TUBE(f"bar{i}", (x, y, 0.06), (x, y, 0.44), 0.012, k.MET)
    k.PIPE("handle", [(-0.07, 0, 0.5), (-0.07, 0, 0.58), (0.07, 0, 0.58), (0.07, 0, 0.5)], 0.012)
    k.CYL("valve", 0.02, 0.03, (0.07, -0.06, 0.515), k.RUST, v=8)
    k.WRAP("haz", (0, 0), 0.122, 0.008, 0.052, 0, 360, k.D_HAZARD, 20)
    k.LIGHT("marker_light_amber", (0, 0, 0.25))
    k.COL_CYL(0.125, 0.6, (0, 0, 0.3), v=8)
    k.finish(subdiv=0.2, ao_dist=0.4)


PROPS = {f.__name__: f for f in (crate_large, crate_small, drum_amber, amber_cell)}
