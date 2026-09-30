"""Missile Silo 00's generators, rendered to audio/silo/gen_*.wav (44.1 kHz mono 16-bit: mono so AudioStreamPlayer3D places
it cleanly). Run: python tools/audio/silo_generator.py   Needs numpy. No downloads. Played by SiloGeneratorSound.
  gen_drone    the running machine, a seamless LOOP-second loop: a sub fundamental beating against its detuned twin, the
               rotor's heavy chug, the saturated buzz of the windings, a thin turbine whine drifting, a rumble under it all
  gen_pulse    the beat each machine gives once a breath (SiloGenerators' throb): a sucked-in pre-swell, then a huge
               falling sub thump, the housing ringing like a bell the size of a house, an arc snapping off the core, the
               hall's long tail. Played as the glow starts to swell, so the light answers the sound
  gen_arc_1..3 a loose arc cracking off a machine now and then: sizzle, snaps and a stab of buzz
  gen_pour     the amber pouring into a crown pool, a seamless loop: a thick gurgling stream and the splash under it
  gen_bow_e2 / _b2 / _g3   each machine's note (SiloGeneratorSound swells it with the machine's glow): a low bowed string
               section holding one note, seamless loops. Together an E minor chord over the drones' E (41 Hz), in the silo
               theme's key (A minor); the machines breathe out of step, so the chord rolls round the hall
"""
import os
import wave

import numpy as np

from blast_door import band, clunk, decay
from lift_crash import crackle
from silo_cue import RATE, ROOT, highpass, lowpass, reverb, smooth_noise, timeline

OUT = os.path.join(ROOT, "audio", "silo")
LOOP = 8.0          # drone / pour loop length (s); every periodic part fits a whole number of cycles in it
XFADE = 1.5         # seconds rendered past the loop and folded back over its start
HIT = 0.45          # the pulse's thump, after its pre-swell


def looped(render, seconds, seed):
    """Renders seconds + XFADE and folds the extra over the start, so the end runs straight into the beginning."""
    x = render(seconds + XFADE, seed)
    n, f = int(seconds * RATE), int(XFADE * RATE)
    ramp = np.linspace(0.0, 1.0, f)
    out = x[:n].copy()
    out[:f] = x[:f] * np.sqrt(ramp) + x[n:n + f] * np.sqrt(1.0 - ramp)
    return out


def brown(n, seed):
    b = np.cumsum(np.random.default_rng(seed).standard_normal(n))
    b = highpass(b, 18.0)
    return b / np.abs(b).max()


def drone_body(seconds, seed):
    t = timeline(seconds)
    n = len(t)
    sub = np.sin(2 * np.pi * 41.0 * t) + 0.7 * np.sin(2 * np.pi * 41.5 * t)          # beats every 2 s
    chug = 0.55 + 0.45 * (0.5 + 0.5 * np.sin(2 * np.pi * 3.25 * t)) ** 3               # the rotor's mass going round
    growl = sum(np.sin(2 * np.pi * 41.0 * k * t + k * 0.7) / k ** 0.8 for k in range(2, 16))   # the machine's body, audible
    growl = band(np.tanh(growl * 0.8), 70.0, 900.0)                                     # on small speakers too
    windings = np.tanh(3.0 * np.sin(2 * np.pi * 60.0 * t))                              # odd harmonics of the mains
    windings = band(windings, 110.0, 1600.0) * (0.7 + 0.3 * smooth_noise(seconds, 0.7, seed + 1))
    drift = 5.0 * smooth_noise(seconds, 0.25, seed + 2)
    whine = np.sin(2 * np.pi * np.cumsum(880.0 + drift) / RATE) + 0.5 * np.sin(2 * np.pi * np.cumsum(1320.0 + 1.5 * drift) / RATE)
    rumble = lowpass(brown(n, seed + 3), 110.0, 3.0)
    grit = band(np.random.default_rng(seed + 4).standard_normal(n), 300.0, 3000.0) * chug ** 2
    x = sub * chug * 0.55 + growl * chug * 0.9 + windings * 0.35 + whine * 0.05 + rumble * 0.35 + grit * 0.12
    return np.tanh(x * 0.9)


def drone():
    return normalise(looped(drone_body, LOOP, 10), -2.0)


def pulse():
    t = timeline(5.5)
    d = np.maximum(t - HIT, 0.0)
    on = np.clip(d / 0.003, 0.0, 1.0)
    pre = np.clip(t / HIT, 0.0, 1.0) ** 3 * (t < HIT)                                   # breath drawn in
    suck = band(np.random.default_rng(20).standard_normal(len(t)), 80.0, 1200.0) * pre * 0.35
    f = 34.0 + 60.0 * np.exp(-d / 0.06)                                                  # the thump falls into the floor
    thump = np.sin(2 * np.pi * np.cumsum(f) / RATE) * decay(t, HIT, 0.55) * on
    punch = band(np.tanh(6.0 * np.sin(2 * np.pi * np.cumsum(f * 2.0) / RATE)), 60.0, 700.0) * decay(t, HIT, 0.16) * on
    house = np.zeros_like(t)                                                             # the housing rings
    for i, (hz, tau, gain) in enumerate(((55.0, 1.1, 0.5), (83.0, 0.9, 0.5), (131.0, 0.8, 0.5), (197.0, 0.6, 0.45),
                                         (263.0, 0.45, 0.35), (409.0, 0.3, 0.25), (587.0, 0.2, 0.15))):
        house += np.sin(2 * np.pi * hz * d + i) * decay(t, HIT, tau) * gain * on
    arc = crackle(t, HIT, HIT + 0.25, 900.0, 21) * 1.2
    arc += band(np.tanh(4.0 * np.sin(2 * np.pi * 120.0 * t)), 100.0, 4000.0) * decay(t, HIT, 0.12) * 0.4
    x = thump * 0.7 + punch * 1.6 + house * 1.7 + clunk(t, HIT, 1.8, 22) * 1.8 + arc * 1.4 + suck
    x = np.tanh(x * 1.5)                                                                  # driven: dense and loud
    wet = reverb(x, rt60=4.5, wet=0.3, darkness=1800.0, predelay=0.04)[:len(x)].mean(axis=1)
    tail = int(RATE * 0.5)
    wet[-tail:] *= np.linspace(1.0, 0.0, tail)
    wet = np.tanh(normalise(wet, 0.0) * 3.0)                                            # limit: the body comes up to the sub
    return normalise(wet, -0.5)


