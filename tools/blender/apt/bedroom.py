"""Apartment kit: bedroom. Origin on the floor, back on y = 0, front -Y.
bed_double      1.4 x 2.0, head on y = 0: hospital-cornered, duvet folded back to an exact band, two pillows mirrored, knit throw
                squared across the foot; marker_use_sleep
nightstand      drawer labelled PILLS, top at apt_dims.NIGHT_H (the organizer, bottles and lamp go on it)
dresser         six labelled drawers, top at apt_dims.DRESSER_H
wardrobe_open   sliding doors parked left: eight identical shirts evenly spaced, sweaters stacked edge to edge, labelled shoe boxes
"""
import apt_dims as D
import ps1_lib as L
from apt_lib import AptKit


BED_W, BED_L, BED_TOP = 1.44, 2.04, 0.56                                                   # mattress top at BED_TOP


def bed_frame(k, sheet=None):
    """Headboard, rails, legs, footboard and the mattress (in `sheet`, default linen): shared by bed_double and
    mess_home.bed_unmade. Also its collision and the SLEEP use."""
    w, l, top = BED_W, BED_L, BED_TOP
    k.B("headboard", (w + 0.06, 0.06, 0.96), (0, -0.03, 0.48), k.WOOD, 0.01)
    k.SOFT("headboard_cap", (w + 0.1, 0.08, 0.05), (0, -0.03, 0.985), k.WOOD, 0.02, step=0.1)
    for s in (-1, 1):
        k.B(f"rail{s}", (0.05, l - 0.06, 0.2), (s * (w / 2 - 0.025), -l / 2, 0.24), k.WOOD, 0.006)
        k.CYL(f"leg{s}", 0.03, 0.16, (s * (w / 2 - 0.04), -l + 0.04, 0.08), k.WOOD_D, v=12)
    k.B("footboard", (w, 0.05, 0.3), (0, -l + 0.025, 0.28), k.WOOD, 0.008)
    k.SOFT("mattress", (w - 0.06, l - 0.1, 0.22), (0, -l / 2 - 0.01, top - 0.11), sheet or k.LINEN, 0.05, step=0.12)
    k.COL((w, l, 0.62), (0, -l / 2, 0.31))
    k.COL((w + 0.06, 0.06, 1.0), (0, -0.03, 0.5))
    k.USE("sleep", (0, -1.1, 0.65))


def bed_double():
    k = AptKit("bed_double")
    w, l, top = BED_W, BED_L, BED_TOP
    bed_frame(k)
    dl = 1.5                                                                              # duvet: over the top, draped down the sides
    k.SOFT("duvet", (w + 0.02, dl, 0.3), (0, -l + 0.06 + dl / 2, top + 0.065 - 0.15), k.DUVET, 0.075, puff=0.02, step=0.1)
    k.SOFT("fold", (w + 0.03, 0.26, 0.1), (0, -l + 0.04 + dl - 0.1, top + 0.08), k.LINEN, 0.045, puff=0.01, step=0.08)
    for s in (-1, 1):                                                                     # two pillows, mirrored
        k.SOFT(f"pillow{s}", (0.62, 0.4, 0.16), (s * 0.34, -0.27, top + 0.07), k.LINEN, 0.075, puff=0.035, axis="z", step=0.06,
               rot=(-7, 0, 0))
    k.SOFT("throw", (w - 0.16, 0.38, 0.04), (0, -l + 0.32, top + 0.085), k.RUSTF, 0.018, puff=0.006, step=0.08)
    k.finish(wall=True, subdiv=0.3, ao_dist=0.5)


def _drawer(k, name, x, z, w, h, y, word):
    k.B(name, (w - 0.02, 0.02, h - 0.02), (x, y, z), k.WOOD, 0.004)
    k.TUBE(name + "_pull", (x - 0.05, y - 0.022, z + h * 0.18), (x + 0.05, y - 0.022, z + h * 0.18), 0.007, k.BRASS)
    for sx in (-1, 1):
        k.B(f"{name}_post{sx}", (0.008, 0.014, 0.008), (x + sx * 0.045, y - 0.014, z + h * 0.18), k.BRASS)
    if word:
        k.LABEL(word, (x, y - 0.0105, z - h * 0.12), 0.07)


