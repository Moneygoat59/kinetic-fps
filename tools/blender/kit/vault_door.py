"""Records vault: the round doorway through the vault wall and its door (built by vault.py). The wall (VAULT_WALL thick,
front face at y = VAULT_APPROACH) has a round doorway (DOOR_R at DOOR_ZC); the floor runs straight through its foot on a
steel sill. A steel frame ring and liner, a pintle on the left. The leaf is a stepped disc (flange DOOR_FLANGE, plug that
fits the doorway, 14 locking bolts round the plug, bolt-work on its back, a spoked wheel and a combination dial on its
face) cut flat just over the floor. It is node `door` (origin on the pintle axis at floor level), modelled standing
swung out DOOR_OPEN degrees onto the dock; its collision and the dial's face decal are static (the door never moves yet).
"""
import math

import bpy

import ps1_lib as L
from junction import lathe
from kit_dims import DOOR_FLANGE, DOOR_HINGE, DOOR_OPEN, DOOR_R, DOOR_ZC, VAULT_APPROACH, VAULT_CLEAR, VAULT_HW, VAULT_WALL, WALK_Z

F = WALK_Z
Y0 = VAULT_APPROACH                  # the wall's front face (tunnel side)
BOLTS = 14


def _disc(name, r0, r1, y0, y1, mat, segs=32):
    """Ring (r0 > 0) or disc (r0 = 0) about the doorway axis (along Y), from y0 to y1."""
    prof = [(max(r0, 0.001), y0), (r1, y0), (r1, y1), (max(r0, 0.001), y1)]
    o = lathe(name, prof, mat, segs=segs)                   # built about Z (its z = our y) ...
    L.rotate_about([o], (0, 0, 0), (-90, 0, 0))             # ... then turned so Z runs along Y: (x, y, z) -> (x, z, -y)
    o.location = (0, 0, DOOR_ZC)
    return _apply(o)


def _apply(o):
    bpy.context.view_layer.update()
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def _floor_cut(o, top=F + 0.02):
    """Cut a part flat at `top`: the floor runs through the doorway's foot."""
    L.cut(o, L.fast_box("cut", (8.0, 4.0, 4.0), (0.0, Y0 + 0.5, top - 2.0)))
    return o


def doorway(k):
    """The wall with its round doorway, the sill, the frame ring and the liner. Returns nothing: parts go into the kit."""
    top = F + VAULT_CLEAR + 0.5
    wall = L.fast_box("vault_wall", (2 * VAULT_HW + 0.8, VAULT_WALL, top + 0.5), (0, Y0 + VAULT_WALL / 2, (top - 0.5) / 2), k.CON)
    L.cut(wall, L.fast_cylinder("hole", DOOR_R, VAULT_WALL + 0.4, (0, Y0 + VAULT_WALL / 2, DOOR_ZC), None, 32, (90, 0, 0)))
    k.parts.append(wall)
    k.COL_COPY(wall)
    sill_h = F - (DOOR_ZC - DOOR_R)
    k.B("sill", (2 * DOOR_R - 0.2, VAULT_WALL + 0.1, sill_h), (0, Y0 + VAULT_WALL / 2, F - sill_h / 2), k.PLATE)
    k.COL((2 * DOOR_R, VAULT_WALL + 0.1, sill_h), (0, Y0 + VAULT_WALL / 2, F - sill_h / 2))
    k.parts.append(_floor_cut(_disc("frame", DOOR_R, DOOR_R + 0.42, Y0 - 0.1, Y0, k.MET_D)))
    k.parts.append(_floor_cut(_disc("frame_in", DOOR_R, DOOR_R + 0.25, Y0 + VAULT_WALL, Y0 + VAULT_WALL + 0.05, k.MET_D)))
    k.parts.append(_floor_cut(_disc("liner", DOOR_R - 0.03, DOOR_R + 0.01, Y0 - 0.1, Y0 + VAULT_WALL + 0.05, k.MET)))
    for i in range(20):
        a = math.tau * i / 20
        x, z = (DOOR_R + 0.3) * math.cos(a), DOOR_ZC + (DOOR_R + 0.3) * math.sin(a)
        if z > F + 0.08:
            k.CYL(f"frame_bolt{i}", 0.035, 0.04, (x, Y0 - 0.12, z), k.RUST, "y", 6)
    hx, hy = DOOR_HINGE                                                    # the pintle and its wall brackets
    k.CYL("pintle", 0.1, 3.0, (hx, hy, F + 1.55), k.MET_D, "z", 10)
    for z in (F + 0.15, F + 2.95):
        k.B(f"pintle_bracket{z:.1f}", (0.3, Y0 - hy + 0.05, 0.16), (hx + 0.05, (hy + Y0) / 2, z), k.MET_D)
    k.COL_CYL(0.14, 3.0, (hx, hy, F + 1.55))


