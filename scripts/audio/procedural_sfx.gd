class_name ProceduralSfx
extends RefCounted
## Small synthesized sounds shared by props and devices (no asset files). Built once, then cached.

const RATE := 22050

static var _tick: AudioStreamWAV


## One Geiger-tube tick: ~5 ms of sharply decaying noise (16-bit signed PCM).
static func geiger_tick() -> AudioStreamWAV:
	if _tick:
		return _tick
	var samples := 120
	var data := PackedByteArray()
	data.resize(samples * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 73
	for i in samples:
		var env := exp(-float(i) / 16.0)
		data.encode_s16(i * 2, int(26000.0 * env * rng.randf_range(-1.0, 1.0)))
	_tick = AudioStreamWAV.new()
	_tick.format = AudioStreamWAV.FORMAT_16_BITS
	_tick.mix_rate = RATE
	_tick.data = data
	return _tick
