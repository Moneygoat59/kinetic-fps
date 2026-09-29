"""The rail tunnel's music: three synchronised stems, audio/tunnel/tunnel_theme*.ogg (44.1 kHz stereo Vorbis, same length and loop).
Run: python tools/audio/tunnel_theme.py (numpy + soundfile, a minute or two). Layered by the walker's progress down the line:
  tunnel_theme.ogg         base    always: the rail's E1 hum, a thin open pad, the motif on bowed glass, far-off rail ticks
  tunnel_theme_deep.ogg    deep    a low bowed voice answers the motif two octaves down, in the silence after it
  tunnel_theme_strain.ogg  strain  a wrong copy of the motif, a semitone up and a beat late, and a low draught under it

The motif is four notes, slow and unhurried: B E D, then back to B. It never comes home to E. Four statements of 24 s, each
sounded, then left in silence, then answered (deep); the second falls to G, the third lifts (D G F# E), the fourth stops
short on D and does not return. The pad turns E (i) -> C (VI) -> A (iv) -> B (v) -> E under the E1 pedal: an Aeolian rotation.
Form: INTRO (16 s: the hum rises, one lone B) then a LOOP of 96 s, written twice; every .import loops from loop_offset =
INTRO + LOOP. Seamless: events render the same wherever they sit, tails are shorter than a loop, and the hum runs on absolute
time (whole cycles per loop). All stems share one gain (full mix peaks at -1 dBFS); LAYER_DB sets each layer against the base.
"""
import os

import numpy as np
import soundfile

import silo_cue as cue
import silo_voices as v
import tunnel_voices as tv

OUT = os.path.join(cue.ROOT, "audio", "tunnel")
INTRO = 16.0
STATEMENT = 24.0
LOOP = 96.0
LENGTH = INTRO + 2.0 * LOOP
CHECK = 2.0
LAYER_DB = {"deep": -5.0, "strain": -8.0}

# (offset s, hold s, MIDI): B4 = 71. The notes overlap: each rings on under the next.
FIGURES = (
    ((0.0, 2.2, 71), (3.0, 1.8, 76), (6.0, 1.8, 74), (8.5, 3.5, 71)),     # B E D B
    ((0.0, 2.2, 71), (3.0, 1.8, 76), (6.0, 1.8, 74), (8.5, 3.5, 67)),     # B E D G   it falls short of B
    ((0.0, 2.2, 74), (3.0, 1.8, 79), (6.0, 1.8, 78), (8.5, 3.5, 76)),     # D G F# E  it lifts
    ((0.0, 2.2, 71), (3.0, 1.8, 76), (6.0, 6.0, 74)),                     # B E D     and stops
)
# Two 12 s pad slots under each statement (MIDI): E, C, A, B, then home.
PADS = (
    (40, 47, 52), (40, 47, 54), (48, 55, 64), (48, 55, 59), (45, 52, 60), (45, 52, 64), (47, 54, 62), (40, 47, 52),
)
PINGS = ((9.3, 88), (31.7, 91), (40.2, 79), (58.9, 88), (66.3, 84), (83.6, 91))    # (s in loop, MIDI E6 B5 G5)


def statements():
    """Every statement on the timeline: (loop, index, start s). The third loop only reaches the CHECK overhang."""
    for n in range(3):
        for i in range(len(FIGURES)):
            start = INTRO + n * LOOP + i * STATEMENT
            if start < LENGTH + CHECK:
                yield n, i, start


def pad_slots():
    for n in range(3):
        for j, notes in enumerate(PADS):
            start = INTRO + n * LOOP + j * 12.0
            if start < LENGTH + CHECK:
                yield start, notes


def tube(x):
    """The tunnel answers: three fading taps, darker each time."""
    out = x.copy()
    for delay, gain, cut in ((0.47, 0.30, 2400.0), (0.94, 0.16, 1500.0), (1.61, 0.08, 900.0)):
        n = int(delay * cue.RATE)
        out[n:] += gain * cue.lowpass(x, cut)[:len(x) - n]
    return out


