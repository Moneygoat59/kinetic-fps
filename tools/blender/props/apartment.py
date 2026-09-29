"""Apartment 4C: the one-bedroom flat the walker cannot leave (the first level). One plan for apt_shell.py; the furniture is
apartment-kit pieces placed through marker_kit_* empties (spawned live by scenes/levels/apartment.tscn -> ApartmentLevel).
Run: python tools/blender/apt_textures.py; tools\\blender.ps1 tools/blender/props/apt_kit.py; tools\\blender.ps1 tools/blender/props/apartment.py
     then godot --headless --path . --import.   Output: models/generated/apartment.glb.
Plan (Blender x east, y north; Godot (x, z, -y)): living room across the south (x -5..5, y -3.6..0.2, three south windows and
one west window: the low sun comes in from the south-west), bedroom / bathroom / kitchen along the north behind a 14 cm
partition. Front door on the east wall, locked four ways.
What the flat says about them: everything squared and in even numbers, tape marks where things go back, labels on every drawer,
every knob taped at OFF, caps in every socket, tallies by the door and the switch, pharmacy bottles in rows, labels forward.
One frame is crooked.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "..", "apt"))
sys.path.insert(0, HERE)
import apartment_mess  # noqa: E402
import apt_dims as D  # noqa: E402
from apt_shell import Shell  # noqa: E402

S = Shell("apartment")
H = D.CEILING
LIV = S.paint("living", (0.95, 0.86, 0.72))           # warm cream
BED = S.paint("bedroom", (0.7, 0.78, 0.72))           # sage
KIT = S.paint("kitchen", (0.97, 0.93, 0.84))          # warm white
BATH = S.paint("bath", (0.95, 0.95, 0.93))
WOOD = S.surface("floor_wood", "apt_wood_floor.png")
CHECK = S.surface("checker", "apt_checker.png")
HEX = S.surface("hex", "apt_tile_hex.png")
TILE = S.surface("tile_bath", "apt_tile_bath.png")
SUB = S.surface("tile_subway", "apt_tile_subway.png")

# ---------------------------------------------------------------- rooms and openings
S.room("living", -5.0, -3.6, 5.0, 0.2, LIV, WOOD)
S.room("bedroom", -5.0, 0.34, -1.4, 3.6, BED, WOOD)
S.room("bath", -1.26, 0.34, 0.9, 3.6, BATH, HEX)
S.room("kitchen", 1.04, 0.34, 5.0, 3.6, KIT, CHECK)
S.split("bath", 1.2, TILE)
PART = (0.15, 0.39)                                    # y range through the partition
S.opening(-2.0 - D.DOOR_W / 2, PART[0], -2.0 + D.DOOR_W / 2, PART[1], 0.0, D.DOOR_H)   # bedroom door
S.opening(-0.2 - D.DOOR_W / 2, PART[0], -0.2 + D.DOOR_W / 2, PART[1], 0.0, D.DOOR_H)   # bathroom door
S.opening(1.5, PART[0], 4.4, PART[1], 0.0, 2.25, arch=True)               # kitchen arch
S.opening(4.95, -2.9, 5.6, -1.9, 0.0, D.FRONT_H)                          # front door
SOUTH = (-3.7, -0.9, 2.2)
for x in SOUTH:
    S.opening(x - D.WIN_W / 2, -4.2, x + D.WIN_W / 2, -3.55, D.WIN_SILL, D.WIN_SILL + D.WIN_H)
for y in (-1.6, 2.0):                                                     # living and bedroom west windows
    S.opening(-5.6, y - D.WIN_W / 2, -4.95, y + D.WIN_W / 2, D.WIN_SILL, D.WIN_SILL + D.WIN_H)
KW, KZ = 3.24, 0.23                                                       # kitchen window over the sink: casing clears the stove's backguard
S.opening(KW - D.WIN_W / 2, 3.55, KW + D.WIN_W / 2, 4.2, D.WIN_SILL + KZ, D.WIN_SILL + KZ + D.WIN_H)
S.envelope()

# splashback, avoiding the window
for x0, x1, z1 in ((1.48, KW - 0.6, 1.45), (KW - 0.6, KW + 0.6, D.WIN_SILL + KZ - 0.03), (KW + 0.6, 5.0, 1.45)):
    S.band(f"splash{x0}", (x0, 3.59, D.COUNTER_H), (x1, 3.6, z1), SUB)

# ---------------------------------------------------------------- outside the windows (emissive backdrop, no shadows)
S.view("view_s", (0, -14.0, 2.5), 40, 20, "+y")
S.view("view_w", (-15.0, 0, 2.5), 40, 20, "+x")
S.view("view_n", (0, 14.0, 2.5), 40, 20, "-y")

# ---------------------------------------------------------------- pieces: (name, x, y, z, yaw, flags, proxy)
P = S.piece
box = lambda sx, sy, sz, ly=0.0: ((sx, sy, sz), (0, ly, sz / 2))  # noqa: E731
# fixtures
P("door_interior", -2.0, 0.34, 0, 180, ("open",))
P("door_interior", -0.2, 0.34, 0, 180, ("open",))
P("door_front", 5.0, -2.4, 0, -90)
for x in SOUTH:
    P("window_blinds", x, -3.6, 0, 180)
P("window_blinds_raised", -5.0, -1.6, 0, 90)
P("window_blinds", -5.0, 2.0, 0, 90)
P("window_blinds", KW, 3.6, KZ, 0, ("no_sill",))                         # no stool: it would cut the backguard
for x, y, yaw in ((-0.9, -3.6, 180), (2.2, -3.6, 180), (-5.0, 2.0, 90), (-5.0, -1.6, 90)):
    P("radiator", x, y, 0, yaw, proxy=box(0.9, 0.2, 0.64, -0.12))
for x, y, yaw in ((5.0, -1.65, -90), (-2.68, 0.34, 180), (0.42, 0.2, 0), (4.7, 0.2, 0), (-1.26, 0.8, 90)):
    P("light_switch", x, y, 1.2, yaw)
for x, y, z, yaw in ((-2.3, -3.6, 0.3, 180), (0.9, -3.6, 0.3, 180), (4.7, 0.2, 0.3, 0), (-2.2, 3.6, 0.3, 0), (-1.4, 1.2, 0.3, -90),
                     (2.0, 3.6, 1.12, 0), (4.3, 3.6, 1.12, 0), (-1.26, 2.1, 1.0, 90)):
    P("outlet", x, y, z, yaw)
P("ceiling_pendant", 2.8, -1.7, H)
for x, y in ((0.6, -1.6), (-3.2, 1.2)):
    P("smoke_detector", x, y, H)
# living room: lounge in the west half, the dining table and the door in the east
P("sofa", -3.7, -3.1, 0, 180, proxy=box(2.0, 0.9, 0.85))
P("rug_living", -3.7, -1.9, 0, 90)
P("coffee_table", -3.7, -1.9, 0, 0, proxy=box(1.1, 0.6, 0.42))
P("tv_console", -3.7, -0.02, 0, 0, proxy=box(1.6, 0.42, 0.5))
P("wall_clock", -3.7, 0.2, 2.12, 0)
P("bookshelf", -5.0, -0.35, 0, 90, proxy=box(0.9, 0.3, 1.9, -0.15))
P("floor_lamp", -4.7, -3.3, 0, 0)
P("side_table", -2.35, -3.25, 0, 0)
P("table_lamp", -2.35, -3.25, D.SIDE_H, 0)
P("armchair", -1.8, -1.9, 0, -90, proxy=box(0.82, 0.8, 0.9))
P("plant_snake", 4.7, -0.15, 0, 0)
for name, x, z, roll in (("picture_frame_a", 0.62, 1.87, 0), ("picture_frame_b", 1.1, 1.87, 0), ("picture_frame_c", 0.62, 1.35, 0),
                         ("picture_frame_d", 1.1, 1.35, 4.0)):                  # the last one hangs crooked
    P(name, x, 0.2, z, 0, roll=roll)
P("dining_table", 2.8, -1.7, 0, 0, proxy=box(0.9, 0.7, 0.75))
P("chair_wood", 2.8, -2.28, 0, 180)
P("chair_wood", 2.8, -1.22, 0, 0)
P("shoe_tray", 4.72, -3.27, 0, -90)
P("shoes_pair", 4.72, -3.12, 0.006, -90)
P("shoes_pair_b", 4.72, -3.42, 0.006, -90)
# kitchen: one run along the north wall
for name, x, w in (("fridge", 1.86, 0.76), ("counter_drawers", 2.54, 0.6), ("counter_sink", 3.24, 0.8), ("stove", 4.02, 0.76),
                   ("counter_base", 4.7, 0.6)):
    P(name, x, 3.6, 0, 0, proxy=box(w, 0.64, 1.78 if name == "fridge" else D.COUNTER_H, -0.32))
P("trash_bin", 1.28, 3.3, 0, 0)
P("wall_cabinet", 1.86, 3.6, 0.4, 0)                                     # over the fridge, clear of the window casing
P("wall_cabinet", 4.7, 3.6, 0, 0)
P("wall_shelf_pantry", 1.04, 2.0, 0, 90)
P("canisters", 2.54, 3.47, D.COUNTER_H, 0)
P("dish_rack", 2.6, 3.2, D.COUNTER_H, 0)
P("kettle", 4.53, 3.44, D.COUNTER_H, 0)
P("toaster", 4.83, 3.42, D.COUNTER_H, 0)
P("fruit_bowl", 2.8, -1.56, D.TABLE_H, 0)
# bathroom
P("bathtub", -0.46, 3.6, 0, 0, proxy=box(1.6, 0.75, 0.57, -0.375))
P("toilet", 0.9, 2.2, 0, -90, proxy=box(0.5, 0.72, 0.8, -0.36))
P("vanity", -1.26, 1.5, 0, 90, proxy=box(0.8, 0.5, 0.84, -0.25))
P("medicine_cabinet", -1.26, 1.5, 1.55, 90)
P("vanity_light", -1.26, 1.5, 2.08, 90)
P("towel_rack", 0.9, 1.1, 1.2, -90)
P("bath_mat", -0.46, 2.5, 0, 0)
P("tp_pyramid", 0.76, 2.65, 0, -90)
P("cleaning_row", 0.78, 0.75, 0, -90)
P("soap_stack", 0.3, 3.3, 0.57, 90)
# bedroom
P("bed_double", -3.5, 3.6, 0, 0, proxy=box(1.44, 2.04, 0.62, -1.02))
for x in (-4.45, -2.55):
    P("nightstand", x, 3.6, 0, 0, proxy=box(0.46, 0.4, D.NIGHT_H, -0.2))
P("table_lamp", -4.45, 3.43, D.NIGHT_H, 0)
P("table_lamp", -2.68, 3.45, D.NIGHT_H, 0)
P("alarm_clock", -4.28, 3.3, D.NIGHT_H, -25)
P("pill_organizer", -2.55, 3.26, D.NIGHT_H, 0)
for name, x in (("pill_bottle", -2.48), ("pill_bottle_tall", -2.39)):                  # tonight's two, beside the organizer
    P(name, x, 3.52, D.NIGHT_H, 0)
P("water_glass", -2.4, 3.37, D.NIGHT_H, 0)
P("dresser", -1.4, 2.35, 0, -90, proxy=box(1.1, 0.5, 0.86, -0.25))
P("book_stack", -1.65, 2.2, D.DRESSER_H, -90)
P("blister_pack", -1.65, 2.62, D.DRESSER_H, -90)
P("wardrobe_open", -5.0, 0.845, 0, 90, proxy=box(1.0, 0.6, 2.0, -0.3))        # west wall, left of the window: walk-up room
P("picture_frame_a", -3.5, 3.6, 1.55, 0)

# ---------------------------------------------------------------- decals: tape, tallies, pencil
TB = "tape_blue"


def tape_corners(cx, cy, hx, hy, n=0.12):
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = cx + sx * hx, cy + sy * hy
            S.decal(f"tc{x}{y}a", TB, (x - sx * n / 2, y, 0.003), n, 0.025, "+z", (0, 1, 0))
            S.decal(f"tc{x}{y}b", TB, (x, y - sy * n / 2, 0.0031), n, 0.025, "+z", (1, 0, 0))


tape_corners(-3.7, -3.1, 1.02, 0.47)                                          # where the sofa goes back
tape_corners(-1.8, -1.9, 0.43, 0.42)                                          # the armchair
tape_corners(2.8, -1.7, 0.47, 0.37)                                           # the table
tape_corners(4.72, -3.27, 0.19, 0.32)                                         # the shoe tray
S.decal("door_line", TB, (4.15, -2.4, 0.003), 1.1, 0.05, "+z", (1, 0, 0))    # a line on the floor in front of the door
S.decal("tally_switch", "tally", (4.995, -1.42, 1.25), 0.16, 0.32, "-x")
S.decal("tally_bed", "tally", (-1.405, 0.95, 1.2), 0.12, 0.24, "-x")
S.decal("pencil", "pencil", (0.86, 0.199, 1.61), 1.0, 0.5, "-y")

# ---------------------------------------------------------------- the flat gone to squalor (spawned only after night 4)
apartment_mess.place(S)

# ---------------------------------------------------------------- gameplay anchors
S.marker("marker_spawn", (-2.3, 1.05, 0.0), 58)                               # beside the bed, facing the window light
S.finish()
