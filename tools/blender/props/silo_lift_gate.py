"""Missile Silo 00's lift gates: the cage's room-side and hall-side gates, the level 09 landing gate in the shaft wall and
the hall landing gate in the frame (silo_lift.build calls gate() for each). A barred gate that rises GATE_RISE to open
(LiftGate), built closed in the end-wall frame across x = CAB x -/+ w/2 at frame y, base at world z. Same heavy, chamfered
steel as the lift frame and the hall's portal frames: two box-section stiles, a bolted header channel, hazard-striped kick
plate between a sill and a cap, mid and upper rails, square bars, diagonal braces (one per face) and a lock box with a
status lamp on each face. The cage gates get a pull handle on the cage side.
"""
import silo_hall as HALL
from silo_lift_cab import CAB, box

GATE_H = 2.3


def gate(c, into, name, y, z, w):
    x, top = CAB[0], z + GATE_H
    lo, hi = x - w / 2, x + w / 2
    for s in (-1, 1):                                                     # stiles
        box(c, f"g{name}_stile{s}", x + s * (w / 2 - 0.05) - 0.05, x + s * (w / 2 - 0.05) + 0.05, y - 0.045, y + 0.045,
            z + 0.02, top, c.M_MET_D, into, chamfer=0.012)
    box(c, f"g{name}_header", lo, hi, y - 0.06, y + 0.06, top - 0.17, top, c.M_MET_D, into, chamfer=0.015)
    n = max(int(w / 0.3), 2)
    for k in range(n):                                                    # header bolts, both faces
        bx = lo + 0.15 + (w - 0.3) * k / (n - 1)
        for s in (-1, 1):
            c.CYL(f"g{name}_hb{k}{s}", 0.02, 0.02, HALL.shaft_xy(bx, y + s * 0.065, top - 0.085), c.M_MET, v=6, into=into,
                  rot=(90, 0, HALL.A0))
    kx0, kx1 = lo + 0.1, hi - 0.1
    box(c, f"g{name}_sill", kx0, kx1, y - 0.045, y + 0.045, z + 0.02, z + 0.07, c.M_MET_D, into)
    box(c, f"g{name}_kick", kx0, kx1, y - 0.03, y + 0.03, z + 0.07, z + 0.34, c.M_HAZ_T, into)
    box(c, f"g{name}_cap", kx0, kx1, y - 0.045, y + 0.045, z + 0.34, z + 0.38, c.M_MET_D, into)
    box(c, f"g{name}_mid", kx0, kx1, y - 0.045, y + 0.045, z + 1.04, z + 1.12, c.M_MET_D, into, chamfer=0.01)
    box(c, f"g{name}_upper", kx0, kx1, y - 0.03, y + 0.03, z + 1.72, z + 1.77, c.M_MET_D, into)
    n = int((w - 0.2) / 0.17)
    for k in range(n + 1):
        bx = kx0 + (kx1 - kx0) * k / n
        box(c, f"g{name}_bar{k}", bx - 0.02, bx + 0.02, y - 0.0175, y + 0.0175, z + 0.38, top - 0.17, c.M_RUST_D, into)
    for s, (a, b) in zip((1, -1), ((kx0, kx1), (kx1, kx0))):              # one diagonal brace on each face
        c.TUBE(f"g{name}_brace{s}", HALL.shaft_xy(a, y + s * 0.033, z + 0.38), HALL.shaft_xy(b, y + s * 0.033, z + 1.04), 0.016,
               c.M_MET_D, 4, into=into)
    box(c, f"g{name}_lock", hi - 0.2, hi - 0.03, y - 0.075, y + 0.075, z + 0.9, z + 1.2, c.M_MET_D, into, chamfer=0.012)
    for s in (-1, 1):
        box(c, f"g{name}_lamp{s}", hi - 0.155, hi - 0.105, *sorted((y + s * 0.075, y + s * 0.087)), z + 1.1, z + 1.15, c.M_KEY, into)
    if name in ("in", "out"):                                             # a pull handle on the cage side
        s = -1 if name == "in" else 1
        for hx in (x - 0.32, x + 0.32):
            box(c, f"g{name}_hpost{hx}", hx - 0.025, hx + 0.025, *sorted((y, y + s * 0.11)), z + 0.94, z + 1.06, c.M_MET_D, into)
        box(c, f"g{name}_handle", x - 0.38, x + 0.38, *sorted((y + s * 0.09, y + s * 0.14)), z + 0.97, z + 1.03, c.M_MET, into,
            chamfer=0.01)
