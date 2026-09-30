class_name WraithStalk
extends Node
## Night 3 (ForestNights ending CAUGHT): nothing at first; after NOTICE_AT metres the walker thinks "I don't think I am
## alone..." and the drone starts; from FIRST_AT it is glimpsed between the trees, each glimpse nearer than the last (the
## distance shrinks with metres walked, and with time, so standing still does not help). A glimpse ends when it is looked at
## for LOOK_TIME (it dissolves), when the walker goes toward it, or after SHOW_MAX; unwatched it drifts closer. Near the end
## it turns up behind, announced by a whisper at the ear. At MIN_DIST it takes them (WraithGrab: a hand on the shoulder,
## wrenched round into its face, red eyes, the scream). `caught` when that is over.
## ForestNightDirector calls tick(walked, delta) every physics frame.

signal caught

enum State { DORMANT, UNEASE, HIDDEN, SHOWN, FINALE, DONE }

const LINE := "I don't think I am alone..."
const NOTICE_AT := 22.0            # metres walked
const FIRST_AT := 42.0
const START_DIST := 36.0           # first glimpse this far ...
const MIN_DIST := 5.0              # ... closing to this
const CLOSE_PER_M := 0.1           # metres nearer per metre of progress
const TIME_PROGRESS := 0.8         # metres of progress per second regardless of walking
const REST := Vector2(3.0, 6.5)    # seconds hidden between glimpses
const SHOW_MAX := 7.0
const LOOK_TIME := 0.45
const SEEN_DOT := 0.974            # cos(13 deg): looking straight at it
const BEHIND_BELOW := 16.0         # nearer than this, half the glimpses are behind the walker
const CHECK := 0.1                 # seconds between sight checks (one ray)

var state := State.DORMANT
var wraith: Wraith
var player: Player
var dread := 0.0
var _progress := 0.0
var _t := 0.0
var _seen_t := 0.0
var _check_t := 0.0
var _seen := false
var _stung := false
var _whisper_t := 6.0
var _rest := 4.0
var _sight: WraithSight


func setup(p: Player, terrain: Node3D) -> void:
	player = p
	wraith = Wraith.new()
	wraith.name = "Wraith"
	wraith.terrain = terrain
	p.get_parent().add_child(wraith)
	_sight = WraithSight.new(p, SEEN_DOT)


func tick(walked: float, delta: float) -> void:
	if state == State.DONE or state == State.FINALE or player == null:
		return
	var dt := clampf(delta, 0.0, 0.1)
	if state == State.DORMANT:
		if walked >= NOTICE_AT:
			FieldHud.speak(LINE)
			_set_dread(0.06)
			state = State.UNEASE
		return
	if state == State.UNEASE:
		if walked >= FIRST_AT:
			_glimpse(START_DIST, false)
		return
	_progress += dt * TIME_PROGRESS
	_progress = maxf(_progress, walked - FIRST_AT)
	var dist := maxf(MIN_DIST, START_DIST - _progress * CLOSE_PER_M)
	_set_dread(1.0 - (dist - MIN_DIST) / (START_DIST - MIN_DIST))
	_t += dt
	match state:
		State.HIDDEN:
			_whisper_t -= dt
			if _whisper_t <= 0.0 and dread > 0.3:
				_whisper_t = randf_range(4.0, 8.0)
				wraith.audio.whisper(player, -_sight.forward().rotated(Vector3.UP, randf_range(-1.2, 1.2)))
			if _t >= _rest:
				if dist <= MIN_DIST:
					_finale()
				else:
					_glimpse(dist, dist < BEHIND_BELOW and randf() < 0.5)
		State.SHOWN:
			_shown(dist, dt)


func _shown(dist: float, dt: float) -> void:
	_check_t -= dt
	if _check_t <= 0.0:
		_check_t = CHECK
		_seen = _sight.sees(wraith.global_position)
	wraith.face(player.global_position)
	if _seen:
		_seen_t += dt
		if not _stung:
			_stung = true
			wraith.audio.sting(lerpf(-16.0, 0.0, dread))
	else:
		wraith.drift(player.global_position, 0.3 + 1.6 * dread, dist * 0.6, dt)
	var gap := wraith.global_position.distance_to(player.global_position)
	if _seen_t >= LOOK_TIME or gap < dist * 0.45 or _t >= SHOW_MAX:
		wraith.vanish()
		_rest = randf_range(REST.x, REST.y)
		_enter(State.HIDDEN)


func _glimpse(dist: float, behind: bool) -> void:
	var fwd := _sight.forward()
	var pos := Vector3.ZERO
	for i in 6:                                                       # somewhere with a clear line from the walker's eyes
		var ang := (PI + randf_range(-0.8, 0.8)) if behind else randf_range(0.26, 0.7) * (1.0 if randf() < 0.5 else -1.0)
		pos = wraith.ground(player.global_position + fwd.rotated(Vector3.UP, ang) * dist)
		if _sight.clear(pos):
			break
	wraith.appear(pos, player.global_position)
	if behind:
		wraith.audio.whisper(player, pos - player.global_position)
	_stung = false; _seen = false
	_seen_t = 0.0
	_enter(State.SHOWN)


func _finale() -> void:
	_set_dread(1.0)
	_enter(State.FINALE)
	var grab := WraithGrab.new()
	add_child(grab)
	grab.finished.connect(_on_taken)
	grab.start(player, wraith, _sight.forward())


func _on_taken() -> void:
	state = State.DONE
	caught.emit()


func _enter(next: State) -> void:
	state = next
	_t = 0.0


func _set_dread(d: float) -> void:
	dread = clampf(d, 0.0, 1.0)
	wraith.audio.dread = dread
	wraith.audio.breathing = wraith.is_there() and dread > 0.45
	wraith.view.set_flicker(dread * 0.6)
