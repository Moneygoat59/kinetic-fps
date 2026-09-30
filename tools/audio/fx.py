"""Shared post-processing for the tools/audio generators: a room reverb and a master stage.
Needs numpy, scipy, soundfile, pedalboard, pyloudnorm (pip install scipy pedalboard pyloudnorm). Timing is kept sample-exact (no
latency, no lookahead), so a file that must stay in step with the game (BunkerDoor seeking) can use it.
  room_ir(dims, src, ear)   impulse response of a box room: discrete early reflections off the six walls (image
                            sources, so the slapback and flutter of bare concrete are there) then a diffuse noise tail
                            that darkens as it decays
  room(x, ir, wet)          convolve with it (pedalboard.Convolution), same length out
  master(x, lufs)           glue compressor, gain to a loudness target (EBU R128 integrated), peak limiter;
                            lufs is what keeps files level with each other (peak normalising does not)
  limit(x, ceiling_db)      the peak limiter on its own
  save(path, x)             16-bit wav, mono or stereo (n, 2)
"""
import itertools

import numpy as np
import pedalboard as pb
import pyloudnorm as pyln
import soundfile as sf
from scipy.ndimage import minimum_filter1d

from silo_cue import RATE, lowpass

SPEED = 343.0


def room_ir(dims=(8.0, 5.0, 3.2), src=(4.0, 0.3, 1.5), ear=(3.0, 3.5, 1.7), rt60=1.4, absorb=0.12,
            darkness=3200.0, order=6, seed=1):
    """dims: room size in metres (x, y, z); src / ear: the sound and the listener inside it. absorb: the walls' share
    of energy lost per bounce (bare concrete ~0.02-0.1, soft rooms 0.3+). Returns a float32 IR, unit energy."""
    n = int(RATE * rt60 * 1.1)
    er = np.zeros(n)
    beta = np.sqrt(1.0 - absorb)
    direct = np.linalg.norm(np.subtract(src, ear))
    for axes in itertools.product(range(-order, order + 1), (0, 1), repeat=3):
        img, bounces = [], 0
        for a in range(3):
            m, q = axes[2 * a], axes[2 * a + 1]
            img.append((1 - 2 * q) * src[a] + 2 * m * dims[a])
            bounces += abs(m - q) + abs(m)
        if bounces == 0 or bounces > order:
            continue
        d = np.linalg.norm(np.subtract(img, ear))
        i = int((d - direct) / SPEED * RATE)                  # relative to the direct sound, which is the dry signal
        if i < n:
            er[i] += beta ** bounces * direct / d
    er = lowpass(er, darkness * 1.6)
    t = np.arange(n) / RATE
    noise = np.random.default_rng(seed).standard_normal(n)
    mix = np.exp(-t / (rt60 * 0.25))                          # bright early, dull late
    tail = (lowpass(noise, darkness) * mix + lowpass(noise, darkness * 0.25) * (1.0 - mix)) * np.exp(-6.9 * t / rt60)
    onset = 2.0 * max(dims) / SPEED                           # the diffuse field builds once the walls have answered
    tail *= np.clip(t / onset, 0.0, 1.0) ** 2
    tail *= np.sqrt(np.sum(er ** 2) / max(np.sum(tail[int(onset * RATE):] ** 2), 1e-12)) * 0.8
    ir = er + tail
    return (ir / np.sqrt(np.sum(ir ** 2))).astype(np.float32)


def room(x, ir, wet=0.3):
    """x mono or (n, 2); dry + wet, same length as x (the tail past the end is cut: fade it yourself)."""
    y = pb.Convolution(ir, mix=1.0, sample_rate=RATE)(np.asarray(x, np.float32).T, RATE).T
    return x * (1.0 - wet) + y * wet


def master(x, lufs=-20.0, ceiling_db=-1.0, max_limit_db=3.0, glue_db=-18.0, ratio=2.0):
    """Compress anything over glue_db (relative to the peak) by ratio, gain towards the integrated loudness lufs, then
    limit to ceiling_db. The transient wins: the gain stops where the limiter would take more than max_limit_db off the
    peak, and the file lands quieter than lufs (printed), so a slam keeps its punch."""
    x = np.asarray(x, np.float32)
    x = x / np.max(np.abs(x))
    glue = pb.Compressor(threshold_db=glue_db, ratio=ratio, attack_ms=15.0, release_ms=180.0)
    x = glue(x.T, RATE).T
    meter = pyln.Meter(RATE)
    peak = 20.0 * np.log10(np.max(np.abs(x)))
    gain = min(lufs - meter.integrated_loudness(x), ceiling_db + max_limit_db - peak)
    x = limit(x * 10.0 ** (gain / 20.0), ceiling_db)
    print(f"  {meter.integrated_loudness(x):.1f} LUFS (target {lufs:.0f}), limited {max(peak + gain - ceiling_db, 0):.1f} dB")
    return x


def limit(x, ceiling_db=-1.0, look_ms=3.0, release_ms=120.0):
    """Peak limiter. Offline, so it can see a peak coming and turn down look_ms before it with no latency added
    (pedalboard.Limiter adds makeup gain and cannot look ahead). Gain recovers over release_ms."""
    ceiling = 10.0 ** (ceiling_db / 20.0)
    env = np.abs(x) if x.ndim == 1 else np.abs(x).max(axis=1)
    look = max(int(RATE * look_ms / 1000.0), 1)
    need = minimum_filter1d(np.minimum(1.0, ceiling / np.maximum(env, 1e-9)), 2 * look + 1)
    k = np.exp(-1.0 / (RATE * release_ms / 1000.0))
    g = need.copy()
    for i in range(1, len(g)):
        g[i] = min(need[i], g[i - 1] * k + (1.0 - k))
    g = np.convolve(g, np.hanning(look) / np.hanning(look).sum(), "same")   # no clicks where it bites
    g = g if x.ndim == 1 else g[:, None]
    return np.clip(x * g, -ceiling, ceiling).astype(np.float32)


def save(path, x):
    sf.write(path, np.asarray(x), RATE, subtype="PCM_16")
    print(f"{path}  {len(x) / RATE:.1f} s")