def nightstand():
    k = AptKit("nightstand")
    w, d, h = 0.46, 0.4, D.NIGHT_H
    k.B("case", (w, d, h - 0.1), (0, -d / 2, 0.1 + (h - 0.1) / 2), k.WOOD)
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        for y in (-d + 0.03, -0.03):
            k.B(f"leg{x}{y}", (0.035, 0.035, 0.1), (x, y, 0.05), k.WOOD_D)
    _drawer(k, "drawer", 0, h - 0.1, w, 0.16, -d - 0.01, "PILLS")
    k.B("shelf_gap", (w - 0.04, 0.01, 0.2), (0, -d + 0.004, 0.25), k.BLACK)
    k.COL((w, d, h), (0, -d / 2, h / 2))
    k.finish(wall=True, subdiv=0.2, ao_dist=0.3)


def dresser():
    k = AptKit("dresser")
    w, d, h = 1.1, 0.5, D.DRESSER_H
    k.B("case", (w, d, h - 0.08), (0, -d / 2, 0.08 + (h - 0.08) / 2), k.WOOD, 0.006)
    k.B("plinth", (w - 0.04, d - 0.04, 0.08), (0, -d / 2, 0.04), k.WOOD_D)
    words = (("SOCKS", "SHIRTS"), ("PANTS", "SHEETS"), ("TOWELS", "WINTER"))
    for r, row in enumerate(words):
        z = h - 0.14 - r * 0.24
        for c, word in enumerate(row):
            _drawer(k, f"d{r}{c}", (c - 0.5) * w / 2, z, w / 2 - 0.02, 0.23, -d - 0.01, word)
    k.COL((w, d, h), (0, -d / 2, h / 2))
    k.finish(wall=True, subdiv=0.25, ao_dist=0.35)


def wardrobe_open():
    k = AptKit("wardrobe_open")
    w, d, h = 1.0, 0.6, 2.0
    k.B("back", (w, 0.02, h), (0, -0.01, h / 2), k.WOOD_L)
    for s in (-1, 1):
        k.B(f"side{s}", (0.02, d, h), (s * (w / 2 - 0.01), -d / 2, h / 2), k.WOOD_L)
    k.B("top", (w, d, 0.02), (0, -d / 2, h - 0.01), k.WOOD_L)
    k.B("bottom", (w, d, 0.08), (0, -d / 2, 0.04), k.WOOD_L)
    k.B("shelf", (w - 0.04, d - 0.04, 0.02), (0, -d / 2, 1.7), k.WOOD_L)
    k.TUBE("rail", (-w / 2 + 0.02, -d / 2, 1.6), (w / 2 - 0.02, -d / 2, 1.6), 0.012, k.CHROME)
    shirt = L.material("apt_shirt", (0.18, 0.22, 0.28))
    for i in range(8):                                                                       # identical, 10 cm apart
        x = -0.35 + i * 0.1
        k.TUBE(f"hook{i}", (x, -d / 2, 1.62), (x, -d / 2, 1.56), 0.004, k.CHROME)
        k.B(f"hanger{i}", (0.012, 0.4, 0.02), (x, -d / 2, 1.55), k.WOOD)
        k.SOFT(f"shirt{i}", (0.035, 0.44, 0.72), (x, -d / 2, 1.18), shirt, 0.015, step=0.08)
    for i in range(4):                                                                       # sweaters, edge to edge
        k.SOFT(f"sweater{i}", (0.38, 0.32, 0.06), (-0.22, -d / 2, 1.74 + i * 0.06), k.KNIT, 0.022, step=0.08)
    for i in range(2):
        for j in range(2):
            x, z = -0.22 + i * 0.44, 0.14 + j * 0.13
            k.B(f"box{i}{j}", (0.36, 0.3, 0.12), (x, -d / 2 - 0.05, z), k.CARD, 0.004)
            k.LABEL("SHOES", (x, -d / 2 - 0.2005, z), 0.08)
    for i, y in enumerate((-d - 0.012, -d - 0.036)):                                      # sliding doors, both parked left
        k.B(f"door{i}", (w / 2 - 0.01, 0.022, h - 0.1), (-w / 4 + 0.005 * i, y, h / 2 + 0.04), k.WOOD_L, 0.004)
        k.B(f"pull{i}", (0.02, 0.012, 0.16), (-0.06 - 0.005 * i, y - 0.015, 1.05), k.BRASS)
    for z in (0.09, h - 0.02):
        k.B(f"track{z}", (w, 0.06, 0.018), (0, -d - 0.03, z), k.CHROME)
    k.COL((w, d, h), (0, -d / 2, h / 2))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.4)


PROPS = {f.__name__: f for f in (bed_double, nightstand, dresser, wardrobe_open)}
