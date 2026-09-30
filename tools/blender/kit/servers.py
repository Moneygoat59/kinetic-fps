"""Outpost 73 kit: server room. Same art rules (matte violet-black steel, colour only from lamps and screens); sizes in
kit_dims.py (SRV_*, TRAY_*), screen frames from tools/blender/server_textures.py.
server_rack       0.6 x 1.0 x 2.1 m cabinet, no front door: rails, blade handles, the equipment face is one emissive quad
                  (kit_scr_rack: activity LEDs flicker). Optional part `risers` (cables up into a cable_tray over it).
server_rack_open  the same cabinet gutted: door hanging open, blades pulled out or gone (one on the floor), cables spilling,
                  face kit_scr_rack_dead (two power lamps and a fault lamp).
terminal_server   the data room's operator console: desk, hutch with a big CRT (kit_scr_nodes: node status board),
                  keyboard, instrument bay, drive slots. Put a chair_steel in front of it.
crac_unit         1.2 x 0.8 x 2.2 m cooling cabinet: return grille, LCD (kit_scr_crac), alarm lamp, lower doors.
cable_tray        2 m ladder tray segment along Y with cables in it, hung on rods: origin = tray underside, the rods reach
                  TRAY_HANG (0.8 m) up, so mount it at ceiling - 0.8. Segments join end to end. No collision (overhead).
"""
import math

from mathutils import Vector

import kit_dims as K
import ps1_lib as L
from kit_lib import Kit
from terminals import _bezel

HW, HD = K.SRV_W / 2, K.SRV_D / 2
UH = K.SRV_FACE_H / K.SRV_UNITS                     # one rack unit on the face (m)
FACE_Y = -HD + 0.096                                # the equipment face, 2 mm proud of the recess back wall (y -0.402)


def _unit_z(i):
    """Centre height of rack unit i, counted from the top like the face texture's rows."""
    return K.SRV_FACE_Z + K.SRV_FACE_H - (i + 0.5) * UH


