"""Instruments for the tunnel theme (tunnel_theme.py). Each returns a mono signal from its own t = 0, seeded and drawn over
its full length, so the same call renders identically wherever it is placed: the loop stays seamless.
  glass   the motif's voice: a bowed glass tone, near-sine, two copies beating slowly, a vibrato that grows in after the bow
  bowed   a warm low bowed string (the answering voice) and, chorded and slower, the pad
  hum     the amber conductor rail: E1 and its overtones, each with a twin a hair away, on absolute time (loops cleanly)
  ping    the rail contracting far down the line: a small metal tick with a short ring, pitched into the key
"""
import numpy as np

import silo_cue as cue
from silo_voices import local_time

RATE = cue.RATE
E1 = 3956.0 / 96.0                # 41.208 Hz, whole cycles in the 96 s loop (0.2 cent from equal temperament)


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def _shape(tt, attack, hold, release):
    """cue.envelope, faded to nothing over its last second so a cut tail never clicks."""
    length = tt[-1] + 1.0 / RATE
    return cue.envelope(tt, attack, hold, release) * np.clip((length - tt) / 1.0, 0.0, 1.0)


def glass(f, hold, gain=1.0, seed=0, attack=0.9, release=3.6):
    seconds = attack + hold + release * 4.5
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    vib = 0.0032 * np.sin(2.0 * np.pi * 4.3 * tt + local.uniform(0, 6.3)) * np.clip((tt - attack) / 2.5, 0.0, 1.0)
    x = np.zeros_like(tt)
    for detune, amp in ((0.0, 1.0), (0.0021, 0.8)):              # ~1 Hz apart at 500 Hz: the slow shimmer of glass
        ph = 2.0 * np.pi * f * np.cumsum(1.0 + detune + vib) / RATE + local.uniform(0, 6.3)
        x += amp * (np.sin(ph) + 0.30 * np.sin(2.0 * ph) + 0.10 * np.sin(3.0 * ph) + 0.04 * np.sin(5.0 * ph))
    bow = cue.lowpass(cue.highpass(local.standard_normal(len(tt)), 1800.0), 6000.0) * np.exp(-tt / 0.35) * 0.05
    return (x * 0.5 + bow) * _shape(tt, attack, hold, release) * gain


def bowed(f, hold, gain=1.0, seed=0, attack=1.4, release=3.0, brightness=6.0):
    seconds = attack + hold + release * 4.5
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    vib = 0.004 * np.sin(2.0 * np.pi * 4.6 * tt + local.uniform(0, 6.3)) * np.clip((tt - attack) / 2.0, 0.0, 1.0)
    x = np.zeros_like(tt)
    for detune in (-0.003, 0.0, 0.0035):
        ph = 2.0 * np.pi * f * np.cumsum(1.0 + detune + vib) / RATE + local.uniform(0, 6.3)
        for k in range(1, 14):
            x += np.sin(k * ph) / k * np.exp(-(k - 1) / brightness)
    return cue.lowpass(x, 1100.0) * _shape(tt, attack, hold, release) * gain * 0.4


def hum(t):
    """The rail's E1 under everything, on absolute time: every frequency is whole cycles per 96 s, and it breathes every 32 s."""
    breath = 0.72 + 0.28 * np.sin(2.0 * np.pi * t / 32.0)
    x = np.zeros_like(t)
    for k, amp in ((1, 1.0), (2, 0.55), (3, 0.3), (4, 0.16), (6, 0.08)):
        x += amp * np.sin(2.0 * np.pi * k * E1 * t)
        x += 0.7 * amp * np.sin(2.0 * np.pi * (k * E1 + 0.125 * k) * t)          # the twin: beats every 8 s / k
    return x * breath


def ping(f, gain=1.0, seed=0, seconds=3.0):
    tt = local_time(seconds)
    local = np.random.default_rng(seed)
    x = np.zeros_like(tt)
    for ratio, amp, decay in ((1.0, 1.0, 0.9), (2.76, 0.5, 0.45), (5.4, 0.3, 0.22)):
        x += amp * np.sin(2.0 * np.pi * f * ratio * tt + local.uniform(0, 6.3)) * np.exp(-tt / decay)
    tick = cue.highpass(local.standard_normal(len(tt)), 1500.0) * np.exp(-tt * 300.0) * 0.4
    return (x + tick) * np.minimum(tt / 0.002, 1.0) * gain * 0.3
