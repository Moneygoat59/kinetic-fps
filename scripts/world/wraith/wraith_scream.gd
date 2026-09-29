class_name WraithScream
extends Node
## The finale scream, as loud as the mix allows: audio/wraith/scream.wav (three torn voices, tools/audio/wraith_voice.py)
## over the old stalker scream at two pitches and its roar an octave down. All of it goes through its own bus (overdrive,
## then a hard limiter with a lot of pre-gain) so it is pushed far past everything else without clipping the master.
## play() starts every layer together; stop() cuts it dead (the cut to black).

const BUS := &"WraithScream"
const LAYERS := [                  # stream, pitch, volume dB
	[preload("res://audio/wraith/scream.wav"), 1.0, 0.0],
	[preload("res://audio/stalker/scream.mp3"), 0.78, -1.0],
	[preload("res://audio/stalker/scream.mp3"), 0.52, -3.0],
	[preload("res://audio/stalker/roar.mp3"), 0.6, -4.0],
]
const PRE_GAIN := 10.0             # dB into the limiter: it is the loudest thing in the game
const CEILING := -0.3

var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_ensure_bus()
	for layer in LAYERS:
		var p := AudioStreamPlayer.new()
		p.stream = layer[0]
		p.pitch_scale = layer[1]
		p.volume_db = layer[2]
		p.bus = BUS
		add_child(p)
		_players.append(p)


func play() -> void:
	for p in _players:
		p.play()


func stop() -> void:
	for p in _players:
		p.stop()


static func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, &"Master")
	var drive := AudioEffectDistortion.new()
	drive.mode = AudioEffectDistortion.MODE_OVERDRIVE
	drive.drive = 0.45
	drive.post_gain = -4.0
	AudioServer.add_bus_effect(i, drive)
	var limit := AudioEffectHardLimiter.new()
	limit.pre_gain_db = PRE_GAIN
	limit.ceiling_db = CEILING
	AudioServer.add_bus_effect(i, limit)
