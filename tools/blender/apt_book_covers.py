"""Front covers for the face-out books (apt_books.COVERS); called by apt_book_art.build(). Typographic self-help covers:
a tagline, a big title, a subtitle, one simple motif, the author along the foot. Nothing is a real book.
"""
import textwrap

from PIL import Image, ImageDraw

import apt_books as K
from apt_book_art import centred, fit, font

SUB = {0: "Finding stillness in an anxious world", 3: "A practical guide to unhooking from anxious thinking",
       11: "Break the loop in twenty-one days", 19: "Exercises for worry, doubt and intrusive thoughts",
       20: "How to live with doubt without obeying it", 26: "Small daily practices for a quieter life"}
TAG = {0: "“A gentle, wise book.”", 3: "INTERNATIONAL BESTSELLER", 11: "THE NEW EDITION", 19: "SECOND EDITION",
       20: "“Quietly life-changing.”", 26: "OVER ONE MILLION COPIES SOLD"}


def _lines(d, box, text, key, fill, width, max_line_h, align="c"):
    """Wrap text to `width` chars per line, fit every line to the box width, stack them from the top. Returns the bottom y."""
    x0, y0, x1, _y1 = box
    y = y0
    for line in textwrap.wrap(text, width):
        f = fit(line, key, x1 - x0, max_line_h)
        l, t, r, b = f.getbbox(line)
        x = (x0 + x1 - (r + l)) / 2 if align == "c" else x0 - l
        d.text((x, y - t), line, font=f, fill=fill)
        y += (b - t) + max_line_h * 0.18
    return y


def _circles(d, cx, cy, r, col, n=5):
    for k in range(n):
        rr = r * (1 - k / n)
        d.ellipse((cx - rr, cy - rr, cx + rr, cy + rr), outline=col, width=3)


def cover(i):
    title, author, _imp, style, bg, fg, acc = K.B[i][:7]
    w, h = K.cover_px(i), K.COVER_H
    im = Image.new("RGB", (w, h), bg)
    d = ImageDraw.Draw(im)
    m = int(w * 0.09)
    sub, tag = SUB.get(i, ""), TAG.get(i, "")
    if style == "serif":
        d.rectangle((m // 2, m // 2, w - m // 2, h - m // 2), outline=acc, width=2)
        centred(d, (0, m, w, m + 22), tag, font("lora_i", 17), acc)
        d.ellipse((w / 2 - 26, h * 0.13, w / 2 + 26, h * 0.13 + 52), fill=acc)            # a moon over a still line
        d.line((m * 1.5, h * 0.13 + 60, w - m * 1.5, h * 0.13 + 60), fill=acc, width=2)
        y = _lines(d, (m, h * 0.3, w - m, h), title, "dm", fg, 12, 70)
        _lines(d, (m * 1.3, y + 10, w - m * 1.3, h), sub, "lora_i", fg, 26, 20)
    elif style == "block":
        _circles(d, w * 0.78, h * 0.16, w * 0.36, acc)
        centred(d, (m, h * 0.8, w - m, h * 0.84), tag, font("work_b", 13), fg, 2)
        y = _lines(d, (m, h * 0.3, w - m, h), title.upper(), "mont_x", fg, 9, 44, "l")
        _lines(d, (m, y + 12, w - m * 2, h), sub, "work", fg, 24, 17, "l")
        d.rectangle((0, h * 0.86, w, h), fill=acc)
        centred(d, (0, h * 0.86, w, h), author.upper(), font("work_b", 20), bg, 3)
        return im
    elif style == "stack":
        d.pieslice((w * 0.2, h * 0.7, w * 0.8, h * 1.02), 180, 360, fill=acc)              # sun on the horizon
        d.line((m, h * 0.86, w - m, h * 0.86), fill=acc, width=3)
        centred(d, (m, m, w - m, m + 18), tag, font("work_b", 13), fg, 2)
        y = h * 0.1
        for word in title.split():
            f = fit(word, "archivo", w - 2 * m, 90)
            l, t, r, b = f.getbbox(word)
            d.text(((w - (r + l)) / 2, y - t), word, font=f, fill=fg)
            y += (b - t) + 12
        _lines(d, (m, y + 8, w - m, h), sub, "work", fg, 26, 18)
    else:                                                                                   # work
        d.rectangle((0, 0, w, h * 0.12), fill=acc)
        centred(d, (0, 0, w, h * 0.12), tag, font("work_b", 18), bg, 3)
        y = _lines(d, (m, h * 0.18, w - m, h), title.upper(), "anton", fg, 10, 64)
        y = _lines(d, (m, y + 10, w - m, h), sub, "work", fg, 24, 19)
        for k in range(int((h * 0.84 - y - 16) // 28)):                                     # checkbox list motif
            yy = y + 16 + k * 28
            d.rectangle((m * 1.6, yy, m * 1.6 + 18, yy + 18), outline=fg, width=2)
            d.line((m * 1.6 + 30, yy + 9, w - m * 2, yy + 9), fill=fg, width=2)
    centred(d, (0, h * 0.88, w, h * 0.96), author.upper(), font("work_b", 18), fg if style != "serif" else acc, 3)
    return im
