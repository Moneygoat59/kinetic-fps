"""Outpost 73 kit: walkways. Steel stairs, landings, catwalks, gates and blast doors that snap together on a 2 m grid
(dimensions in kit_dims.py; the Missile Silo 00 stair tower is built from them). Same art rules as the rest of the kit:
checker-plate treads, near-black steel, dark rust rails, hazard paint on the edges people trip over.
stair_flight         2 m wide, rises 4 m over an 8 m run. Origin = foot of the flight (bottom nosing line, centre, lower floor
                     level); it climbs toward local +Y (Blender), i.e. Godot -Z. Rails both sides. Collision: ramp + rail walls.
stair_flight_broken  the same flight snapped off 3 m below its top: bent stringers, a hanging tread. Same origin.
stair_landing        4 x 2 m switchback landing, walking surface at z 0. Two flights attach side by side on its back edge
                     (+Y); optional rails opt_rail_front / opt_rail_left / opt_rail_right on the open edges.
catwalk_2m           2 x 2 m grating walkway along Y, top at z 0, open ends; optional rails opt_rail_left / opt_rail_right.
gate_barred          2 m chained barred gate across X, front -Y (warning plate), 2 m tall. Collision: full gate.
door_blast           two-leaf sliding blast door in a 4.4 x 3.1 x 0.5 m pocket housing, 2 x 2.4 m opening, centre plane y 0.
                     Leaves door_left / door_right + marker_door_center: scripts/bunker/bunker_door.gd (BunkerDoor.mount) runs it.
"""
from mathutils import Vector

from kit_dims import DOOR_DEPTH, DOOR_FRAME_H, DOOR_FRAME_W, DOOR_H, DOOR_W, FLIGHT_RISE, FLIGHT_RUN, GOING, LANDING_W, \
    RAIL_H, RISER, WALK_W
from kit_lib import Kit, jitter_verts

HW = WALK_W / 2
STR_T = 0.06                    # stringer / edge channel thickness
POST_R, RAIL_R = 0.025, 0.03


def _rail(k, name, p0, p1, posts, into=None, col=None):
    """Handrail from p0 to p1 (x, y) at deck level z 0: posts at fractions `posts`, top + mid rail, toe plate.
    col = OPT name to give the run a 1.1 m collision wall."""
    a, b = Vector((p0[0], p0[1], 0.0)), Vector((p1[0], p1[1], 0.0))
    for i, t in enumerate(posts):
        p = a.lerp(b, t)
        k.TUBE(f"{name}_post{i}", p + Vector((0, 0, -0.2)), p + Vector((0, 0, RAIL_H + 0.03)), POST_R, k.RUST, 6, into=into)
    for z, r in ((RAIL_H, RAIL_R), (RAIL_H / 2, RAIL_R * 0.8)):
        k.TUBE(f"{name}_rail{z}", a + Vector((0, 0, z)), b + Vector((0, 0, z)), r, k.RUST, 6, into=into)
    d = b - a
    along_x = abs(d.x) > abs(d.y)
    size = (d.length, 0.012, 0.1) if along_x else (0.012, d.length, 0.1)
    mid = (a + b) / 2
    k.B(f"{name}_toe", size, (mid.x, mid.y, 0.05), k.RUST, into=into)
    if col:
        k.OPT_COL(col, (d.length, 0.08, 1.1) if along_x else (0.08, d.length, 1.1), (mid.x, mid.y, 0.55))


def _deck(k, w, d, joists):
    """Checker-plate deck w (x) by d (y), top at z 0, edge channels all round, joists underneath at the given x."""
    k.B("deck", (w - 2 * STR_T, d - 2 * STR_T, 0.05), (0, 0, -0.025), k.PLATE)
    for s in (-1, 1):
        k.B(f"edge_x{s}", (STR_T, d, 0.22), (s * (w - STR_T) / 2, 0, -0.11), k.MET_D)
        k.B(f"edge_y{s}", (w - 2 * STR_T, STR_T, 0.22), (0, s * (d - STR_T) / 2, -0.11), k.MET_D)
    for x in joists:
        k.B(f"joist{x}", (0.08, d - 2 * STR_T, 0.16), (x, 0, -0.13), k.RUST)
    k.COL((w, d, 0.3), (0, 0, -0.15))


