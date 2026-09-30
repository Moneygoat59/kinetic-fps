"""Outpost 73 kit: ventilation ducts. Square sheet-steel ducts big enough to crawl through (clear inside DUCT_W x DUCT_H,
kit_dims.py) that snap together on the 2 m grid. Crawling surface at z 0; a run goes along local Y. Same art rules as the
rest of the kit: near-black steel, dark rust at the seams, dust and streaks inside. Collision: floor, walls and roof, so a
crawling walker stays in the duct (scripts/player_crawl.gd, scripts/world/vent_duct.gd).
duct_straight   a 2 m run centred on the origin (y -1..1), flanged joints at both ends.
duct_bend       a 90 deg corner in one 2 m cell centred on the origin, open on its -Y edge and its +X edge: heading +Y it is
                a right turn; walked the other way (in at +X, out at -Y) it is a left turn.
duct_mouth      the wall end: a flanged frame on the wall face (y 0, front -Y into the room) and a stub DUCT_MOUTH long into
                the wall (+Y); four bent screws where the grille came off. marker_crawl = the crawl spot just inside.
duct_grille     that grille, loose: a louvred panel lying flat (front up), origin at its bottom edge's centre, so a placement
                can lean it against a wall by tilting it about local X.
duct_cap        a blanking plate closing a run at y 0 (its face toward -Y, the duct side), a louvred slot in it with a dim
                amber glow behind (marker_light_amber): the end of the run, for now.
"""
from kit_dims import DUCT_H, DUCT_MOUTH, DUCT_T, DUCT_W
from kit_lib import Kit, jitter_verts

HW, H, T = DUCT_W / 2, DUCT_H, DUCT_T
FLANGE = 0.06                  # how far a joint flange stands proud of the sheet
LIP = 0.05                     # flange depth along the run


def _box(k, name, x0, x1, y0, y1, z0, z1, mat, col=True, into=None):
    """Axis-aligned box from its bounds (local Blender axes); col = also a collision box."""
    size, loc = (x1 - x0, y1 - y0, z1 - z0), ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    if mat is not None:
        k.B(name, size, loc, mat, into=into)
    if col:
        k.COL(size, loc)


def _run_y(k, name, y0, y1, left=True, right=True):
    """Duct along Y from y0 to y1: floor, roof, and the side walls asked for (left = -X)."""
    _box(k, f"{name}_floor", -HW - T, HW + T, y0, y1, -T, 0.0, k.MET_D)
    _box(k, f"{name}_roof", -HW - T, HW + T, y0, y1, H, H + T, k.MET)
    for s, keep in ((-1, left), (1, right)):
        if keep:
            _box(k, f"{name}_wall{s}", s * HW if s > 0 else -HW - T, HW + T if s > 0 else -HW, y0, y1, -T, H + T, k.MET)


def _run_x(k, name, x0, x1, back=True, front=True):
    """Duct along X from x0 to x1 (the bend's second arm): floor, roof, walls at +Y (back) / -Y (front)."""
    _box(k, f"{name}_floor", x0, x1, -HW - T, HW + T, -T, 0.0, k.MET_D)
    _box(k, f"{name}_roof", x0, x1, -HW - T, HW + T, H, H + T, k.MET)
    for s, keep in ((-1, front), (1, back)):
        if keep:
            _box(k, f"{name}_wall{s}", x0, x1, HW if s > 0 else -HW - T, HW + T if s > 0 else -HW, -T, H + T, k.MET)


