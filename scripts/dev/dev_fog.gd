class_name DevFog
extends RefCounted
## Dev fog override (DevManager, F2): fog off, sun shadows out to 200 m and the camera's far plane out to 4 km (the forest
## clips its camera at the fog wall, DeadForestManager.VIEW_PAST_FOG); on puts back what was there. Belongs to one level:
## DevManager makes a fresh one when the level changes.

enum State { ON, OFF }

const CLEAR_FAR := 4000.0
const CLEAR_SHADOWS := 200.0

var state := State.ON
var _env: Environment
var _sun: DirectionalLight3D
var _shadow_before := 0.0
var _far_before := 0.0


## Flips the fog; false if this level has no WorldEnvironment.
func toggle(scene: Node, cam: Camera3D) -> bool:
	if _env == null and scene:
		var we := scene.find_children("*", "WorldEnvironment", true, false)
		_env = (we[0] as WorldEnvironment).environment if not we.is_empty() else null
		var suns := scene.find_children("*", "DirectionalLight3D", true, false)
		_sun = suns[0] as DirectionalLight3D if not suns.is_empty() else null
	if _env == null:
		return false
	state = State.OFF if state == State.ON else State.ON
	var off := state == State.OFF
	_env.fog_enabled = not off
	if off:
		_shadow_before = _sun.directional_shadow_max_distance if _sun else 0.0
		_far_before = cam.far if cam else 0.0
	if _sun: _sun.directional_shadow_max_distance = CLEAR_SHADOWS if off else _shadow_before
	if cam and _far_before > 0.0: cam.far = CLEAR_FAR if off else _far_before
	return true


## A camera that became current while the fog is off (landing from a flight) gets the clear view too.
func fit(cam: Camera3D) -> void:
	if state != State.OFF or cam == null or cam.far >= CLEAR_FAR:
		return
	_far_before = cam.far
	cam.far = CLEAR_FAR


func is_off() -> bool:
	return state == State.OFF