def _flight(name, broken):
    k = Kit(name)
    steps = int(round(FLIGHT_RISE / RISER))
    first = 13 if broken else 1                        # a broken flight keeps its top 7 treads
    for j in range(first, steps):
        y, z = j * GOING, j * RISER
        k.B(f"tread{j}", (WALK_W - 2 * STR_T, GOING + 0.02, 0.05), (0, y, z - 0.025), k.PLATE)
        k.B(f"nose{j}", (WALK_W - 2 * STR_T, 0.05, 0.056), (0, y - GOING / 2 + 0.025, z - 0.027), k.HAZ if j in (1, steps - 1) else k.MET_D)
        for s in (-1, 1):
            k.B(f"clip{j}{s}", (0.05, GOING - 0.06, 0.07), (s * (HW - STR_T - 0.025), y, z - 0.085), k.MET_D)
    y0 = 5.0 if broken else 0.0
    top = [(FLIGHT_RUN, FLIGHT_RISE - 0.25), (FLIGHT_RUN, FLIGHT_RISE), (FLIGHT_RUN - 0.3, FLIGHT_RISE)]
    foot = [(y0, y0 / 2 + 0.15)] + ([(y0, y0 / 2 - 0.25)] if broken else [(0.0, 0.0), (0.5, 0.0)])
    for s in (-1, 1):                                                  # stringers: 0.4 deep plate following the pitch
        k.PRISM(f"stringer{s}", foot[1:] + top + foot[:1], STR_T, (HW - STR_T if s > 0 else -HW, 0, 0), k.RUST, plane="yz")
        k.B(f"head{s}", (STR_T + 0.02, 0.12, 0.3), (s * (HW - STR_T / 2), FLIGHT_RUN - 0.06, FLIGHT_RISE - 0.17), k.MET_D)
        if not broken:
            k.B(f"base{s}", (0.16, 0.3, 0.02), (s * (HW - STR_T / 2), 0.3, 0.01), k.MET_D)
    if broken:
        for s in (-1, 1):                                              # torn stringer ends bent down into the dark
            k.TUBE(f"bent{s}", (s * (HW - 0.03), y0 + 0.05, y0 / 2 - 0.05), (s * (HW - 0.03) + s * 0.3, y0 - 0.9, 0.3), 0.07, k.RUST, 5)
        hang = k.B("tread_hanging", (WALK_W - 0.3, GOING, 0.05), (0.35, y0 - 0.25, y0 / 2 - 0.9), k.PLATE, rot=(70, 8, 0))
        jitter_verts(hang, 0.02, 3)
        k.TUBE("rail_stub", (HW - 0.03, FLIGHT_RUN - 0.1, FLIGHT_RISE + 0.03 + RAIL_H), (HW + 0.2, 6.0, 2.9), RAIL_R, k.RUST, 6)
        k.TUBE("rail_post", (HW - 0.03, FLIGHT_RUN - 0.1, FLIGHT_RISE - 0.1), (HW - 0.03, FLIGHT_RUN - 0.1, FLIGHT_RISE + 1.03), POST_R,
               k.RUST)
        k.PRISM("ramp_c", [(y0, y0 / 2 + 0.02), (FLIGHT_RUN, FLIGHT_RISE + 0.02), (FLIGHT_RUN, FLIGHT_RISE - 0.28), (y0, y0 / 2 - 0.28)],
                WALK_W, (-HW, 0, 0), None, plane="yz", into=k.cols)
    else:
        for s in (-1, 1):
            x = s * (HW - STR_T / 2)
            for i, y in enumerate((0.1, 2.7, 5.3, FLIGHT_RUN - 0.1)):
                k.TUBE(f"post{s}{i}", (x, y, y / 2 + 0.1), (x, y, y / 2 + RAIL_H + 0.03), POST_R, k.RUST, 6)
            for z, r in ((RAIL_H, RAIL_R), (RAIL_H / 2, RAIL_R * 0.8)):
                k.TUBE(f"rail{s}{z}", (x, 0.1, 0.05 + z), (x, FLIGHT_RUN - 0.1, FLIGHT_RISE - 0.05 + z), r, k.RUST, 6)
            k.PRISM(f"wall_c{s}", [(0, 0), (FLIGHT_RUN, FLIGHT_RISE), (FLIGHT_RUN, FLIGHT_RISE + 1.1), (0, 1.1)], 0.08,
                    (x - 0.04, 0, 0), None, plane="yz", into=k.cols)
        k.PRISM("ramp_c", [(0, 0.02), (FLIGHT_RUN, FLIGHT_RISE + 0.02), (FLIGHT_RUN, FLIGHT_RISE - 0.28), (0, -0.28)], WALK_W,
                (-HW, 0, 0), None, plane="yz", into=k.cols)
    for j in (3, 9, 16):
        if j >= first:
            k.DECAL(f"dust{j}", (0.15 * (j % 3 - 1), j * GOING, j * RISER + 0.002), 1.5, GOING - 0.04, k.D_DUST, facing="+z",
                    up=(0, 1, 0))
    k.finish(subdiv=0.4, ao_dist=0.6)


