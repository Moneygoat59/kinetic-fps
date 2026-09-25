extends Node
## Two-leaf sliding blast door for the Outpost 73 bunker.
## One enum state; only processes while the leaves are moving. The blocker collider is enabled unless fully open.

signal state_changed(old_state: int, new_state: int)

enum State { CLOSED, OPENING, OPEN, CLOSING }

const TRAVEL := 1.0  # metres each leaf slides sideways into the wall
const SPEED := 1.8   # open/close fraction per second (~0.55 s)
const OPEN_SOUND = preload("res://audio/ui/Audio/open_001.ogg")
const CLOSE_SOUND = preload("res://audio/ui/Audio/close_001.ogg")

var state: State = State.CLOSED
var factor: float = 0.0
var _left: Node3D
var _right: Node3D
var _left_x0: float = 0.0
var _right_x0: float = 0.0
var _blocker: CollisionShape3D
var _audio: AudioStreamPlayer3D


func setup(left: Node3D, right: Node3D, blocker: CollisionShape3D, audio: AudioStreamPlayer3D) -> void:
	if left == null or right == null:
		return
	_left = left
	_right = right
	_left_x0 = left.position.x
	_right_x0 = right.position.x
	_blocker = blocker
	_audio = audio
	set_process(false)


## Ask the door to be open (true) or closed (false). Safe to call every frame; reverses mid-travel.
func request_open(wanted: bool) -> void:
	if _left == null:
		return
	match state:
		State.CLOSED, State.CLOSING:
			if wanted:
				_set_state(State.OPENING)
		State.OPEN, State.OPENING:
			if not wanted:
				_set_state(State.CLOSING)


func _process(delta: float) -> void:
	var dir := 1.0 if state == State.OPENING else -1.0
	factor = clampf(factor + dir * SPEED * delta, 0.0, 1.0)
	_left.position.x = _left_x0 - TRAVEL * factor
	_right.position.x = _right_x0 + TRAVEL * factor
	if state == State.OPENING and factor >= 1.0:
		_set_state(State.OPEN)
	elif state == State.CLOSING and factor <= 0.0:
		_set_state(State.CLOSED)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	set_process(state == State.OPENING or state == State.CLOSING)
	if _blocker:
		_blocker.set_deferred("disabled", state == State.OPEN)
	if _audio and (state == State.OPENING or state == State.CLOSING):
		_audio.stream = OPEN_SOUND if state == State.OPENING else CLOSE_SOUND
		_audio.play()
	state_changed.emit(old, new_state)
