"""Instruments for the silo theme's layers (silo_theme.py). Each returns a mono signal from its own t = 0, seeded and
drawn over its full length, so the same call renders identically wherever it is placed: the loop stays seamless.
  thump    a muffled machine beat, lub-dub, pitched to the chord (descent layer; tight and fast in the alarm)
  rumble   a grain of low filtered noise that breathes (descent layer bed)
  strings  a high sustained tone, slow vibrato, optionally a semitone rubbing against it (core layer)
  bell     a big inharmonic bell struck once (core layer)
  rise     a siren-like glissando climbing into the next chord, cut off as it lands (alarm layer)
"""
import numpy as np

import silo_cue as cue

RATE = cue.RATE


def local_time(seconds):
    return np.arange(int(seconds * RATE)) / RATE


def add(x, start, sig):
    """Mix sig into x at `start` seconds (cut at the end of x)."""
    lo = int(round(start * RATE))
    hi = min(len(x), lo + len(sig))
    if lo < hi:
        x[lo:hi] += sig[:hi - lo]


def _hit(f, tt, decay, drop):
    freq = f * (1.0 + drop * np.exp(-tt * 28.0))                # the pitch drops as it lands, like a struck drum
    ph = 2.0 * np.pi * np.cumsum(freq) / RATE
    body = (np.sin(ph) + 0.3 * np.sin(2.0 * ph)) * np.exp(-tt * decay)
    return body * np.minimum(tt / 0.004, 1.0)


def thump(f, gain=1.0, seed=0, decay=5.0, second=0.55, gap=0.38):
    tt = local_time(1.4)
    local = np.random.default_rng(seed)
    x = _hit(f, tt, decay, 1.4)
    late = tt >= gap
    x[late] += second * _hit(f * 0.97, tt[late] - gap, decay * 1.2, 1.0)
    knock = local.standard_normal(len(tt)) * np.exp(-tt * 70.0) * 0.25
    return (x + cue.lowpass(knock, 400.0)) * gain


def rumble(seconds, gain=1.0, seed=0, fade=2.0):
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    noise = cue.lowpass(local.standard_normal(len(tt)), 90.0, slope=3.0)
    noise /= np.max(np.abs(noise)) + 1e-9
    breath = 0.65 + 0.35 * np.sin(2.0 * np.pi * tt / seconds * 2.0 + local.uniform(0, 6.3))
    edge = np.clip(np.minimum(tt, seconds - tt) / fade, 0.0, 1.0)
    return noise * breath * np.sin(edge * np.pi / 2.0) ** 2 * gain


def strings(f, seconds, gain=1.0, seed=0, attack=3.0, release=3.0, rub=0.0):
    """rub: level of a tone a semitone above (0 = none): unease, used sparingly."""
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    vib = 0.003 * np.sin(2.0 * np.pi * 4.6 * tt) * np.clip(tt / attack, 0.0, 1.0)
    x = np.zeros_like(tt)
    for tone, amp in ((f, 1.0), (f * 2.0 ** (1.0 / 12.0), rub)):          # the rub: a semitone above
        if amp <= 0.0:
            continue
        for detune in (-0.004, 0.0, 0.005):
            ph = 2.0 * np.pi * tone * np.cumsum(1.0 + detune + vib) / RATE + local.uniform(0, 6.3)
            for k in range(1, 5):
                x += amp * np.sin(k * ph) / k ** 1.5
    env = np.clip(tt / attack, 0.0, 1.0) ** 2 * np.clip((seconds - tt) / release, 0.0, 1.0) ** 2
    tremolo = 0.8 + 0.2 * np.sin(2.0 * np.pi * 0.23 * tt + local.uniform(0, 6.3))
    return x * env * tremolo * gain


def bell(f0, gain=1.0, seed=0, seconds=12.0):
    """f0 is the prime; the hum sounds an octave below it. Partials beat and die at their own rates."""
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    x = np.zeros_like(tt)
    for ratio, amp, decay in ((0.5, 1.0, 9.0), (1.0, 0.8, 6.0), (1.19, 0.55, 4.5), (1.5, 0.35, 3.5), (2.0, 0.6, 3.0),
                              (2.52, 0.3, 2.0), (2.66, 0.25, 1.8), (3.0, 0.2, 1.4), (4.07, 0.15, 0.9)):
        for beat in (-0.35, 0.35):
            x += amp * np.sin(2.0 * np.pi * (f0 * ratio + beat) * tt) * np.exp(-tt / decay)
    hit = cue.lowpass(local.standard_normal(len(tt)) * np.exp(-tt * 40.0), 900.0) * 0.8
    return (x + hit) * gain


def rise(f_from, f_to, seconds, gain=1.0, seed=0):
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    k = tt / seconds
    freq = f_from * (f_to / f_from) ** (k ** 1.6)                          # slow at first, then climbing hard
    x = np.zeros_like(tt)
    for rotor, amp in ((1.0, 1.0), (1.498, 0.5)):
        ph = 2.0 * np.pi * np.cumsum(freq * rotor) / RATE + local.uniform(0, 6.3)
        for h in range(1, 7):
            x += amp * np.sin(h * ph) / h ** 1.4
    env = k ** 2.2 * np.clip((seconds - tt) / 0.08, 0.0, 1.0)              # swells up, cut dead as the chord lands
    return x * env * gain
