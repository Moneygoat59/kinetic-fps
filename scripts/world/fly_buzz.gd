class_name FlyBuzz
extends AudioStreamPlayer3D
## The sound of a fly swarm (FlySwarm): not a loop, but one fly at a time now and then. After a random silence (GAP) it plays
## one of the takes (audio/apartment/fly_buzz_*.wav, tools/audio/flies.py: a pass, a circle, a short hop, bumping) at a
## random pitch and level, from a random point round the swarm, then falls silent again. Swarms start at random points in
## that cycle, so no two are in step and nothing repeats in a pattern.

enum State { SILENT, BUZZING }

const TAKES: Array[AudioStream] = [
	preload("res://audio/apartment/fly_buzz_0.wav"), preload("res://audio/apartment/fly_buzz_1.wav"),
	preload("res://audio/apartment/fly_buzz_2.wav"), preload("res://audio/apartment/fly_buzz_3.wav"),
	preload("res://audio/apartment/fly_buzz_4.wav"), preload("res://audio/apartment/fly_buzz_5.wav"),
	preload("res://audio/apartment/fly_buzz_6.wav"), preload("res://audio/apartment/fly_buzz_7.wav"),
]
const GAP := Vector2(3.0, 16.0)             # seconds of silence between flies
const PITCH := Vector2(0.82, 1.22)
const LEVEL := Vector2(-34.0, -24.0)        # dB
const MAX_DELTA := 0.1

var state := State.SILENT
var radius := 0.35                          # m round the swarm the sound can come from
var _wait := 0.0
var _last := -1


func _ready() -> void:
	unit_size = 0.7
	max_distance = 5.0
	_wait = randf_range(0.5, GAP.y)           # out of step with every other swarm from the start
	finished.connect(_on_finished)


func _process(delta: float) -> void:
	if state != State.SILENT:
		return
	_wait -= clampf(delta, 0.0, MAX_DELTA)
	if _wait <= 0.0:
		_buzz()


func _buzz() -> void:
	var i := randi() % TAKES.size()
	if i == _last:                            # never the same take twice running
		i = (i + 1) % TAKES.size()
	_last = i
	stream = TAKES[i]
	pitch_scale = randf_range(PITCH.x, PITCH.y)
	volume_db = randf_range(LEVEL.x, LEVEL.y)
	position = Vector3(randf_range(-radius, radius), randf_range(-radius, radius) * 0.5, randf_range(-radius, radius))
	state = State.BUZZING
	play()


func _on_finished() -> void:
	state = State.SILENT
	_wait = randf_range(GAP.x, GAP.y)
