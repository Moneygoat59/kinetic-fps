"""The silo's music: four synchronised stems, audio/silo/silo_theme*.ogg (44.1 kHz stereo Vorbis, same length and loop).
Run: python tools/audio/silo_theme.py (numpy + soundfile, a few minutes). SiloMusic plays them together through MusicZone
and fades the layers in as the walker goes deeper:
  silo_theme.ogg        base    always: the swells (silo_cue.swell_signal) and a low pedal
  silo_theme_deep.ogg   descent down the shaft: a lub-dub machine beat pitched to each chord, a low breathing rumble
  silo_theme_core.ogg   core    level 09 / launch control: high strings (a semitone rubs on the tense chords), a bell
  silo_theme_alarm.ogg  alarm   override engaged: a hit on every chord, a driving pulse, a siren climbing into each chord

Form: INTRO (21 s, the discovery: Am F Dm E quick, silo_cue.SWELLS), then a LOOP of 16 slots of 8 s:
  A  Am  F  Dm  E  | Am(high)  Bb  F  E      pedal A   the layers beat every 4 s
  B  Dm  Bb Gm  A  | Dm(high)  Bb  Fm E      pedal D   the layers beat every 2 s: it tightens, then E hands back to A
Seamless loop: every event renders the same wherever it sits (seeded, from its own t = 0) and every tail is shorter than a
loop, so the second loop is the steady state; the file is intro + two loops and the .import loops from loop_offset = INTRO
+ LOOP. The pedal runs on absolute time, so its pitches are tuned to whole cycles per loop (55 and 36.75 Hz * 128 s).
All stems share one gain (the full mix peaks at -1 dBFS), so their balance is baked in: layer weight 1 = as mixed here.
"""
import os

import numpy as np
import soundfile

import silo_cue as cue
import silo_voices as v

INTRO = 21.0
SLOT = 8.0
LOOP = 128.0
LENGTH = INTRO + 2.0 * LOOP
CHECK = 2.0                    # rendered past the end to prove the loop point
LAYER_DB = {"deep": -5.0, "core": -7.0, "alarm": -2.0}    # each layer's loudness against the base (RMS over a loop)


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def chord(*midi):
    return tuple(hz(m) for m in midi)


# (chord, root Hz (the sub), attack, hold, release, gain): one per 8 s slot
SLOTS = (
    (chord(33, 40, 45, 48, 52), hz(33), 3.0, 1.2, 3.0, 1.0),     # A   Am
    (chord(29, 36, 41, 45, 48), hz(29), 3.0, 1.2, 3.0, 0.95),    #     F
    (chord(38, 45, 50, 53, 57), hz(26), 3.0, 1.0, 3.0, 0.9),     #     Dm
    (chord(28, 35, 40, 44, 47), hz(28), 3.4, 1.6, 3.4, 1.0),     #     E
    (chord(45, 52, 57, 60, 64), hz(33), 3.5, 1.0, 3.5, 0.6),     #     Am high, thin
    (chord(34, 41, 46, 50, 53), hz(34), 3.2, 1.4, 3.2, 1.0),     #     Bb: the menace
    (chord(29, 36, 41, 45, 48), hz(29), 3.0, 1.0, 3.0, 0.85),    #     F
    (chord(28, 35, 40, 44, 47), hz(28), 3.6, 1.8, 3.2, 1.0),     #     E
    (chord(38, 45, 50, 53, 57), hz(26), 3.0, 1.2, 3.0, 0.95),    # B   Dm
    (chord(34, 41, 46, 50, 53), hz(34), 3.0, 1.2, 3.0, 0.95),    #     Bb
    (chord(31, 38, 43, 46, 50), hz(31), 3.0, 1.2, 3.0, 0.95),    #     Gm
    (chord(33, 40, 45, 49, 52), hz(33), 3.2, 1.4, 3.2, 1.0),     #     A major: wrong, too bright
    (chord(50, 57, 62, 65, 69), hz(26), 3.5, 1.0, 3.5, 0.6),     #     Dm high, thin
    (chord(34, 41, 46, 50, 53), hz(34), 3.0, 1.2, 3.0, 1.0),     #     Bb
    (chord(29, 36, 41, 44, 48), hz(29), 3.0, 1.2, 3.0, 0.95),    #     Fm: the floor drops
    (chord(28, 35, 40, 44, 47), hz(28), 3.8, 2.0, 3.4, 1.05),    #     E, longest, back to Am
)


# Unease, used sparingly. The pedal holds one note through chords that fight it (A under Bb and E; D under A major, Fm
# and E): it drops back there so it only grinds a little. The strings' semitone rub sounds only on the tense chords.
PEDAL_LEVEL = (1.0, 1.0, 1.0, 0.35, 1.0, 0.3, 1.0, 0.35, 1.0, 1.0, 1.0, 0.35, 1.0, 1.0, 0.5, 0.5)
RUB = (0.0, 0.0, 0.0, 0.3, 0.0, 0.3, 0.0, 0.3, 0.0, 0.0, 0.0, 0.3, 0.0, 0.0, 0.3, 0.3)


def slots():
    """Every slot on the timeline: (loop index, slot index, start s). The third loop only reaches the CHECK overhang."""
    for n in range(3):
        for i in range(len(SLOTS)):
            start = INTRO + n * LOOP + i * SLOT
            if start < LENGTH + CHECK:
                yield n, i, start


def loop_phase(t):
    return np.where(t >= INTRO, (t - INTRO) % LOOP, -1.0)