def _flange(k, name, at, axis="y"):
    """Joint flange: a rectangular collar standing FLANGE proud round the duct at y = at (axis 'y') or x = at ('x'),
    bolted at the corners."""
    o = HW + T + FLANGE
    lo, hi = -T - FLANGE, H + T + FLANGE
    bars = ((-o, o, lo, -T), (-o, o, H + T, hi), (-o, -HW - T, -T, H + T), (HW + T, o, -T, H + T))
    for i, (a0, a1, z0, z1) in enumerate(bars):
        if axis == "y":
            _box(k, f"{name}_fl{i}", a0, a1, at - LIP / 2, at + LIP / 2, z0, z1, k.RUST, col=False)
        else:
            _box(k, f"{name}_fl{i}", at - LIP / 2, at + LIP / 2, a0, a1, z0, z1, k.RUST, col=False)
    for sa in (-1, 1):
        for z in (lo + 0.03, hi - 0.03):
            a = sa * (o - 0.03)
            loc = (a, at, z) if axis == "y" else (at, a, z)
            k.B(f"{name}_bolt{sa}{z}", (0.05, 0.05, 0.05) if axis == "y" else (0.05, 0.05, 0.05), loc, k.MET_D)


def _inside(k, name, x, y, length, along="y", seed=1):
    """What 200 years left inside: a dust bank along the floor, a rust streak down one wall."""
    w, h = (DUCT_W - 0.2, length - 0.2) if along == "y" else (length - 0.2, DUCT_W - 0.2)
    k.DECAL(f"{name}_dust", (x, y, 0.003), w, h, k.D_DUST, facing="+z", up=(0, 1, 0))
    side = 1 if seed % 2 else -1
    if along == "y":
        k.DECAL(f"{name}_streak", (side * (HW - 0.003), y, H / 2), length * 0.6, H * 0.9, k.D_STREAK, facing="-x" if side > 0 else "+x")
    else:
        k.DECAL(f"{name}_streak", (x, side * (HW - 0.003), H / 2), length * 0.6, H * 0.9, k.D_STREAK, facing="-y" if side > 0 else "+y")


def duct_straight():
    k = Kit("duct_straight")
    _run_y(k, "run", -1.0, 1.0)
    for y in (-1.0, 1.0):
        _flange(k, f"j{int(y)}", y - y * LIP / 2)
    _box(k, "seam", -HW, HW, -0.02, 0.02, 0.0, 0.004, k.RUST, col=False)
    _inside(k, "in", 0.0, 0.0, 2.0)
    k.finish(subdiv=0.3, ao_dist=0.7, ground=False)


def duct_bend():
    k = Kit("duct_bend")
    _run_y(k, "a", -1.0, -HW - T, left=True, right=True)                    # the -Y arm up to the corner square
    _box(k, "c_floor", -HW - T, HW + T, -HW - T, HW + T, -T, 0.0, k.MET_D)  # the corner square
    _box(k, "c_roof", -HW - T, HW + T, -HW - T, HW + T, H, H + T, k.MET)
    _box(k, "c_wall_l", -HW - T, -HW, -HW - T, HW + T, -T, H + T, k.MET)     # outside of the turn: -X and +Y
    _box(k, "c_wall_b", -HW - T, HW + T, HW, HW + T, -T, H + T, k.MET)
    _run_x(k, "b", HW + T, 1.0)
    _flange(k, "j_in", -1.0 + LIP / 2, "y")
    _flange(k, "j_out", 1.0 - LIP / 2, "x")
    k.B("vane", (0.02, 0.9, H - 0.1), (0.05, 0.05, H / 2), k.RUST, rot=(0, 0, -45))   # a bent turning vane in the corner
    _inside(k, "in_a", 0.0, -0.4, 1.2, "y", 1)
    _inside(k, "in_b", 0.5, 0.0, 1.0, "x", 2)
    k.finish(subdiv=0.3, ao_dist=0.7, ground=False)


