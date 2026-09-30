"""The silo freight lift's failure (night 4's ending), rendered to audio/silo/lift_crash.wav (44.1 kHz stereo 16-bit).
Run: python tools/audio/lift_crash.py   Needs numpy. No downloads. SiloLiftCrash plays it once (2D, the walker is inside)
the moment the cage seizes; the cage moves to the same timeline, so the times below must equal SiloLiftCrash's constants.
  SEIZE  0.0   a huge clank, the motor's whine dies, a spit of sparks; then the cage hangs: groans, creaks, cable pings
  JOLT   1.3   it lurches down a hand's width (clunk, rattle)
  SNAP   2.4   the cable goes: a whip crack and a falling twang, then free fall (rising rush, rail rattle speeding up)
  BRAKE  3.6   the safety brakes bite: a shriek and grinding sparks, a slam as it stops dead
  HOLD   4.05  it hangs on the brakes: ringing, ticking, a slow groan that rises as they give
  SLIP   4.9   a bang, the brakes let go screaming; the rush and rattle build and build
  WRECK  7.1   the floor: a sub boom, a crunch of plate and frame, debris, and a concussed ringing into the black
"""
import os
import wave

import numpy as np

from blast_door import band, clunk, decay
from silo_cue import RATE, ROOT, lowpass, reverb, smooth_noise, timeline

OUT = os.path.join(ROOT, "audio", "silo")
JOLT = 1.3
SNAP = 2.4
BRAKE = 3.6
HOLD = 4.05
SLIP = 4.9
WRECK = 7.1
TAIL = 3.6


def gate(t, a, b, fade=0.03):
    """1 between a and b (seconds), with short linear fades."""
    return np.clip((t - a) / fade, 0.0, 1.0) * np.clip((b - t) / fade, 0.0, 1.0)


def ping(t, start, hz, seed, tau=0.5):
    """A strand of the cable parting: a thin inharmonic ring."""
    r = np.random.default_rng(seed)
    d = np.maximum(t - start, 0.0)
    x = sum(np.sin(2.0 * np.pi * hz * m * r.uniform(0.98, 1.02) * d) / m for m in (1.0, 2.76, 5.4))
    return x * decay(t, start, tau)


def groan(t, a, b, hz, seed):
    """Steel under load: a low tone that wanders, chattering (stick-slip) and swelling in and out."""
    n = smooth_noise(len(t) / RATE, 1.7, seed)
    ph = 2.0 * np.pi * np.cumsum(hz * (1.0 + 0.18 * n)) / RATE
    rough = 0.55 + 0.45 * np.sign(np.sin(2.0 * np.pi * (17.0 + 9.0 * n) * t))
    swell = np.clip(0.5 + 0.8 * smooth_noise(len(t) / RATE, 2.3, seed + 1), 0.0, 1.0)
    x = (np.sin(ph) + 0.5 * np.sin(2.0 * ph) + 0.25 * np.sin(3.3 * ph)) * rough * swell
    return lowpass(x, 1100.0) * gate(t, a, b, 0.25)


def creaks(t, a, b, count, seed):
    """Short resonant squeaks of plates shifting against each other."""
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    for when in r.uniform(a, b, count):
        hz = r.uniform(380.0, 900.0)
        d = np.maximum(t - when, 0.0)
        env = np.clip(d / 0.03, 0.0, 1.0) * decay(t, when + 0.03, r.uniform(0.05, 0.14))
        x += np.sin(2.0 * np.pi * (hz + 60.0 * np.sin(2.0 * np.pi * 31.0 * d)) * d) * env * r.uniform(0.3, 1.0)
    return x


def crackle(t, a, b, density, seed):
    """Sparks: dense tiny clicks of bright noise."""
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    for when in r.uniform(a, b, int(density * (b - a))):
        i = int(when * RATE)
        n = int(r.uniform(0.001, 0.006) * RATE)
        x[i:i + n] += r.uniform(-1.0, 1.0) * np.exp(-np.arange(len(x[i:i + n])) / (n * 0.3))
    return band(x, 1500.0, 9000.0)