def arc(seed):
    t = timeline(1.4)
    r = np.random.default_rng(seed)
    length = r.uniform(0.35, 0.8)
    body = np.clip(t / 0.01, 0.0, 1.0) * np.exp(-np.maximum(t - length, 0.0) / 0.08)
    stutter = (smooth_noise(1.4, 38.0, seed) > r.uniform(-0.4, 0.1)).astype(float)
    buzz = np.tanh(5.0 * np.sin(2 * np.pi * np.cumsum(120.0 + 9.0 * smooth_noise(1.4, 6.0, seed + 1)) / RATE))
    sizzle = band(r.standard_normal(len(t)), 2500.0, 11000.0)
    x = (band(buzz, 100.0, 5000.0) * 0.5 + sizzle * 0.35) * body * stutter + crackle(t, 0.0, length, 400.0, seed + 2) * 0.9
    x += clunk(t, 0.0, 0.4, seed + 3) * 0.3
    wet = reverb(x, rt60=3.0, wet=0.35, darkness=4000.0, predelay=0.03)[:len(x)].mean(axis=1)
    return normalise(wet, -3.0)


def pour_body(seconds, seed):
    t = timeline(seconds)
    n = len(t)
    r = np.random.default_rng(seed)
    gurgle = 0.55 + 0.45 * smooth_noise(seconds, 9.0, seed)
    stream = band(r.standard_normal(n), 180.0, 2200.0) * gurgle
    bubbles = np.zeros(n)
    for when in r.uniform(0.0, seconds, int(seconds * 14)):
        i = int(when * RATE)
        k = np.arange(min(int(0.06 * RATE), n - i))
        hz = r.uniform(180.0, 520.0) * (1.0 + 0.8 * k / RATE / 0.06)                    # a bubble's rising blip
        bubbles[i:i + len(k)] += np.sin(2 * np.pi * np.cumsum(hz) / RATE) * np.exp(-k / (0.018 * RATE)) * r.uniform(0.2, 0.7)
    splash = lowpass(brown(n, seed + 1), 220.0) * (0.8 + 0.2 * smooth_noise(seconds, 2.0, seed + 2))
    return stream * 0.5 + bubbles * 0.4 + splash * 0.7


def pour():
    return normalise(looped(pour_body, LOOP, 30), -4.0)


BOWS = {"e2": 82.41, "b2": 123.47, "g3": 196.0}


def bow_body(seconds, seed, hz):
    """Three detuned players bowing one note: sawtooth-like partials with slow vibrato, bow hiss, a woody body filter."""
    t = timeline(seconds)
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    for v in range(3):
        f = hz * (1.0 + r.uniform(-0.004, 0.004)) * (1.0 + 0.004 * np.sin(2 * np.pi * r.uniform(4.6, 5.4) * t + v))
        f *= 1.0 + 0.002 * smooth_noise(seconds, 0.6, seed + v)
        ph = 2 * np.pi * np.cumsum(f) / RATE
        voice = sum(np.sin(k * ph) / k ** 1.1 for k in range(1, 18) if k * hz < 6000.0)
        x += voice * (0.8 + 0.2 * smooth_noise(seconds, 0.35, seed + 10 + v))           # bow pressure wanders
    hiss = band(r.standard_normal(len(t)), 1500.0, 6000.0) * 0.04
    body = lowpass(x, 2400.0, 1.5) + band(x, 250.0, 450.0) * 0.4                     # the wood's low hump
    return body + hiss * np.abs(x).mean()


def bow(hz, seed):
    return normalise(looped(lambda s, sd: bow_body(s, sd, hz), LOOP, seed), -3.0)


def normalise(x, db):
    return x / np.max(np.abs(x)) * 10 ** (db / 20.0)


def save(name, mono):
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((np.clip(mono, -1.0, 1.0) * 32767.0).astype("<i2").tobytes())
    print(f"{path}  {len(mono) / RATE:.2f} s")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("gen_drone", drone())
    save("gen_pulse", pulse())
    for k in (1, 2, 3):
        save(f"gen_arc_{k}", arc(40 + k * 7))
    save("gen_pour", pour())
    for k, (note, hz) in enumerate(BOWS.items()):
        save(f"gen_bow_{note}", bow(hz, 50 + k))
