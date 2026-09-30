"""Shared numbers for the apartment kit (pure Python: used by the Blender builders, the shell generator and apt_textures.py).
Metres, Blender axes (Z up, front -Y = Godot +Z). Mirror any number the runtime needs in scripts/apartment/apt_kit.gd."""

# ---------------------------------------------------------------- architecture (tools/blender/apt/apt_shell.py)
CEILING = 2.7                 # floor to ceiling
WALL_T = 0.14                 # interior partition (two 0.07 room skins back to back)
EXT_T = 0.3                   # exterior wall
DOOR_W, DOOR_H = 1.0, 2.1     # interior door opening (the player capsule is 0.8 wide: keep >= 0.95 clear with the leaf open)
FRONT_W, FRONT_H = 1.0, 2.15  # entry door opening
WIN_W, WIN_H, WIN_SILL = 1.2, 1.4, 0.9   # window opening and sill height
BASE_H = 0.1                  # baseboard height
LEAF_T = 0.04                 # door leaf thickness

# ---------------------------------------------------------------- furniture heights (tabletop props go at these)
COUNTER_H = 0.92              # kitchen worktop
COUNTER_D = 0.62
UPPER_Z = 1.45                # underside of the wall cabinets
TABLE_H = 0.75                # dining table top
COFFEE_H = 0.42               # coffee table top
NIGHT_H = 0.56                # nightstand top
DRESSER_H = 0.86
VANITY_H = 0.84
SIDE_H = 0.55                 # living-room side table top

# ---------------------------------------------------------------- atlases (apt_textures.py draws them, builders map them)
LABELS = ["FORKS", "SPOONS", "KNIVES", "TOWELS", "FOIL", "BAGS", "PILLS", "SOCKS", "SHIRTS", "SALT", "SUGAR", "RICE",
          "FLOUR", "TEA", "CHECKED", "DO NOT", "PANTS", "SHEETS", "SHOES", "WINTER"]
RX = [("SERTRALINE", "100MG", "TAKE 2 TABS DAILY"),
      ("FLUVOXAMINE", "50MG", "1 TAB AT BEDTIME"),
      ("CLOMIPRAMINE", "25MG", "1 CAP 3X DAILY"),
      ("HYDROXYZINE", "25MG", "AS NEEDED - ANXIETY")]
CANS = [(176, 48, 40), (220, 150, 50), (70, 120, 70), (60, 90, 150), (200, 180, 90), (130, 60, 90)]
ART_CELLS = 2                 # apt_art.png is a 2 x 2 grid of prints


def label_uv(word):
    """UV rect (u0, v0, u1, v1) of a label-maker word in apt_labels.png (rows top to bottom; Blender v = 0 at the bottom)."""
    i = LABELS.index(word)
    n = len(LABELS)
    return (0.0, 1 - (i + 1) / n, 1.0, 1 - i / n)


def row_uv(i, n):
    """UV rect of row i of an n-row horizontal-strip atlas (rx, cans)."""
    return (0.0, 1 - (i + 1) / n, 1.0, 1 - i / n)


def cell_uv(i, cols=ART_CELLS):
    """UV rect of cell i (row-major from the top-left) in a cols x cols atlas (apt_art.png)."""
    r, c = divmod(i, cols)
    return (c / cols, 1 - (r + 1) / cols, (c + 1) / cols, 1 - r / cols)

# apt_mess.png (apt_mess_textures.py): 4 x 4 cells of 128 px, row-major from the top-left; the squalor pieces (mess.py) map them
MESS = ["pizza_lid", "pizza_in", "carton", "chips", "can_cola", "can_lime", "can_energy", "can_orange", "flyer", "receipt",
        "envelope", "notice", "ship_label", "crust", "stain_card", "tissue"]


def mess_uv(name, inset=0.0):
    """UV rect of a named cell of apt_mess.png (inset in cell fractions trims the edges)."""
    r, c = divmod(MESS.index(name), 4)
    e = inset / 4
    return (c / 4 + e, 1 - (r + 1) / 4 + e, (c + 1) / 4 - e, 1 - r / 4 - e)
