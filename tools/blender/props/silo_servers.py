"""Missile Silo 00 data room (level 09, floor GZ). Called by missile_silo.py as build(c) right after silo_room: through the
doorway in launch control's left wall (silo_room.SERVER_DOOR) a long low room runs on along -u, dug into the rock beside
it. Two rows of server racks (kit server_rack / server_rack_open, backs to the side walls) face a centre aisle lined up
with the door; cable trays hang over the rows; at the far end the operator console (kit terminal_server) faces back down
the aisle, a cooling unit and a tape cabinet in the corners, the room's stencil over it.
Same frame and helpers as silo_room (u along the wall, v outward from the bore face, z above the floor); kit sizes from
kit_dims (SRV_*, TRAY_*). Runtime: SiloServers batches the racks and trays; SiloAmbience lights marker_light_srv_*.
"""
import math
import os
import sys

from mathutils import Vector

import silo_room as ROOM

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "kit"))
import kit_dims as K  # noqa: E402

RB, W, FACE = ROOM.RB, ROOM.W, ROOM.FACE
U0, U1 = -17.1, ROOM.U0 - 0.4          # interior along u: far end wall face .. launch control's left wall (its outer face)
V0, V1 = 5.0, 10.2                     # interior across; the aisle's centre line = the doorway's
H = 3.2                                # lower than launch control: the trays hang close overhead
AISLE = (V0 + V1) / 2
ROW_A = V0 + K.SRV_D / 2 + 0.05        # rack centre lines (backs 5 cm off the walls)
ROW_C = V1 - K.SRV_D / 2 - 0.05
TRAY_Z = H - K.TRAY_HANG               # cable_tray origin: its rods reach the ceiling
LAMPS = (-9.5, -13.5)                  # ceiling lamp strips over the aisle (u); marker_light_srv_0 / _1

# (prop, u, v, facing[, marker flags]) - kit fronts face their local -Y; facing picks the room direction (silo_room.FACE).
# The console's __drive_silo_data09 makes it a TerminalStation (res://content/terminals/silo_data09.tres).
KIT = [("terminal_mainframe", -7.3, V0 + 0.37, "back"), ("shelf_rack", -7.5, V1 - 0.245, "in"),
       ("terminal_server", -16.62, AISLE, "+u", "__drive_silo_data09"), ("chair_steel", -15.83, AISLE - 0.2, "-u"),
       ("crac_unit", -16.66, V0 + 0.7, "+u"), ("terminal_mainframe", -16.71, V1 - 0.6, "+u"),
       ("crate_small", -15.2, V1 - 0.35, "in")]
KIT += [("server_rack_open" if u == -10.0 else "server_rack", u, ROW_A, "back")
        for u in (-8.2, -8.8, -9.4, -10.0, -10.6, -11.2, -12.4, -13.0, -13.6)]      # -11.8: a rack gone, its cables left
KIT += [("server_rack_open" if u == -12.2 else "server_rack", u, ROW_C, "in")
        for u in (-8.6, -9.2, -9.8, -10.4, -11.0, -11.6, -12.2, -12.8, -13.4)]
KIT += [("cable_tray", u, v, "+u") for v in (ROW_A, ROW_C) for u in (-7.7, -9.7, -11.7, -13.7)]


def build(c):
    shell(c)
    dressing(c)
    for i, row in enumerate(KIT):
        prop, u, v, facing = row[:4]
        flags = row[4] if len(row) > 4 else ""                         # e.g. __drive_<id>: a usable terminal
        f = FACE(c, facing)
        z = TRAY_Z if prop == "cable_tray" else 0.0
        c.empty(f"marker_kit_{prop}__srv{i}{flags}", W(c, u, v, c.GZ + z), math.degrees(math.atan2(f[1], f[0])) + 90.0)


