"""Apartment kit: by the front door. Shoes are a height field over a real last outline (ball, waist, heel), sole with toe spring,
collar opening sunk into the upper, tongue, straight bar laces; nothing boxy. Toes of every pair sit on one line (y = -TOE).
shoes_pair     canvas sneakers: navy upper, white sole with a navy stripe, white laces, a pull tab
shoes_pair_b   brown leather derbies: low, polished, stacked heel
shoe_tray      black rubber boot tray with a raised rim (both pairs stand on it; blue tape at its corners in the shell)
"""
import math

import numpy as np

import apt_forms as F
from apt_lib import AptKit

TOE = 0.14
N = 56                                  # frame stations along the shoe, toe -> heel (cosine-spaced: dense at the ends)
SNEAKER = dict(L=0.275, W=0.1, sole=(0.026, 0.032), spring=0.016, k=2.4, cap=0.0, fox=0.0, tongue=True,
               plan=[(0, 0.8), (0.28, 1.0), (0.45, 0.9), (0.62, 0.8), (0.82, 0.83), (1, 0.75)], round=(0.13, 0.09),
               H=[(0, 0.045), (0.12, 0.056), (0.3, 0.064), (0.5, 0.078), (0.62, 0.082), (0.85, 0.088), (1, 0.085)],
               open=(0.775, 0.19, 0.62))
DERBY = dict(L=0.285, W=0.094, sole=(0.013, 0.032), spring=0.012, k=2.8, cap=0.0, fox=0.0, tongue=True,
             plan=[(0, 0.62), (0.26, 1.0), (0.45, 0.88), (0.62, 0.76), (0.82, 0.8), (1, 0.72)], round=(0.17, 0.08),
             H=[(0, 0.034), (0.14, 0.046), (0.3, 0.056), (0.5, 0.066), (0.62, 0.07), (0.85, 0.074), (1, 0.07)],
             open=(0.79, 0.17, 0.6))


def _smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def _frame(p, side):
    """Per-station arrays along the shoe: y, centre x, half width, sole bottom and top, upper height."""
    s = 0.5 - 0.5 * np.cos(np.linspace(0, math.pi, N))
    rt, rh = p["round"]
    ends = np.sqrt(1 - (1 - np.minimum(s / rt, 1)) ** 2) * np.sqrt(1 - (1 - np.minimum((1 - s) / rh, 1)) ** 2)
    hw = p["W"] / 2 * np.interp(s, *zip(*p["plan"])) * ends
    cx = side * p["W"] * 0.06 * (1 - s) ** 2
    zb = p["spring"] * np.maximum(0, 1 - s / 0.22) ** 2
    zt = zb + p["sole"][0] + (p["sole"][1] - p["sole"][0]) * _smooth(0.58, 0.8, s)
    toe = (1 - (1 - np.minimum(s / rt, 1)) ** 2) ** 0.4                   # the toe rounds over in height as well as in plan
    return s, -TOE + s * p["L"], cx, hw, zb, zt, np.interp(s, *zip(*p["H"])) * toe


def _dome(u, k):
    return (1 - np.abs(u) ** k) ** (1 / k)


def _at(fr, s):
    """Shoe frame values at any s (interpolated between stations)."""
    return [np.interp(s, fr[0], a) for a in fr[1:]]


def _upper(p, fr, rays=128, rings=26):
    """Upper as rings round the collar: in (s, u) space the footprint is the rectangle [0, 1] x [-1, 1] and the opening an
    ellipse inside it, so rays from the ellipse to the rectangle give a mesh whose first ring IS the collar edge. The
    opening drops to an insole floor inside that ring. Faces: 0 upper, 1 toe cap / foxing, 2 lining."""
    sc, ls, wu = p["open"]
    verts, faces, mat = [], [], []

    def put(s, u, dz=0.0, floor=False):
        y, cx, hw, _zb, zt, H = _at(fr, s)
        z = zt + 0.014 if floor else zt + H * _dome(u, p["k"]) + dz
        verts.append((cx + u * hw, y, z))
        return z - zt

    zrel, sv, colu = {}, {}, []
    ey = p["W"] / 2                                                         # metric lengths: rays spread evenly along the edge
    edge = [((0, 0), (0, -1), ey), ((0, -1), (1, -1), p["L"]), ((1, -1), (1, 1), 2 * ey), ((1, 1), (0, 1), p["L"]),
            ((0, 1), (0, 0), ey)]
    per = sum(e[2] for e in edge)
    for a in range(rays):
        d = a / rays * per
        for (s0, u0), (s1, u1), ln in edge:
            if d <= ln:
                sb, ub = s0 + (s1 - s0) * d / ln, u0 + (u1 - u0) * d / ln
                break
            d -= ln
        th = math.atan2(ub / wu, (sb - sc) / ls)
        se, ue = sc + ls * math.cos(th), wu * math.sin(th)                   # the collar point on the way out
        for r in range(rings):
            t = 0.5 - 0.5 * math.cos(math.pi * r / (rings - 1))
            sv[a, r] = se + (sb - se) * t
            zrel[a, r] = put(sv[a, r], ue + (ub - ue) * t, 0.005 * math.exp(-(t / 0.05) ** 2))
        colu.append(ue)
    base = len(verts)
    for a in range(rays):                                                    # inside the collar: lining wall, insole
        put(sc + (sv[a, 0] - sc) * 0.9, colu[a] * 0.9, floor=True)
    put(sc, 0.0, floor=True)
    for a in range(rays):
        b = (a + 1) % rays
        for r in range(rings - 1):
            faces.append([a * rings + r, b * rings + r, b * rings + r + 1, a * rings + r + 1])
            s_mid = (sv[a, r] + sv[b, r] + sv[a, r + 1] + sv[b, r + 1]) / 4
            low = min(zrel[a, r], zrel[b, r], zrel[a, r + 1], zrel[b, r + 1]) < p["fox"]
            mat.append(1 if (s_mid < p["cap"] or low) else 0)
        faces.append([a * rings, base + a, base + b, b * rings])
        faces.append([base + a, base + rays, base + b])
        mat += [2, 2]
    return verts, faces, mat


