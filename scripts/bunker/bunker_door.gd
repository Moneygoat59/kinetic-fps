class_name BunkerDoor
extends Node
## Two-leaf sliding blast door (Outpost 73, Relay Hub 00). `mount` wires it onto a model's door_left / door_right nodes.
## One enum state; only processes while the leaves are moving. The blocker collider is enabled unless fully open.

signal state_changed(old_state: int, new_state: int)

enum State { CLOSED, OPENING, OPEN, CLOSING }

const TRAVEL := 1.0  # metres each leaf slides sideways into the wall
const OPEN_TIME := 2.8  # seconds for a full open or close; = TRAVEL_TIME in tools/audio/blast_door.py
const OPEN_SOUND = preload("res://audio/doors/blast_door_open.wav")
const CLOSE_SOUND = preload("res://audio/doors/blast_door_close.wav")

var state: State = State.CLOSED
var factor: float = 0.0
var _left: Node3D
var _right: Node3D
var _left_x0: float = 0.0
var _right_x0: float = 0.0
var _blocker: CollisionShape3D
var _audio: AudioStreamPlayer3D


## Builds the door for a model with door_left / door_right leaves and a marker_door_center (floor level, door centre):
## a blocker collider of `blocker_size` and a positional audio source. The door node goes under `host`. Null if missing.
static func mount(host: Node, model: Node3D, blocker_size: Vector3) -> BunkerDoor:
	var left := model.get_node_or_null("door_left") as Node3D
	var right := model.get_node_or_null("door_right") as Node3D
	var center := model.get_node_or_null("marker_door_center") as Node3D
	if left == null or right == null or center == null:
		push_warning("BunkerDoor: door nodes missing from " + String(model.name))
		return null
	var body := StaticBody3D.new()
	body.position = center.position + Vector3(0.0, blocker_size.y * 0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = blocker_size
	shape.shape = box
	body.add_child(shape)
	model.add_child(body)
	var audio := AudioStreamPlayer3D.new()
	audio.unit_size = 18.0
	audio.position = center.position + Vector3(0.0, 1.25, 0.0)
	model.add_child(audio)
	var door := BunkerDoor.new()
	host.add_child(door)
	door.setup(left, right, shape, audio)
	return door


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
	factor = clampf(factor + dir * delta / OPEN_TIME, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, factor)  # heavy leaves: slow to start, slow to stop
	_left.position.x = _left_x0 - TRAVEL * eased
	_right.position.x = _right_x0 + TRAVEL * eased
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
		# Seek to where the leaves are, so a reversal mid-travel skips the start clunk and keeps the drag in step.
		var opening := state == State.OPENING
		_audio.stream = OPEN_SOUND if opening else CLOSE_SOUND
		_audio.play((factor if opening else 1.0 - factor) * OPEN_TIME)
	state_changed.emit(old, new_state)
