"""Book spines and covers for the apartment (tools/blender/apt/apt_books.py holds the books and the atlas layout).
Run: python tools/blender/apt_book_art.py   -> models/generated/tex/apt_books.png   (apt_textures.py runs it too)
Typography uses OFL Google Fonts kept in tools/asset_src/fonts (not in git; tools/README.md lists them). Spines are drawn
lying down (text left to right) and turned so they read top to bottom, as English spines do; imprint marks stand upright.
Covers: apt_book_covers.py.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "apt"))
import apt_books as K  # noqa: E402
from textures import OUT, ROOT  # noqa: E402

FONT_DIR = os.path.join(ROOT, "tools", "asset_src", "fonts")
FONTS = {"bebas": ("BebasNeue-Regular.ttf", None), "anton": ("Anton-Regular.ttf", None), "archivo": ("ArchivoBlack-Regular.ttf", None),
         "abril": ("AbrilFatface-Regular.ttf", None), "dm": ("DMSerifDisplay-Regular.ttf", None), "dm_i": ("DMSerifDisplay-Italic.ttf", None),
         "slab": ("AlfaSlabOne-Regular.ttf", None), "mont": ("Montserrat[wght].ttf", b"SemiBold"), "mont_x": ("Montserrat[wght].ttf", b"ExtraBold"),
         "work": ("WorkSans[wght].ttf", b"Medium"), "work_b": ("WorkSans[wght].ttf", b"SemiBold"), "play": ("PlayfairDisplay[wght].ttf", b"Bold"),
         "lora": ("Lora[wght].ttf", b"Medium"), "lora_i": ("Lora-Italic[wght].ttf", None)}
PAGES = (238, 230, 210)


def font(key, size):
    name, var = FONTS[key]
    f = ImageFont.truetype(os.path.join(FONT_DIR, name), max(4, int(size)))
    if var:
        f.set_variation_by_name(var)
    return f


def fit(text, key, max_w, max_h, start=None):
    """Largest font of `key` whose rendering of `text` fits max_w x max_h."""
    size = int(start or max_h * 1.4)
    while size > 5:
        f = font(key, size)
        l, t, r, b = f.getbbox(text)
        if r - l <= max_w and b - t <= max_h:
            return f
        size -= 1
    return font(key, 5)


def centred(d, box, text, f, fill, spacing=0):
    """Draw text centred in box=(x0, y0, x1, y1); spacing adds tracking (letter-spaced caps)."""
    x0, y0, x1, y1 = box
    if spacing:
        widths = [f.getlength(c) for c in text]
        total = sum(widths) + spacing * (len(text) - 1)
        l, t, r, b = f.getbbox(text)
        x, y = (x0 + x1 - total) / 2, (y0 + y1 - (b + t)) / 2
        for c, w in zip(text, widths):
            d.text((x, y), c, font=f, fill=fill)
            x += w + spacing
        return
    l, t, r, b = f.getbbox(text)
    d.text(((x0 + x1 - (r + l)) / 2, (y0 + y1 - (b + t)) / 2), text, font=f, fill=fill)


def along(im, y0, y1, text, key, fill, fill_h=0.56, spacing=0):
    """Text running down the spine between y0 and y1 (reads top to bottom)."""
    w = im.width
    strip = Image.new("RGBA", (y1 - y0, w), (0, 0, 0, 0))
    f = fit(text, key, (y1 - y0) * 0.94 - spacing * len(text), w * fill_h)
    centred(ImageDraw.Draw(strip), (0, 0, y1 - y0, w), text, f, fill, spacing)
    rot = strip.rotate(-90, expand=True)
    im.paste(rot, (0, y0), rot)


def imprint(d, w, y, name, col, bg):
    """Publisher mark standing upright at the foot of the spine."""
    s = min(w * 0.5, 22)
    cx, cy = w / 2, y + s / 2
    if name == "harbor":
        d.ellipse((cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2), outline=col, width=2)
        d.arc((cx - s / 3, cy - s / 6, cx + s / 3, cy + s / 3), 200, 340, fill=col, width=2)
    elif name == "lantern":
        d.polygon([(cx, cy - s / 2), (cx + s / 2.4, cy - s / 8), (cx + s / 2.4, cy + s / 2), (cx - s / 2.4, cy + s / 2),
                   (cx - s / 2.4, cy - s / 8)], fill=col)
        d.rectangle((cx - s / 8, cy, cx + s / 8, cy + s / 3), fill=bg)
    elif name == "north":
        d.polygon([(cx, cy - s / 2), (cx + s / 2, cy + s / 2), (cx - s / 2, cy + s / 2)], fill=col)
    elif name == "vesta":
        d.ellipse((cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2), fill=col)
        centred(d, (cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2), "V", font("archivo", s * 0.62), bg)
    else:
        d.ellipse((cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2), outline=col, width=2)
        d.line((cx - s / 2, cy, cx + s / 2, cy), fill=col, width=2)
    if w >= 58:
        centred(d, (0, y + s + 2, w, y + s + 12), name.upper(), font("work_b", 8), col, 1)


def spine(i):
    title, author, imp, style, bg, fg, acc = K.B[i][:7]
    w, H = K.spine_px(i), K.SPINE_PX
    im = Image.new("RGB", (w, H), bg)
    d = ImageDraw.Draw(im)
    p = lambda f: int(H * f)  # noqa: E731
    surname = author.split(",")[0].split(" ")[-1].upper() if author else ""
    if style == "stack" and w >= 60:
        y = p(0.05)
        for word in title.split():
            f = fit(word, "archivo", w - 10, p(0.1))
            centred(d, (0, y, w, y + p(0.1)), word, f, fg)
            y += p(0.105)
        along(im, max(y + p(0.03), p(0.5)), p(0.84), surname, "work_b", acc, 0.4, 2)
    elif style == "serif":
        for y in (p(0.06), p(0.075), p(0.82), p(0.835)):
            d.line((3, y, w - 4, y), fill=acc, width=2)
        along(im, p(0.1), p(0.62), title, "dm" if i % 2 else "lora", fg, 0.6)
        along(im, p(0.64), p(0.8), author, "lora_i", fg, 0.42)
    elif style == "paper":
        d.rectangle((0, 0, w, p(0.09)), fill=acc)
        along(im, p(0.12), p(0.66), title, "mont_x", fg, 0.5)
        along(im, p(0.68), p(0.85), author.upper(), "work", (70, 70, 74), 0.34, 1)
    elif style == "block":
        d.rectangle((0, 0, w, p(0.22)), fill=acc)
        along(im, p(0.02), p(0.2), surname, "work_b", bg, 0.42, 2)
        along(im, p(0.25), p(0.84), title, "play" if i % 3 else "mont", fg, 0.55)
    elif style == "work":
        d.rectangle((0, p(0.06), w, p(0.2)), fill=acc)
        centred(d, (0, p(0.06), w, p(0.2)), "2E", font("archivo", w * 0.42), bg)
        along(im, p(0.23), p(0.72), title, "anton", fg, 0.6)
        along(im, p(0.74), p(0.86), author.upper(), "work_b", fg, 0.34, 1)
    else:                                                            # band (and stacks too thin to stack)
        for y0, y1 in ((p(0.045), p(0.07)), (p(0.83), p(0.855))):
            d.rectangle((0, y0, w, y1), fill=acc)
        along(im, p(0.09), p(0.66), title.upper(), "bebas" if i % 2 else "anton", fg, 0.62, 1)
        along(im, p(0.68), p(0.81), surname, "mont", fg, 0.36, 2)
    imprint(d, w, p(0.875), imp, fg if style != "paper" else acc, bg)
    return _wear(im, i, cloth=style == "serif")


def _wear(im, seed, cloth=False, round_x=True):
    """Printed-card grain, a rounded spine (darker at the hinges), a little shelf wear."""
    rng = np.random.default_rng(seed + 7)
    a = np.asarray(im, np.float32) / 255.0
    h, w = a.shape[:2]
    a *= 1.0 + rng.normal(0, 0.035 if cloth else 0.018, (h, w, 1))
    if cloth:
        a *= 1.0 + 0.04 * (np.arange(h)[:, None, None] % 2) + 0.04 * (np.arange(w)[None, :, None] % 2)
    if round_x:
        x = (np.arange(w) + 0.5) / w
        a *= (0.8 + 0.2 * np.sin(np.pi * x) ** 0.6)[None, :, None]
    y = np.arange(h)[:, None, None] / h
    a = a * (1 - 0.1 * np.exp(-y * 40) - 0.08 * np.exp(-(1 - y) * 40)) + 0.05 * (rng.random((h, w, 1)) > 0.995)
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8))


def swatch(i):
    """Under each spine: its cover colour (left) and its page edges (right, lines along v)."""
    w, bg = K.spine_px(i), K.B[i][4]
    im = Image.new("RGB", (w, K.SWATCH_PX), bg)
    rng = np.random.default_rng(i)
    cols = np.clip(np.array(PAGES)[None, :] * rng.uniform(0.86, 1.02, (w - w // 2, 1)), 0, 255).astype(np.uint8)
    im.paste(Image.fromarray(np.repeat(cols[None], K.SWATCH_PX, 0)), (w // 2, 0))
    return im


def build():
    import apt_book_covers
    atlas = Image.new("RGB", (K.ATLAS_W, K.ATLAS_H), PAGES)
    for i, (x, y, _w) in enumerate(K.SPINES):
        atlas.paste(spine(i), (x, y))
        atlas.paste(swatch(i), (x, y + K.SPINE_PX))
    for i, (x, y, _w) in K.COVER_RECTS.items():
        atlas.paste(_wear(apt_book_covers.cover(i), i, round_x=False), (x, y))
    os.makedirs(OUT, exist_ok=True)
    atlas.save(os.path.join(OUT, "apt_books.png"))
    print("TEX apt_books.png")


if __name__ == "__main__":
    build()