def rush(t, a, b, seed):
    """Air rushing past a falling cage: noise that rises in pitch and level toward b."""
    u = np.clip((t - a) / (b - a), 0.0, 1.0) * gate(t, a, b + 0.02, 0.02)
    noise = np.random.default_rng(seed).standard_normal(len(t))
    lo = band(noise, 60.0, 500.0)
    hi = band(noise, 700.0, 3500.0)
    return (lo * (0.4 + 0.6 * u) + hi * u ** 1.5 * 0.8) * u ** 0.7


def rattle(t, a, b, v0, v1, seed):
    """Guide shoes clattering over rail joints, faster as the cage falls faster (clicks per second v0 -> v1)."""
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    when = a
    while when < b:
        u = (when - a) / (b - a)
        i = int(when * RATE)
        n = int(0.02 * RATE)
        x[i:i + n] += r.uniform(0.5, 1.0) * np.exp(-np.arange(len(x[i:i + n])) / (n * 0.2))
        when += 1.0 / (v0 + (v1 - v0) * u * u) * r.uniform(0.7, 1.3)
    return band(x, 200.0, 2500.0) + lowpass(x, 180.0) * 0.6


def shriek(t, a, b, hz0, hz1, seed):
    """Brake shoes on rail: a harsh squeal with vibrato and grinding underneath."""
    u = np.clip((t - a) / (b - a), 0.0, 1.0)
    wob = smooth_noise(len(t) / RATE, 9.0, seed)
    hz = (hz0 + (hz1 - hz0) * u) * (1.0 + 0.03 * wob + 0.012 * np.sin(2.0 * np.pi * 7.0 * t))
    ph = 2.0 * np.pi * np.cumsum(hz) / RATE
    tone = np.sin(ph) + 0.6 * np.sin(2.0 * ph + 0.3) + 0.35 * np.sin(3.0 * ph) + 0.2 * np.sin(5.0 * ph)
    grind = band(np.random.default_rng(seed + 1).standard_normal(len(t)), 300.0, 4000.0)
    grind *= 0.6 + 0.4 * np.abs(smooth_noise(len(t) / RATE, 40.0, seed + 2))
    return (tone * 0.5 + grind * 0.7) * gate(t, a, b, 0.04)


def power_down(t, start, seed):
    """The motor's whine dying: a buzzy tone sliding down and out."""
    d = np.maximum(t - start, 0.0)
    hz = 20.0 + 70.0 * np.exp(-d / 0.35)
    ph = 2.0 * np.pi * np.cumsum(hz) / RATE
    saw = sum(np.sin(k * ph) / k for k in range(1, 9))
    return lowpass(saw, 900.0) * decay(t, start, 0.5) * (t >= start)


def crack(t, start, seed):
    """The cable parting: a whip crack and a long twang falling in pitch."""
    r = np.random.default_rng(seed)
    d = np.maximum(t - start, 0.0)
    whip = band(r.standard_normal(len(t)), 800.0, 12000.0) * decay(t, start, 0.018) * (t >= start)
    hz = 180.0 + 1300.0 * np.exp(-d / 0.12)
    twang = np.sin(2.0 * np.pi * np.cumsum(hz) / RATE) * decay(t, start, 0.7) * (t >= start)
    return whip * 2.2 + twang * 0.6


