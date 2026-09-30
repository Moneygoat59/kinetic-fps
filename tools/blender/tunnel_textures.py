"""Textures for the rail tunnel kit (tools/blender/kit/tunnels.py, rail_props.py). Same helpers and look as textures.py /
silo_textures.py: century-faded stencils on obsidian. The emergency system is painted violet (its one colour; the glow is
kit_glow_emergency, re-tinted at runtime by EmergencyPylon.COLOR). Functional signage only.
Run: python tools/blender/tunnel_textures.py   -> models/generated/tex/tun_*.png   then rebuild the kit pieces (they embed them).
"""
import numpy as np
from PIL import Image, ImageDraw

from textures import _font, _noise, _rgba, _save_img

INK = (14, 12, 12, 255)
VIOLET = (92, 46, 150, 255)          # faded emergency paint (sRGB)
PALE = (0.46, 0.44, 0.40)            # the kit's stencil grey


def _flake(a, rng, keep=0.3, lo=0.25):
    h, w = a.shape
    wear = np.clip(lo + 1.5 * np.resize(_noise(max(w, h), 6, rng), (h, w)), 0, 1)
    return a * wear * (rng.random((h, w)) > keep)


def _worn_rgba(im, seed, holes=0.1):
    rng = np.random.default_rng(seed)
    arr = np.asarray(im, dtype=np.float32) / 255
    h, w = arr.shape[:2]
    rot = np.resize(_noise(max(w, h), 6, rng), (h, w))
    arr[..., :3] *= (0.5 + 0.4 * rot)[..., None]
    arr[..., 3] *= (rng.random((h, w)) > holes) * (0.6 + 0.4 * (rot < 0.8))
    return Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), "RGBA")


def line_stencil(w=192, h=96, seed=121):
    """Left-wall stencil every straight: the line number and the direction of travel."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((8, 10), "LINE", font=_font("Oxanium-SemiBold.ttf", 22), fill=255)
    d.text((8, 36), "00", font=_font("Oxanium-SemiBold.ttf", 52), fill=255)
    for i in range(3):                                            # chevrons: the way the line runs
        x = 104 + i * 26
        d.polygon([(x, 30), (x + 16, 52), (x, 74), (x + 9, 74), (x + 25, 52), (x + 9, 30)], fill=255)
    d.rectangle([0, 60, w, 62], fill=0)                           # stencil bridge
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.3, 0.2)
    _save_img("tun_stencil_line.png", _rgba(PALE, a * 0.75))


def refuge_sign(w=208, h=72, seed=122):
    """Beside every refuge niche: REFUGE and an arrow to it (pointing right as painted), in the emergency violet."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, w - 2, h - 2], fill=VIOLET, outline=INK, width=3)
    d.text((12, h // 2), "REFUGE", font=_font("Oxanium-SemiBold.ttf", 28), fill=INK, anchor="lm")
    d.polygon([(176, 20), (198, 36), (176, 52)], fill=INK)
    d.rectangle([152, 31, 178, 41], fill=INK)
    _worn_rgba(im, seed, holes=0.06).save(_path("tun_refuge.png"))


def emergency_plate(w=128, h=96, seed=123):
    """The call cabinet's plate on every emergency pylon."""
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle([1, 1, w - 2, h - 2], fill=VIOLET, outline=INK, width=3)
    d.text((w // 2, 16), "EMERGENCY", font=_font("Oxanium-SemiBold.ttf", 17), fill=INK, anchor="mm")
    d.text((w // 2, 32), "LINE 00", font=_font("Silkscreen-Regular.ttf", 8), fill=INK, anchor="mm")
    d.rectangle([20, 42, w - 21, 44], fill=INK)
    d.text((w // 2, 58), "LIFT HANDSET", font=_font("Silkscreen-Regular.ttf", 9), fill=INK, anchor="mm")
    d.text((w // 2, 72), "PULL TO CALL", font=_font("Silkscreen-Regular.ttf", 9), fill=INK, anchor="mm")
    d.polygon([(w // 2 - 6, 80), (w // 2 + 6, 80), (w // 2, 90)], fill=INK)
    _worn_rgba(im, seed).save(_path("tun_plate_emergency.png"))


def section_stencil(w=256, h=88, seed=124):
    """On both faces of every bulkhead lintel."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 20), "LINE 00  //  SECTION", font=_font("Oxanium-SemiBold.ttf", 20), fill=255, anchor="mm")
    d.text((w // 2, 60), "04", font=_font("Oxanium-SemiBold.ttf", 48), fill=255, anchor="mm")
    d.rectangle([0, 58, w, 60], fill=0)
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.3, 0.2)
    _save_img("tun_section.png", _rgba(PALE, a * 0.75))


def interchange_stencil(w=256, h=64, seed=125):
    """Over every mouth of an interchange hall, on the portal."""
    rng = np.random.default_rng(seed)
    im = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(im)
    d.text((w // 2, 18), "LINE 00", font=_font("Oxanium-SemiBold.ttf", 18), fill=255, anchor="mm")
    d.text((w // 2, 44), "INTERCHANGE", font=_font("Oxanium-SemiBold.ttf", 30), fill=255, anchor="mm")
    a = _flake(np.asarray(im, dtype=np.float32) / 255, rng, 0.3, 0.2)
    _save_img("tun_interchange.png", _rgba(PALE, a * 0.75))


def _path(name):
    import os
    from textures import OUT
    os.makedirs(OUT, exist_ok=True)
    print("TEX", name)
    return os.path.join(OUT, name)


if __name__ == "__main__":
    line_stencil()
    refuge_sign()
    emergency_plate()
    section_stencil()
    interchange_stencil()
