class_name ViewZone
extends Node
## A place bigger than the level's view distance (the silo bore: 112 m wide, 220 m deep): while the player is inside, the
## current camera's far plane is pushed out to `view_far` so the place is never clipped (the forest clips its camera just
## past the fog wall, DeadForestManager.VIEW_PAST_FOG, and a clipped shaft shows the sky through it as a pale hole).
## Leaving puts the old far plane back, unless something else (DevFog) changed it meanwhile. Enter / exit radii differ so
## walking the edge does not flap. Owner calls update(distance) each frame, like MusicZone.

enum State { OUTSIDE, INSIDE }

var state := State.OUTSIDE
var view_far := 0.0
var enter_dist := 0.0
var exit_dist := 0.0
var _cam: Camera3D
var _far_before := 0.0


static func make(far: float, enter: float, exit: float) -> ViewZone:
	var z := ViewZone.new()
	z.name = "ViewZone"
	z.view_far = far
	z.enter_dist = enter
	z.exit_dist = maxf(exit, enter)
	return z


func update(distance: float) -> void:
	if state == State.OUTSIDE and distance < enter_dist:
		_enter()
	elif state == State.INSIDE and distance > exit_dist:
		_exit()


func _enter() -> void:
	_cam = get_viewport().get_camera_3d() if is_inside_tree() else null
	if _cam == null:
		return
	state = State.INSIDE
	_far_before = _cam.far
	_cam.far = maxf(_cam.far, view_far)


func _exit() -> void:
	state = State.OUTSIDE
	if is_instance_valid(_cam) and is_equal_approx(_cam.far, maxf(_far_before, view_far)):
		_cam.far = _far_before
	_cam = null


func _exit_tree() -> void:
	if state == State.INSIDE:
		_exit()
