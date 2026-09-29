"""Rail tunnel kit: shared geometry. Every tunnel piece is built along a TunnelPath (straight or a constant-radius curve)
by sweeping 2D cross-sections (x across, z up) along it, so straights and curves share one builder and join seamlessly.
Dimensions: kit_dims.py (TUN_*, TRACK_X, WALK_*, ...). Pieces: tunnels.py.

Frame: the path's centreline is the tunnel centre (x 0) at invert level (z 0); s = metres along it from the entry face.
At s: pos(s) + right(s) * x + up * z. A piece's marker_next sits at pos(L) with the exit heading (TunnelPath.exit_yaw).
"""
import math

import bmesh
from mathutils import Vector

import ps1_lib as L
from kit_lib import Kit, _t, glow
from kit_dims import GAUGE, MAIN_R, MAIN_X, MAIN_Z, POWER_X, RAIL_TOP, TRACK_X, TUN_HW, TUN_LEN, TUN_LINING, TUN_RIB, \
    TUN_SLAB, TUN_SPRING, WALK_X0, WALK_Z

UP = Vector((0.0, 0.0, 1.0))
ARCH_SEGS = 14
EMERGENCY_RGB = (0.55, 0.2, 1.0)        # the emergency system's colour (EmergencyPylon.COLOR in Godot re-tints it at runtime)


class TunnelKit(Kit):
    """The kit plus the line's own materials: the dim amber conductor, dead lamp glass, the emergency glow and paint,
    the line's stencils and plates (python tools/blender/tunnel_textures.py)."""

    def __init__(self, name):
        super().__init__(name)
        self.RAIL_GLOW = glow("kit_glow_rail", (1.0, 0.3, 0.03), 0.45)
        self.GLASS_DEAD = L.material("kit_glass_dead", (0.012, 0.011, 0.014))
        self.EMERG = glow("kit_glow_emergency", EMERGENCY_RGB, 1.4)
        self.VIOLET = L.material("kit_violet", (0.022, 0.009, 0.045))          # the emergency system's paint, faded
        self.ROCK = L.tex_material("kit_rock", _t("basalt.png"), tint=(0.55, 0.52, 0.58))
        d = lambda n, f: L.decal_material(n, _t(f))  # noqa: E731
        self.D_LINE, self.D_REFUGE = d("kit_decal_tun_line", "tun_stencil_line.png"), d("kit_decal_tun_refuge", "tun_refuge.png")
        self.D_EMERG, self.D_SECTION = d("kit_decal_tun_emergency", "tun_plate_emergency.png"), d("kit_decal_tun_section", "tun_section.png")
        self.D_CRACK = d("kit_decal_crack", "decal_crack.png")
        self.D_JUNC = d("kit_decal_tun_junction", "tun_interchange.png")


class TunnelPath:
    """turn_deg 0 = straight along +Y; > 0 turns right (toward +X), < 0 left, over `length` metres of centreline."""

    def __init__(self, turn_deg=0.0, length=TUN_LEN):
        self.length = length
        self.turn = math.radians(turn_deg)
        self.sign = 1.0 if turn_deg >= 0 else -1.0
        self.radius = length / abs(self.turn) if self.turn else 0.0

    def frame(self, s):
        """(position, tangent, right) at s."""
        if not self.turn:
            return Vector((0.0, s, 0.0)), Vector((0.0, 1.0, 0.0)), Vector((1.0, 0.0, 0.0))
        t, r, g = s / self.radius, self.radius, self.sign
        pos = Vector((g * (r - r * math.cos(t)), r * math.sin(t), 0.0))
        return pos, Vector((g * math.sin(t), math.cos(t), 0.0)), Vector((math.cos(t), -g * math.sin(t), 0.0))

    def at(self, s, x, z=0.0):
        pos, _t, right = self.frame(s)
        return pos + right * x + UP * z

    def yaw(self, s):
        """Degrees about Z that turn +Y onto the tangent at s (rotation for parts placed along the path)."""
        return -math.degrees(self.sign * s / self.radius) if self.turn else 0.0

    def stations(self, s0, s1, step=1.0):
        n = max(1, int(math.ceil((s1 - s0) / step - 1e-6))) if self.turn else 1
        return [s0 + (s1 - s0) * i / n for i in range(n + 1)]