def base(t):
    hum = 0.35 * tv.hum(t) * np.clip(t / 14.0, 0.0, 1.0) ** 2
    pad = np.zeros_like(t)
    for start, notes in pad_slots():
        for k, m in enumerate(notes):
            v.add(pad, start, tv.bowed(tv.hz(m), 2.5, 0.22, seed=10 + k, attack=4.0, release=3.5, brightness=3.0))
    glass = np.zeros_like(t)
    v.add(glass, 8.0, tv.glass(tv.hz(71), 4.0, 0.9, seed=1))                 # the lone B: a question, before the figure
    for _, i, start in statements():
        for k, (off, hold, m) in enumerate(FIGURES[i]):
            v.add(glass, start + off, tv.glass(tv.hz(m), hold, 1.0, seed=20 + i * 8 + k))
    pings = np.zeros_like(t)
    for n in range(3):
        for k, (off, m) in enumerate(PINGS):
            v.add(pings, INTRO + n * LOOP + off, tv.ping(tv.hz(m), 1.0, seed=50 + k))
    x = cue.lowpass(hum + pad, 1600.0) + cue.lowpass(tube(glass), 4500.0) + pings
    return cue.reverb(x, rt60=8.5, wet=0.6, darkness=2000.0)


def deep(t):
    x = np.zeros_like(t)
    for _, i, start in statements():
        for k, (off, hold, m) in enumerate(FIGURES[i]):
            v.add(x, start + 12.5 + off, tv.bowed(tv.hz(m - 24), hold * 1.3, 1.0, seed=100 + i * 8 + k))
    return cue.reverb(cue.lowpass(x, 1400.0), rt60=8.0, wet=0.55, darkness=1600.0)


def strain(t):
    x = np.zeros_like(t)
    for _, i, start in statements():
        if i < 2:
            continue
        v.add(x, start - 1.0, v.rumble(STATEMENT + 2.0, 0.45, seed=200 + i))
        for k, (off, hold, m) in enumerate(FIGURES[i]):
            v.add(x, start + 1.5 + off, tv.glass(tv.hz(m + 1), hold, 0.55, seed=300 + i * 8 + k))
    return cue.reverb(cue.lowpass(x, 3000.0), rt60=8.5, wet=0.6, darkness=1800.0)


def rms(stem, lo, hi):
    return float(np.sqrt(np.mean(stem[lo:hi] ** 2)))


if __name__ == "__main__":
    t = cue.timeline(LENGTH + CHECK)
    loop_at, end = int((INTRO + LOOP) * cue.RATE), int(LENGTH * cue.RATE)
    n = int(CHECK * cue.RATE) - int(0.2 * cue.RATE)              # clear of the FFT filters' wrap at the very end
    stems = {}
    for name, build in (("base", base), ("deep", deep), ("strain", strain)):
        stem = build(t)[:len(t)]
        seam = np.max(np.abs(stem[end:end + n] - stem[loop_at:loop_at + n])) / np.max(np.abs(stem))
        print(f"{name:6s} loop seam error {seam:.2e} (want < 1e-3)", flush=True)
        stems[name] = stem[:end]
    ref = rms(stems["base"], loop_at, end)
    for name, db in LAYER_DB.items():
        stems[name] *= ref * 10.0 ** (db / 20.0) / rms(stems[name], loop_at, end)
    scale = 0.89 / np.max(np.abs(sum(stems.values())))           # the full mix peaks at -1 dBFS
    os.makedirs(OUT, exist_ok=True)
    for name, stem in stems.items():
        stem = stem * scale
        path = os.path.join(OUT, "tunnel_theme.ogg" if name == "base" else f"tunnel_theme_{name}.ogg")
        with soundfile.SoundFile(path, "w", cue.RATE, 2, format="OGG", subtype="VORBIS") as f:
            for i in range(0, len(stem), 8192):                  # in blocks: one big write overflows libsndfile's stack
                f.write(stem[i:i + 8192])
        peak = 20.0 * np.log10(np.max(np.abs(stem)))
        print(f"{path}  {len(stem) / cue.RATE:.1f} s, peak {peak:.1f} dBFS, loop_offset={INTRO + LOOP}", flush=True)
