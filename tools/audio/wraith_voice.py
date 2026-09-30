"""The wraith's voice, rendered to audio/wraith/*.wav (44.1 kHz mono 16-bit). Run: python tools/audio/wraith_voice.py
Needs numpy and Windows (System.Speech, the built-in David/Zira voices, through PowerShell). No downloads.

Whispers are real speech made breathless: Windows TTS speaks nonsense syllables, then every 23 ms frame's spectral envelope
(LPC, order 44) is laid over fresh noise instead of the voice. That is what a whisper physically is (turbulent air through the
same vocal tract, no vocal folds), so it keeps real consonants and vowel shapes but no pitch. The envelope is warped down a
little (a bigger tract than a person's) and some takes are reversed, so it is speech-like but never quite words.
  whisper_1..5   single close whispers (WraithAudio picks one at random each time)
  whisper_many   three overlapping, for the moment before it takes you
  inhale         a sharp reversed breath, the moment before it screams
  scream         the finale scream: three torn, jittering voices (root, an octave down, a tritone up) with period
                 doubling and roughness, through moving formants, driven hard, boom on the onset. Layered in game over
                 audio/stalker/scream.mp3.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "audio", "wraith")
rng = np.random.default_rng(66)

# (voice, speaking rate -10..10, text, reversed, formant scale)
WHISPERS = {
    "whisper_1": ("David", -2, "sheh ta morrin, hass ka lee", True, 0.86),
    "whisper_2": ("Zira", -3, "hushaa seh nah tessa", False, 0.9),
    "whisper_3": ("David", -3, "ahh seh mah, keh loss", True, 0.82),
    "whisper_4": ("Zira", -2, "tess ah shee noh vah", True, 0.88),
    "whisper_5": ("David", -3, "shhh. hah teh sorra", False, 0.84),
}
MANY = [("David", -3, "ohs tah sehn, kah loh reesh", True, 0.8), ("Zira", -2, "tsee ah, mohna fess", True, 0.9),
        ("David", -4, "hahh keh teh morrah", False, 0.78)]


def tts(voice, rate, text):
    path = os.path.join(tempfile.gettempdir(), f"wraith_tts_{abs(hash((voice, rate, text)))}.wav")
    ps = ("Add-Type -AssemblyName System.Speech; $s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
          f"$s.SelectVoice('Microsoft {voice} Desktop'); $s.Rate = {rate}; "
          f"$f = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo({RATE}, 'Sixteen', 'Mono'); "
          f"$s.SetOutputToWaveFile('{path}', $f); $s.Speak('{text}'); $s.Dispose()")
    subprocess.run(["powershell", "-NoProfile", "-Command", ps], check=True)
    with wave.open(path, "rb") as w:
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float64) / 32768.0
    os.remove(path)
    return x


def lpc(frame, order):
    r = np.correlate(frame, frame, "full")[len(frame) - 1:len(frame) + order]
    if r[0] <= 1e-9:
        return None, 0.0
    r[0] *= 1.0001
    a, err = np.zeros(order + 1), r[0]
    a[0] = 1.0
    for i in range(1, order + 1):                                           # Levinson-Durbin
        k = -(r[i] + np.dot(a[1:i], r[i - 1:0:-1])) / err
        a[1:i] = a[1:i] + k * a[i - 1:0:-1]
        a[i] = k
        err *= 1.0 - k * k
    return a, max(err, 0.0)


def whisperize(x, warp=0.86, order=44, n=1024, hop=256):
    """Each frame: the voice's LPC envelope (formants warped by `warp`) times the spectrum of fresh noise, overlap-added."""
    x = np.append(x[0], x[1:] - 0.94 * x[:-1])                              # pre-emphasis: envelope, not tilt
    win = np.hanning(n)
    out = np.zeros(len(x) + n)
    norm = np.zeros(len(x) + n)
    bins = np.arange(n // 2 + 1)
    for s in range(0, len(x) - n, hop):
        a, err = lpc(x[s:s + n] * win, order)
        if a is None:
            continue
        a = a * 0.988 ** np.arange(order + 1)                             # widen every formant ~170 Hz: breath, not whistle
        env = np.sqrt(err) / np.maximum(np.abs(np.fft.rfft(a, n)), 1e-4)
        env = np.interp(bins / warp, bins, env, right=0.0)                  # formants lower: a bigger throat
        noise = np.fft.rfft(rng.standard_normal(n) * win)
        out[s:s + n] += np.fft.irfft(noise * env, n) * win
        norm[s:s + n] += win * win
    y = out[:len(x)] / np.maximum(norm[:len(x)], 1e-3)
    return onepole(y, 0.6)                                                  # partly undo the pre-emphasis: breath, not hiss


def onepole(x, k):
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = v + k * acc
        y[i] = acc
    return y


def trim(x, floor=0.02):
    idx = np.nonzero(np.abs(x) > floor * np.max(np.abs(x)))[0]
    x = x[max(idx[0] - 800, 0):idx[-1] + 2000]
    fade = min(len(x) // 4, 2000)
    x[:fade] *= np.linspace(0, 1, fade)
    x[-fade:] *= np.linspace(1, 0, fade)
    return x


def whisper(spec):
    voice, rate, text, rev, warp = spec
    y = trim(whisperize(tts(voice, rate, text), warp))
    return y[::-1].copy() if rev else y


def formant_filter(x, tracks, n=2048, hop=512):
    """Time-varying resonances: tracks = [(freq(t), bandwidth, gain)] with freq a function of time in seconds."""
    win = np.hanning(n)
    out = np.zeros(len(x) + n)
    norm = np.zeros(len(x) + n)
    f = np.fft.rfftfreq(n, 1.0 / RATE)
    for s in range(0, len(x) - n, hop):
        t = (s + n / 2) / RATE
        env = np.full_like(f, 0.04)
        for freq, bw, gain in tracks:
            env += gain / (1.0 + ((f - freq(t)) / (bw / 2.0)) ** 2)
        out[s:s + n] += np.fft.irfft(np.fft.rfft(x[s:s + n] * win) * env, n) * win
        norm[s:s + n] += win * win
    return out[:len(x)] / np.maximum(norm[:len(x)], 1e-3)


def scream_voice(t, ratio, jitter, seed):
    r = np.random.default_rng(seed)
    contour = np.interp(t, [0.0, 0.07, 0.2, 0.9, 1.7, 2.6], [170, 240, 640, 700, 660, 430]) * ratio
    walk = np.cumsum(r.standard_normal(len(t))) / np.sqrt(RATE) * 6.0      # a slow drunken wander
    walk -= np.interp(t, t[::4000], walk[::4000])                           # (kept near the contour)
    f0 = contour * (1.0 + jitter * walk + 0.035 * np.sin(np.pi * 2 * 10.5 * t) + jitter * 0.5 * r.standard_normal(len(t)))
    ph = np.cumsum(f0) / RATE
    saw = 2.0 * (ph % 1.0) - 1.0
    sub = np.sign(np.sin(np.pi * ph)) * np.clip(np.sin(np.pi * 2 * 2.3 * t + seed) * 1.5, 0.0, 1.0)  # period doubling, on and off
    rough = 1.0 - 0.55 * (0.5 + 0.5 * np.sin(np.pi * 2 * 74.0 * t + 3.0 * np.sin(np.pi * 2 * 5.0 * t)))
    return (saw + 0.6 * sub) * rough + 0.3 * r.standard_normal(len(t))


def scream():
    dur = 2.7
    t = np.arange(int(RATE * dur)) / RATE
    v = scream_voice(t, 1.0, 0.05, 1) + 0.75 * scream_voice(t, 0.5, 0.03, 2) + 0.5 * scream_voice(t, 1.414, 0.08, 3)
    v = formant_filter(v, [
        (lambda s: np.interp(s, [0, 0.2, 2.7], [600, 950, 820]), 260.0, 1.0),
        (lambda s: np.interp(s, [0, 0.2, 1.2, 2.7], [1100, 1500, 1900, 1400]), 300.0, 0.8),
        (lambda s: 2900.0 + 200.0 * np.sin(s * 3.0), 400.0, 0.55),
        (lambda s: 3900.0, 500.0, 0.3)])
    v /= np.max(np.abs(v))
    v = np.tanh(4.0 * v)                                                    # torn
    env = np.minimum(t / 0.035, 1.0) * np.interp(t, [0, 2.1, 2.7], [1.0, 0.85, 0.0])
    boom = np.sin(np.pi * 2 * 38.0 * t * (1.0 - 0.2 * t)) * np.exp(-t * 3.0) * 0.8
    hit = rng.standard_normal(len(t)) * np.exp(-t * 18.0) * 0.5
    return v * env * 0.8 + boom + hit


def inhale():
    y = whisperize(tts("David", -6, "haaa"), 0.8)
    y = trim(y)[::-1].copy()
    return y * np.linspace(0.3, 1.0, len(y)) ** 2


def layered(specs, offsets):
    takes = [whisper(s) for s in specs]
    n = max(int(o * RATE) + len(x) for x, o in zip(takes, offsets))
    y = np.zeros(n)
    for x, o in zip(takes, offsets):
        y[int(o * RATE):int(o * RATE) + len(x)] += x / np.max(np.abs(x))
    return y


def save(name, x, peak=0.95):
    x = x / max(np.max(np.abs(x)), 1e-9) * peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"{name}.wav  {len(x) / RATE:.2f} s")


if __name__ == "__main__":
    for name, spec in WHISPERS.items():
        save(name, whisper(spec))
    save("whisper_many", layered(MANY, [0.0, 0.35, 0.8]))
    save("inhale", inhale())
    save("scream", scream(), 0.99)