def duct_mouth():
    k = Kit("duct_mouth")
    _run_y(k, "stub", 0.0, DUCT_MOUTH)
    _flange(k, "j", DUCT_MOUTH - LIP / 2)
    o, fw = HW + T + 0.16, 0.05                                            # the frame on the wall face
    for i, (x0, x1, z0, z1) in enumerate(((-o, o, -T - 0.16, -T), (-o, o, H + T, H + T + 0.16), (-o, -HW - T, -T, H + T),
                                          (HW + T, o, -T, H + T))):
        _box(k, f"frame{i}", x0, x1, -fw, 0.0, z0, z1, k.MET_D, col=False)
    _box(k, "sill", -HW, HW, -0.1, 0.0, -0.02, 0.0, k.MET, col=True)        # the bottom lip: where you haul yourself in
    for sx in (-1, 1):
        for z in (-T - 0.08, H + T + 0.08):                                 # screws, bent out when the grille came away
            k.TUBE(f"screw{sx}{z}", (sx * (o - 0.08), -fw, z), (sx * (o - 0.04), -fw - 0.07, z - 0.03), 0.012, k.RUST, 4)
    k.DECAL("streak_below", (0.0, -fw - 0.004, -0.55), 1.1, 0.9, k.D_STREAK, facing="-y")
    k.DECAL("dust_sill", (0.0, 0.5, 0.003), DUCT_W - 0.2, 0.8, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.markers["marker_crawl"] = (0.0, 0.75, 0.0)
    k.finish(subdiv=0.3, ao_dist=0.7, ground=False)


def duct_grille():
    k = Kit("duct_grille")
    w, h, t = DUCT_W + 0.28, H + 0.28, 0.03
    for i, (x0, x1, y0, y1) in enumerate(((-w / 2, w / 2, 0.0, 0.07), (-w / 2, w / 2, h - 0.07, h), (-w / 2, -w / 2 + 0.07, 0.07, h - 0.07),
                                          (w / 2 - 0.07, w / 2, 0.07, h - 0.07))):
        _box(k, f"frame{i}", x0, x1, y0, y1, 0.0, t, k.MET_D, col=False)
    n = 9
    for j in range(n):                                                      # louvres, a couple knocked askew
        y = 0.12 + (h - 0.24) * j / (n - 1)
        slat = k.B(f"slat{j}", (w - 0.14, 0.09, 0.012), (0.0, y, t / 2), k.MET, rot=(40 + (25 if j in (3, 7) else 0), 0, 0))
        if j in (3, 7):
            jitter_verts(slat, 0.01, j)
    k.COL((w, h, t), (0.0, h / 2, t / 2))
    k.finish(subdiv=0.3, ao_dist=0.4)


def duct_cap():
    k = Kit("duct_cap")
    o = HW + T + FLANGE
    lo, hi = -T - FLANGE, H + T + FLANGE
    slot_w, slot_z = 0.7, (0.35, 0.65)                                      # a louvred slot, amber light coming through
    sx = slot_w / 2
    for i, (x0, x1, z0, z1) in enumerate(((-o, o, lo, slot_z[0]), (-o, o, slot_z[1], hi), (-o, -sx, slot_z[0], slot_z[1]),
                                          (sx, o, slot_z[0], slot_z[1]))):
        _box(k, f"plate{i}", x0, x1, 0.0, 0.03, z0, z1, k.MET_D, col=False)
    k.COL((2 * o, 0.03, hi - lo), (0.0, 0.015, (hi + lo) / 2))
    for i, (x0, x1, z0, z1) in enumerate(((-o, o, lo, -T), (-o, o, H + T, hi))):
        _box(k, f"rim{i}", x0, x1, -LIP, 0.0, z0, z1, k.RUST, col=False)
    k.B("glow", (slot_w, 0.01, slot_z[1] - slot_z[0]), (0.0, 0.05, sum(slot_z) / 2), k.AMBER)
    for j in range(5):
        z = slot_z[0] + 0.03 + (slot_z[1] - slot_z[0] - 0.06) * j / 4
        k.B(f"louvre{j}", (slot_w, 0.05, 0.012), (0.0, -0.01, z), k.MET, rot=(-35, 0, 0))
    k.DECAL("streak", (0.25, -0.004, 0.35), 0.5, 0.6, k.D_STREAK, facing="-y")
    k.LIGHT("marker_light_amber", (0.0, -0.35, sum(slot_z) / 2))
    k.finish(subdiv=0.3, ao_dist=0.5, ground=False)


PROPS = {f.__name__: f for f in (duct_straight, duct_bend, duct_mouth, duct_grille, duct_cap)}