def _clockwise(poly):
    area = sum(poly[i][0] * poly[(i + 1) % len(poly)][1] - poly[(i + 1) % len(poly)][0] * poly[i][1] for i in range(len(poly)))
    return list(reversed(poly)) if area > 0 else list(poly)


def sweep(name, poly, path, s0, s1, mat, caps=True, step=1.0):
    """Solid swept along the path from s0 to s1: poly = closed cross-section [(x, z), ...] (any winding, outward normals).
    caps=False leaves the ends open."""
    poly = _clockwise(poly)
    n = len(poly)
    bm = bmesh.new()
    rings = []
    for s in path.stations(s0, s1, step):
        rings.append([bm.verts.new(path.at(s, x, z)) for x, z in poly])
    for a, b in zip(rings, rings[1:]):
        for j in range(n):
            k = (j + 1) % n
            bm.faces.new((a[j], a[k], b[k], b[j]))
    if caps:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    o = L._bm_object(name, bm, mat)
    return o


def arch(d=0.0, z0=0.0):
    """The lining's inner face offset d inward (d < 0: outward), as an open polyline from the left wall foot over the
    crown to the right wall foot."""
    r = TUN_HW - d
    pts = [(-r, z0), (-r, TUN_SPRING)]
    for i in range(1, ARCH_SEGS):
        a = math.pi * (1.0 - i / ARCH_SEGS)
        pts.append((r * math.cos(a), TUN_SPRING + r * math.sin(a)))
    return pts + [(r, TUN_SPRING), (r, z0)]


def arch_z(x, d=0.0):
    """Height of the (offset) inner face above x (on the arch or the walls)."""
    r = TUN_HW - d
    return TUN_SPRING + math.sqrt(max(r * r - x * x, 0.0))


def band(d_in, d_out, z0=0.0):
    """Closed cross-section between two offsets of the inner face (a lining ring, a rib, a portal)."""
    return arch(d_in, z0) + list(reversed(arch(d_out, z0)))


def rect(x0, x1, z0, z1):
    return [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]


def circle(cx, cz, r, n=8):
    return [(cx + r * math.cos(i * math.tau / n + math.pi / n), cz + r * math.sin(i * math.tau / n + math.pi / n)) for i in range(n)]


def at_rot(k, name, size, path, s, x, z, mat, pitch=0.0, into=None):
    """A box of `size` (x across, y along, z up) centred at (s, x, z), turned with the path."""
    return k.B(name, size, tuple(path.at(s, x, z)), mat, rot=(pitch, 0, path.yaw(s)), into=into)


def runs(s0, s1, skip):
    """Split [s0, s1] around the skipped intervals."""
    out, cur = [], s0
    for a, b in sorted(skip):
        if a > cur:
            out.append((cur, min(a, s1)))
        cur = max(cur, b)
    if cur < s1:
        out.append((cur, s1))
    return [(a, b) for a, b in out if b - a > 0.05]


# ------------------------------------------------------------------ the shell: invert slab, lining, rings, walkway
def shell(k, path, s0=0.0, s1=None, walk_skip=(), lining=True):
    """Slab + lining + walkway (cess) from s0 to s1, with collision. Returns the lining object (to cut niches into)."""
    s1 = path.length if s1 is None else s1
    slab = sweep("slab", rect(-TUN_HW - TUN_LINING, TUN_HW + TUN_LINING, -TUN_SLAB, 0.0), path, s0, s1, k.CON_T)
    k.parts.append(slab)
    k.COL_COPY(slab)
    lin = None
    if lining:
        lin = sweep("lining", band(0.0, -TUN_LINING, -0.02), path, s0, s1, k.CON)
        k.parts.append(lin)
    for a, b in runs(s0, s1, walk_skip):
        walk = sweep(f"walk{a:.1f}", rect(WALK_X0, TUN_HW + 0.02, -0.02, WALK_Z), path, a, b, k.CON_T)
        k.parts.append(walk)
        k.COL_COPY(walk)
        k.parts.append(sweep(f"coping{a:.1f}", rect(WALK_X0 - 0.04, WALK_X0 + 0.16, WALK_Z - 0.06, WALK_Z + 0.02), path, a, b, k.CON_B))
    return lin


