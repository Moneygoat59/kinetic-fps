"""Missile Silo 00 freight lift: launch control (level 09) down LIFT_DROP to the generator hall. Called by missile_silo.py
as build(c) after silo_hall. Laid out in the hall's end-wall frame (silo_hall.shaft_xy: x along the ray at A0, y toward
the room): the tunnel from launch control ends at the shaft's room-side wall (y 0); the cage (CAB_W square, centre CAB)
drops through a closed rock shaft, out through the hall ceiling and down an open steel frame to the hall floor, where it
opens on the hall side (-y). Parts that move are their own nodes, built at the top / closed (SiloLift drives them):
  silo_lift_cab          the cage (silo_lift_cab.py: floor, side walls, roof, crosshead, lamp, panel, fittings)
  silo_lift_cab_art      the art laid inside it (wall panels, floor, ceiling, plate, panel face: own UVs, not world-projected)
  silo_lift_gate_in/out  the cage's gates, room side / hall side (silo_lift_gate.py; rise GATE_RISE to open)
  silo_lift_gate_top     level 09 landing gate in the shaft wall; silo_lift_gate_bottom  hall landing gate in the frame
  silo_lift_wreck (+ c.lift_dec -> silo_lift_wreck_decals)  what the crash left at the foot: the snapped cable heaped on
                         the cage roof and hanging down the shaft, sheared brake shoe, fence rails, ceiling chips, scorch
                         (hidden until SiloLift.wreck())
Markers: marker_lift_top / _bottom (cage floor centre, yaw A0: Godot local x = frame x, local +z = frame -y),
marker_lift_call_top / _bottom (where the player stands to call it), marker_light_lift_top / _bottom.
"""
import math

import ps1_lib as L
import silo_hall as HALL
import silo_lift_cab as CABIN
import silo_room as ROOM
from silo_lift_cab import CAB, CAB_H, XY, box
from silo_lift_gate import GATE_H, gate

INNER = (62.2, 65.8, -3.8, -0.2)          # shaft clear (x0, x1, y0, y1); walls WALL thick outside it
WALL = 0.5
OPEN = (63.0, 65.0)                       # level 09 opening in the room-side wall (= the tunnel), height silo_hall.DH
GATE_W = 2.8                              # cage + hall gates (the level 09 gate is OPEN wide); GATE_H in silo_lift_gate
GATE_RISE = 2.3                           # SiloLift.GATE_RISE
COLS = ((61.95, -0.35), (66.05, -0.35), (61.95, -3.85), (66.05, -3.85))   # hall frame columns
CALL_TOP = (8.2, 6.45)                    # level 09 call panel: launch-control frame (u, v) on the tunnel's bore-side wall


def build(c):
    c.lift = {n: [] for n in ("silo_lift_cab", "silo_lift_cab_art", "silo_lift_gate_in", "silo_lift_gate_out", "silo_lift_gate_top",
                              "silo_lift_gate_bottom", "silo_lift_wreck")}
    c.lift_dec = []
    shaft(c)
    frame(c)
    CABIN.build(c, c.lift["silo_lift_cab"], c.lift["silo_lift_cab_art"])
    for name, y, z in (("in", -0.45, c.GZ), ("out", -3.55, c.GZ), ("bottom", -4.05, c.FL)):
        gate(c, c.lift[f"silo_lift_gate_{name}"], name, y, z, GATE_W)
    gate(c, c.lift["silo_lift_gate_top"], "top", 0.05, c.GZ, OPEN[1] - OPEN[0] + 0.2)
    panels(c)
    wreck(c, c.lift["silo_lift_wreck"])
    for name, z in (("top", c.GZ), ("bottom", c.FL)):
        c.empty(f"marker_lift_{name}", XY(CAB[0], CAB[1], z), HALL.A0)


