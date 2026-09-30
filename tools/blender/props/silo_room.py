"""Missile Silo 00 launch control (level 09, floor GZ). Called by missile_silo.py as build(c) after silo_bore (it cuts the
door and the observation window through c.lining). The room is dug into the rock behind the lining at angle ROOM_A,
off the end of the gantry deck; a doorway in its right wall (+u) leads down to the generator hall (silo_hall.py), one
in its left wall (-u) into the data room (silo_servers.py).
Local frame: u runs along the wall (+u away from the tower), v outward from the bore face (the lining is v 0..3, the
room v 2.6..10.4), z world height. The launch desk stands under the window facing into the room;
its screen silo_scr_launch is driven at runtime (SiloConsole, PixelScreen); marker_launch = where the operator stands.
"""
import math

from mathutils import Vector

import ps1_lib as L

ROOM_A = -106.5
U0, U1, V0, V1, H = -6.3, 6.3, 2.6, 10.4, 4.0
DOOR = (-2.95, -0.95, 2.4)            # u0, u1, height: the door_blast kit opening (kit_dims DOOR_W x DOOR_H)
WIN = (1.0, 5.0, 1.5, 2.9)            # u0, u1, z0, z1 above the floor
HALL_DOOR = (6.4, 8.4, 2.8)           # v0, v1, height: the right-wall doorway to the generator hall (silo_hall.D0 / D1 / DH)
SERVER_DOOR = (6.6, 8.6, 2.6)         # v0, v1, height: the left-wall doorway to the data room (silo_servers.py)


def build(c):
    t = math.radians(ROOM_A)
    c.room_r = Vector((math.cos(t), math.sin(t), 0.0))
    c.room_u = Vector((math.cos(t - math.pi / 2), math.sin(t - math.pi / 2), 0.0))
    shell(c)
    desk(c)
    dressing(c)
    kit(c)


def W(c, u, v, z):
    p = c.room_r * (c.R + v) + c.room_u * u
    return (p.x, p.y, z)


def RB(c, name, u0, u1, v0, v1, z0, z1, mat, col=False, into=None, tilt=0.0):
    """Box in room space (u0..u1, v0..v1, z0..z1 above the floor)."""
    size, loc = (u1 - u0, v1 - v0, z1 - z0), W(c, (u0 + u1) / 2, (v0 + v1) / 2, c.GZ + (z0 + z1) / 2)
    o = c.B(name, size, loc, mat, rot=(tilt, 0, ROOM_A - 90.0), into=c.bore if into is None else into) if mat else None
    if col:
        c.COL(name + "_c", size, loc, (tilt, 0, ROOM_A - 90.0))
    return o


def FACE(c, name):
    return {"in": tuple(-c.room_r), "back": tuple(c.room_r), "+u": tuple(c.room_u), "-u": tuple(-c.room_u)}[name]


