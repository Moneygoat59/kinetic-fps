class_name WraithSfx
extends RefCounted
## The wraith's synthesized sounds, built once and cached when night 2 loads (~0.2 s). Its voice (whispers, inhale, scream)
## is recorded instead: audio/wraith/, made by tools/audio/wraith_voice.py.
##   drone      6 s seamless loop: two sub tones beating against each other, a slow swell, a faint dissonant pair above
##   heartbeat  lub-dub loop (WraithAudio speeds it up with dread)
##   sting      dissonant cluster + boom + noise hit, the moment it is really there
##   vanish     a sucked-in rising rush that stops dead

const Synth = preload("res://scripts/world/wraith/wraith_synth.gd")
const RATE := Synth.RATE

static var _cache := {}


static func drone() -> AudioStreamWAV:
	return _build(&"drone")


static func heartbeat() -> AudioStreamWAV:
	return _build(&"heartbeat")


static func sting() -> AudioStreamWAV:
	return _build(&"sting")


static func vanish() -> AudioStreamWAV:
	return _build(&"vanish")


static func _build(key: StringName) -> AudioStreamWAV:
	if not _cache.has(key):
		var samples: PackedFloat32Array
		match key:
			&"drone": samples = Synth.drone()
			&"heartbeat": samples = Synth.heartbeat()
			&"sting": samples = Synth.sting()
			_: samples = Synth.vanish()
		_cache[key] = _wav(samples, key == &"drone" or key == &"heartbeat")
	return _cache[key]


static func _wav(s: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var peak := 0.001
	for v in s:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(s[i] / peak * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = s.size()
	return w
