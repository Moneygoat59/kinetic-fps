extends CanvasLayer
## Autoload `LevelFlow`: moves the walker between the game's levels (the apartment, the dead forest, the silo depths)
## through black.
##   LevelFlow.go(&"forest")        visits(&"apartment") = how many times that level was entered through go()
## Levels read visits() to vary themselves between returns (ApartmentLevel picks its lighting mood by it).
## Add a level = one LEVELS row. Dev jumps (DevWarps) use warp() to arrive as if the walker had lived a given history.
## first_time(key) remembers one-off moments across levels (AptThoughts: a check's first thought); a warp forgets them.

signal level_entered(level: StringName, visit: int)

enum State { IDLE, FADE_OUT, FADE_IN }

const LEVELS := {
	&"apartment": "res://scenes/levels/apartment.tscn",
	&"forest": "res://scenes/levels/dead_forest.tscn",
	&"silo": "res://scenes/levels/silo_depths.tscn",
}
const FADE_OUT := 1.6
const FADE_IN := 0.8
const HOLD := 0.5

var state := State.IDLE
var current: StringName = &""
var _visits := {}
var _pending := {}             # warp(): the visit counts the next swap installs instead of counting one more
var _once := {}                # first_time() keys already seen this run
var _black: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_black)


func visits(level: StringName) -> int:
	return _visits.get(level, 0)


## True the first time it is asked for `key` this run (a warp starts a fresh run), false ever after.
func first_time(key: StringName) -> bool:
	if key == &"" or _once.has(key):
		return false
	_once[key] = true
	return true


## Fades out, swaps to `level`, fades in. Ignored (false) while a transition runs or for an unknown level.
## fade_out 0 = a hard cut to black (waking with a jolt); hold = seconds of black before the swap.
func go(level: StringName, fade_out := FADE_OUT, hold := HOLD) -> bool:
	if state != State.IDLE or not LEVELS.has(level):
		return false
	state = State.FADE_OUT
	var tw := create_tween()
	if fade_out <= 0.0:
		_black.color.a = 1.0
	else:
		tw.tween_property(_black, "color:a", 1.0, fade_out).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_interval(maxf(hold, 0.01))
	tw.tween_callback(_swap.bind(level))
	return true


## Dev jump: like go(), but on arrival the visit counts are exactly `history` (level -> visits, missing = 0), so the
## level builds itself for that point in the story (the forest's night, the apartment's mood and wake).
func warp(level: StringName, history: Dictionary, fade_out := 0.4, hold := 0.1) -> bool:
	if not go(level, fade_out, hold):
		return false
	_pending = history.duplicate()
	_once = {}
	return true


func _swap(level: StringName) -> void:
	if _pending.is_empty():
		_visits[level] = visits(level) + 1
	else:
		_visits = _pending
		_pending = {}
	current = level
	if get_tree().change_scene_to_file(LEVELS[level]) != OK:
		push_error("LevelFlow: cannot open " + LEVELS[level])
	state = State.FADE_IN
	var tw := create_tween()
	tw.tween_interval(0.1)
	tw.tween_property(_black, "color:a", 0.0, FADE_IN)
	tw.tween_callback(_arrived.bind(level))


func _arrived(level: StringName) -> void:
	state = State.IDLE
	level_entered.emit(level, visits(level))
