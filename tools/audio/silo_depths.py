"""The silo depths' close sounds, rendered to audio/silo/*.wav (44.1 kHz mono 16-bit). Run: python tools/audio/silo_depths.py
Needs numpy. No downloads.
  ears_ring        coming to after the crash (HearingReturn): a high ringing tone, beating faintly against a second one,
                   loud at first and dying over RING seconds, with the blood pounding in the ears under it, slowing
  breath_calm      the walker's breathing while crawling (DuctSound), a seamless LOOP: slow, through the nose and mouth
  breath_fast      the same, short and ragged with effort and nerves (a voiced catch on the out-breaths); DuctSound
                   crossfades to it as the duct's end gets closer
  duct_flex_1..3   the duct's sheet steel popping under the walker's weight ("oil-canning"): a dull bwong and a click
  duct_draft       air coming through the cap's slot, a seamless LOOP: a breathy rush with a thin whistle that comes and goes
  beyond_1..3      from somewhere past the cap, far off and muffled: a heavy thud, a long scrape, a slow knocking. Nothing
                   says what it is
"""
import os
import wave

import numpy as np

from blast_door import band, decay
from silo_cue import RATE, ROOT, lowpass, reverb, smooth_noise, timeline
from silo_generator import brown, looped, normalise

OUT = os.path.join(ROOT, "audio", "silo")
RING = 22.0
LOOP = 8.0


def ears_ring():
    t = timeline(RING)
    fade = np.exp(-t / 6.0) * np.clip(t / 0.05, 0.0, 1.0)
    wobble = 1.0 + 0.002 * smooth_noise(RING, 0.8, 1)
    tone = np.sin(2 * np.pi * np.cumsum(5230.0 * wobble) / RATE) + 0.35 * np.sin(2 * np.pi * 5237.0 * t)
    tone += 0.12 * np.sin(2 * np.pi * np.cumsum(7910.0 * wobble) / RATE)
    tone *= fade * (0.85 + 0.15 * np.sin(2 * np.pi * 0.35 * t))
    rate = 1.35 - 0.35 * np.clip(t / RING, 0.0, 1.0)                                 # the heart slows as they come round
    beat_phase = np.cumsum(rate) / RATE
    blood = np.zeros_like(t)
    for k in range(int(beat_phase[-1])):
        i = int(np.searchsorted(beat_phase, k))
        for off, gain in ((0.0, 1.0), (0.22, 0.6)):                                     # lub-dub
            start = t[i] + off / rate[i]
            d = np.maximum(t - start, 0.0)
            blood += np.sin(2 * np.pi * 48.0 * d) * decay(t, start, 0.09) * gain * (t >= start)
    blood = lowpass(blood + band(brown(len(t), 2), 30.0, 250.0) * 0.15, 200.0) * np.exp(-t / 9.0)
    return normalise(tone * 0.5 + blood * 1.2, -3.0)


def breath_body(seconds, seed, period, rough):
    """Inhale: brightening noise through the mouth; exhale: darker and longer, with a voiced catch when rough > 0."""
    t = timeline(seconds)
    r = np.random.default_rng(seed)
    air = r.standard_normal(len(t))
    inhale_air = band(air, 700.0, 3200.0)
    exhale_air = band(air, 250.0, 1700.0)
    x = np.zeros_like(t)
    start = 0.0
    while start < seconds:
        p = period * r.uniform(0.85, 1.15)
        i_len, e_len = p * 0.38, p * 0.5
        u_in = np.clip((t - start) / i_len, 0.0, 1.0)
        env_in = np.sin(np.pi * u_in) ** 1.5 * ((t >= start) & (t < start + i_len))
        e0 = start + i_len + p * 0.04
        u_out = np.clip((t - e0) / e_len, 0.0, 1.0)
        env_out = (np.sin(np.pi * u_out ** 0.6)) ** 1.2 * ((t >= e0) & (t < e0 + e_len))
        x += inhale_air * env_in * 0.7 * r.uniform(0.8, 1.1) + exhale_air * env_out * r.uniform(0.9, 1.2)
        if rough > 0.0:
            voice = np.tanh(3.0 * np.sin(2 * np.pi * r.uniform(105.0, 125.0) * (t - e0)))
            x += band(voice, 100.0, 900.0) * env_out ** 2 * rough * r.uniform(0.2, 0.6) * (t < e0 + e_len * 0.4)
        start += p
    return x