def shaft(c):
    """Closed rock shaft from the hall ceiling up past level 09: four walls, the level 09 opening, a roof, guide rails,
    a lamp every 12 m (emissive only: the cage's own lamp lights the walls going by)."""
    x0, x1, y0, y1 = INNER
    lo, hi = c.CEIL + 1.5, c.GZ + 5.2
    top = c.GZ + HALL.DH
    for name, a, b, cc, d, z0, z1 in (("sh_back", x0 - WALL, x1 + WALL, y0 - WALL, y0, lo, hi),
                                      ("sh_left", x0 - WALL, x0, y0, y1, lo, hi), ("sh_right", x1, x1 + WALL, y0, y1, lo, hi),
                                      ("sh_front_low", x0 - WALL, x1 + WALL, y1, y1 + WALL, lo, c.GZ - 0.2),
                                      ("sh_front_l", x0 - WALL, OPEN[0], y1, y1 + WALL, c.GZ - 0.2, hi),
                                      ("sh_front_r", OPEN[1], x1 + WALL, y1, y1 + WALL, c.GZ - 0.2, hi),
                                      ("sh_front_head", OPEN[0], OPEN[1], y1, y1 + WALL, top, hi),
                                      ("sh_roof", x0 - WALL, x1 + WALL, y0 - WALL, y1 + WALL, hi, hi + 0.5)):
        box(c, name, a, b, cc, d, z0, z1, c.M_CON, c.hall, col=True)
    for k, x in enumerate((x0 + 0.05, x1 - 0.05)):
        box(c, f"lift_rail{k}", x - 0.05, x + 0.05, CAB[1] - 0.12, CAB[1] + 0.12, c.FL, hi, c.M_MET, c.hall)
    z = c.GZ - 6.0
    while z > lo + 2.0:
        box(c, f"sh_lamp{int(z)}", CAB[0] - 0.2, CAB[0] + 0.2, y0 + 0.01, y0 + 0.11, z, z + 0.2, c.M_LAMP, c.hall)
        z -= 12.0
    c.DECAL("sh_hazard", XY(CAB[0], y1 + WALL + 0.02, top + 0.3), 2.4, 0.4, XY(0.0, 1.0), c.D_HAZARD, into=c.hall_dec)


def frame(c):
    """Open steel frame in the hall, floor to ceiling: columns, ring beams every 4 m, X-braces, a fence round the foot and
    the hall landing opening (-y) with its call panel and lamp."""
    fl, top = c.FL, c.CEIL + 1.5
    for k, (x, y) in enumerate(COLS):
        box(c, f"lf_col{k}", x - 0.2, x + 0.2, y - 0.2, y + 0.2, fl, top, c.M_MET_D, c.hall)
    z = fl + 4.0
    while z < top - 1.0:
        for name, a, b, cc, d in (("l", 61.75, 62.15, -3.85, -0.35), ("r", 65.85, 66.25, -3.85, -0.35),
                                  ("b", 61.95, 66.05, -3.95, -3.65), ("f", 61.95, 66.05, -0.3, 0.0)):
            box(c, f"lf_beam{name}{int(z)}", a, b, cc, d, z - 0.15, z + 0.15, c.M_RUST, c.hall)
        for x in (61.95, 66.05):                                          # X-braces on the side faces
            p, q = XY(x, -0.35, z - 3.85), XY(x, -3.85, z - 0.15)
            c.TUBE(f"lf_br{x}{int(z)}", p, q, 0.06, c.M_MET_D, 4, into=c.hall)
            c.TUBE(f"lf_br2{x}{int(z)}", XY(x, -3.85, z - 3.85), XY(x, -0.35, z - 0.15), 0.06, c.M_MET_D, 4, into=c.hall)
        z += 4.0
    for x in (61.95, 66.05):                                              # fence round the foot (the cage comes down here)
        for h in (0.1, 0.8, 1.5, 2.2):
            box(c, f"lf_fence{x}{h}", x - 0.03, x + 0.03, -3.85, -0.35, fl + h, fl + h + 0.06, c.M_RUST, c.hall)
        box(c, f"lf_fence{x}", x - 0.05, x + 0.05, -3.85, -0.35, fl, fl + 2.4, None, c.hall, col=True)
    for a, b in ((61.95, 62.6), (65.4, 66.05)):                           # beside the hall landing gate
        box(c, f"lf_jamb{a}", a, b, -4.1, -4.0, fl, fl + GATE_H + 0.2, c.M_MET_D, c.hall, col=True, chamfer=0.02)
    box(c, "lf_head", 62.6, 65.4, -4.2, -4.1, fl + GATE_H + 0.05, fl + GATE_H + 0.3, c.M_MET_D, c.hall, chamfer=0.02)   # the gate rises behind it
    box(c, "lf_lamp", CAB[0] - 0.3, CAB[0] + 0.3, -4.3, -4.1, fl + 3.3, fl + 3.5, c.M_LAMP, c.hall)
    L.empty("marker_light_lift_bottom", XY(CAB[0], -4.8, fl + 3.2))
    c.DECAL("lf_hazard", XY(CAB[0], -4.22, fl + GATE_H + 0.18), 2.6, 0.22, XY(0.0, -1.0), c.D_HAZARD, into=c.hall_dec)


