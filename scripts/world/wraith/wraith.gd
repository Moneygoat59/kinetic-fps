class_name Wraith
extends Node3D
## The night-2 creature: no body to collide with, no walking. It is either GONE or somewhere: it fades in (APPEARING), stands
## there facing you (PRESENT, drifting nearer while unwatched) or dissolves (VANISHING). WraithStalk decides where and
## when (and WraithGrab moves it for the finale); this node only does it. Visuals: WraithView; sound: WraithAudio (its
## `audio` is shared with the stalk logic for the beds and cues).

enum State { GONE, APPEARING, PRESENT, VANISHING }

const APPEAR := 1.4                # seconds to fade in
const VANISH := 0.55
const MAX_DELTA := 0.1

var state := State.GONE
var view: WraithView
var audio: WraithAudio
var terrain: Node3D
var _t := 0.0
var _fade := APPEAR


func _ready() -> void:
	view = WraithView.new()
	add_child(view)
	audio = WraithAudio.new()
	add_child(audio)
	audio.setup(self)
	set_process(false)


## Fade in over `fade` seconds at `pos` (snapped to the ground), facing `look_at_pos`.
func appear(pos: Vector3, look_at_pos: Vector3, fade := APPEAR) -> void:
	_fade = maxf(fade, 0.01)
	global_position = ground(pos)
	face(look_at_pos)
	view.reach = 0.0
	view.grip = 0.0
	_enter(State.APPEARING)


func vanish() -> void:
	if state == State.GONE or state == State.VANISHING:
		return
	audio.vanish()
	_enter(State.VANISHING)


func is_there() -> bool:
	return state == State.APPEARING or state == State.PRESENT


func face(pos: Vector3) -> void:
	var d := pos - global_position
	if Vector2(d.x, d.z).length_squared() > 0.01:
		rotation.y = atan2(d.x, d.z)


## Slide toward `pos` at `speed` m/s, never nearer than `keep` metres (only while PRESENT).
func drift(pos: Vector3, speed: float, keep: float, delta: float) -> void:
	if state != State.PRESENT:
		return
	var d := Vector3(pos.x - global_position.x, 0.0, pos.z - global_position.z)
	var gap := d.length()
	if gap > keep:
		global_position = ground(global_position + d / gap * minf(speed * clampf(delta, 0.0, MAX_DELTA), gap - keep))


func ground(pos: Vector3) -> Vector3:
	var y: float = terrain.get_height(pos.x, pos.z) if terrain and terrain.has_method("get_height") else pos.y
	return Vector3(pos.x, y, pos.z)


func _enter(next: State) -> void:
	state = next
	_t = 0.0
	set_process(state != State.GONE and state != State.PRESENT)


func _process(delta: float) -> void:
	_t += clampf(delta, 0.0, MAX_DELTA)
	match state:
		State.APPEARING:
			view.set_presence(_t / _fade)
			if _t >= _fade:
				_enter(State.PRESENT)
		State.VANISHING:
			view.set_presence(1.0 - _t / VANISH)
			if _t >= VANISH:
				view.set_presence(0.0)
				_enter(State.GONE)