def breath(period, rough, seed):
    return normalise(looped(lambda s, sd: breath_body(s, sd, period, rough), LOOP, seed), -4.0)


def flex(seed):
    t = timeline(0.9)
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    drop = 1.0 + 0.35 * np.exp(-t / 0.03)                                               # the panel's pitch settles
    for hz, tau, gain in ((r.uniform(150, 200), 0.18, 1.0), (r.uniform(290, 340), 0.12, 0.6), (r.uniform(500, 560), 0.08, 0.4),
                          (r.uniform(850, 950), 0.05, 0.3)):
        x += np.sin(2 * np.pi * np.cumsum(hz * drop) / RATE) * decay(t, 0.0, tau) * gain
    x += band(r.standard_normal(len(t)), 1500.0, 7000.0) * decay(t, 0.0, 0.006) * 0.6
    wet = reverb(x, rt60=0.6, wet=0.35, darkness=3500.0, predelay=0.004)[:len(x)].mean(axis=1)   # a small metal box
    return normalise(wet, -4.0)


def draft_body(seconds, seed):
    t = timeline(seconds)
    r = np.random.default_rng(seed)
    gust = 0.6 + 0.4 * smooth_noise(seconds, 0.5, seed)
    rush = band(r.standard_normal(len(t)), 300.0, 2500.0) * gust
    whistle_hz = 1150.0 + 60.0 * smooth_noise(seconds, 0.3, seed + 1)
    whistle = np.sin(2 * np.pi * np.cumsum(whistle_hz) / RATE) * np.clip(smooth_noise(seconds, 0.4, seed + 2), 0.0, 1.0) ** 2
    return rush * 0.6 + whistle * 0.25 * gust


def draft():
    return normalise(looped(draft_body, LOOP, 60), -6.0)


def beyond(kind, seed):
    t = timeline(6.0)
    r = np.random.default_rng(seed)
    x = np.zeros_like(t)
    if kind == 0:                                                                       # one heavy thud, something settling
        for start, w in ((0.3, 1.0), (0.9, 0.35)):
            d = np.maximum(t - start, 0.0)
            x += np.sin(2 * np.pi * np.cumsum(40.0 + 30.0 * np.exp(-d / 0.05)) / RATE) * decay(t, start, 0.35) * w * (t >= start)
            x += band(r.standard_normal(len(t)), 80.0, 600.0) * decay(t, start, 0.08) * w * 0.5
    elif kind == 1:                                                                     # a long scrape, dragged
        env = np.clip((t - 0.3) / 0.6, 0.0, 1.0) * np.clip((3.6 - t) / 0.8, 0.0, 1.0)
        grind = band(r.standard_normal(len(t)), 200.0, 1400.0) * (0.5 + 0.5 * np.abs(smooth_noise(6.0, 14.0, seed)))
        x += grind * env
    else:                                                                               # slow knocking, then nothing
        for k, start in enumerate((0.3, 1.5, 2.7, 4.3)):
            d = np.maximum(t - start, 0.0)
            x += np.sin(2 * np.pi * 110.0 * d) * decay(t, start, 0.12) * (t >= start) * (0.8 if k < 3 else 0.4)
            x += band(r.standard_normal(len(t)), 150.0, 900.0) * decay(t, start, 0.03) * 0.4
    x = lowpass(x, 700.0, 2.0)                                                          # far away, through steel and rock
    wet = reverb(x, rt60=3.5, wet=0.6, darkness=900.0, predelay=0.06)[:len(x)].mean(axis=1)
    tail = int(RATE * 0.5)
    wet[-tail:] *= np.linspace(1.0, 0.0, tail)
    return normalise(wet, -6.0)


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
    save("ears_ring", ears_ring())
    save("breath_calm", breath(3.6, 0.0, 70))
    save("breath_fast", breath(1.9, 1.0, 71))
    for k in (1, 2, 3):
        save(f"duct_flex_{k}", flex(80 + k))
        save(f"beyond_{k}", beyond(k - 1, 90 + k))
    save("duct_draft", draft())
