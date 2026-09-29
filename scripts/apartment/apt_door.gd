class_name AptDoor
extends AnimatableBody3D
## A swinging door leaf (apartment kit node `pivot_leaf`, origin on the hinge). AptProp mounts one per leaf: the body is the
## leaf's collision and its interaction target ([E] OPEN DOOR / CLOSE DOOR). The leaf swings toward the piece's front (+Z).
## Per placement: a marker named ..__open starts it open (e.g. marker_kit_door_interior__2__open). Prompt text and sounds
## come from TEXT by the piece's name (the medicine cabinet's mirror door is one too).

enum State { CLOSED, OPENING, OPEN, CLOSING }

const OPEN_ANGLE := -95.0            # degrees about the hinge (negative swings the free edge toward +Z)
const SWING_SPEED := 2.4             # rad/s
const MAX_DELTA := 0.1
const LEAF_T := 0.04                 # leaf slab thickness (apt_dims.LEAF_T); knobs stand symmetric about it
## piece name -> [open title, close title, sub, open sound, close sound]
const TEXT := {
	"door_interior": ["OPEN DOOR", "CLOSE DOOR", "INTERIOR DOOR", "res://audio/rpg/Audio/doorOpen_1.ogg",
		"res://audio/rpg/Audio/doorClose_1.ogg"],
	"medicine_cabinet": ["OPEN CABINET", "CLOSE CABINET", "MEDICINE CABINET", "res://audio/rpg/Audio/creak2.ogg",
		"res://audio/rpg/Audio/metalClick.ogg"],
}
const DEFAULT := "door_interior"

var state := State.CLOSED
var _leaf: Node3D
var _angle := 0.0
var _open_rad := deg_to_rad(OPEN_ANGLE)
var _audio: AudioStreamPlayer3D
var _text: Array = TEXT[DEFAULT]
var _snd_open: AudioStream
var _snd_close: AudioStream


static func mount(leaf: Node3D) -> AptDoor:
	if leaf == null or not (leaf is MeshInstance3D) or (leaf as MeshInstance3D).mesh == null:
		return null
	var door := AptDoor.new()
	door.name = "door_body"
	var box := (leaf as MeshInstance3D).mesh.get_aabb()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3(box.size.x, box.size.y, LEAF_T)   # the slab only: knobs must not narrow the doorway
	shape.position = box.get_center()
	door.add_child(shape)
	door._leaf = leaf
	door._text = TEXT.get(String(leaf.get_parent().name) if leaf.get_parent() else DEFAULT, TEXT[DEFAULT])
	door._snd_open = load(door._text[3])
	door._snd_close = load(door._text[4])
	leaf.add_child(door)
	var marker := leaf.get_parent().get_parent() if leaf.get_parent() else null
	if marker and String(marker.name).contains("__open"):
		door._set_state(State.OPEN)
		door._angle = door._open_rad
		leaf.rotation.y = door._angle
	return door


func _ready() -> void:
	sync_to_physics = false             # the leaf (our parent) moves us: synced bodies ignore inherited motion and stay shut
	_audio = AudioStreamPlayer3D.new()
	_audio.unit_size = 3.0
	_audio.max_distance = 18.0
	add_child(_audio)
	set_physics_process(state == State.OPENING or state == State.CLOSING)


func get_interaction_prompt() -> String:
	return _text[1] if state == State.OPEN or state == State.OPENING else _text[0]


func get_interaction_detail() -> String:
	return _text[2]


func interact(_player: Node) -> void:
	if _leaf == null:
		return
	var opening := state == State.CLOSED or state == State.CLOSING
	_set_state(State.OPENING if opening else State.CLOSING)
	_audio.stream = _snd_open if opening else _snd_close
	_audio.play()


func _set_state(next: State) -> void:
	state = next
	if is_inside_tree():
		set_physics_process(state == State.OPENING or state == State.CLOSING)


func _physics_process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var target := _open_rad if state == State.OPENING else 0.0
	_angle = move_toward(_angle, target, SWING_SPEED * dt)
	_leaf.rotation.y = _angle
	if is_equal_approx(_angle, target):
		_set_state(State.OPEN if state == State.OPENING else State.CLOSED)
