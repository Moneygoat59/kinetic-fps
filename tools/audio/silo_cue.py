"""The silo's discovery cues, rendered to audio/silo/discover_*.wav (44.1 kHz stereo 16-bit). Run: python tools/audio/silo_cue.py
Needs numpy. No downloads. Each is a one-shot heard once, when the walker first steps out of the trees into the blast
clearing (MissileSilo, DISCOVER_DIST). All are far away: lowpassed and put in a long stereo reverb (noise impulse).
  discover_braam   four slow brass-like swells overlapping, Am -> F -> Dm -> E, each opening up and closing (~20 s)
  discover_toll    a huge inharmonic bell struck twice, the second fainter: something old, and alone
  discover_siren   a civil-defence siren somewhere past the rim, one slow wail up and down, bent by the wind
  discover_hum     a reversed rush sucked into a sub drone that beats, a thin shimmer and a few geiger clicks
"""
import os
import wave

import numpy as np

RATE = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "audio", "silo")
rng = np.random.default_rng(73)


def timeline(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def lowpass(x, cutoff, slope=2.0):
    """Gentle FFT lowpass (1 / (1 + (f/fc)^(2*slope)))."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1.0 / RATE)
    spec *= 1.0 / np.sqrt(1.0 + (f / cutoff) ** (2.0 * slope))
    return np.fft.irfft(spec, len(x))


def highpass(x, cutoff):
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1.0 / RATE)
    spec *= 1.0 / np.sqrt(1.0 + (cutoff / np.maximum(f, 1e-3)) ** 4.0)
    return np.fft.irfft(spec, len(x))


def smooth_noise(seconds, rate_hz, seed):
    """Slow random wobble in -1..1 (for wind, drift)."""
    r = np.random.default_rng(seed)
    n = int(seconds * rate_hz) + 3
    pts = r.uniform(-1.0, 1.0, n)
    t = timeline(seconds) * rate_hz
    return np.interp(t, np.arange(n), pts)


def reverb(x, rt60=6.0, wet=0.6, darkness=2500.0, predelay=0.03):
    """Stereo: the dry signal centred plus two decorrelated exponentially decaying noise tails, darker as they decay."""
    n_ir = int(RATE * rt60 * 1.1)
    t = np.arange(n_ir) / RATE
    out = []
    for seed in (1, 2):
        noise = np.random.default_rng(seed).standard_normal(n_ir)
        bright = lowpass(noise, darkness)
        dull = lowpass(noise, darkness * 0.25)
        mix = np.exp(-t / (rt60 * 0.25))                       # bright early, dull late
        ir = (bright * mix + dull * (1.0 - mix)) * np.exp(-6.9 * t / rt60)
        ir = np.concatenate([np.zeros(int(RATE * predelay)), ir])
        ir /= np.sqrt(np.sum(ir ** 2))
        n = len(x) + len(ir) - 1
        size = 1 << (n - 1).bit_length()
        tail = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[:n]
        dry = np.concatenate([x, np.zeros(n - len(x))])
        out.append(dry * (1.0 - wet) + tail * wet)
    mid, side = (out[0] + out[1]) * 0.5, (out[0] - out[1]) * 0.5
    side = highpass(side, 250.0)                               # the lows stay mono: no phasey sub, no mono cancelling
    return np.stack([mid + side, mid - side], axis=1)


def envelope(t, attack, hold, release):
    a = np.clip(t / max(attack, 1e-4), 0.0, 1.0) ** 2
    r = np.exp(-np.maximum(t - attack - hold, 0.0) / release)
    return a * r


# (start s, attack, hold, release, sub Hz, notes): overlapping swells, each rising under the last one's fade.
# A minor -> F -> D minor -> E major: it falls away and never comes home (the G# on the last swell leaves it hanging).
SWELLS = (
    (0.0, 2.6, 0.8, 2.4, 55.0, (55.0, 82.41, 110.0, 130.81, 164.81)),        # Am  A1 E2 A2 C3 E3
    (4.6, 2.4, 0.8, 2.4, 43.65, (43.65, 65.41, 87.31, 110.0, 130.81)),       # F   F1 C2 F2 A2 C3
    (9.2, 2.4, 0.9, 2.4, 36.71, (73.42, 110.0, 146.83, 174.61, 220.0)),      # Dm  D2 A2 D3 F3 A3
    (13.6, 3.2, 1.6, 3.4, 41.2, (41.2, 61.74, 82.41, 103.83, 123.47)),       # E   E1 B1 E2 G#2 B2, longest
)
BRAAM_LEN = 24.0


def swell_signal(attack, hold, release, sub, notes, gain=1.0, seed=0, cut=None):
    """One slow brass-like chord from its own t = 0: detuned sawtooth voices whose upper harmonics open with the swell and
    close again. Seeded and drawn over its full length, so it renders identically wherever it is placed or cut short
    (silo_theme.py relies on that to loop seamlessly)."""
    length = attack + hold + release * 5.0
    n = int(length * RATE) if cut is None else min(int(length * RATE), cut)
    local = np.random.default_rng(seed)
    tt = np.arange(n) / RATE
    env = envelope(tt, attack, hold, release)
    bright = 1.5 + 9.0 * env                                   # harmonics that speak: the section opens up and closes
    knots = int(length * 0.7) + 3
    drift = np.interp(tt, np.arange(knots) / 0.7, local.uniform(-1.0, 1.0, knots)) * 0.004
    x = np.zeros_like(tt)
    for f in notes:
        for detune in (-0.0025, 0.0, 0.0031):
            ph = 2.0 * np.pi * f * (1.0 + detune + drift) * tt + local.uniform(0, 6.3)
            for k in range(1, 26):
                if f * k > 4000.0:
                    break
                x += np.sin(k * ph) / k * np.exp(-(k - 1) / bright)
    x *= env
    x += np.sin(2.0 * np.pi * sub * tt) * envelope(tt, attack * 0.85, hold + 0.4, release) * 6.0     # sub under it
    return x * gain


def swell(t, start, attack, hold, release, sub, notes, gain=1.0, seed=0):
    """swell_signal placed at `start` on the timeline t."""
    out = np.zeros_like(t)
    lo = int(round(start * RATE))
    if lo < len(t):
        sig = swell_signal(attack, hold, release, sub, notes, gain, seed, cut=len(t) - lo)
        out[lo:lo + len(sig)] = sig
    return out


def braam():
    t = timeline(BRAAM_LEN)
    x = np.zeros_like(t)
    for i, spec in enumerate(SWELLS):
        x += swell(t, *spec, seed=5 + i)
    x = lowpass(x, 1400.0)
    return reverb(x, rt60=7.0, wet=0.55)


def bell(t, f0, strike):
    """A big bell's partials (hum, prime, tierce, quint, nominal ...), each beating a little and dying at its own rate."""
    x = np.zeros_like(t)
    dt = np.maximum(t - strike, 0.0)
    on = t >= strike
    for ratio, amp, decay in ((0.5, 1.0, 9.0), (1.0, 0.8, 6.0), (1.19, 0.55, 4.5), (1.5, 0.35, 3.5), (2.0, 0.6, 3.0),
                              (2.52, 0.3, 2.0), (2.66, 0.25, 1.8), (3.0, 0.2, 1.4), (4.07, 0.15, 0.9), (5.2, 0.1, 0.6)):
        for beat in (-0.35, 0.35):
            x += amp * np.sin(2.0 * np.pi * (f0 * ratio + beat) * dt) * np.exp(-dt / decay) * on
    hit = rng.standard_normal(len(t)) * np.exp(-dt * 40.0) * on * 0.8
    return x + lowpass(hit, 900.0)


def toll():
    t = timeline(14.0)
    x = bell(t, 98.0, 0.1) + 0.45 * bell(t, 98.0, 5.2)
    x = lowpass(x, 1800.0)
    return reverb(x, rt60=8.0, wet=0.6, darkness=2000.0)


def siren():
    t = timeline(14.0)
    rise = np.clip(t / 4.0, 0.0, 1.0)
    fall = np.clip((t - 6.0) / 7.0, 0.0, 1.0)
    pitch = 120.0 + 330.0 * (np.sin(rise * np.pi / 2.0) - fall ** 1.6)          # up to 450 Hz, hold, sag back down
    pitch = np.maximum(pitch, 60.0)
    x = np.zeros_like(t)
    for rotor, amp in ((1.0, 1.0), (1.19, 0.7)):                                 # two rotors a minor third apart
        ph = 2.0 * np.pi * np.cumsum(pitch * rotor) / RATE
        for k in range(1, 12):
            x += amp * np.sin(k * ph) / k ** 1.3
    wind = 0.65 + 0.35 * smooth_noise(14.0, 0.9, 9)                             # the wind carries it and takes it away
    x *= envelope(t, 1.8, 6.5, 2.2) * wind
    x = highpass(lowpass(x, 900.0), 110.0)
    return reverb(x, rt60=7.5, wet=0.72, darkness=1500.0, predelay=0.12)


def hum():
    t = timeline(12.0)
    swell_t = 2.4
    k = np.clip(t / swell_t, 0.0, 1.0)
    rush = lowpass(rng.standard_normal(len(t)), 3000.0) * (k ** 4) * (t < swell_t) * 0.9      # sucked in, stops dead
    dt = np.maximum(t - swell_t, 0.0)
    on = t >= swell_t
    drone = (np.sin(2.0 * np.pi * 36.0 * dt) + 0.8 * np.sin(2.0 * np.pi * 37.3 * dt) + 0.35 * np.sin(2.0 * np.pi * 72.6 * dt))
    drone *= np.minimum(dt / 0.05, 1.0) * np.exp(-dt / 4.5) * on * 1.6
    shimmer = (np.sin(2.0 * np.pi * 1760.0 * t) + np.sin(2.0 * np.pi * 1797.0 * t)) * 0.04
    shimmer *= np.clip((t - swell_t) / 3.0, 0.0, 1.0) * np.exp(-dt / 5.0)
    clicks = np.zeros_like(t)
    for when in np.sort(rng.uniform(swell_t + 0.4, 10.5, 18)):
        i = int(when * RATE)
        clicks[i:i + 90] += rng.uniform(0.3, 0.8) * np.exp(-np.arange(len(clicks[i:i + 90])) / 12.0)
    x = rush + drone + shimmer + highpass(clicks, 1500.0) * 0.5
    return reverb(x, rt60=5.5, wet=0.45)


def save(name, stereo):
    level = np.abs(stereo).max(axis=1)
    stereo = stereo[:np.nonzero(level > level.max() * 0.001)[0][-1] + 1]      # cut the tail below -60 dB
    tail = int(RATE * 0.5)
    stereo[-tail:] *= np.linspace(1.0, 0.0, tail)[:, None]
    stereo = stereo / np.max(np.abs(stereo)) * 0.89                              # -1 dBFS
    pcm = (stereo * 32767.0).astype("<i2")
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    print(f"{path}  {len(stereo) / RATE:.1f} s")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("discover_braam", braam())
    save("discover_toll", toll())
    save("discover_siren", siren())
    save("discover_hum", hum())
