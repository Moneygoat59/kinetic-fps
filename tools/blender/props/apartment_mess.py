"""Apartment 4C gone to squalor: where the rubbish and neglect lie (the flat after night 4). Called by apartment.py; each row
becomes a marker_mess_<piece>__<n> empty that AptSqualor spawns on those mornings only (tidy pieces are swapped in
AptSqualor.SWAPS: bed, fruit bowl, bin, blinds). Same plan coordinates as apartment.py (Blender x east, y north).
Paths stay open: the front door, the kitchen arch, the bedroom and bathroom doors, the walk from the bed to the window.
Floor litter has no collision; bags and cartons do.
"""
import apt_dims as D

COFFEE, TABLE, COUNTER, NIGHT = D.COFFEE_H, D.TABLE_H, D.COUNTER_H, D.NIGHT_H

ROWS = (
    # the front door: weeks of post under it, the bags never taken out heaped along the wall, deliveries never unpacked
    ("mail_pile", 4.62, -2.4, 0, -90),
    ("trash_heap", 4.5, -1.2, 0, -90),
    ("parcel_boxes", 3.7, -3.3, 0, 0),
    ("pizza_tower", 3.1, -3.33, 0, 5),
    ("trash_bag_white", 4.1, -0.45, 0, 60),
    # living room: the sofa end is where they live now
    ("pizza_box_open", -3.85, -1.85, COFFEE, 15),
    ("takeout", -3.3, -1.95, COFFEE, -20),
    ("mug_mould", -4.15, -2.05, COFFEE, 0),
    ("paper_cup", -3.55, -1.72, COFFEE, 0),
    ("pizza_stack", -2.7, -2.45, 0, 25),
    ("pizza_box", -2.35, -2.9, 0.0, -35),
    ("bottles_litter", -4.5, -2.45, 0, 40),
    ("clothes_pile", -4.25, -1.05, 0, 10),
    ("clothes_pile_small", -1.2, -3.1, 0, -40),
    ("trash_heap_small", 1.1, -0.35, 0, 0),
    ("trash_bag_slump", -4.55, -0.75, 0, 110),
    # the dining table: the dishes came here and stayed
    ("dish_pile", 2.5, -1.82, TABLE, 10),
    ("counter_clutter", 3.05, -1.55, TABLE, 180),
    ("paper_cup", 2.35, -1.5, TABLE, 0),
    ("pizza_box", 3.55, -2.65, 0, 25),
    ("pizza_box_open", 1.9, -2.3, 0, -70),
    # kitchen: the bin gave up; the bags stand in front of the fridge and along the wall
    ("trash_heap_small", 1.75, 2.55, 0, 0),
    ("trash_heap", 4.55, 1.4, 0, 90),
    ("dish_pile", 4.65, 3.12, COUNTER, -5),
    ("pot_crusted", 4.02, 3.3, COUNTER, 20),
    ("mug_mould", 4.3, 3.05, COUNTER, 0),
    ("takeout", 2.35, 3.12, COUNTER, 40),
    ("paper_cup", 2.75, 3.08, COUNTER, 0),
    # bedroom: clothes where they came off, the night's cups and bottles
    ("clothes_pile", -2.35, 2.45, 0, 20),
    ("clothes_pile_small", -4.3, 1.5, 0, -30),
    ("mug_mould", -4.62, 3.22, NIGHT, 0),
    ("paper_cup", -2.72, 3.25, NIGHT, 0),
    ("bottles_litter", -4.6, 2.3, 0, 0),
    ("trash_bag_slump", -1.82, 3.25, 0, 0),
    ("pizza_box", -4.55, 3.1, 0.0, 15),
    # bathroom
    ("towel_floor", -0.7, 1.9, 0, 20),
    ("towel_floor", 0.2, 2.35, 0, -60),
    ("clothes_pile_small", 0.35, 3.0, 0, 100),
    ("bottles_litter", 0.45, 1.55, 0, 70),
    ("trash_bag_white", -0.95, 0.75, 0, -20),
)

# floors: overlapping carpets of rubbish (no collision: the walker wades through it), three seeds turned every way
SPREADS = (
    (-3.0, -2.6, 20), (-4.3, -1.6, 80), (2.0, -2.8, 10), (3.6, -1.2, -60),      # round the sofa, the table, the door
    (3.1, 2.0, 30),                                                                 # kitchen
    (-2.3, 2.6, -10),                                                               # bedroom
    (-0.3, 1.5, 45),                                                                # bathroom
)


def place(S):
    for name, x, y, z, yaw in ROWS:
        S.mess(name, x, y, z, yaw)
    for i, (x, y, yaw) in enumerate(SPREADS):
        S.mess("litter_spread_" + "abc"[i % 3], x, y, 0.0, yaw)