def pedal(t):
    """A1 under section A, D1 under B (crossfading), dark and quiet, breathing every 32 s, dropping back under the chords
    that fight it (PEDAL_LEVEL); fades in under the intro."""
    u = loop_phase(t)
    w_b = np.clip((u - 62.0) / 4.0, 0.0, 1.0) - np.clip((u - 124.0) / 4.0, 0.0, 1.0)
    breath = 0.6 + 0.4 * np.sin(2.0 * np.pi * t / 32.0)
    knots = [SLOT * i + edge for i in range(len(SLOTS)) for edge in (1.5, SLOT - 1.5)]
    level = np.interp(np.maximum(u, 0.0), knots, np.repeat(PEDAL_LEVEL, 2), period=LOOP)  # eases over 3 s per change
    breath *= np.where(u >= 0.0, level, 1.0)
    x = np.zeros_like(t)
    for f, weight in ((55.0, 1.0 - w_b), (36.75, w_b)):
        for octave, amp in ((1.0, 1.0), (2.0, 0.35)):
            for k in range(1, 6):
                x += weight * amp * np.sin(2.0 * np.pi * f * octave * k * t) / k ** 2
    return x * breath * np.clip(t / INTRO, 0.0, 1.0) ** 2 * 2.2


def base(t):
    x = pedal(t)
    for i, spec in enumerate(cue.SWELLS):
        v.add(x, spec[0], cue.swell_signal(*spec[1:], seed=5 + i))
    for _, i, start in slots():
        notes, sub, attack, hold, release, gain = SLOTS[i]
        v.add(x, start, cue.swell_signal(attack, hold, release, sub, notes, gain, seed=100 + i))
    return cue.reverb(cue.lowpass(x, 1400.0), rt60=7.0, wet=0.55)


def deep(t):
    x = np.zeros_like(t)
    for _, i, start in slots():
        root = SLOTS[i][1] * 2.0
        beat = 4.0 if i < 8 else 2.0
        for j in range(int(SLOT / beat)):
            v.add(x, start + j * beat, v.thump(root, 1.0 if j == 0 else 0.7, seed=200 + i * 4 + j))
        v.add(x, start - 1.0, v.rumble(SLOT + 2.0, 0.5, seed=300 + i))
    return cue.reverb(cue.lowpass(x, 900.0), rt60=5.0, wet=0.4)


def core(t):
    x = np.zeros_like(t)
    for _, i, start in slots():
        root = SLOTS[i][1]
        v.add(x, start - 1.0, v.strings(root * 12.0, SLOT + 3.0, seed=400 + i, rub=RUB[i]))
        if i % 2 == 0:
            v.add(x, start, v.bell(root * 4.0, 1.4, seed=500 + i))
    return cue.reverb(cue.lowpass(x, 3000.0), rt60=8.0, wet=0.65)


def alarm(t):
    x = np.zeros_like(t)
    for _, i, start in slots():
        notes, sub = SLOTS[i][0], SLOTS[i][1]
        v.add(x, start, cue.swell_signal(0.12, 0.3, 1.0, sub, notes, 1.0, seed=600 + i))
        for j in range(int(SLOT / 0.5)):
            v.add(x, start + j * 0.5, v.thump(sub * 2.0, 1.0 if j % 4 == 0 else 0.5, seed=700 + i * 16 + j,
                                              decay=9.0, second=0.0) * 3.0)
        after = SLOTS[(i + 1) % len(SLOTS)][1]
        v.add(x, start + 1.5, v.rise(sub * 4.0, after * 8.0, SLOT - 1.5, 2.0, seed=800 + i))
    return cue.reverb(cue.lowpass(x, 2500.0), rt60=5.0, wet=0.45)


def rms(stem, lo, hi):
    return float(np.sqrt(np.mean(stem[lo:hi] ** 2)))


if __name__ == "__main__":
    t = cue.timeline(LENGTH + CHECK)
    loop_at, end = int((INTRO + LOOP) * cue.RATE), int(LENGTH * cue.RATE)
    n = int(CHECK * cue.RATE) - int(0.2 * cue.RATE)              # clear of the FFT filters' wrap at the very end
    stems = {}
    for name, build in (("base", base), ("deep", deep), ("core", core), ("alarm", alarm)):
        stem = build(t)[:len(t)]
        seam = np.max(np.abs(stem[end:end + n] - stem[loop_at:loop_at + n])) / np.max(np.abs(stem))
        print(f"{name:6s} loop seam error {seam:.2e} (want < 1e-3)", flush=True)
        stems[name] = stem[:end]
    ref = rms(stems["base"], loop_at, end)
    for name, db in LAYER_DB.items():
        stems[name] *= ref * 10.0 ** (db / 20.0) / rms(stems[name], loop_at, end)
    scale = 0.89 / np.max(np.abs(sum(stems.values())))           # the full mix peaks at -1 dBFS
    os.makedirs(cue.OUT, exist_ok=True)
    for name, stem in stems.items():
        stem = stem * scale
        path = os.path.join(cue.OUT, "silo_theme.ogg" if name == "base" else f"silo_theme_{name}.ogg")
        with soundfile.SoundFile(path, "w", cue.RATE, 2, format="OGG", subtype="VORBIS") as f:
            for i in range(0, len(stem), 8192):                  # in blocks: one big write overflows libsndfile's stack
                f.write(stem[i:i + 8192])
        peak = 20.0 * np.log10(np.max(np.abs(stem)))
        print(f"{path}  {len(stem) / cue.RATE:.1f} s, peak {peak:.1f} dBFS, loop_offset={INTRO + LOOP}", flush=True)
