class_name DosimeterSounds
extends RefCounted
## The field dosimeter's synthesized voice (8-bit sine pips, built once and shared): the Geiger beep paced by
## RadiationDosimeter, and the relay-reached lock (two short soft pips, low and rising).

const LOCK_TONES: Array[float] = [0.11, 0.15]     # rad/sample at 22050 Hz (~390 Hz, ~525 Hz)
const LOCK_PIP := 1300                                # samples per pip (~60 ms)
const LOCK_GAP := 700

static var beep_wav: AudioStreamWAV
static var lock_wav: AudioStreamWAV


static func beep() -> AudioStreamWAV:
	if beep_wav:
		return beep_wav
	beep_wav = AudioStreamWAV.new()
	beep_wav.format = AudioStreamWAV.FORMAT_8_BITS
	beep_wav.mix_rate = 22050
	var samples := 1100
	var data := PackedByteArray()
	data.resize(samples)
	for i in samples:
		var env := sin(float(i) / float(samples) * PI)
		data[i] = clampi(int(128.0 + 100.0 * sin(float(i) * 0.26) * env), 0, 255)
	beep_wav.data = data
	return beep_wav


## The relay-reached sound: two short soft sine pips, rising, same 8-bit voice as the Geiger beep.
static func lock() -> AudioStreamWAV:
	if lock_wav:
		return lock_wav
	lock_wav = AudioStreamWAV.new()
	lock_wav.format = AudioStreamWAV.FORMAT_8_BITS
	lock_wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(LOCK_TONES.size() * (LOCK_PIP + LOCK_GAP))
	data.fill(0)                                      # 8-bit AudioStreamWAV samples are signed: 0 is silence
	for k in LOCK_TONES.size():
		var at := k * (LOCK_PIP + LOCK_GAP)
		for i in LOCK_PIP:
			var env := sin(float(i) / float(LOCK_PIP) * PI)
			data[at + i] = posmod(int(55.0 * sin(float(i) * LOCK_TONES[k]) * env * env), 256)
	lock_wav.data = data
	return lock_wav
