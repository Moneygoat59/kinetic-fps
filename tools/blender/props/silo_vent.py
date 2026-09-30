"""Missile Silo 00: the open vent in the generator hall. Called by missile_silo.py as build(c) after silo_hall. A duct
(vent duct kit, tools/blender/kit/ducts.py) runs out of the hall's far end wall (silo_hall.A1) just above the floor: its
grille is off and leans against the wall beside the mouth. Inside, it runs RUN straight metres into the rock, turns
outward (away from the bore) and runs on to a blanking cap: the end, for now (the next place goes there).
Far-wall frame (far_xy): x = radius along the end wall's ray, y = into the rock (away from the hall; the end wall's hall
face is y 0). Markers: marker_kit_duct_* (the run, in order), marker_vent_mouth (hall floor in front of the mouth),
marker_vent_end (the crawl spot in front of the cap), marker_light_vent_mouth / _bend (SiloPit: the lamp over the mouth,
a faint amber spill at the turn).
"""
import math
import os
import sys

from mathutils import Vector

import ps1_lib as L
import silo_hall as HALL

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "kit"))
from kit_dims import DUCT_H, DUCT_MOUTH, DUCT_T, DUCT_W  # noqa: E402

X = 73.0                                  # the mouth's radius on the end wall (clear of the floor channel's drain at RM)
LIFT = 0.5                                # the duct's floor above the hall floor
RUN = 4.0                                 # straight metres behind the mouth stub before the turn
OUT = 4.0                                 # straight metres after the turn before the cap


def far_xy(x, y, z=0.0):
    a = math.radians(HALL.A1)
    return (x * math.cos(a) + y * math.sin(a), x * math.sin(a) - y * math.cos(a), z)


def far_dir(dx, dy):
    """A direction in the far-wall frame, in world xy."""
    p, o = Vector(far_xy(dx, dy)), Vector(far_xy(0.0, 0.0))
    return (p - o).normalized()


def yaw_front(d):
    """Yaw (deg) that turns a kit piece's front (local -Y) to face world direction d (xy)."""
    return math.degrees(math.atan2(d.x, -d.y))


def build(c):
    z = c.FL + LIFT
    into, out, back = far_dir(0.0, 1.0), far_dir(1.0, 0.0), far_dir(0.0, -1.0)
    hw = DUCT_W / 2 + DUCT_T + 0.02
    for target in ("hall_end_far", "hall_end_far_c"):
        L.cut(bpy_obj(target), L.vprism(f"cut_vent_{target}", [far_xy(x, y)[:2] for x, y in ((X - hw, -0.2), (X + hw, -0.2),
                                                                                              (X + hw, DUCT_MOUTH + 0.1), (X - hw, DUCT_MOUTH + 0.1))],
                                        z - DUCT_T - 0.02, z + DUCT_H + DUCT_T + 0.02))
    run = [("duct_mouth", X, 0.0, yaw_front(back))]
    y = DUCT_MOUTH
    for k in range(int(RUN / 2.0)):
        run.append(("duct_straight", X, y + 1.0, yaw_front(back)))
        y += 2.0
    run.append(("duct_bend", X, y + 1.0, yaw_front(out)))       # walked in at its +X edge, out at its -Y edge: a left turn
    x, y = X + 1.0, y + 1.0
    for k in range(int(OUT / 2.0)):
        run.append(("duct_straight", x + 1.0, y, yaw_front(out)))
        x += 2.0
    run.append(("duct_cap", x, y, yaw_front(-out)))
    for i, (piece, px, py, yaw) in enumerate(run):
        c.empty(f"marker_kit_{piece}__vent{i}", far_xy(px, py, z), yaw)
    _check_bend(c, into, out)
    grille = L.empty("marker_kit_duct_grille__vent", far_xy(X - 1.9, -0.42, c.FL + 0.01))
    grille.rotation_euler = (math.radians(72.0), 0.0, math.radians(yaw_front(back) - 8.0))   # leaning back on the wall
    lamp = far_xy(X, -0.12, z + DUCT_H + 0.75)                       # a caged wall lamp over the mouth
    c.B("vent_lamp", (0.3, 0.2, 0.18), lamp, c.M_LAMP, rot=(0, 0, HALL.A1), into=c.hall)
    c.B("vent_lamp_cage", (0.4, 0.28, 0.05), far_xy(X, -0.12, z + DUCT_H + 0.87), c.M_MET_D, rot=(0, 0, HALL.A1), into=c.hall)
    L.empty("marker_light_vent_mouth", far_xy(X, -0.6, z + DUCT_H + 0.6))
    L.empty("marker_light_vent_bend", far_xy(X + 0.6, DUCT_MOUTH + RUN + 1.0, z + DUCT_H * 0.6))   # amber spilling round the turn
    L.empty("marker_vent_mouth", far_xy(X, -1.2, c.FL))
    L.empty("marker_vent_end", far_xy(x - 0.9, y, z))
    c.DECAL("vent_dust", far_xy(X, -0.9, c.FL + 0.012), 2.2, 1.4, "+z", c.D_DUST, up=tuple(into), into=c.hall_dec)


def _check_bend(c, into, out):
    """The bend's +X edge must face back down the run (the way in) for the turn to go outward."""
    a = math.radians(yaw_front(out))
    plus_x = Vector((math.cos(a), math.sin(a), 0.0))
    assert plus_x.dot(Vector((-into.x, -into.y, 0.0))) > 0.99, "silo_vent: duct_bend faces the wrong way"


def bpy_obj(name):
    import bpy
    return bpy.data.objects[name]
