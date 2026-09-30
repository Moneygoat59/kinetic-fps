"""The walker's books (pure Python: apt_book_art.py paints them, the kit builders place them). Mostly self-help: anxiety, doubt,
habits, calm. Titles, authors and imprints are invented. One atlas, tex/apt_books.png: spines packed in rows along the top
(each spine SPINE_PX tall, as wide as its thickness at that scale, a SWATCH_PX strip under it holds the cover colour and the
page edges), front covers along the bottom.
A book: (title, author, imprint, style, bg, fg, accent, thickness, height, depth) in metres; colours are sRGB 0..255.
Styles: band (bold sans, bands top and bottom), serif (cloth hardcover, gilt-ish rules), paper (white paperback, coloured
title), block (colour block with the author on top), stack (thick: title words stacked upright), work (big workbook).
"""

SPINE_PX = 480
SWATCH_PX = 32
ROW_PX = SPINE_PX + SWATCH_PX
ATLAS_W = 2048
SPINE_ROWS = 3
COVER_H = 448
ATLAS_H = ROW_PX * SPINE_ROWS + COVER_H

B = [
    ("The Quiet Mind", "Helen Marsh", "harbor", "serif", (38, 52, 74), (222, 196, 132), (222, 196, 132), 0.032, 0.235, 0.16),
    ("Let It Be Enough", "Daniel Okafor", "lantern", "paper", (242, 238, 228), (196, 72, 52), (196, 72, 52), 0.024, 0.21, 0.14),
    ("GET UNSTUCK", "R. J. Whitfield", "north", "band", (232, 186, 48), (28, 28, 30), (28, 28, 30), 0.028, 0.215, 0.14),
    ("You Are Not Your Thoughts", "Dr. Anita Rao", "harbor", "block", (92, 142, 150), (250, 246, 236), (240, 214, 170), 0.03, 0.23, 0.155),
    ("THE WORRY TRAP", "Mark Ellison", "vesta", "band", (178, 44, 40), (250, 244, 232), (250, 244, 232), 0.026, 0.21, 0.14),
    ("Good Enough", "Claire Benton", "lantern", "paper", (246, 242, 234), (70, 110, 90), (228, 170, 60), 0.02, 0.2, 0.135),
    ("Breathe First", "Lena Voss", "north", "serif", (160, 190, 176), (40, 60, 56), (40, 60, 56), 0.022, 0.205, 0.14),
    ("10 MINUTES OF CALM", "Tom Harker", "vesta", "band", (70, 120, 180), (255, 255, 255), (250, 210, 80), 0.018, 0.195, 0.13),
    ("Living With Uncertainty", "Paul Wexler, PhD", "meridian", "serif", (98, 40, 46), (226, 202, 150), (226, 202, 150), 0.04, 0.24, 0.165),
    ("SMALL STEPS", "Maya Lindqvist", "harbor", "block", (236, 120, 70), (255, 250, 240), (60, 40, 30), 0.024, 0.21, 0.14),
    ("The Doubt Spiral", "J. P. Carrow", "meridian", "band", (32, 34, 40), (236, 200, 90), (236, 200, 90), 0.03, 0.235, 0.155),
    ("RESET YOUR BRAIN", "Dr. Sam Adeyemi", "vesta", "stack", (40, 150, 170), (255, 255, 255), (20, 40, 60), 0.045, 0.24, 0.16),
    ("Mindful Mornings", "Grace Holloway", "lantern", "paper", (250, 246, 238), (214, 128, 70), (120, 160, 190), 0.02, 0.2, 0.135),
    ("A Clear Head", "Nora Pike", "north", "block", (210, 214, 206), (40, 50, 60), (200, 70, 60), 0.022, 0.2, 0.135),
    ("Stop Checking", "Ben Aldous", "harbor", "band", (58, 86, 60), (240, 232, 210), (240, 232, 210), 0.026, 0.215, 0.14),
    ("The Art of Leaving It", "Ruth Calder", "meridian", "serif", (120, 70, 110), (238, 220, 180), (238, 220, 180), 0.028, 0.22, 0.15),
    ("WHAT IF?", "Owen Price", "vesta", "stack", (248, 208, 64), (30, 30, 36), (200, 50, 40), 0.034, 0.215, 0.14),
    ("Slow Down", "Ikumi Sato", "lantern", "paper", (244, 240, 230), (40, 70, 120), (40, 70, 120), 0.018, 0.195, 0.13),
    ("Be Kind To Your Brain", "Jo Whitaker", "north", "block", (238, 150, 150), (255, 252, 246), (120, 50, 60), 0.024, 0.21, 0.14),
    ("THE CALM WORKBOOK", "Dr. K. Hollis", "meridian", "work", (74, 160, 130), (255, 255, 255), (250, 230, 120), 0.022, 0.275, 0.215),
    ("Nothing Bad Will Happen", "E. M. Grant", "harbor", "serif", (46, 46, 52), (200, 200, 205), (170, 40, 40), 0.03, 0.225, 0.15),
    ("Permission To Rest", "Leah Moreno", "lantern", "paper", (240, 236, 226), (150, 110, 160), (150, 110, 160), 0.02, 0.2, 0.135),
    ("ONE THING AT A TIME", "Chris Aldana", "vesta", "band", (240, 110, 40), (255, 250, 240), (40, 40, 44), 0.026, 0.215, 0.14),
    ("Exposure, Step By Step", "Dr. M. Keane", "meridian", "work", (60, 90, 150), (255, 255, 255), (240, 190, 60), 0.024, 0.275, 0.215),
    ("The Kind Voice", "Sofia Lind", "north", "serif", (200, 170, 120), (60, 40, 30), (60, 40, 30), 0.026, 0.215, 0.145),
    ("Untangled", "Ada Brooks", "harbor", "paper", (248, 244, 236), (40, 140, 130), (230, 120, 90), 0.022, 0.2, 0.135),
    ("HABITS OF CALM", "Victor Nguyen", "vesta", "stack", (30, 60, 110), (255, 255, 255), (250, 200, 60), 0.04, 0.235, 0.155),
    ("Rewire", "Dr. Ellen Soto", "meridian", "block", (150, 40, 60), (255, 246, 236), (250, 200, 170), 0.028, 0.22, 0.145),
    ("The Gentle Guide to Anxiety", "Hana Mori", "lantern", "serif", (176, 196, 214), (30, 44, 70), (30, 44, 70), 0.03, 0.225, 0.15),
    ("LET GO OF PERFECT", "Amy Castell", "north", "band", (250, 250, 248), (220, 60, 90), (220, 60, 90), 0.022, 0.205, 0.135),
    ("Checked Twice", "Dr. P. Lawson", "harbor", "serif", (74, 60, 50), (222, 200, 160), (222, 200, 160), 0.036, 0.235, 0.16),
    ("THE PAUSE", "Ines Varga", "vesta", "stack", (240, 232, 214), (40, 40, 40), (210, 90, 50), 0.034, 0.215, 0.14),
    ("Calm, Vol. 1", "Tom Harker", "vesta", "band", (100, 170, 200), (255, 255, 255), (30, 60, 90), 0.02, 0.2, 0.135),
    ("Calm, Vol. 2", "Tom Harker", "vesta", "band", (100, 170, 200), (255, 255, 255), (30, 60, 90), 0.02, 0.2, 0.135),
    ("Calm, Vol. 3", "Tom Harker", "vesta", "band", (100, 170, 200), (255, 255, 255), (30, 60, 90), 0.02, 0.2, 0.135),
    ("Calm, Vol. 4", "Tom Harker", "vesta", "band", (100, 170, 200), (255, 255, 255), (30, 60, 90), 0.02, 0.2, 0.135),
    ("Brave Little Steps", "Maya Lindqvist", "harbor", "paper", (246, 240, 228), (90, 150, 80), (240, 170, 60), 0.02, 0.2, 0.135),
    ("Sleep, Finally", "Dr. Iris Kent", "north", "block", (44, 50, 90), (240, 230, 200), (240, 200, 110), 0.026, 0.21, 0.14),
    ("THE THOUGHT LOOP", "Marcus Hale", "meridian", "band", (120, 124, 130), (255, 255, 255), (230, 60, 50), 0.028, 0.22, 0.145),
    ("Enough Is Enough", "Carla Diaz", "lantern", "serif", (190, 90, 60), (250, 236, 210), (250, 236, 210), 0.026, 0.215, 0.145),
    ("Pocket Dictionary", "", "meridian", "band", (180, 30, 36), (240, 220, 140), (240, 220, 140), 0.04, 0.19, 0.12),
    ("Cooking For One", "Pat Ellery", "harbor", "block", (240, 226, 190), (60, 90, 60), (200, 80, 40), 0.024, 0.25, 0.19),
    ("The Clean Home", "Martha Quill", "north", "paper", (248, 248, 246), (40, 120, 180), (40, 120, 180), 0.022, 0.24, 0.18),
    ("STILLNESS", "Adele Fry", "vesta", "stack", (214, 206, 190), (40, 40, 40), (40, 40, 40), 0.032, 0.21, 0.14),
    ("The Anxious Brain, Explained", "Dr. Rob Fielding", "meridian", "serif", (58, 82, 70), (232, 220, 186), (232, 220, 186), 0.034, 0.23, 0.155),
    ("SAY NO, KINDLY", "Tess Moran", "vesta", "band", (206, 58, 70), (255, 255, 255), (255, 218, 120), 0.02, 0.2, 0.135),
    ("The Worry Journal", "Jun Park", "lantern", "paper", (246, 242, 232), (60, 100, 160), (240, 180, 70), 0.018, 0.21, 0.15),
    ("THE HABIT CURE", "Leo Brandt", "north", "band", (22, 92, 94), (250, 238, 206), (250, 238, 206), 0.028, 0.22, 0.145),
    ("Unclench", "Mira Solano", "harbor", "block", (240, 200, 178), (84, 40, 40), (160, 62, 52), 0.024, 0.205, 0.135),
    ("Feelings Are Not Facts", "Dr. Alan Chu", "meridian", "serif", (82, 52, 92), (236, 214, 170), (236, 214, 170), 0.03, 0.225, 0.15),
    ("TINY WINS", "Kate Oduya", "vesta", "stack", (248, 122, 92), (255, 255, 255), (40, 40, 60), 0.036, 0.215, 0.14),
    ("A Year of Calm Days", "Hannah Brook", "lantern", "paper", (250, 246, 236), (120, 150, 90), (120, 150, 90), 0.03, 0.2, 0.14),
    ("Hold Still", "Noor Haddad", "north", "serif", (196, 208, 200), (46, 60, 58), (46, 60, 58), 0.022, 0.205, 0.14),
    ("ANXIETY, UNPACKED", "Dr. Lucy Frame", "harbor", "band", (92, 70, 150), (255, 255, 255), (250, 200, 90), 0.026, 0.215, 0.14),
    ("The Overthinker's Handbook", "Greg Tolley", "meridian", "block", (230, 222, 120), (40, 40, 44), (40, 40, 44), 0.028, 0.22, 0.145),
    ("STOP. BREATHE. RESET.", "Dana Wells", "vesta", "band", (30, 30, 34), (255, 255, 255), (80, 200, 190), 0.022, 0.205, 0.135),
    ("When the Mind Won't Rest", "Dr. Omar Siddiq", "harbor", "serif", (30, 58, 90), (220, 200, 150), (220, 200, 150), 0.032, 0.23, 0.155),
    ("Soft Mornings", "Ella Grey", "lantern", "paper", (248, 240, 236), (200, 110, 120), (200, 110, 120), 0.018, 0.195, 0.13),
    ("THE OCD COMPANION", "Dr. R. Menon", "meridian", "work", (130, 60, 110), (255, 255, 255), (250, 210, 110), 0.026, 0.275, 0.215),
    ("MIND OVER DOUBT", "Karl Jensen", "north", "band", (50, 120, 90), (255, 255, 255), (250, 230, 150), 0.024, 0.21, 0.14),
    ("Stay Here", "Poppy Lane", "harbor", "block", (160, 200, 220), (30, 50, 70), (30, 50, 70), 0.022, 0.2, 0.135),
    ("Quiet Hands", "Ruth Calder", "meridian", "serif", (150, 90, 70), (246, 230, 200), (246, 230, 200), 0.026, 0.215, 0.145),
    ("THE WORRY-FREE WEEK", "Nadia Kerr", "vesta", "band", (250, 190, 60), (40, 30, 30), (40, 30, 30), 0.02, 0.2, 0.135),
    ("Letters to an Anxious Friend", "Tom Aske", "harbor", "serif", (104, 120, 90), (240, 228, 196), (240, 228, 196), 0.026, 0.215, 0.145),
    ("Clean Slate", "Joy Palmer", "lantern", "paper", (246, 244, 238), (30, 130, 170), (30, 130, 170), 0.02, 0.2, 0.135),
    ("PANIC, EXPLAINED", "Dr. Ivan Rusk", "meridian", "band", (190, 40, 50), (255, 244, 230), (255, 244, 230), 0.024, 0.215, 0.14),
    ("The Five-Minute Reset", "Lily Chen", "north", "block", (130, 200, 190), (30, 60, 60), (30, 60, 60), 0.022, 0.2, 0.135),
    ("Loosen Your Grip", "Sam Oyelaran", "harbor", "serif", (140, 60, 50), (240, 220, 180), (240, 220, 180), 0.028, 0.22, 0.145),
    ("ENOUGH FOR TODAY", "Beth Marlow", "vesta", "stack", (60, 70, 140), (255, 255, 255), (250, 190, 90), 0.034, 0.215, 0.14),
    ("Gentle Discipline", "Ann Weller", "lantern", "paper", (248, 244, 234), (170, 90, 60), (170, 90, 60), 0.02, 0.2, 0.135),
    ("The Uncertainty Muscle", "Dr. Jae Kim", "meridian", "block", (230, 230, 226), (200, 60, 50), (40, 40, 44), 0.028, 0.225, 0.15),
    ("Rituals That Heal", "Mara Quinn", "north", "serif", (70, 100, 120), (236, 224, 196), (236, 224, 196), 0.026, 0.215, 0.145),
    ("DON'T LOOK BACK", "Eric Salas", "vesta", "band", (40, 40, 44), (250, 200, 60), (250, 200, 60), 0.022, 0.205, 0.135),
    ("Everyday Courage", "Ruth Calder", "meridian", "serif", (160, 110, 60), (246, 234, 206), (246, 234, 206), 0.026, 0.215, 0.145),
    ("Soft Focus", "Iris Nolan", "lantern", "paper", (250, 244, 240), (140, 110, 170), (140, 110, 170), 0.018, 0.195, 0.13),
    ("Beyond Reassurance", "Dr. N. Farrow", "harbor", "block", (200, 220, 160), (50, 70, 40), (50, 70, 40), 0.026, 0.215, 0.145),
    ("THE STEADY MIND", "Paul Wexler, PhD", "meridian", "band", (30, 80, 70), (240, 220, 160), (240, 220, 160), 0.03, 0.225, 0.15),
    ("A Little Less", "Kim Harrow", "north", "paper", (244, 240, 230), (220, 90, 70), (220, 90, 70), 0.018, 0.195, 0.13),
    ("Present Tense", "Ola Brandt", "vesta", "block", (255, 170, 120), (60, 30, 30), (60, 30, 30), 0.024, 0.21, 0.14),
    ("Calm, Vol. 5", "Tom Harker", "vesta", "band", (100, 170, 200), (255, 255, 255), (30, 60, 90), 0.02, 0.2, 0.135),
]