def shell(c):
    RB(c, "srv_floor", U0 - 0.4, U1, V0 - 0.4, V1 + 0.4, -0.5, 0.0, c.M_FLOOR, col=True)
    RB(c, "srv_ceiling", U0 - 0.4, U1, V0 - 0.4, V1 + 0.4, H, H + 0.5, c.M_CON_T)
    RB(c, "srv_wall_front", U0 - 0.4, U1, V0 - 0.4, V0, 0.0, H, c.M_CON, col=True)
    RB(c, "srv_wall_back", U0 - 0.4, U1, V1, V1 + 0.4, 0.0, H, c.M_CON, col=True)
    RB(c, "srv_wall_end", U0 - 0.4, U0, V0, V1, 0.0, H, c.M_CON, col=True)
    RB(c, "srv_skirt_end", U0, U0 + 0.03, V0, V1, 0.0, 1.0, c.M_PLATE)                 # plate dado behind the console
    d0, d1, _dh = ROOM.SERVER_DOOR
    RB(c, "srv_sill", ROOM.U0 - 0.48, ROOM.U0 + 0.08, d0, d1, 0.0, 0.012, c.M_PLATE)
    for k, u in enumerate(LAMPS):
        RB(c, f"srv_lamp{k}", u - 0.6, u + 0.6, AISLE - 0.15, AISLE + 0.15, H - 0.1, H, c.M_LAMP)
        c.empty(f"marker_light_srv_{k}", W(c, u, AISLE, c.GZ + H - 0.3))


def dressing(c):
    fl = c.GZ + 0.012
    c.DECAL("srv_dust", W(c, (U0 + U1) / 2, AISLE, fl), V1 - V0, U1 - U0, "+z", c.D_DUST, up=FACE(c, "+u"), inside=True)
    c.DECAL("srv_stain", W(c, -11.8, V0 + 0.9, fl + 0.004), 1.4, 1.4, "+z", c.D_STAIN, inside=True)
    c.DECAL("srv_papers", W(c, -15.5, AISLE + 0.5, fl + 0.006), 1.2, 1.2, "+z", c.D_PAPERS, up=FACE(c, "-u"), inside=True)
    c.DECAL("srv_sign", W(c, U0 + 0.045, AISLE, c.GZ + 2.45), 1.7, 0.85, FACE(c, "+u"), c.D_DATA, inside=True)
    c.DECAL("srv_crack", W(c, -10.5, V1 - 0.035, c.GZ + 2.75), 0.5, 0.8, FACE(c, "in"), c.D_CRACK, inside=True)
    c.DECAL("srv_streak", W(c, U1 - 0.035, V1 - 0.9, c.GZ + 1.9), 1.2, 2.2, FACE(c, "-u"), c.D_STREAK, inside=True)
    for k in range(3):                              # launch control's mainframes -> through the door -> the first rack
        p0 = Vector(W(c, -4.9 - k * 0.45, 9.5, c.GZ + 0.03))
        p1 = Vector(W(c, ROOM.U0 + 0.2, 8.25 - k * 0.15, c.GZ + 0.03))
        p2 = Vector(W(c, -8.3 - k * 0.3, ROW_C - 0.55, c.GZ + 0.03))
        c.TUBE(f"srv_cable{k}a", p0, p1, 0.035, c.M_CABLE, 4, into=c.bore)
        c.TUBE(f"srv_cable{k}b", p1, p2, 0.035, c.M_CABLE, 4, into=c.bore)
    for k in range(2):                              # the missing rack's cables, hanging out of the tray to the floor
        top = Vector(W(c, -11.95 + k * 0.25, ROW_A + 0.1, c.GZ + TRAY_Z + 0.03))
        mid = Vector(W(c, -11.9 + k * 0.3, ROW_A + 0.25, c.GZ + 0.5))
        end = Vector(W(c, -11.6 + k * 0.4, ROW_A + 0.7 + k * 0.2, c.GZ + 0.03))
        c.TUBE(f"srv_drop{k}a", top, mid, 0.022, c.M_CABLE, 4, into=c.bore)
        c.TUBE(f"srv_drop{k}b", mid, end, 0.022, c.M_CABLE, 4, into=c.bore)