def shell(c):
    for name, (u0, u1, z0, z1) in (("door", DOOR[:2] + (0.0, DOOR[2])), ("window", WIN)):
        L.cut(c.lining, L.fast_box(f"cut_{name}", (u1 - u0, 5.0, z1 - z0), W(c, (u0 + u1) / 2, 1.5, c.GZ + (z0 + z1) / 2), None,
                              (0, 0, ROOM_A - 90.0)))
    RB(c, "floor", U0 - 0.4, U1 + 0.4, V0, V1 + 0.4, -0.5, 0.0, c.M_FLOOR, col=True)
    RB(c, "ceiling", U0 - 0.4, U1 + 0.4, V0, V1 + 0.4, H, H + 0.5, c.M_CON_T)
    RB(c, "wall_back", U0 - 0.4, U1 + 0.4, V1, V1 + 0.4, 0.0, H, c.M_CON, col=True)
    side_wall(c, "wall_l", U0 - 0.4, U0, SERVER_DOOR)                  # left wall: the doorway into the data room
    door_frame(c, "srv", U0 - 0.48, U0 + 0.08, SERVER_DOOR)             # lines the whole opening: rooms on both sides
    side_wall(c, "wall_r", U1, U1 + 0.4, HALL_DOOR)                     # right wall: the doorway down to the generator hall
    door_frame(c, "hall", U1 - 0.08, U1 + 0.1, HALL_DOOR)
    RB(c, "lin_back", U0, U1, V1 - 0.05, V1, 0.0, 1.6, c.M_PLATE)
    RB(c, "front_l_c", U0 - 0.4, DOOR[0], 2.2, 2.9, 0.0, H, None, col=True)
    RB(c, "front_r_c", DOOR[1], U1 + 0.4, 2.2, 2.9, 0.0, H, None, col=True)
    RB(c, "tunnel_floor", DOOR[0], DOOR[1], -0.2, 3.0, -0.08, 0.02, c.M_PLATE, col=True)
    for s, u in ((-1, DOOR[0]), (1, DOOR[1])):
        RB(c, f"tunnel_c{s}", u + (-0.3 if s < 0 else 0.0), u + (0.0 if s < 0 else 0.3), -0.2, 3.0, 0.0, DOOR[2], None, col=True)
    f = Vector(FACE(c, "in"))                                             # kit blast door on the bore face (MissileSilo opens it)
    c.empty("marker_kit_door_blast__room", W(c, (DOOR[0] + DOOR[1]) / 2, 0.0, c.GZ), math.degrees(math.atan2(f.y, f.x)) + 90.0)
    u0, u1, z0, z1 = WIN
    RB(c, "win_sill", u0 - 0.2, u1 + 0.2, -0.3, 3.1, z0 - 0.1, z0, c.M_MET_D)
    RB(c, "win_head", u0 - 0.2, u1 + 0.2, -0.3, 3.1, z1, z1 + 0.1, c.M_MET_D)
    for k in range(4):
        u = u0 + (u1 - u0) * k / 3
        RB(c, f"win_bar{k}", u - 0.06, u + 0.06, -0.1, 0.1, z0, z1, c.M_MET_D)
    RB(c, "win_c", u0, u1, 2.2, 2.9, z0, z1, None, col=True)
    a0 = math.degrees(math.atan2(*reversed(W(c, DOOR[0], 0, 0)[:2])))
    a1 = math.degrees(math.atan2(*reversed(W(c, DOOR[1], 0, 0)[:2])))
    lo, hi = min(a0, a1), max(a0, a1)
    for i, (s0, s1) in enumerate(((-117.0, lo), (hi, -103.0))):         # the deck's wall side (the lining has no collision)
        c.ring(f"deck_wall{i}_c", c.R - 0.25, c.R + 0.3, [c.GZ, c.GZ + 3.0], s0, s1, 8, c.M_PLATE, into=c.cols)


def side_wall(c, name, u0, u1, door):
    """A side wall (u0..u1 thick, the room's full depth V0..V1) with a doorway: door = (v0, v1, height)."""
    d0, d1, dh = door
    RB(c, f"{name}0", u0, u1, V0, d0, 0.0, H, c.M_CON, col=True)
    RB(c, f"{name}1", u0, u1, d1, V1, 0.0, H, c.M_CON, col=True)
    RB(c, f"{name}_head", u0, u1, d0, d1, dh, H, c.M_CON, col=True)


def door_frame(c, name, u0, u1, door):
    """Steel jambs and lintel round a side-wall doorway, u0..u1 deep; door = (v0, v1, height)."""
    d0, d1, dh = door
    for v in (d0 - 0.12, d1 + 0.12):
        RB(c, f"{name}_jamb{v}", u0, u1, v - 0.12, v + 0.12, 0.0, dh, c.M_MET_D)
    RB(c, f"{name}_lintel", u0, u1, d0 - 0.24, d1 + 0.24, dh, dh + 0.24, c.M_MET_D)


def desk(c):
    RB(c, "desk_body", 0.6, 5.4, 3.05, 3.95, 0.0, 0.82, c.M_MET_D, col=True)
    RB(c, "desk_panel", 0.6, 5.4, 3.3, 4.05, 0.84, 0.92, c.M_MET, tilt=-18.0)
    RB(c, "desk_hood", 0.9, 5.1, 3.05, 3.4, 0.92, 1.45, c.M_MET_D, tilt=-12.0)
    n = Vector(FACE(c, "back")) * math.cos(math.radians(14)) + Vector((0, 0, math.sin(math.radians(14))))
    c.screens.append(L.quad("scr_launch", W(c, 3.35, 3.47, c.GZ + 1.2), 1.5, 0.84, tuple(n), c.S_LAUNCH))
    c.screens.append(L.quad("scr_map", W(c, 1.55, 3.47, c.GZ + 1.2), 0.9, 0.64, tuple(n), c.S_MAP))
    RB(c, "launch_key", 4.55, 4.75, 3.7, 3.9, 0.9, 1.0, c.M_KEY)
    RB(c, "launch_guard", 4.45, 4.85, 3.62, 3.98, 0.9, 0.93, c.M_HAZ)
    c.empty("marker_launch", W(c, 3.0, 4.6, c.GZ))
    c.DECAL("desk_hazard", W(c, 3.0, 3.94 + 0.02, c.GZ + 0.62), 4.6, 0.3, FACE(c, "back"), c.D_HAZARD, inside=True)