def ribs(k, path, s0=0.0, s1=None, skip=()):
    """Segment rings: a band proud of the lining every TUN_RIB metres (half bands at a piece's ends meet the next piece's)."""
    s1 = path.length if s1 is None else s1
    s = s0
    while s <= s1 + 1e-6:
        a, b = max(s0, s - 0.11), min(s1, s + 0.11)
        if not any(x0 <= s <= x1 for x0, x1 in skip) and b - a > 0.02:
            k.parts.append(sweep(f"rib{s:.1f}", band(0.07, -0.05, 0.0), path, a, b, k.CON_B))
        s += TUN_RIB


def lining_col(k, lin):
    if lin is not None:
        k.COL_COPY(lin)


# ------------------------------------------------------------------ track: sleepers, rails, the amber conductor rail
RAIL = [(-0.065, 0.05), (0.065, 0.05), (0.065, 0.065), (0.012, 0.075), (0.012, 0.16), (0.036, 0.165), (0.036, RAIL_TOP),
        (-0.036, RAIL_TOP), (-0.036, 0.165), (-0.012, 0.16), (-0.012, 0.075), (-0.065, 0.065)]


def track(k, path, s0=0.0, s1=None, rails=True):
    s1 = path.length if s1 is None else s1
    n = int((s1 - s0) / 0.65)
    for i in range(n):
        s = s0 + 0.325 + i * (s1 - s0 - 0.65) / max(n - 1, 1)
        at_rot(k, f"sleeper{i}", (2.5, 0.26, 0.14), path, s, TRACK_X, -0.02, k.CON_B)
    if rails:
        for side in (-1, 1):
            x = TRACK_X + side * GAUGE / 2
            k.parts.append(sweep(f"rail{side}", [(x + px, pz) for px, pz in RAIL], path, s0, s1, k.MET, step=0.5))
    power_rail(k, path, s0, s1)


def power_rail(k, path, s0, s1):
    """The amber conductor: a sealed glass channel of amber (a faint line along the floor, the one light the line still
    carries) in a steel case on dark insulators, a hood over its wall side."""
    k.parts.append(sweep("power_core", rect(POWER_X - 0.03, POWER_X + 0.03, 0.26, 0.31), path, s0, s1, k.RAIL_GLOW, step=0.5))
    k.parts.append(sweep("power_case", rect(POWER_X - 0.05, POWER_X + 0.05, 0.23, 0.26), path, s0, s1, k.MET_D, step=0.5))
    k.parts.append(sweep("power_lip", rect(POWER_X - 0.05, POWER_X - 0.03, 0.26, 0.33), path, s0, s1, k.MET_D, step=0.5))
    k.parts.append(sweep("power_hood", rect(POWER_X - 0.2, POWER_X - 0.01, 0.37, 0.4), path, s0, s1, k.MET_D, step=0.5))
    s = s0 + 1.0
    while s < s1:
        k.CYL(f"insul{s:.1f}", 0.045, 0.16, tuple(path.at(s, POWER_X, 0.14)), k.CABLE, v=8)
        k.CYL(f"insul_foot{s:.1f}", 0.07, 0.04, tuple(path.at(s, POWER_X, 0.04)), k.MET_D, v=8)
        at_rot(k, f"hood_post{s:.1f}", (0.04, 0.04, 0.4), path, s, POWER_X - 0.18, 0.2, k.RUST)
        s += 2.0
    k.parts.append(sweep("drain", rect(-TUN_HW + 0.02, -TUN_HW + 0.32, 0.0, 0.025), path, s0, s1, k.PLATE))