def _cabinet(k, face, gone=()):
    """Rack cabinet both racks share: plinth, body with the recessed equipment face, front frame, blade handles (none on
    the units in `gone`), vented cap, side streak, top dust, collision."""
    fw, fh, fz = K.SRV_FACE_W, K.SRV_FACE_H, K.SRV_FACE_Z
    k.B("plinth", (K.SRV_W - 0.04, K.SRV_D - 0.04, 0.08), (0, 0, 0.04), k.CABLE)
    body = k.B("body", (K.SRV_W, K.SRV_D, 2.0), (0, 0, 1.08), k.PLATE, 0.01)
    L.cut(body, L.box("recess", (fw + 0.02, 0.2, fh + 0.04), (0, -HD - 0.002, fz + fh / 2)))   # back wall at y = -0.4
    k.B("cap", (K.SRV_W + 0.02, K.SRV_D + 0.02, 0.03), (0, 0, K.SRV_H - 0.015), k.MET_D, 0.008)
    for i in range(5):
        k.B(f"vent{i}", (0.36, 0.03, 0.008), (0, -0.3 + i * 0.12, K.SRV_H + 0.002), k.CABLE)
    k.SCREEN("face", (0, FACE_Y, fz + fh / 2), fw, fh, face)
    k.B("frame_t", (K.SRV_W, 0.02, 0.05), (0, -HD - 0.01, fz + fh + 0.045), k.MET_D)
    k.B("frame_b", (K.SRV_W, 0.02, 0.05), (0, -HD - 0.01, fz - 0.045), k.MET_D)
    for s in (-1, 1):
        k.B(f"post{s}", (0.045, 0.02, fh + 0.14), (s * (HW - 0.0225), -HD - 0.01, fz + fh / 2), k.MET_D)
        k.B(f"rail{s}", (0.012, 0.09, fh), (s * (fw / 2 - 0.006), FACE_Y - 0.045, fz + fh / 2), k.MET)
    for i in range(K.SRV_UNITS):
        if i in gone or i % 2:
            continue
        for s in (-1, 1):
            k.B(f"ear{i}{s}", (0.018, 0.03, UH * 0.7), (s * (fw / 2 - 0.03), FACE_Y - 0.016, _unit_z(i)), k.MET_D)
    k.DECAL("streak", (HW + 0.001, 0.1, 1.3), 0.7, 1.2, k.D_STREAK, facing="+x")
    k.DECAL("dust", (0, 0, K.SRV_H + 0.008), K.SRV_W, K.SRV_D, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.COL((K.SRV_W + 0.02, K.SRV_D + 0.02, K.SRV_H), (0, 0, K.SRV_H / 2))


def _risers(k):
    """Cables from the cap up into a cable_tray hung over the rack at the silo room's height (optional part)."""
    lst = k.OPT("risers")
    top = K.SRV_H + 0.3                                  # tray rungs (silo: ceiling 3.2, tray origin 2.4, rungs +0.02)
    for i, (x, r) in enumerate(((-0.14, 0.022), (-0.06, 0.016), (0.1, 0.02))):
        k.PIPE(f"riser{i}", [(x, 0.32, K.SRV_H - 0.01), (x, 0.32, K.SRV_H + 0.14), (x * 0.6, 0.12, top + 0.02)], r,
               k.CABLE, verts=5, into=lst)


def server_rack():
    k = Kit("server_rack")
    _cabinet(k, k.scr("rack", "kit_screen_rack_a.png", 1.4))
    _risers(k)
    k.finish(subdiv=0.3, ao_dist=0.6)


def _blade(k, name, y_out, z, tilt=0.0, into=None):
    """A server blade slid y_out metres out of its slot (front plate, handles, a drive lamp that is dead now)."""
    parts = [k.B(f"{name}_case", (K.SRV_FACE_W - 0.04, 0.7, UH - 0.02), (0, FACE_Y + 0.35 - y_out, z), k.MET_D, 0.004, into=[]),
             k.B(f"{name}_front", (K.SRV_FACE_W - 0.02, 0.015, UH - 0.01), (0, FACE_Y - y_out - 0.008, z), k.PLATE, into=[])]
    for s in (-1, 1):
        parts.append(k.B(f"{name}_pull{s}", (0.02, 0.03, UH * 0.6), (s * 0.2, FACE_Y - y_out - 0.03, z), k.MET, into=[]))
    if tilt:
        L.rotate_about(parts, (0, FACE_Y, z), (tilt, 0, 0))
    (k.parts if into is None else into).extend(parts)
    return parts


def server_rack_open():
    k = Kit("server_rack_open")
    _cabinet(k, k.scr("rack_dead", "kit_screen_rack_dead_a.png", 1.4), gone=(2, 3, 7, 11))
    _risers(k)
    _blade(k, "blade2", 0.42, _unit_z(2))                              # pulled half out
    _blade(k, "blade7", 0.3, _unit_z(7), tilt=7.0)                     # pulled out, sagging on bent rails
    fallen = _blade(k, "blade3", 0.0, 0.0, into=[])                    # the one that came out lies on the floor
    L.rotate_about(fallen, (0, FACE_Y + 0.35, 0), (0, 0, 28))
    for o in fallen:                                                   # built round z 0: lift onto the floor, out front
        o.location += Vector((0.15, -0.95, (UH - 0.01) / 2))
    k.parts.extend(fallen)
    for i, (z, x) in enumerate(((_unit_z(3), 0.08), (_unit_z(11), -0.1))):   # cables spilling out of the empty slots
        k.PIPE(f"spill{i}", [(x, FACE_Y + 0.05, z), (x + 0.02, FACE_Y - 0.12, z - 0.06), (x + 0.1, FACE_Y - 0.3, 0.02),
                             (x + 0.2, FACE_Y - 0.55, 0.012)], 0.012, k.CABLE, verts=5)
    door = [k.B("door", (K.SRV_W - 0.04, 0.025, 1.92), (0, -HD - 0.035, 1.1), k.MET_D, 0.006, into=[])]
    for z0 in (0.35, 0.95, 1.55):                                      # louvred vent bands
        for i in range(6):
            door.append(k.B(f"door_louvre{z0}{i}", (0.4, 0.012, 0.022), (0, -HD - 0.052, z0 + i * 0.05), k.CABLE, into=[]))
    door.append(k.B("door_handle", (0.025, 0.035, 0.18), (-HW + 0.07, -HD - 0.06, 1.1), k.RUST, into=[]))
    L.rotate_about(door, (HW - 0.01, -HD - 0.035, 0), (0, 0, 104))      # hinged on the +x post, swung out into the aisle
    k.parts.extend(door)
    k.COL_COPY(door[0])
    k.finish(subdiv=0.3, ao_dist=0.6)


def terminal_server():
    k = Kit("terminal_server")
    top = 0.76
    for s in (-1, 1):                                                  # pedestals: two drawers each
        x = s * 0.68
        k.B(f"ped{s}", (0.44, 0.8, top - 0.02), (x, 0, (top - 0.02) / 2), k.PLATE, 0.01)
        for j, z in enumerate((0.22, 0.52)):
            k.B(f"drawer{s}{j}", (0.38, 0.02, 0.24), (x, -0.405, z), k.MET_D, 0.006)
            k.B(f"pull{s}{j}", (0.12, 0.025, 0.02), (x, -0.42, z + 0.08), k.RUST)
    k.B("modesty", (0.92, 0.02, 0.6), (0, 0.37, 0.42), k.MET_D)
    k.B("top", (1.84, 0.84, 0.04), (0, 0, top), k.MET, 0.01)
    # hutch along the back of the desk, the CRT housing standing out of its face
    k.B("hutch", (1.84, 0.42, 1.08), (0, 0.21, top + 0.02 + 0.54), k.PLATE, 0.015)                   # front face y = 0
    k.B("hutch_cap", (1.88, 0.48, 0.04), (0, 0.2, top + 1.12), k.MET_D, 0.01)
    k.B("crt", (0.84, 0.16, 0.66), (0, -0.08, 1.15), k.MET_D, 0.02)                                  # front face y = -0.16
    _bezel(k, 0, 1.16, 0.62, 0.46, -0.16)
    k.SCREEN("scr", (0, -0.162, 1.16), 0.62, 0.46, k.scr("nodes", "kit_screen_nodes_a.png", 1.3))
    k.B("visor", (0.84, 0.1, 0.025), (0, -0.2, 1.47), k.MET_D)
    k.PANEL("bay", (-0.62, -0.002, 1.62), 0.46, 0.23, k.CTRL)                                        # instrument bay
    for i in range(6):                                                                               # lamp row
        mat = (k.AMBER, k.BLINK, k.AMBER, k.GREEN, k.AMBER, k.RED)[i]
        k.B(f"lamp{i}", (0.035, 0.012, 0.025), (0.47 + i * 0.065, -0.006, 1.68), mat)
        k.B(f"sw{i}", (0.015, 0.025, 0.035), (0.47 + i * 0.065, -0.012, 1.6), k.MET)
    for i in range(6):                                                                               # speaker grille
        k.B(f"grille{i}", (0.34, 0.012, 0.018), (-0.62, -0.006, 1.02 + i * 0.045), k.CABLE)
    for j, z in enumerate((1.0, 1.1)):                                                               # drive slots
        k.B(f"slot{j}", (0.26, 0.012, 0.018), (0.62, -0.006, z), k.CABLE)
    k.B("drive_lamp", (0.03, 0.012, 0.018), (0.8, -0.006, 1.05), k.BLINK)
    k.DECAL("plate", (0.62, -0.0015, 1.24), 0.15, 0.056, k.D_PLATE)
    # keyboard wedge on the desk, keycap texture on its sloped top
    k.PRISM("kb", [(-0.40, 0.0), (-0.18, 0.0), (-0.18, 0.05), (-0.40, 0.03)], 0.5, (-0.25, 0, top + 0.02), k.MET_D, plane="yz")
    slope = math.degrees(math.atan2(0.02, 0.22))
    k.PANEL("keys", (0, -0.29, top + 0.061), 0.46, 0.19, k.KEYS, facing="+z", tilt=-slope, up=(0, 1, 0))
    k.CYL("mug", 0.04, 0.09, (-0.62, -0.22, top + 0.065), k.MET, v=8)
    k.B("mug_handle", (0.012, 0.035, 0.05), (-0.665, -0.22, top + 0.07), k.MET)
    k.B("binder", (0.3, 0.24, 0.04), (0.6, -0.2, top + 0.04), k.OCHRE, rot=(0, 0, 12))
    k.DECAL("papers", (0.42, -0.24, top + 0.022), 0.34, 0.34, k.D_PAPERS, facing="+z", up=(0, 1, 0))
    k.DECAL("dust", (0, 0.2, top + 1.142), 1.84, 0.46, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.DECAL("streak", (0.921, 0.2, 1.3), 0.4, 0.8, k.D_STREAK, facing="+x")
    for i, x in enumerate((-0.3, -0.22, 0.4)):                                                       # cables into the floor
        k.PIPE(f"cable{i}", [(x, 0.42, 0.9 + i * 0.1), (x, 0.5, 0.6), (x - 0.04, 0.52, 0.02), (x - 0.1, 0.8, 0.02)], 0.025,
               k.CABLE, verts=6)
    k.LIGHT("marker_light_screen", (0, -0.6, 1.15))
    k.COL((1.84, 0.84, top + 0.02), (0, 0, (top + 0.02) / 2))
    k.COL((1.84, 0.48, 1.12), (0, 0.2, top + 0.58))
    k.COL((0.84, 0.16, 0.66), (0, -0.08, 1.15))
    k.finish()


def crac_unit():
    k = Kit("crac_unit")
    hw, hd = 0.6, 0.4
    k.B("plinth", (1.16, 0.76, 0.08), (0, 0, 0.04), k.CABLE)
    k.B("body", (1.2, 0.8, 2.12), (0, 0, 1.14), k.PLATE, 0.015)                                      # front face y = -0.4
    k.B("cap", (1.24, 0.84, 0.03), (0, 0, 2.215), k.MET_D, 0.008)
    k.B("grille_frame", (1.08, 0.02, 0.66), (0, -hd - 0.01, 1.76), k.MET_D)                          # return-air grille
    for i in range(12):
        k.B(f"slat{i}", (1.0, 0.03, 0.02), (0, -hd - 0.03, 1.47 + i * 0.05), k.CABLE, rot=(-30, 0, 0))
    k.B("lcd_frame", (0.32, 0.012, 0.18), (-0.3, -hd - 0.006, 1.26), k.CABLE)
    k.SCREEN("lcd", (-0.3, -hd - 0.014, 1.26), 0.26, 0.13, k.scr("crac", "kit_screen_crac_a.png", 1.0))
    for i, mat in enumerate((k.AMBER, k.GREEN, k.BLINK)):
        k.B(f"lamp{i}", (0.035, 0.012, 0.025), (0.08 + i * 0.07, -hd - 0.006, 1.29), mat)
    k.PANEL("keys", (0.3, -hd - 0.003, 1.22), 0.1, 0.13, k.KEYPAD)
    for s in (-1, 1):                                                                                # lower service doors
        x = s * 0.29
        k.B(f"door{s}", (0.55, 0.02, 0.9), (x, -hd - 0.01, 0.62), k.MET_D, 0.006)
        k.B(f"handle{s}", (0.025, 0.035, 0.16), (x - s * 0.22, -hd - 0.03, 0.72), k.RUST)
        for i in range(5):
            k.B(f"louvre{s}{i}", (0.4, 0.012, 0.02), (x, -hd - 0.025, 0.28 + i * 0.045), k.CABLE)
    k.DECAL("haz", (0, -hd - 0.0015, 0.13), 1.2, 0.05, k.D_HAZARD)
    k.DECAL("plate", (0.3, -hd - 0.0015, 1.12), 0.15, 0.056, k.D_PLATE)
    k.DECAL("streak", (hw + 0.001, 0.1, 1.2), 0.6, 1.1, k.D_STREAK, facing="+x")
    k.DECAL("dust", (0, 0, 2.232), 1.2, 0.8, k.D_DUST, facing="+z", up=(0, 1, 0))
    k.PIPE("drain", [(hw - 0.1, -0.1, 1.95), (hw + 0.05, -0.1, 1.95), (hw + 0.05, -0.1, 0.0)], 0.025, clamps=0.5)
    k.LIGHT("marker_light_green", (-0.3, -0.6, 1.26))
    k.COL((1.24, 0.84, 2.23), (0, 0, 1.115))
    k.finish(ao_dist=0.7)


def cable_tray():
    k = Kit("cable_tray")
    w, ln = K.TRAY_W, K.TRAY_L
    for s in (-1, 1):
        k.B(f"rail{s}", (0.03, ln, 0.1), (s * w / 2, 0, 0.05), k.MET_D)
    for i in range(8):
        k.B(f"rung{i}", (w, 0.03, 0.015), (0, -ln / 2 + 0.125 + i * 0.25, 0.012), k.MET)
    for i, (x, r) in enumerate(((-0.17, 0.02), (-0.1, 0.016), (-0.04, 0.024), (0.04, 0.018), (0.11, 0.022), (0.17, 0.014))):
        k.TUBE(f"cable{i}", (x, -ln / 2, 0.02 + r), (x, ln / 2, 0.02 + r), r, k.CABLE, 5)
    k.TUBE("cable_top", (-0.07, -ln / 2, 0.075), (0.08, ln / 2, 0.07), 0.018, k.CABLE, 5)
    for y in (-ln / 2 + 0.25, ln / 2 - 0.25):                                                        # hangers
        k.B(f"strut{y}", (w + 0.12, 0.04, 0.04), (0, y, -0.02), k.MET_D)
        for s in (-1, 1):
            x = s * (w / 2 + 0.04)
            k.TUBE(f"rod{y}{s}", (x, y, -0.04), (x, y, K.TRAY_HANG), 0.008, k.MET, 4)
            k.B(f"anchor{y}{s}", (0.08, 0.08, 0.012), (x, y, K.TRAY_HANG - 0.006), k.MET_D)
    k.finish(subdiv=0.4, ao_dist=0.3, ground=False)


PROPS = {f.__name__: f for f in (server_rack, server_rack_open, terminal_server, crac_unit, cable_tray)}