def stair_flight():
    _flight("stair_flight", False)


def stair_flight_broken():
    _flight("stair_flight_broken", True)


def stair_landing():
    k = Kit("stair_landing")
    hx, hy = LANDING_W / 2, WALK_W / 2
    _deck(k, LANDING_W, WALK_W, (-1.0, 0.0, 1.0))
    ex, ey = hx - STR_T / 2, hy - STR_T / 2
    for sx in (-1, 1):                                                 # corner posts stay whatever rails are dropped
        for sy in (-1, 1):
            k.TUBE(f"corner{sx}{sy}", (sx * ex, sy * ey, -0.2), (sx * ex, sy * ey, RAIL_H + 0.03), POST_R, k.RUST, 6)
    _rail(k, "front", (-ex, -ey), (ex, -ey), (1 / 3, 2 / 3), k.OPT("rail_front"), "rail_front")
    _rail(k, "left", (-ex, -ey), (-ex, ey), (0.5,), k.OPT("rail_left"), "rail_left")
    _rail(k, "right", (ex, -ey), (ex, ey), (0.5,), k.OPT("rail_right"), "rail_right")
    k.DECAL("haz_back", (0, hy - 0.16, 0.003), LANDING_W - 0.3, 0.14, k.D_HAZARD, facing="+z", up=(0, 1, 0))
    k.DECAL("dust", (0.3, -0.2, 0.002), LANDING_W - 0.8, WALK_W - 0.6, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.finish(subdiv=0.4, ao_dist=0.6)


def catwalk_2m():
    k = Kit("catwalk_2m")
    _deck(k, WALK_W, WALK_W, (-0.5, 0.5))
    e = HW - STR_T / 2
    _rail(k, "left", (-e, -e), (-e, e), (0.0, 0.5, 1.0), k.OPT("rail_left"), "rail_left")
    _rail(k, "right", (e, -e), (e, e), (0.0, 0.5, 1.0), k.OPT("rail_right"), "rail_right")
    k.DECAL("dust", (0.1, 0.2, 0.002), 1.5, 1.6, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.finish(subdiv=0.4, ao_dist=0.6)


def gate_barred():
    k = Kit("gate_barred")
    h, e = 2.0, HW - 0.04
    for s in (-1, 1):
        k.B(f"post{s}", (0.08, 0.08, h + 0.1), (s * e, 0, (h + 0.1) / 2), k.MET_D)
        k.B(f"foot{s}", (0.2, 0.2, 0.02), (s * e, 0, 0.01), k.MET)
        k.B(f"stile{s}", (0.05, 0.05, h - 0.15), (s * (e - 0.09), 0, 0.05 + (h - 0.15) / 2), k.RUST)
    for z in (0.12, 1.0, h - 0.1):
        k.B(f"bar_h{z}", (2 * e - 0.18, 0.05, 0.05), (0, 0, z), k.RUST)
    for i in range(9):
        x = -e + 0.09 + (2 * e - 0.18) * (i + 1) / 10
        k.TUBE(f"bar{i}", (x, 0, 0.12), (x, 0, h - 0.1), 0.014, k.RUST, 5)
    k.TUBE("brace", (-e + 0.09, 0.03, 0.15), (e - 0.09, 0.03, h - 0.13), 0.018, k.RUST, 5)
    for i in range(7):                                                 # chain wrapped round the right post, padlock
        z = 1.05 + 0.035 * i
        k.TUBE(f"link{i}", (e - 0.14, -0.05 + 0.1 * (i % 2), z), (e + 0.06, -0.05 + 0.1 * ((i + 1) % 2), z + 0.03), 0.009,
               k.MET, 4)
    k.B("padlock", (0.07, 0.03, 0.09), (e - 0.02, -0.08, 0.97), k.MET, 0.008)
    k.B("sign", (0.4, 0.012, 0.52), (0, -0.035, 1.45), k.MET_D)
    k.DECAL("warning", (0, -0.0425, 1.45), 0.36, 0.48, k.D_WARN)
    k.DECAL("haz", (0, -0.0265, 0.12), 2 * e - 0.2, 0.05, k.D_HAZARD)
    k.COL((2 * e + 0.08, 0.1, h + 0.1), (0, 0, (h + 0.1) / 2))
    k.finish(subdiv=0.3, ao_dist=0.5)


def door_blast():
    k = Kit("door_blast")
    fw, fh, fd = DOOR_FRAME_W / 2, DOOR_FRAME_H, DOOR_DEPTH / 2
    ow, oh = DOOR_W / 2, DOOR_H
    for y in (-fd + 0.06, fd - 0.06):                                  # front and back plates (the leaves run between them)
        for s in (-1, 1):
            k.B(f"jamb{s}{y}", (fw - ow, 0.12, fh), (s * (fw + ow) / 2, y, fh / 2), k.MET_D, 0.02)
        k.B(f"lintel{y}", (2 * ow, 0.12, fh - oh), (0, y, (fh + oh) / 2), k.MET_D, 0.02)
    k.B("header", (2 * fw, 2 * fd - 0.24, fh - oh), (0, 0, (fh + oh) / 2), k.MET_D)
    for s in (-1, 1):
        k.B(f"cap{s}", (0.05, 2 * fd - 0.24, fh), (s * (fw - 0.025), 0, fh / 2), k.MET_D)
    k.B("threshold", (2 * ow, 2 * fd, 0.02), (0, 0, 0.01), k.MET)
    for side, x0, lean in (("door_left", -ow / 2, 30), ("door_right", ow / 2, -30)):
        leaf = k.PIVOT(side, (x0, 0, 0))
        k.B(f"{side}_plate", (ow - 0.01, 0.1, oh - 0.02), (x0, 0, oh / 2), k.MET, 0.01, into=leaf)
        for z in (0.5, 1.2, 1.9):
            for y in (-0.065, 0.065):
                k.B(f"{side}_rib{z}{y}", (ow - 0.2, 0.03, 0.12), (x0, y, z), k.MET_D, into=leaf)
        for i, z in enumerate((0.25, 0.85, 1.55, 2.2)):               # chevrons meeting at the seam
            k.B(f"{side}_chev{i}", (0.5, 0.012, 0.1), (x0 / 2, -0.056, z), k.HAZ, rot=(0, lean, 0), into=leaf)
        k.B(f"{side}_pull", (0.04, 0.05, 0.3), (x0 * 0.1, -0.075, 1.2), k.RUST, into=leaf)
    k.B("motor", (1.6, 0.4, 0.3), (0, -0.1, fh + 0.15), k.MET_D, 0.03)
    k.B("lamp", (0.16, 0.06, 0.1), (0.55, -0.33, fh + 0.15), k.AMBER)
    k.B("lamp_cage", (0.2, 0.08, 0.02), (0.55, -0.34, fh + 0.21), k.MET)
    k.PIPE("conduit", [(0.7, -0.1, fh + 0.03), (fw - 0.3, -0.1, fh + 0.03), (fw - 0.3, -fd - 0.03, fh + 0.03),
                       (fw - 0.3, -fd - 0.03, 0.0)], 0.03, k.CABLE, verts=6)
    k.DECAL("haz_top", (0, -fd - 0.003, (fh + oh) / 2), 2 * ow, 0.25, k.D_HAZARD)
    k.DECAL("warning", (-(fw + ow) / 2, -fd - 0.003, 1.5), 0.45, 0.6, k.D_WARN)
    k.DECAL("streak", ((fw + ow) / 2, -fd - 0.004, 2.2), 0.9, 1.4, k.D_STREAK)
    k.markers["marker_door_center"] = (0, 0, 0)
    for s in (-1, 1):
        k.COL((fw - ow, 2 * fd, fh), (s * (fw + ow) / 2, 0, fh / 2))
    k.COL((2 * ow, 2 * fd, fh - oh), (0, 0, (fh + oh) / 2))
    k.finish(subdiv=0.3, ao_dist=0.5)


PROPS = {f.__name__: f for f in (stair_flight, stair_flight_broken, stair_landing, catwalk_2m, gate_barred, door_blast)}
