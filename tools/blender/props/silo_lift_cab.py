"""Missile Silo 00's freight lift cage (silo_lift.py builds the shaft, frame and gates round it): the shell, its fittings and
the art laid on its inside. Built at the top (level 09) in the hall's end-wall frame (silo_hall.shaft_xy: x along the ray at
A0, y toward the room); SiloLift drives the whole node down the shaft. Built like the hall it rides into: chamfered
box-section steel (pilasters on the wall joints, a cornice, ceiling beams), not thin bars.
  silo_lift_cab       floor, side walls with pilasters / cornice / bump rail, corner posts, roof and its beams, guide
                      shoes, the caged lamp, conduit to the control panel (two glowing buttons, a stop button), hatch,
                      tie-down plates, the guide channels the gates rise in
  silo_lift_cab_art   opaque quads with their own UVs (never world-projected) laid 1-2 cm proud of the surfaces: the two
                      wall panels, floor, ceiling, capacity plate and panel face (tools/blender/lift_textures.py and
                      lift_fixtures.py; python those first). Image directions are noted at lay_art.
"""
import ps1_lib as L
import silo_hall as HALL

XY = HALL.shaft_xy
CAB = (64.0, -2.0)                        # cage centre (frame x, y)
CAB_W, CAB_H = 3.2, 2.6
IN = CAB_W / 2 - 0.1                      # centre to a side wall's inner face
GATE_LINE = 1.55                          # centre to a cage gate's plane
PANEL = (0.8, 0.5, 0.8, 1.25)             # control panel face: centre (y from cage centre), width, height, centre height
BUTTONS = ((0.32, 0.43), (0.32, 0.61))    # glowing buttons on the face, fractions from its top left (lift_fixtures.py: keep equal)
STOP = (0.5, 0.75)


