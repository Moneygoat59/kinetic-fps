"""The blast door's open / close, rendered to audio/doors/blast_door_{open,close}.wav (44.1 kHz mono 16-bit, mono so
AudioStreamPlayer3D places it cleanly). Run: python tools/audio/blast_door.py   Needs numpy + fx.py's (pedalboard, pyloudnorm).
Played by BunkerDoor (Outpost 73, outposts 02/03, Relay Hub 00, the silo): the leaves travel for TRAVEL_TIME seconds,
which must equal BunkerDoor.OPEN_TIME, and the travel noise follows the door's smoothstep speed so a reversal mid-way
can seek into the other file at the matching point.
  open    a bolt clunks back and a hydraulic sigh, a low motor drags the leaves along the track (rumble, grit,
          a faint groan), and they bump to rest inside the wall
  close   the same drag, then the leaves meet: a deep slam, a ringing tail, the bolt shooting home
"""
import os

import numpy as np

import fx
from silo_cue import RATE, ROOT, highpass, lowpass, smooth_noise, timeline

OUT = os.path.join(ROOT, "audio", "doors")
TRAVEL_TIME = 2.8  # = BunkerDoor.OPEN_TIME
TAIL = 1.6


def band(x, lo, hi):
    return lowpass(highpass(x, lo), hi)


def decay(t, start, tau):
    d = t - start
    return np.where(d >= 0.0, np.exp(-np.maximum(d, 0.0) / tau), 0.0)


def clunk(t, start, weight, seed):
    """A heavy steel part hitting steel: a falling sub thump, a few inharmonic plate modes and a short gritty click."""
    r = np.random.default_rng(seed)
    d = np.maximum(t - start, 0.0)
    f = 34.0 + 30.0 * np.exp(-d / 0.05) * weight
    thump = np.sin(2.0 * np.pi * np.cumsum(f) / RATE) * decay(t, start, 0.12 + 0.3 * weight)
    ring = np.zeros_like(t)
    for mode in (97.0, 231.0, 386.0, 611.0, 947.0, 1480.0):
        f_m = mode * r.uniform(0.94, 1.06)
        ring += np.sin(2.0 * np.pi * f_m * d + r.uniform(0, 6.3)) * r.uniform(0.3, 1.0) * decay(t, start, 0.05 + 40.0 / f_m * weight)
    click = band(r.standard_normal(len(t)), 300.0, 3500.0) * decay(t, start, 0.012)
    return thump * weight + ring * 0.25 + click * 0.5


def travel(t, seed):
    """The drag: roller rumble, motor drone rising with speed, stick-slip grit and a faint metal groan."""
    r = np.random.default_rng(seed)
    u = np.clip(t / TRAVEL_TIME, 0.0, 1.0)
    speed = 4.0 * u * (1.0 - u)                                          # smoothstep's speed, 0..1
    on = np.clip(t / 0.15, 0.0, 1.0) * np.clip((TRAVEL_TIME + 0.12 - t) / 0.12, 0.0, 1.0)
    brown = np.cumsum(r.standard_normal(len(t)))
    rumble = lowpass(highpass(brown, 25.0), 170.0, 3.0)
    rumble /= np.abs(rumble).max()
    bumps = 1.0 + 0.45 * smooth_noise(len(t) / RATE, 11.0, seed + 1)    # roller over joints in the track
    rumble *= bumps * (0.25 + 0.75 * speed) * on
    hz = 40.0 + 14.0 * speed + 0.6 * smooth_noise(len(t) / RATE, 3.0, seed + 2)
    ph = 2.0 * np.pi * np.cumsum(hz) / RATE
    motor = sum(np.sin(k * ph) / k ** 1.3 for k in (1, 2, 3, 4, 6)) * on * (0.4 + 0.6 * speed)
    motor = lowpass(motor, 500.0)
    grains = np.zeros_like(t)
    for when in np.sort(r.uniform(0.1, TRAVEL_TIME - 0.1, 70)):
        i = int(when * RATE)
        if r.uniform() < speed[i] ** 0.7:
            n = int(r.uniform(0.02, 0.07) * RATE)
            seg = grains[i:i + n]
            seg += r.uniform(0.4, 1.0) * np.exp(-np.arange(len(seg)) / (len(seg) * 0.35))
    grit = band(r.standard_normal(len(t)), 600.0, 2600.0) * (grains + 0.12 * speed * on)
    g_hz = 190.0 + 35.0 * smooth_noise(len(t) / RATE, 1.5, seed + 3)
    g_ph = 2.0 * np.pi * np.cumsum(g_hz) / RATE
    rough = 0.6 + 0.4 * np.sign(np.sin(2.0 * np.pi * 23.0 * t))          # stick-slip chatter
    swell = np.clip(smooth_noise(len(t) / RATE, 0.9, seed + 4), 0.0, 1.0) * speed
    groan = lowpass((np.sin(g_ph) + 0.4 * np.sin(2.0 * g_ph)) * rough * swell, 900.0)
    rattle = band(r.standard_normal(len(t)), 160.0, 650.0) * bumps ** 2 * speed * on     # leaves shaking in the track
    return rumble * 1.1 + motor * 0.35 + rattle * 0.35 + grit * 0.45 + groan * 0.1


def door_open():
    t = timeline(TRAVEL_TIME + TAIL)
    hiss = band(np.random.default_rng(5).standard_normal(len(t)), 1200.0, 5000.0)
    hiss *= np.clip((t - 0.06) / 0.04, 0.0, 1.0) * decay(t, 0.1, 0.35)
    x = clunk(t, 0.0, 0.6, 1) + clunk(t, 0.14, 0.35, 2) + hiss * 0.12 + travel(t, 10)
    x += clunk(t, TRAVEL_TIME + 0.02, 0.5, 3)                              # leaves bump to rest in their pockets
    return x


def door_close():
    t = timeline(TRAVEL_TIME + TAIL)
    x = travel(t, 20)
    x += clunk(t, TRAVEL_TIME, 1.0, 4) * 1.4                              # the leaves meet
    x += clunk(t, TRAVEL_TIME + 0.33, 0.45, 5)                            # the bolt shoots home
    return x


def save(name, mono):
    # the door in its concrete entrance passage: bare walls, so early slaps off the near sides then a ~1.4 s tail
    ir = fx.room_ir(dims=(4.0, 12.0, 3.2), src=(2.0, 0.4, 1.6), ear=(2.6, 4.5, 1.7), rt60=1.4, absorb=0.08)
    wet = fx.room(mono, ir, wet=0.3)
    tail = int(RATE * 0.3)
    wet[-tail:] *= np.linspace(1.0, 0.0, tail)
    fx.save(os.path.join(OUT, name + ".wav"), fx.master(wet, lufs=-20.0))


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("blast_door_open", door_open())
    save("blast_door_close", door_close())