def leaf(k):
    """The door leaf, built closed, then swung open about the pintle; node `door`."""
    parts = k.PIVOT("door", (DOOR_HINGE[0], DOOR_HINGE[1], F))
    yf = Y0 - 0.34                                                         # the flange's front face
    for name, r0, r1, y0, y1, mat in (("flange", 0.0, DOOR_FLANGE, yf, Y0 - 0.12, k.MET_D),
                                      ("plug", 0.0, DOOR_R - 0.03, Y0 - 0.12, Y0 + VAULT_WALL - 0.25, k.MET),
                                      ("step", 0.0, DOOR_FLANGE - 0.35, yf - 0.05, yf, k.MET_D),
                                      ("gear", 0.0, 0.5, Y0 + VAULT_WALL - 0.25, Y0 + VAULT_WALL - 0.2, k.RUST)):
        parts.append(_floor_cut(_disc(name, r0, r1, y0, y1, mat)))
    parts.append(_disc("hub", 0.0, 0.3, yf - 0.13, yf - 0.05, k.MET_D, 16))
    yw = yf - 0.3                                                          # the wheel
    rim = [(0.55 * math.cos(a * math.tau / 16), yw, DOOR_ZC + 0.55 * math.sin(a * math.tau / 16)) for a in range(17)]
    k.PIPE("wheel", rim, 0.03, k.MET, verts=6, into=parts)
    for i in range(3):
        a = math.tau * i / 3 + 0.5
        end = (0.55 * math.cos(a), yw, DOOR_ZC + 0.55 * math.sin(a))
        k.TUBE(f"spoke{i}", (0, yf - 0.1, DOOR_ZC), end, 0.025, k.MET, 6, into=parts)
        k.TUBE(f"grip{i}", end, (end[0] * 1.12, yw - 0.02, DOOR_ZC + (end[2] - DOOR_ZC) * 1.12), 0.028, k.RUST, 6, into=parts)
    k.TUBE("axle", (0, yf - 0.05, DOOR_ZC), (0, yw - 0.04, DOOR_ZC), 0.06, k.MET_D, 8, into=parts)
    dial = (-0.72, yf - 0.03, DOOR_ZC + 0.62)
    k.CYL("dial", 0.14, 0.06, dial, k.MET_D, "y", 16, into=parts)
    face = k.DECAL("dial_face", (dial[0], yf - 0.062, dial[2]), 0.26, 0.26, k.D_DIAL)   # static (in `decals`)
    k.B("plate", (0.5, 0.02, 0.22), (0.62, yf - 0.06, DOOR_ZC + 0.85), k.MET_D, into=parts)
    for i in range(BOLTS):                                                 # locking bolts and the bolt-work linking them
        a = math.tau * (i + 0.5) / BOLTS
        c, s = math.cos(a), math.sin(a)
        if DOOR_ZC + 1.35 * s < F + 0.12:
            continue
        yb = Y0 + 0.35
        k.TUBE(f"bolt{i}", (1.3 * c, yb, DOOR_ZC + 1.3 * s), (1.72 * c, yb, DOOR_ZC + 1.72 * s), 0.07, k.MET, 8, into=parts)
        yb = Y0 + VAULT_WALL - 0.18
        k.TUBE(f"link{i}", (0.45 * c, yb, DOOR_ZC + 0.45 * s), (1.3 * c, yb, DOOR_ZC + 1.3 * s), 0.03, k.RUST, 5, into=parts)
    for z in (F + 0.7, F + 2.4):                                           # hinge arms to the pintle
        x0 = -math.sqrt(max(DOOR_FLANGE ** 2 - (z - DOOR_ZC) ** 2, 0.0)) + 0.1
        hx, hy = DOOR_HINGE
        k.B(f"arm{z:.1f}", (x0 - hx, 0.2, 0.22), ((x0 + hx) / 2, hy + 0.12, z), k.MET_D, into=parts)
        k.CYL(f"knuckle{z:.1f}", 0.16, 0.3, (hx, hy, z), k.MET_D, "z", 10, into=parts)
    col = L.box("door_col", (2 * DOOR_FLANGE, VAULT_WALL + 0.1, DOOR_ZC + DOOR_FLANGE - F - 0.05),
                (0, Y0 + 0.3, (DOOR_ZC + DOOR_FLANGE + F + 0.05) / 2), None)
    k.cols.append(col)
    bpy.context.view_layer.update()
    L.rotate_about(parts + [col, face], (DOOR_HINGE[0], DOOR_HINGE[1], 0), (0, 0, DOOR_OPEN))
