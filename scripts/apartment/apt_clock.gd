class_name AptClock
extends Node
## Ticks the hands of an apartment-kit clock (nodes hand_h / hand_m / hand_s, turning about their local Z; clockwise seen
## from the front) to the local time, once a second, with a quiet tick. No per-frame work.

const TICK = preload("res://audio/ui/Audio/tick_002.ogg")
const TICK_DB := -30.0

var _h: Node3D
var _m: Node3D
var _s: Node3D
var _audio: AudioStreamPlayer3D
var _bias_s := 0.0


static func mount(prop: Node3D) -> AptClock:
	if prop == null:
		return null
	var clock := AptClock.new()
	clock._h = prop.get_node_or_null("hand_h") as Node3D
	clock._m = prop.get_node_or_null("hand_m") as Node3D
	clock._s = prop.get_node_or_null("hand_s") as Node3D
	prop.add_child(clock)
	return clock


func _ready() -> void:
	_bias_s = float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
	if _s:
		_audio = AudioStreamPlayer3D.new()
		_audio.stream = TICK
		_audio.volume_db = TICK_DB
		_audio.unit_size = 1.0
		_audio.max_distance = 6.0
		_s.add_child(_audio)
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_tick)
	add_child(timer)
	_tick()


func _tick() -> void:
	var t := fposmod(Time.get_unix_time_from_system() + _bias_s, 43200.0)   # seconds into the 12 h dial
	if _h:
		_h.rotation.z = -TAU * t / 43200.0
	if _m:
		_m.rotation.z = -TAU * fposmod(t, 3600.0) / 3600.0
	if _s:
		_s.rotation.z = -TAU * floorf(fposmod(t, 60.0)) / 60.0
		if _audio and _audio.is_inside_tree():
			_audio.play()
