"""Apartment kit: books (titles and art in apt_books.py / tex/apt_books.png, geometry apt_forms.book).
bookshelf   five shelves: tall books on the bottom one, the rest sorted by colour (neutrals last), spines flush with the front,
            one book face-out on a stand, three lying flat, steel bookends, four identical boxes on top
book_stack  three books lying flat, edges flush, the top one's cover up, a pencil parallel to the spines (tabletop)
"""
import colorsys

import apt_books as K
import apt_forms as F
from apt_lib import AptKit

FACE_OUT = 0                 # The Quiet Mind, on its stand
FLAT = (8, 30, 11)           # bottom to top
STACK = (19, 28, 20)         # book_stack, bottom to top
TABLE = (26, 3)              # the coffee table's shelf (living.py)


def colour_key(i):
    h, l, s = colorsys.rgb_to_hls(*(c / 255 for c in K.B[i][4]))
    return (1, -l, i) if s < 0.2 or l > 0.86 else (0, (h + 0.04) % 1.0, i)


def spine_row(k, books, x0, y_front, z):
    """Stand books spine-out from x0 rightwards, spines on y_front. Returns the x after the last one."""
    x = x0
    for i in books:
        t, d, _h = K.B[i][7:10]
        k.panels.append(F.book(f"bk{i}", i, k.BOOKS, (x + t / 2, y_front + d / 2, z)))
        x += t + 0.0015
    return x


def flat_stack(k, books, cx, y_front, z):
    """Lay books cover-up in a pile centred on cx, spines on y_front."""
    for i in books:
        t, d, h = K.B[i][7:10]
        k.panels.append(F.book(f"bf{i}", i, k.BOOKS, (cx + h / 2, y_front + d / 2, z + t / 2), (0, -90, 0)))
        z += t
    return z


def bookend(k, name, x, y, z, side):
    k.B(name, (0.003, 0.12, 0.15), (x, y + 0.06, z + 0.075), k.BLACK)
    k.B(name + "_foot", (0.1, 0.12, 0.002), (x + side * 0.05, y + 0.06, z + 0.001), k.BLACK)      # under the last books


def bookshelf():
    k = AptKit("bookshelf")
    w, d, h = 0.9, 0.3, 1.9
    for s in (-1, 1):
        k.B(f"side{s}", (0.02, d, h), (s * (w / 2 - 0.01), 0, h / 2), k.WOOD_L)
    k.B("back", (w, 0.01, h), (0, d / 2 - 0.005, h / 2), k.WOOD_L)
    tops = [0.06 + i * 0.37 for i in range(6)]
    for i, z in enumerate(tops):
        k.B(f"shelf{i}", (w - 0.04, d - 0.01, 0.02), (0, -0.005, z), k.WOOD_L)
    front, left, right = -d / 2 + 0.012, -w / 2 + 0.025, w / 2 - 0.025
    rest = sorted((i for i in range(len(K.B)) if i != FACE_OUT and i not in FLAT + STACK + TABLE), key=colour_key)
    tall = [i for i in rest if K.B[i][8] >= 0.24]
    rest = [i for i in rest if i not in tall]
    x = spine_row(k, tall, left, front, tops[0] + 0.01)                      # bottom: the big ones, then two magazine files
    bookend(k, "end0", x + 0.002, front, tops[0] + 0.01, -1)
    for n in range(2):
        k.B(f"file{n}", (0.09, 0.24, 0.28), (right - 0.05 - n * 0.1, front + 0.12, tops[0] + 0.15), k.PAPER, 0.003)
        k.LABEL("CHECKED", (right - 0.05 - n * 0.1, front - 0.001, tops[0] + 0.24), 0.07)
    room = [right - left, right - left - 0.2, right - left - 0.3]            # row 2 keeps its end for the stand, row 3 the pile
    for row in range(3):
        take, used = [], 0.0
        target = sum(K.B[i][7] + 0.0015 for i in rest) / (3 - row)          # share what is left evenly
        while rest and used + K.B[rest[0]][7] <= room[row] and used + K.B[rest[0]][7] / 2 <= target:
            used += K.B[rest[0]][7] + 0.0015
            take.append(rest.pop(0))
        z = tops[row + 1] + 0.01
        x = spine_row(k, take, left, front, z)
        if row:
            bookend(k, f"end{row}", x + 0.002, front, z, -1)
    z = tops[2] + 0.01                                                       # face-out on a little plate stand
    t, bd, bh = K.B[FACE_OUT][7:10]
    cx = right - 0.1
    k.panels.append(F.book("bk_face", FACE_OUT, k.BOOKS, (cx, front + 0.06, z + 0.012), (0, 0, -90)))
    k.B("stand", (0.12, 0.08, 0.012), (cx, front + 0.07, z + 0.006), k.WOOD)
    k.B("stand_back", (0.02, 0.012, 0.16), (cx, front + 0.06 + t / 2 + 0.006, z + 0.08), k.WOOD)
    flat_stack(k, FLAT, right - 0.14, front, tops[3] + 0.01)
    z = tops[4]                                                              # top shelf: four identical boxes
    for i in range(4):
        k.B(f"box{i}", (0.19, 0.24, 0.2), (-0.3 + i * 0.2, -0.01, z + 0.11), k.PAPER, 0.004)
        k.LABEL("CHECKED" if i == 3 else "DO NOT", (-0.3 + i * 0.2, -0.1305, z + 0.14), 0.12)
    k.COL((w, d, h), (0, 0, h / 2))
    k.finish(wall=True, subdiv=0.3, ao_dist=0.35, shift=(0, -d / 2, 0))


def book_stack():
    k = AptKit("book_stack")
    top = flat_stack(k, STACK, 0.0, -0.1, 0.0)
    k.CYL("pencil", 0.0035, 0.17, (0.0, -0.075, top + 0.0035), k.CHAIR, "x", 12)                   # parallel to the spines
    k.COL((0.28, 0.22, top), (0, 0.01, top / 2))
    k.finish(subdiv=0.08, ao_dist=0.08)


PROPS = {f.__name__: f for f in (bookshelf, book_stack)}