# ------------------------------------------------------------------ services on the walls and the crown
def services(k, path, s0=0.0, s1=None, right_skip=(), left_skip=(), glass=None):
    """Amber main on the left wall (with a sight glass at s = glass), cable racks and handrail on the right wall over the
    walkway, the leaky-feeder radio cable along the crown, a dead crown lamp every 8 m."""
    s1 = path.length if s1 is None else s1
    glass_at = [] if glass is None else [(glass - 0.35, glass + 0.35)]
    for a, b in runs(s0, s1, list(left_skip) + glass_at):
        k.parts.append(sweep(f"main{a:.1f}", circle(MAIN_X, MAIN_Z, MAIN_R, 10), path, a, b, k.MET_D, step=0.5))
    for g0, g1 in glass_at:
        k.parts.append(sweep("main_glass", circle(MAIN_X, MAIN_Z, MAIN_R * 0.92, 10), path, g0, g1, k.LIQUID))
        for c in (g0, g1):
            k.parts.append(sweep(f"collar{c:.1f}", circle(MAIN_X, MAIN_Z, MAIN_R + 0.04, 10), path, c - 0.05, c + 0.05, k.RUST))
        k.DECAL("glass_drips", tuple(path.at(glass, -TUN_HW + 0.004, MAIN_Z - 0.75)), 0.6, 1.1, k.D_DRIPS,
                facing=tuple(path.frame(glass)[2]))
    s = s0 + 1.0
    while s < s1:
        if not any(a - 0.2 <= s <= b + 0.2 for a, b in left_skip):
            at_rot(k, f"main_bracket{s:.1f}", (0.34, 0.06, 0.06), path, s, MAIN_X - 0.05, MAIN_Z - MAIN_R - 0.03, k.RUST)
        if not any(a - 0.2 <= s <= b + 0.2 for a, b in right_skip):
            at_rot(k, f"rack{s:.1f}", (0.34, 0.05, 0.05), path, s, TUN_HW - 0.17, 2.02, k.RUST)
            at_rot(k, f"rack_up{s:.1f}", (0.04, 0.05, 0.45), path, s, TUN_HW - 0.02, 2.2, k.RUST)
            at_rot(k, f"rail_arm{s:.1f}", (0.1, 0.04, 0.04), path, s, TUN_HW - 0.05, WALK_Z + 0.98, k.RUST)
        fx = -0.9
        at_rot(k, f"feeder_clip{s:.1f}", (0.05, 0.04, 0.12), path, s, fx, arch_z(fx) - 0.06, k.MET_D)
        s += 2.0
    for a, b in runs(s0, s1, right_skip):
        for i, z in enumerate((2.08, 2.16, 2.24)):
            k.parts.append(sweep(f"cable{i}_{a:.1f}", circle(TUN_HW - 0.12 - 0.05 * i, z, 0.028, 6), path, a, b, k.CABLE, step=0.5))
        k.parts.append(sweep(f"handrail{a:.1f}", circle(TUN_HW - 0.1, WALK_Z + 1.0, 0.024, 6), path, a, b, k.RUST, step=0.5))
    fx = -0.9
    k.parts.append(sweep("feeder", circle(fx, arch_z(fx) - 0.13, 0.022, 6), path, s0, s1, k.CABLE, step=0.5))
    lamp(k, path, (s0 + s1) / 2)


def lamp(k, path, s):
    """A caged crown lamp, long dead: dark glass behind a wire guard."""
    x = 0.9
    z = arch_z(x) - 0.12
    at_rot(k, f"lamp_base{s:.1f}", (0.34, 0.5, 0.1), path, s, x, z, k.MET_D)
    at_rot(k, f"lamp_glass{s:.1f}", (0.24, 0.4, 0.08), path, s, x, z - 0.08, k.GLASS_DEAD)
    for i, dy in enumerate((-0.16, 0.0, 0.16)):
        k.TUBE(f"lamp_guard{s:.1f}_{i}", tuple(path.at(s + dy, x - 0.15, z - 0.05)), tuple(path.at(s + dy, x + 0.15, z - 0.05)),
               0.008, k.MET, 4)


def grime(k, path, s0=0.0, s1=None, seed=0):
    """Dust along the walkway, streaks down both walls."""
    s1 = path.length if s1 is None else s1
    step = 4.0
    s = s0 + step / 2
    i = seed
    while s < s1:
        _pos, tangent, right = path.frame(s)
        fwd = tuple(tangent)
        if i % 2 == 0:
            k.DECAL(f"dust_walk{s:.1f}", tuple(path.at(s, (WALK_X0 + TUN_HW) / 2 + 0.2, WALK_Z + 0.004)), 0.7, step * 0.6,
                    k.D_DUST, facing="+z", up=fwd)
        side = 1 if i % 2 else -1
        k.DECAL(f"streak{s:.1f}", tuple(path.at(s + 0.6, side * (TUN_HW - 0.005), 2.7 + 0.3 * (i % 2))), 1.4, 2.4, k.D_STREAK,
                facing=tuple(-right * side))
        s += step
        i += 1


def next_marker(k, path):
    """marker_next at the exit face, turned to the exit heading."""
    e = L.empty("marker_next", tuple(path.at(path.length, 0.0)))
    e.rotation_euler = (0.0, 0.0, math.radians(path.yaw(path.length)))
    return e


def empty_at(k, name, loc, yaw_deg=0.0):
    e = L.empty(name, loc)
    e.rotation_euler = (0.0, 0.0, math.radians(yaw_deg))
    return e
