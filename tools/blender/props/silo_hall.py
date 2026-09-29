"""Missile Silo 00 generator hall. Called by missile_silo.py as build(c) after silo_room (it opens the launch control's
right wall) and before silo_lift / silo_generator. A curved brutalist hall dug into the rock round the bore, LIFT_DROP
below level 09 (floor FL, -120 m): an annular sector RI..RO (r 60..77, inside the terrain hole so falls reset below it)
from the end wall at A0 round to the far end wall at A1, 34 m high, portal frames (pilaster + ceiling beam + pilaster)
between the generators (silo_generator.py).
Walk: launch control -> door in its right wall (v D0..D1) -> tunnel -> the lift (silo_lift.py) -> the hall floor.
End-wall frame (shaft_xy): x along the ray at A0 (radius), y toward the room (the end wall face is y 0, the hall and the
lift shaft are at y < 0).
"""
import math

from mathutils import Vector

import ps1_lib as L

A0, A1 = -114.5, -170.0                   # end wall faces (deg): lift end, far end
RI, RO, RM = 60.0, 77.0, 68.5             # inner / outer wall faces, centre line (the generators, the conduit)
WALL = 0.8
LIFT_DROP = 84.0                          # level 09 (GZ) down to the hall floor
HALL_H = 34.0
D0, D1, DH = 6.4, 8.4, 2.8                # room right-wall door: v range, height (tunnel the same)
SHAFT = (61.6, 66.4, -4.4, 0.4)           # lift shaft outer footprint in shaft_xy (x0, x1, y0, y1): cut through the ceiling
PORTALS = (-124.0, -138.0, -152.0, -166.0)


def build(c):
    c.FL = c.GZ - LIFT_DROP
    c.CEIL = c.FL + HALL_H
    shell(c)
    portals(c)
    tunnel(c)
    dressing(c)


def shaft_xy(x, y, z=0.0):
    a = math.radians(A0)
    return (x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a), z)


def shell(c):
    fl, ce = c.FL, c.CEIL
    zs = [fl + k * HALL_H / 6 for k in range(7)]
    lo, hi = A1 - 0.9, A0 + 0.9
    c.ring("hall_floor", RI - WALL, RO + WALL, [fl - 1.0, fl], lo, hi, 48, c.M_FLOOR, into=c.hall, sub=3.0)
    ceiling = c.ring("hall_ceiling", RI - WALL, RO + WALL, [ce, ce + 1.5], lo, hi, 48, c.M_CON_T, into=c.hall, sub=3.0)
    c.ring("hall_floor_c", RI - WALL, RO + WALL, [fl - 1.0, fl], lo, hi, 48, c.M_PLATE, into=c.cols)
    for name, r0, r1, a0, a1, segs in (("hall_wall_in", RI - WALL, RI, A1, A0, 48), ("hall_wall_out", RO, RO + WALL, A1, A0, 48),
                                       ("hall_end_far", RI - WALL, RO + WALL, lo, A1, 1)):
        c.ring(name, r0, r1, zs, a0, a1, segs, c.M_CON, into=c.hall, sub=3.0)
        c.ring(name + "_c", r0, r1, zs, a0, a1, segs, c.M_PLATE, into=c.cols)
    c.ring("hall_end", RI - WALL, RO + WALL, zs, A0, hi, 1, c.M_CON, into=c.hall, sub=3.0)
    c.ring("hall_end_c", RI - WALL, RO + WALL, zs, A0, hi, 1, c.M_PLATE, into=c.cols)
    x0, x1, y0, y1 = SHAFT                                              # the lift comes down through the ceiling
    L.cut(ceiling, L.vprism("cut_shaft", [shaft_xy(x, y)[:2] for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1))],
                            ce - 0.2, ce + 1.7, None))
    for i, z in enumerate((fl + 6.0, fl + 22.0)):                        # cast ledges along the outer wall
        c.ring(f"hall_ledge{i}", RO - 0.45, RO, [z - 0.5, z], A1, A0, 48, c.M_CON_T, into=c.hall)