def _sole(fr, lip=0.003):
    """Sole slab round the outline: bands 0 (tread) / 1 (stripe) / 2 (wall) up its side."""
    s, y, cx, hw, zb, zt, _H = fr
    levels = [lambda i: zb[i], lambda i: zb[i] + 0.006, lambda i: zb[i] + 0.009, lambda i: zt[i]]
    ring = [(i, 1) for i in range(N)] + [(i, -1) for i in reversed(range(N))]
    verts, faces, mat = [], [], []
    for lv, zf in enumerate(levels):
        for i, sd in ring:
            inset = 0.002 if lv == 0 else 0.0
            verts.append((cx[i] + sd * max(hw[i] + lip - inset, 0.0005), y[i], zf(i)))
    n = len(ring)
    for lv in range(3):
        for a in range(n):
            b = (a + 1) % n
            faces.append([lv * n + a, lv * n + b, (lv + 1) * n + b, (lv + 1) * n + a])
            mat.append(1 if lv == 1 else 0)
    for off in (0, 3 * n):                                              # bottom and top: strips across the outline
        for i in range(N - 1):
            faces.append([off + i, off + i + 1, off + n - 2 - i, off + n - 1 - i])
            mat.append(0)
    return verts, faces, mat


def _tongue(p, fr, t=0.003):
    s, y, cx, hw, _zb, zt, H = fr
    rows = [i for i in range(N) if 0.38 <= s[i] <= 0.67]
    us = np.linspace(-0.5, 0.5, 7)
    top = [[(cx[i] + u * hw[i], y[i], zt[i] + H[i] * _dome(u, p["k"]) + 0.004 + max(0.0, s[i] - 0.56) * 0.2) for u in us]
           for i in rows]
    return top, rows


def shoe(k, x, p, mats, lace, name):
    side = -1 if x < 0 else 1
    fr = _frame(p, -side)
    v, f, m = _upper(p, fr)
    k.parts.append(F.mesh(f"{name}_upper", v, f, [mats[0], mats[1], mats[2]], m, (x, 0, 0), weld=True))
    v, f, m = _sole(fr)
    k.parts.append(F.mesh(f"{name}_sole", v, f, [mats[3], mats[4]], m, (x, 0, 0), weld=True))
    top, rows = _tongue(p, fr)
    k.parts.append(F.sheet(f"{name}_tongue", top, 0.003, mats[0], (x, 0, 0)))
    for n, r in enumerate(np.linspace(1, len(rows) - 3, 5).astype(int)):                    # bar laces, dead straight
        k.PIPE(f"{name}_lace{n}", [(x + a[0], a[1], a[2] + 0.002) for a in top[r][1:-1]], 0.0022, lace, verts=6)
    if p is SNEAKER:
        s, y, cx, _hw, _zb, zt, H = fr
        k.B(f"{name}_tab", (0.016, 0.005, 0.028), (x + cx[-1], y[-1] + 0.002, zt[-1] + H[-1] - 0.006), mats[0], 0.002)


def shoes_pair():
    k = AptKit("shoes_pair")
    for x in (-0.062, 0.062):
        shoe(k, x, SNEAKER, [k.CANVAS, k.RUBBER, k.CORD, k.RUBBER, k.CANVAS], k.LINEN, f"s{x}")
    k.COL((0.24, 0.28, 0.1), (0, 0, 0.05))
    k.finish(subdiv=1.0, ao_dist=0.1)


def shoes_pair_b():
    k = AptKit("shoes_pair_b")
    for x in (-0.06, 0.06):
        shoe(k, x, DERBY, [k.LEATHER, k.LEATHER, k.CORD, k.SOLE, k.SOLE], k.CORD, f"d{x}")
    k.COL((0.23, 0.29, 0.09), (0, 0, 0.045))
    k.finish(subdiv=1.0, ao_dist=0.1)


def shoe_tray():
    k = AptKit("shoe_tray")
    w, d, h = 0.62, 0.36, 0.022
    k.B("base", (w, d, 0.006), (0, 0, 0.003), k.SOLE)
    for s in (-1, 1):
        k.B(f"rim_x{s}", (0.014, d, h), (s * (w / 2 - 0.007), 0, h / 2), k.SOLE, 0.004)
        k.B(f"rim_y{s}", (w, 0.014, h), (0, s * (d / 2 - 0.007), h / 2), k.SOLE, 0.004)
    for i in range(9):                                                                       # moulded ribs
        k.B(f"rib{i}", (0.006, d - 0.06, 0.003), (-0.24 + i * 0.06, 0, 0.0075), k.SOLE)
    k.COL((w, d, 0.02), (0, 0, 0.01))
    k.finish(subdiv=1.0, ao_dist=0.1)


PROPS = {f.__name__: f for f in (shoes_pair, shoes_pair_b, shoe_tray)}