def dressing(c):
    fl = c.GZ + 0.012
    c.DECAL("room_dust", W(c, 0.0, 6.5, fl), 11.0, 7.0, "+z", c.D_DUST, up=FACE(c, "back"), inside=True)
    c.DECAL("room_papers", W(c, 2.4, 5.6, fl + 0.004), 1.4, 1.4, "+z", c.D_PAPERS, up=FACE(c, "-u"), inside=True)
    c.DECAL("room_stain", W(c, -3.0, 7.8, fl + 0.006), 2.2, 2.2, "+z", c.D_STAIN, inside=True)
    c.DECAL("room_stencil", W(c, -4.4, V1 - 0.03, c.GZ + 3.0), 1.4, 2.1, FACE(c, "in"), c.D_STENCIL, inside=True)
    c.DECAL("room_crack", W(c, 2.8, V1 - 0.035, c.GZ + 2.4), 0.8, 1.6, FACE(c, "in"), c.D_CRACK, inside=True)
    c.DECAL("depth_marker", W(c, -5.3, -0.03, c.GZ + 1.7), 1.8, 0.6, FACE(c, "in"), c.D_DEPTH, inside=True)
    c.DECAL("door_soot", W(c, -1.95, -0.04, c.GZ + 3.6), 5.0, 3.0, FACE(c, "in"), c.D_STREAK, inside=True)
    for k, (u, v) in enumerate(((0.0, 6.6), (3.0, 4.6))):
        RB(c, f"ceil_lamp{k}", u - 0.6, u + 0.6, v - 0.15, v + 0.15, H - 0.12, H, c.M_LAMP)
    L.empty("marker_light_room_c", W(c, 0.0, 6.6, c.GZ + 3.6))
    L.empty("marker_light_room_desk", W(c, 3.0, 4.6, c.GZ + 3.6))
    for k in range(3):                                                  # cables from the desk to the mainframes
        p0 = Vector(W(c, 1.0 + k * 0.5, 4.0, c.GZ + 0.03))
        p1 = Vector(W(c, -3.4 - k * 0.9, 9.6, c.GZ + 0.03))
        c.TUBE(f"floor_cable{k}", p0, p1, 0.035, c.M_CABLE, 4, into=c.bore)


# (prop, u, v, z above the floor, facing) - kit fronts face their local -Y; facing picks the room direction.
KIT = [("terminal_mainframe", -5.4, 10.0, 0.0, "in"), ("terminal_mainframe", -4.4, 10.0, 0.0, "in"),
       ("terminal_mainframe", -3.4, 10.0, 0.0, "in"), ("terminal_console", 5.85, 9.6, 0.0, "-u"),
       ("table_steel", 1.6, 9.5, 0.0, "in"), ("terminal_crt", 1.6, 9.55, 0.78, "in"), ("chair_steel", 1.4, 8.4, 0.0, "back"),
       ("chair_steel", 2.6, 5.3, 0.0, "back"), ("locker", -6.0, 4.3, 0.0, "+u"), ("locker", -6.0, 5.2, 0.0, "+u"),
       ("shelf_rack", 5.95, 5.4, 0.0, "-u"), ("crate_large", 4.7, 9.8, 0.0, "in"), ("drum_amber", -0.9, 9.9, 0.0, "in"),
       ("terminal_wall", 3.9, V1, 0.0, "in")]


def kit(c):
    for i, (prop, u, v, z, facing) in enumerate(KIT):
        f = Vector(FACE(c, facing))
        c.empty(f"marker_kit_{prop}__{i}", W(c, u, v, c.GZ + z), math.degrees(math.atan2(f.y, f.x)) + 90.0)