def portals(c):
    """Brutalist portal frames: pilasters on both walls, a deep ceiling beam across, splayed haunches in the corners."""
    fl, ce = c.FL, c.CEIL
    h = ce - fl
    for a in PORTALS:
        k = int(-a)
        c.ABOX(f"pil_out{k}", RO - 0.6, a, (2.2, 1.2, h), fl + h / 2, c.M_CON, into=c.hall, c=0.06)
        c.ABOX(f"pil_in{k}", RI + 0.5, a, (2.2, 1.0, h), fl + h / 2, c.M_CON, into=c.hall, c=0.06)
        c.ABOX(f"pil_foot_out{k}", RO - 0.9, a, (2.8, 1.8, 1.2), fl + 0.6, c.M_CON_T, into=c.hall, c=0.08)
        c.ABOX(f"pil_foot_in{k}", RI + 0.8, a, (2.8, 1.6, 1.2), fl + 0.6, c.M_CON_T, into=c.hall, c=0.08)
        c.ABOX(f"beam{k}", RM, a, (1.8, RO - RI, 2.6), ce - 1.3, c.M_CON, into=c.hall, c=0.06)
        for s, r in ((1, RO - 1.6), (-1, RI + 1.6)):
            c.ABOX(f"haunch{k}{s}", r, a, (1.8, 2.6, 2.6), ce - 2.8, c.M_CON, into=c.hall, tilt=45.0)
        c.ACOL(f"pil_out{k}_c", RO - 0.6, a, (2.2, 1.2, h), fl + h / 2)
        c.ACOL(f"pil_in{k}_c", RI + 0.5, a, (2.2, 1.0, h), fl + h / 2)


def tunnel_pts(c, u_room, y_hall, v0=D0, v1=D1):
    """Footprint (world xy) of a strip of the tunnel between room v0..v1: from room-frame u_room (the right wall is
    u 6.3..6.7) along +u to end-wall-frame y_hall (the lift shaft's room-side face is y 0)."""
    ey = Vector(shaft_xy(0.0, 1.0))
    pts = []
    for v, room_end in ((v0, False), (v1, False), (v1, True), (v0, True)):
        base = c.room_r * (c.R + v)
        u = u_room if room_end else (y_hall - base.dot(ey)) / c.room_u.dot(ey)
        p = base + c.room_u * u
        pts.append((p.x, p.y))
    return pts


def tunnel(c):
    """Room right wall -> the lift shaft (end-wall frame y 0): floor, side walls, ceiling (silo_room leaves the door gap in
    the room wall). The floor runs on to y -0.3, just short of the cage."""
    z = c.GZ
    floor = tunnel_pts(c, 6.2, -0.3)
    c.hall.append(L.vprism("tun_floor", floor, z - 0.2, z, c.M_PLATE))
    c.cols.append(L.vprism("tun_floor_c", floor, z - 0.3, z, None))
    c.hall.append(L.vprism("tun_ceil", tunnel_pts(c, 6.3, 0.0, D0 - 0.4, D1 + 0.4), z + DH, z + DH + 0.4, c.M_CON_T))
    for s, v0, v1 in ((-1, D0 - 0.4, D0), (1, D1, D1 + 0.4)):
        side = tunnel_pts(c, 6.3, 0.0, v0, v1)
        c.hall.append(L.vprism(f"tun_wall{s}", side, z, z + DH, c.M_CON))
        c.cols.append(L.vprism(f"tun_wall{s}_c", side, z, z + DH, None))


def dressing(c):
    fl = c.FL + 0.012
    for k, (r, a) in enumerate(((RO - 3.0, -124.5), (RI + 3.0, -138.5), (RO - 3.0, -152.5), (RI + 3.0, -165.0))):
        c.DECAL(f"hall_dust{k}", c.polar(r, a, fl), 5.0, 7.0, "+z", c.D_DUST, up=c.polar(1.0, a), into=c.hall_dec)
    for k, a in enumerate((-127.0, -156.0)):
        c.DECAL(f"hall_stain{k}", c.polar(RM + 5.0, a, fl + 0.004), 3.0, 3.0, "+z", c.D_STAIN, into=c.hall_dec)
    c.DECAL("hall_stencil", c.polar(RO - 0.03, -117.5, c.FL + 12.0), 2.8, 4.2, c.polar(1.0, -117.5 + 180.0), c.D_STENCIL, into=c.hall_dec)
    c.DECAL("hall_crack", c.polar(RI + 0.03, -144.0, c.FL + 9.0), 1.6, 3.2, c.polar(1.0, -144.0), c.D_CRACK, into=c.hall_dec)
    c.DECAL("hall_streak", c.polar(RO - 0.03, -159.0, c.FL + 16.0), 8.0, 14.0, c.polar(1.0, -159.0 + 180.0), c.D_STREAK, into=c.hall_dec)
    L.empty("marker_hall", c.polar(RM, (A0 + A1) / 2, c.FL))
