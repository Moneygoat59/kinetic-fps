class_name RouteTerminal
extends Node
## The route terminal of an outer building (kit terminal_wall, the keypad terminal on the wall): where the player programs
## the field dosimeter onto the relay route home to Relay Hub 00. Outposts 73 / 02 / 03 and the silo's launch control all
## carry one; the hub's own place is its router (HubRouterKeys). The same terminal in every building, so traversal works
## the same everywhere and never depends on progress. FSM: LOCKED (no dosimeter to program yet), READY, WRITING (the
## route types onto the screen while the keypad clicks), SET (the dosimeter is on this route; [E] writes it again).
## Emits programmed(route) when a write finishes. mount() finds the terminal in a building model. Look: RouteTerminalView.

signal programmed(route: int)

enum State { LOCKED, READY, WRITING, SET }

const PROP := "terminal_wall"
const REACH := 1.9                 # m from the terminal (horizontal): prompt shows, [E] works
const FADE := 0.5
const LIVE_DIST := 14.0            # the screen renders inside this range
const FLOOR_SPAN := 3.0            # the player must be on the terminal's floor (height difference, m)
const WRITE_TIME := 1.4
const KEY_GAP := Vector2(0.06, 0.16)
const DONE_SOUND = preload("res://audio/rpg/Audio/metalClick.ogg")
const MAX_DELTA := 0.1

var state := State.LOCKED
var route := HubRoutes.Route.W73
var view := RouteTerminalView.new()
var _anchor: Node3D
var _t := 0.0
var _next_key := 0.0
var _title := ""
var _sub_ready := ""
var _sub_set := ""
var _writing_title := ""
var _sfx: AudioStreamPlayer3D


## Mounts a terminal on the first terminal_wall kit piece of `model` (after BunkerKit.furnish). Null if the model has none.
static func mount(host: Node, model: Node3D, r: int, locked: bool) -> RouteTerminal:
	if model == null:
		return null
	for child in model.get_children():
		if String(child.name).begins_with("marker_kit_%s__" % PROP) and child.get_child_count() > 0:
			var terminal := RouteTerminal.new()
			host.add_child(terminal)
			terminal.setup(child.get_child(0) as Node3D, r, locked)
			return terminal
	push_warning("RouteTerminal: no %s in %s" % [PROP, model.name])
	return null


func setup(prop: Node3D, r: int, locked: bool) -> void:
	_anchor = prop
	route = clampi(r, 0, HubRoutes.KEYS.size() - 1)
	var key := HubRoutes.KEYS[route]
	_title = "PROGRAM ROUTE TO CENTRAL HUB"
	_sub_ready = "R-%s  //  %s" % [key, HubRoutes.NAMES[route]]
	_sub_set = "R-%s  //  ROUTE SET" % key
	_writing_title = "PROGRAMMING ROUTE R-%s" % key
	view.build(prop, self, route)
	_sfx = AudioStreamPlayer3D.new()
	_sfx.position = Vector3(0.0, 1.4, -0.3)
	_sfx.unit_size = 2.5
	prop.add_child(_sfx)
	state = State.LOCKED if locked else State.READY
	view.show_state(state)
	set_process(false)


## The dosimeter is paired (taken from its rack): the terminal can program it.
func unlock() -> void:
	if state == State.LOCKED:
		state = State.READY
		view.show_state(state)


## The dosimeter's route changed somewhere: on_this = it now follows this terminal's route home.
func show_route(on_this: bool) -> void:
	if state == State.LOCKED or state == State.WRITING:
		return
	state = State.SET if on_this else State.READY
	view.show_state(state)


## Called every physics frame by the building. force = program now, without the player (dev tools, test hooks).
func update(p_pos: Vector3, force: bool = false) -> void:
	if _anchor == null:
		return
	var at := _anchor.global_position
	var dist := Vector2(p_pos.x - at.x, p_pos.z - at.z).length()
	if absf(p_pos.y - at.y) > FLOOR_SPAN:
		dist = LIVE_DIST                                   # another floor (the silo's rim above launch control)
	set_process(dist < LIVE_DIST or state == State.WRITING)
	view.set_live(dist < LIVE_DIST)
	if state == State.LOCKED:
		return
	if force and state != State.WRITING:
		_finish()
		return
	if dist > REACH:
		return
	var strength := (REACH - dist) / FADE
	if state == State.WRITING:
		InteractPrompt.offer(self, _writing_title, "HOLD  //  WRITING ROUTE", strength)
		return
	InteractPrompt.offer(self, _title, _sub_set if state == State.SET else _sub_ready, strength)
	if Input.is_action_just_pressed("interact"):
		state = State.WRITING
		_t = 0.0
		view.show_state(state)


func _process(delta: float) -> void:
	view.blink(Time.get_ticks_msec() * 0.001)
	if state != State.WRITING:
		return
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_t += dt
	view.show_progress(_t / WRITE_TIME)
	_next_key -= dt
	if _next_key <= 0.0 and _t < WRITE_TIME * 0.8:
		_next_key = randf_range(KEY_GAP.x, KEY_GAP.y)
		_play(HubConsole.CLICKS[randi() % HubConsole.CLICKS.size()], -8.0, randf_range(0.9, 1.2))
	if _t >= WRITE_TIME:
		_finish()


func _finish() -> void:
	state = State.SET
	view.show_state(state)
	_play(DONE_SOUND, -4.0, 0.8)
	programmed.emit(route)


func _play(stream: AudioStream, volume: float, pitch: float) -> void:
	_sfx.stream = stream
	_sfx.volume_db = volume
	_sfx.pitch_scale = pitch
	_sfx.play()
