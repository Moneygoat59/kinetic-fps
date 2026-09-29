class_name TunnelAir
extends Node
## The air of the underground line: while the player is in the tunnels the level's Environment turns to theirs (black depth
## fog that swallows everything past ~40 m, a faint cold ambient, black behind), and leaving puts the level's own values
## back. The silo depths share the forest's pale fog, which would fill a tunnel like milk. Eased over FADE seconds.
## Owner calls update(inside) each frame with its own test (like SkyZone); the environment is read once per change.

enum State { OUTSIDE, INSIDE }

const FADE := 1.2
## Environment property -> the tunnels' value
const LOOK := {
	"background_color": Color.BLACK,
	"fog_light_color": Color.BLACK,
	"fog_depth_begin": 3.0,
	"fog_depth_end": 42.0,
	"ambient_light_color": Color(0.22, 0.2, 0.3),
	"ambient_light_energy": 0.55,
}

var state := State.OUTSIDE
var _saved := {}
var _env: Environment
var _tween: Tween


func update(inside: bool) -> void:
	if state == State.OUTSIDE and inside:
		_enter()
	elif state == State.INSIDE and not inside:
		_exit()


func _enter() -> void:
	var viewport := get_viewport() if is_inside_tree() else null
	_env = viewport.world_3d.environment if viewport and viewport.world_3d else null
	if _env == null:
		return
	state = State.INSIDE
	_saved.clear()
	for key in LOOK:
		_saved[key] = _env.get(key)
	_ease(LOOK)


func _exit() -> void:
	state = State.OUTSIDE
	if _env != null and not _saved.is_empty():
		_ease(_saved)


func _ease(values: Dictionary) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	for key in values:
		_tween.tween_property(_env, key, values[key], FADE)


func _exit_tree() -> void:
	if state == State.INSIDE and _env != null:
		for key in _saved:
			_env.set(key, _saved[key])
		state = State.OUTSIDE