# books shown face-out somewhere (index into B): their front covers go along the bottom of the atlas
COVERS = [0, 3, 11, 19, 20, 26]


def spine_px(i):
    """Width in pixels of book i's spine (thickness at SPINE_PX per height)."""
    t, h = B[i][7], B[i][8]
    return max(12, round(SPINE_PX * t / h))


def _layout():
    rects, x, row = [], 0, 0
    for i in range(len(B)):
        w = spine_px(i)
        if x + w > ATLAS_W:
            x, row = 0, row + 1
        rects.append((x, row * ROW_PX, w))
        x += w + 2
    if row >= SPINE_ROWS:
        raise ValueError(f"apt_books: {len(B)} spines need {row + 1} rows, atlas has {SPINE_ROWS}")
    return rects


SPINES = _layout()          # i -> (x, y, w) in pixels, top-left origin


def cover_px(i):
    """Width in pixels of book i's front cover (COVER_H tall)."""
    return round(COVER_H * B[i][9] / B[i][8])


def _cover_layout():
    rects, x = {}, 0
    for i in COVERS:
        w = cover_px(i)
        rects[i] = (x, ROW_PX * SPINE_ROWS, w)
        x += w + 2
    if x > ATLAS_W:
        raise ValueError("apt_books: covers do not fit the atlas width")
    return rects


COVER_RECTS = _cover_layout()


def _uv(x0, y0, x1, y1):
    """Pixel rect (top-left origin) -> Blender UV rect (u0, v0, u1, v1), v up."""
    return (x0 / ATLAS_W, 1 - y1 / ATLAS_H, x1 / ATLAS_W, 1 - y0 / ATLAS_H)


def spine_uv(i):
    x, y, w = SPINES[i]
    return _uv(x + 0.5, y + 0.5, x + w - 0.5, y + SPINE_PX - 0.5)


def colour_uv(i):
    """Plain cover colour (left half of the swatch strip under the spine)."""
    x, y, w = SPINES[i]
    return _uv(x + 2, y + SPINE_PX + 4, x + w // 2 - 1, y + ROW_PX - 4)


def pages_uv(i, across=True):
    """Page edges (right half of the swatch): lines run along v; across=False turns them."""
    x, y, w = SPINES[i]
    return _uv(x + w // 2 + 1, y + SPINE_PX + 4, x + w - 2, y + ROW_PX - 4)


def cover_uv(i):
    x, y, w = COVER_RECTS[i]
    return _uv(x + 0.5, y + 0.5, x + w - 0.5, y + COVER_H - 0.5)