def panels(c):
    """Call panels: level 09 on the tunnel's bore-side wall (launch-control frame), the hall one on the frame column."""
    u, v = CALL_TOP
    t = math.radians(ROOM.ROOM_A)
    er, eu = (math.cos(t), math.sin(t)), (math.cos(t - math.pi / 2), math.sin(t - math.pi / 2))
    at = lambda uu, vv, z: (er[0] * (c.R + vv) + eu[0] * uu, er[1] * (c.R + vv) + eu[1] * uu, z)  # noqa: E731
    c.B("call_top", (0.35, 0.1, 0.5), at(u, v + 0.05, c.GZ + 1.3), c.M_MET_D, rot=(0, 0, ROOM.ROOM_A - 90.0), into=c.hall)
    c.B("call_top_btn", (0.1, 0.06, 0.1), at(u, v + 0.11, c.GZ + 1.38), c.M_KEY, rot=(0, 0, ROOM.ROOM_A - 90.0), into=c.hall)
    L.empty("marker_lift_call_top", at(u, (HALL.D0 + HALL.D1) / 2, c.GZ))
    L.empty("marker_light_lift_top", at(u, (HALL.D0 + HALL.D1) / 2, c.GZ + HALL.DH - 0.2))
    box(c, "call_bottom", 65.9, 66.2, -4.18, -4.08, c.FL + 1.05, c.FL + 1.55, c.M_MET_D, c.hall)
    box(c, "call_bottom_btn", 66.0, 66.1, -4.24, -4.18, c.FL + 1.3, c.FL + 1.4, c.M_KEY, c.hall)
    L.empty("marker_lift_call_bottom", XY(66.05, -5.0, c.FL))


def wreck(c, into):
    """The crash's leavings round the cage at the bottom: the snapped hoist cable in coils on the roof and trailing up the
    shaft, a brake shoe sheared off the cage, the fence's rails knocked out, chips of the ceiling, scorch where the
    sparks hit."""
    x, y, fl = CAB[0], CAB[1], c.FL
    roof = fl + CAB_H + 0.12
    for k in range(6):                                                    # coils slumped over the crosshead
        r, cx, cy = 0.55 + 0.12 * k, x + 0.25 * math.cos(k * 2.1), y + 0.2 * math.sin(k * 1.7)
        pts = [XY(cx + r * math.cos(t * math.pi / 5), cy + r * 0.8 * math.sin(t * math.pi / 5),
                  roof + 0.06 * k + (0.45 if abs(math.sin(t * math.pi / 5)) < 0.3 else 0.0)) for t in range(11)]
        for j in range(10):
            c.TUBE(f"wr_coil{k}_{j}", pts[j], pts[j + 1], 0.045, c.M_CABLE, 5, into=into)
    for k, (dx, dy) in enumerate(((-0.4, 0.3), (0.2, -0.3), (0.5, 0.4))):  # strands still hanging from the shaft
        p0, p1 = XY(x + dx, y + dy, c.CEIL + 4.0), XY(x + dx * 1.6, y + dy * 1.2, roof + 0.2)
        c.TUBE(f"wr_strand{k}", p0, p1, 0.035, c.M_CABLE, 4, into=into)
    box(c, "wr_shoe", 60.7, 61.2, -5.9, -5.3, fl, fl + 0.35, c.M_RUST, into)
    for k, (a, b) in enumerate((((61.0, -4.6), (62.9, -6.9)), ((66.4, -4.9), (64.7, -7.2)), ((61.6, -6.3), (63.9, -5.1)))):
        c.TUBE(f"wr_rail{k}", XY(a[0], a[1], fl + 0.04), XY(b[0], b[1], fl + 0.04 + 0.1 * k), 0.03, c.M_RUST, 4, into=into)
    for k in range(9):
        px, py = 61.5 + (k * 37 % 50) / 10.0, -4.6 - (k * 23 % 30) / 10.0
        s = 0.18 + (k % 4) * 0.08
        o = c.B(f"wr_chip{k}", (s * 1.3, s, s * 0.7), XY(px, py, fl + s * 0.3), c.M_CON, rot=(k * 13, k * 7, k * 41), into=into)
        L.jitter(o, s * 0.2, k)
    c.DECAL("wr_scorch", XY(x, -5.2, fl + 0.014), 4.5, 3.0, "+z", c.D_SOOT, up=XY(1.0, 0.0), into=c.lift_dec)
    c.DECAL("wr_dust", XY(x - 0.4, -6.4, fl + 0.016), 5.0, 3.5, "+z", c.D_DUST, up=XY(0.0, 1.0), into=c.lift_dec)