def box(c, name, x0, x1, y0, y1, z0, z1, mat, into, col=False, chamfer=0.0):
    """Box in the end-wall frame (x0..x1, y0..y1, world z0..z1); chamfer only on parts at least 4x as thick."""
    size, loc = (x1 - x0, y1 - y0, z1 - z0), XY((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    if mat is not None:
        c.B(name, size, loc, mat, chamfer, rot=(0, 0, HALL.A0), into=into)
    if col:
        c.COL(name + "_c", size, loc, (0, 0, HALL.A0))


def build(c, into, art):
    """The cage at the top, floor at level 09."""
    x, y, z = CAB[0], CAB[1], c.GZ
    shell(c, into, x, y, z)
    walls(c, into, x, y, z)
    roof(c, into, x, y, z)
    gate_channels(c, into, x, y, z)
    panel(c, into, x, y, z)
    lay_art(c, art, x, y, z)


def shell(c, into, x, y, z):
    h = CAB_W / 2
    box(c, "cab_floor", x - h, x + h, y - h, y + h, z - 0.25, z, c.M_PLATE, into)
    for s in (-1, 1):
        box(c, f"cab_haz{s}", x - 1.4, x + 1.4, y + s * (h - 0.08) - 0.06, y + s * (h - 0.08) + 0.06, z, z + 0.025, c.M_HAZ_T, into)
        wx = x + s * (h - 0.05)
        box(c, f"cab_wall{s}", wx - 0.05, wx + 0.05, y - h, y + h, z, z + CAB_H - 0.1, c.M_MET_D, into)
        for sy in (-1, 1):
            box(c, f"cab_post{s}{sy}", wx - 0.08, wx + 0.08, y + sy * h - 0.08, y + sy * h + 0.08, z, z + CAB_H, c.M_MET_D, into,
                chamfer=0.015)
        box(c, f"cab_shoe{s}", x + s * (h + 0.05) - 0.1, x + s * (h + 0.05) + 0.1, y - 0.2, y + 0.2, z + CAB_H, z + CAB_H + 0.5,
            c.M_RUST, into)
    box(c, "cab_roof", x - h, x + h, y - h + 0.15, y + h - 0.15, z + CAB_H, z + CAB_H + 0.1, c.M_MET_D, into)  # gates rise past
    box(c, "cab_crosshead", x - h - 0.1, x + h + 0.1, y - 0.25, y + 0.25, z + CAB_H + 0.1, z + CAB_H + 0.6, c.M_RUST, into)
    for k, (sx, sy) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):   # tie-down plates with an eye each
        box(c, f"lc_tie{k}", x + sx * 1.3 - 0.07, x + sx * 1.3 + 0.07, y + sy * 1.3 - 0.07, y + sy * 1.3 + 0.07, z + 0.008, z + 0.03,
            c.M_MET_D, into)
        c.CYL(f"lc_tie_eye{k}", 0.045, 0.05, XY(x + sx * 1.3, y + sy * 1.3, z + 0.05), c.M_RUST, v=6, into=into)


def walls(c, into, x, y, z):
    """Each side wall: pilasters on the panel joints (art seams at the quarters), a cornice over the top 0.16 m, a lip
    above the hazard band and a bump rail on brackets. The control panel stands where the +x wall's third pilaster would."""
    for s in (-1, 1):
        wx = x + s * IN
        for dy in (-0.8, 0.0, 0.8):
            if s == 1 and dy == 0.8:
                continue
            box(c, f"lc_pil{s}{dy}", *sorted((wx, wx - s * 0.06)), y + dy - 0.08, y + dy + 0.08, z + 0.02, z + 2.34, c.M_MET_D, into,
                chamfer=0.015)
        box(c, f"lc_cornice{s}", *sorted((wx, wx - s * 0.08)), y - 1.5, y + 1.5, z + 2.34, z + 2.5, c.M_MET_D, into, chamfer=0.015)
        box(c, f"lc_lip{s}", *sorted((wx, wx - s * 0.04)), y - 1.5, y + 1.5, z + 0.3, z + 0.33, c.M_MET_D, into)
        rx = wx - s * 0.075
        box(c, f"lc_rail{s}", *sorted((rx - 0.03, rx + 0.03)), y - 1.4, y + 1.4, z + 0.69, z + 0.76, c.M_MET, into, chamfer=0.012)
        for dy in (-1.2, 0.0, 1.2):
            box(c, f"lc_brk{s}{dy}", *sorted((wx, rx)), y + dy - 0.035, y + dy + 0.035, z + 0.66, z + 0.78, c.M_MET_D, into)


def roof(c, into, x, y, z):
    """The caged lamp (glowing lens, rim, wire guard), two beams across the roof, the junction and conduit down to the
    panel, the inspection hatch's hinges and handle (art: lift_textures.ceiling)."""
    zt = z + CAB_H
    box(c, "lc_lens", x - 0.28, x + 0.28, y - 0.13, y + 0.13, zt - 0.11, zt - 0.09, c.M_LAMP, into)      # glows
    for k, (a, b, cc, d) in enumerate(((-0.36, 0.36, -0.2, -0.16), (-0.36, 0.36, 0.16, 0.2), (-0.36, -0.32, -0.2, 0.2),
                                       (0.32, 0.36, -0.2, 0.2))):
        box(c, f"lc_rim{k}", x + a, x + b, y + cc, y + d, zt - 0.14, zt, c.M_MET_D, into)
    for k, dx in enumerate((-0.24, -0.08, 0.08, 0.24)):
        c.TUBE(f"lc_guard{k}", XY(x + dx, y - 0.2, zt - 0.16), XY(x + dx, y + 0.2, zt - 0.16), 0.012, c.M_MET_D, 4, into=into)
    for k, dy in enumerate((-0.1, 0.1)):
        c.TUBE(f"lc_guardx{k}", XY(x - 0.36, y + dy, zt - 0.16), XY(x + 0.36, y + dy, zt - 0.16), 0.012, c.M_MET_D, 4, into=into)
    for s in (-1, 1):                                                     # beams over the two gate lines
        box(c, f"lc_beam{s}", x - IN, x + IN, y + s * 1.38 - 0.07, y + s * 1.38 + 0.07, zt - 0.14, zt, c.M_MET_D, into, chamfer=0.015)
    box(c, "lc_junction", x + 0.4, x + 0.58, y - 0.09, y + 0.09, zt - 0.1, zt, c.M_MET_D, into)
    cx, cy = x + IN - 0.04, y + PANEL[0]
    for k, (p, q) in enumerate(((XY(x + 0.58, y, zt - 0.045), XY(cx, y, zt - 0.045)),
                                (XY(cx, y, zt - 0.045), XY(cx, cy, zt - 0.045)),
                                (XY(cx, cy, zt - 0.045), XY(cx, cy, z + PANEL[3] + PANEL[2] / 2 + 0.03)))):
        c.TUBE(f"lc_conduit{k}", p, q, 0.025, c.M_MET_D, 5, into=into)
    for k, px in enumerate((0.85, 1.15)):
        box(c, f"lc_clamp{k}", x + px - 0.03, x + px + 0.03, y - 0.05, y + 0.05, zt - 0.09, zt, c.M_RUST, into)
    hx, hy = x + 0.82, y - 0.9                                            # hatch, 0.8 m square
    box(c, "lc_hatch_handle", hx - 0.09, hx + 0.09, hy - 0.03, hy + 0.03, zt - 0.05, zt - 0.01, c.M_MET, into)
    for k, dx in enumerate((-0.25, 0.25)):
        box(c, f"lc_hatch_hinge{k}", hx + dx - 0.05, hx + dx + 0.05, hy + 0.38, hy + 0.44, zt - 0.03, zt, c.M_MET_D, into)


def gate_channels(c, into, x, y, z):
    """The channels either side of each cage gate that it rises in (the cage's gates, LiftGate, slide up the outside)."""
    for s in (-1, 1):
        for side in (-1, 1):
            gx = x + side * 1.455
            box(c, f"lc_chan{s}{side}", gx - 0.045, gx + 0.045, y + s * GATE_LINE - 0.09, y + s * GATE_LINE + 0.09, z + 0.02, z + 4.7,
                c.M_MET_D, into, chamfer=0.012)


def panel(c, into, x, y, z):
    """Control panel on the +x wall near the level 09 gate: a housing with a hood, two glowing buttons, the stop button."""
    dy, w, ph, pz = PANEL
    fx = x + IN

    def at(fu, fv):                                                       # face fractions -> frame y, world z
        return y + dy + (0.5 - fu) * w, z + pz + (0.5 - fv) * ph

    box(c, "lc_panel", fx - 0.07, fx, y + dy - w / 2 - 0.03, y + dy + w / 2 + 0.03, z + pz - ph / 2 - 0.03, z + pz + ph / 2 + 0.03,
        c.M_MET_D, into, chamfer=0.012)
    box(c, "lc_panel_hood", fx - 0.12, fx, y + dy - w / 2 - 0.04, y + dy + w / 2 + 0.04, z + pz + ph / 2 + 0.03, z + pz + ph / 2 + 0.06,
        c.M_MET_D, into)
    for k, (fu, fv) in enumerate(BUTTONS):
        by, bz = at(fu, fv)
        box(c, f"lc_btn{k}", fx - 0.115, fx - 0.072, by - 0.045, by + 0.045, bz - 0.045, bz + 0.045, c.M_KEY, into)
    by, bz = at(*STOP)
    c.CYL("lc_stop", 0.055, 0.05, XY(fx - 0.1, by, bz), c.M_HAZ, v=10, into=into, rot=(0, 90, HALL.A0))


def lay_art(c, art, x, y, z):
    """Opaque art quads. Wall images: right = frame +y on the -x wall, -y on the +x wall; floor: up = toward level 09,
    right = +x; ceiling: up = toward level 09, right = -x; panel and plate hang on the +x wall (left = +y)."""
    m = {n: L.tex_material(f"silo_lift_{n}", c.T(f"lift_{n}.png")) for n in ("wall_a", "wall_b", "floor", "ceiling", "plate", "panel")}
    up_y = XY(0.0, 1.0)
    c.DECAL("lc_wall_p", XY(x + IN - 0.006, y, z + 1.25), CAB_W, 2.5, XY(-1.0, 0.0), m["wall_b"], into=art)
    c.DECAL("lc_wall_n", XY(x - IN + 0.006, y, z + 1.25), CAB_W, 2.5, XY(1.0, 0.0), m["wall_a"], into=art)
    c.DECAL("lc_floor", XY(x, y, z + 0.008), 3.0, 3.0, "+z", m["floor"], up=up_y, into=art)
    c.DECAL("lc_ceiling", XY(x, y, z + CAB_H - 0.008), 3.0, 2.9, "-z", m["ceiling"], up=up_y, into=art)
    c.DECAL("lc_plate", XY(x + IN - 0.014, y - 0.4, z + 1.55), 0.62, 0.375, XY(-1.0, 0.0), m["plate"], into=art)
    c.DECAL("lc_panel_face", XY(x + IN - 0.072, y + PANEL[0], z + PANEL[3]), PANEL[1], PANEL[2], XY(-1.0, 0.0), m["panel"], into=art)
