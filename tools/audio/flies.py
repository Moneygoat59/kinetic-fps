"""Flies round the rubbish in the apartment gone to squalor, rendered to audio/apartment/fly_buzz_0..7.wav (44.1 kHz mono
16-bit). Run: python tools/audio/flies.py  (numpy)
Each file is one fly doing one thing, so FlyBuzz can scatter them at random (random file, pitch, level, gap) and no two
minutes sound alike. A wing-beat buzz (~170-260 Hz, rich in harmonics, a little rough), wandering in pitch as it turns:
  pass      comes in, goes by (a small drop in pitch as it passes), fades away
  circle    loops round nearby: two or three swells, near and away
  short     a brief take-off and it lands again, cut off
  bump      bumping against something (a bag, the window): the buzz in hard little bursts
"""
import os
import wave

import numpy as np

from silo_cue import RATE, ROOT, highpass, lowpass

OUT = os.path.join(ROOT, "audio", "apartment")
# (kind, seconds, seed)
TAKES = [("pass", 2.6, 1), ("pass", 3.8, 2), ("circle", 4.2, 3), ("circle", 3.0, 4), ("short", 0.9, 5), ("short", 1.4, 6),
         ("bump", 2.2, 7), ("pass", 1.8, 8)]


def wander(t, rng, rate):
    """Smooth random -1..1 (random points every 1/rate s, eased between)."""
    n = int(t[-1] * rate) + 3
    pts = rng.uniform(-1.0, 1.0, n)
    return np.interp(t * rate, np.arange(n), pts)


def envelope(kind, t, rng):
    u = t / t[-1]
    if kind == "pass":
        peak = rng.uniform(0.35, 0.65)
        return np.exp(-((u - peak) / 0.22) ** 2)
    if kind == "circle":
        laps = rng.integers(2, 4)
        return (0.35 + 0.65 * (0.5 - 0.5 * np.cos(2 * np.pi * laps * u + rng.uniform(0, 1)))) * np.sin(np.pi * u) ** 0.5
    if kind == "short":
        return np.clip(u / 0.15, 0, 1) * (u < rng.uniform(0.75, 0.9))
    bursts = (wander(t, rng, 9.0) > 0.1).astype(float)                   # bump: on / off in bursts
    return lowpass(bursts, 60.0) * np.sin(np.pi * u) ** 0.3


def take(kind, seconds, seed):
    rng = np.random.default_rng(seed)
    t = np.arange(int(RATE * seconds)) / RATE
    f0 = rng.uniform(170.0, 260.0)
    bend = 0.05 * wander(t, rng, 3.0)
    if kind == "pass":                                                  # passing by: a little higher coming, lower going
        bend += 0.04 * np.tanh((0.5 - t / seconds) * 8)
    ph = 2 * np.pi * np.cumsum(f0 * (1.0 + bend)) / RATE
    buzz = sum(np.sin(k * ph + rng.uniform(0, 6.3)) / k ** 0.9 for k in range(1, 14))
    buzz *= 1.0 + 0.25 * np.sin(2 * np.pi * rng.uniform(30, 45) * t)      # wing roughness
    x = lowpass(highpass(buzz, 120.0), rng.uniform(2400.0, 3600.0)) * envelope(kind, t, rng)
    edge = int(RATE * 0.02)
    x[:edge] *= np.linspace(0, 1, edge)
    x[-edge:] *= np.linspace(1, 0, edge)
    return x / np.max(np.abs(x)) * 0.7


def main():
    os.makedirs(OUT, exist_ok=True)
    for i, (kind, seconds, seed) in enumerate(TAKES):
        x = take(kind, seconds, seed)
        path = os.path.join(OUT, f"fly_buzz_{i}.wav")
        with wave.open(path, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes((x * 32767.0).astype("<i2").tobytes())
        print(f"{path}  {kind} {seconds:.1f} s")


if __name__ == "__main__":
    main()