def impact(t, start, seed):
    """The floor: a sub boom, a stack of steel hits, a long crunch and debris, and a concussed ring."""
    r = np.random.default_rng(seed)
    d = np.maximum(t - start, 0.0)
    on = t >= start
    boom = np.sin(2.0 * np.pi * np.cumsum(26.0 + 60.0 * np.exp(-d / 0.08)) / RATE) * decay(t, start, 1.1) * on
    hits = sum(clunk(t, start + dt, w, seed + k) for k, (dt, w) in
               enumerate(((0.0, 2.0), (0.012, 1.6), (0.05, 1.2), (0.13, 0.9), (0.3, 0.7), (0.55, 0.5))))
    crunch = band(r.standard_normal(len(t)), 90.0, 6000.0) * decay(t, start, 0.35) * on
    crunch *= 0.6 + 0.4 * np.abs(smooth_noise(len(t) / RATE, 60.0, seed + 9))
    debris = np.zeros_like(t)
    for k, when in enumerate(start + np.sort(r.exponential(0.5, 26))):
        debris += clunk(t, when, r.uniform(0.08, 0.35), seed + 20 + k) * np.exp(-(when - start) / 1.2)
    ring = np.sin(2.0 * np.pi * 3900.0 * d) * np.clip(d / 0.6, 0.0, 1.0) * decay(t, start + 0.6, 2.2) * on
    return boom * 2.4 + hits * 1.3 + crunch * 1.4 + debris * 0.8 + ring * 0.05


def crash():
    t = timeline(WRECK + TAIL)
    x = clunk(t, 0.0, 1.5, 1) * 1.2 + power_down(t, 0.0, 2) * 0.5 + crackle(t, 0.0, 0.5, 260.0, 3) * 0.6
    x += shriek(t, 0.02, 0.45, 1400.0, 900.0, 4) * 0.35                  # the cage scraping to a halt
    x += groan(t, 0.3, SNAP, 72.0, 5) * 0.5 + creaks(t, 0.4, SNAP - 0.1, 9, 6) * 0.25
    x += ping(t, 0.75, 1700.0, 7) * 0.3 + ping(t, 1.75, 2100.0, 8) * 0.35 + ping(t, 2.15, 1500.0, 9) * 0.4
    x += clunk(t, JOLT, 0.9, 10) + rattle(t, JOLT, JOLT + 0.3, 30.0, 10.0, 11) * 0.5
    x += crack(t, SNAP, 12) + clunk(t, SNAP + 0.02, 1.0, 13) * 0.8
    x += rush(t, SNAP, BRAKE + 0.2, 14) * 1.6 + rattle(t, SNAP, BRAKE, 6.0, 26.0, 15) * 1.1
    x += shriek(t, BRAKE, HOLD, 2400.0, 1600.0, 16) * 0.9 + crackle(t, BRAKE, HOLD + 0.1, 900.0, 17)
    x += clunk(t, HOLD, 1.3, 18) * 1.5
    x += ping(t, HOLD + 0.35, 1200.0, 19, 1.4) * 0.3 + creaks(t, HOLD + 0.2, SLIP, 6, 20) * 0.35
    x += groan(t, HOLD + 0.1, SLIP + 0.1, 58.0, 21) * 0.7 * np.clip((t - HOLD) / (SLIP - HOLD), 0.0, 1.0)
    x += clunk(t, SLIP, 1.2, 22) * 1.3 + crack(t, SLIP + 0.01, 23) * 0.5
    build = 0.4 + 0.8 * np.clip((t - SLIP) / (WRECK - SLIP), 0.0, 1.0)             # louder all the way down
    x += (shriek(t, SLIP, WRECK, 1900.0, 1100.0, 24) * 0.6 + crackle(t, SLIP, WRECK, 500.0, 25)) * build
    x += rush(t, SLIP, WRECK, 26) * 2.6 + rattle(t, SLIP, WRECK, 8.0, 60.0, 27) * 1.4 * build
    x += impact(t, WRECK, 28) * 2.6
    return np.tanh(x * 0.8)                                                  # drive it: the impact clips hard


def save(name, mono):
    wet = reverb(mono, rt60=2.2, wet=0.3, darkness=3000.0, predelay=0.015)[:len(mono)]
    tail = int(RATE * 0.4)
    wet[-tail:] *= np.linspace(1.0, 0.0, tail)[:, None]
    wet = wet / np.max(np.abs(wet)) * 0.89                                  # -1 dBFS
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((wet * 32767.0).astype("<i2").tobytes())
    print(f"{path}  {len(wet) / RATE:.1f} s")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("lift_crash", crash())
