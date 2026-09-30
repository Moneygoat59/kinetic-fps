class_name HubConsole
extends Node
## The router console of Relay Hub 00 (kit terminal_router, facing the door in front of the routing wall): the hub's route
## terminal. Its four route keys (HubRouterKeys) either write a new relay route into the network (progress: the table types
## itself out, the relay chain is laid) or program the dosimeter onto a route that already exists (a quick write). One FSM:
## IDLE (the log shows where the network stands), WRITING (a new route, ~3.6 s), ROUTING (an existing route, ~1.2 s).
## Emits programmed(route) when a new route is written, routed(route) when an existing one is set. Look: HubConsoleView.

signal programmed(route: int)
signal routed(route: int)

enum State { IDLE, WRITING, ROUTING }

const WRITE_TIME := 3.6
const ROUTE_TIME := 1.2
const KEY_GAP := Vector2(0.05, 0.17)
const CLICKS: Array[AudioStream] = [preload("res://audio/ui/Audio/click_001.ogg"), preload("res://audio/ui/Audio/click_002.ogg"),
	preload("res://audio/ui/Audio/click_003.ogg"), preload("res://audio/ui/Audio/click_004.ogg")]
const WRITE_SOUND = preload("res://audio/sci-fi/Audio/computerNoise_001.ogg")
const DONE_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")
const SET_SOUND = preload("res://audio/rpg/Audio/metalClick.ogg")
const DENY_SOUND = preload("res://audio/rpg/Audio/metalLatch.ogg")
const MAX_DELTA := 0.1

var state := State.IDLE
var route := -1
var view := HubConsoleView.new()
var _t := 0.0
var _next_key := 0.0
var _sfx: AudioStreamPlayer3D
var _keys: AudioStreamPlayer3D


func setup(prop: Node3D) -> void:
	view.build(prop, self)
	_sfx = _player(prop, 0.0)
	_keys = _player(prop, -6.0)
	set_process(false)
	view.set_live(false)


func _player(prop: Node3D, volume: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.position = Vector3(0.0, 1.1, 0.4)
	p.unit_size = 3.0
	p.volume_db = volume
	prop.add_child(p)
	return p


func is_busy() -> bool:
	return state != State.IDLE


## Called every physics frame by RelayHub with "is the player near": screen and cursor only run then.
func set_active(near: bool) -> void:
	var on := near or state != State.IDLE
	set_process(on)
	view.set_live(on)


## Idle log for the current stage's route: waiting = it is out and the network waits for its outpost's key; otherwise
## it can be written now (its key pulses).
func show_stage(r: int, waiting: bool) -> void:
	if r < 0 or r >= HubRoutes.KEYS.size() or is_busy():
		return
	var key := HubRoutes.KEYS[r]
	view.set_log(("> R-%s ONLINE // FOLLOW RELAYS\n> HANDSHAKE PENDING: %s\n> " % [key, HubRoutes.NAMES[r]]) if waiting
		else ("> R-%s CARRIER LOST\n> REWRITE RELAY TABLE ?\n> " % key), false)
	view.set_blink(-1 if waiting else r)


func finish_all() -> void:
	if is_busy():
		return
	view.set_log("> ALL ROUTES ONLINE\n> SILO MAIN OPEN // KEEP PUMPING\n> ", false)
	view.set_blink(-1)


## Write new route r into the network (the router key of a route with no carrier yet).
func write(r: int) -> void:
	if r < 0 or r >= HubRoutes.KEYS.size() or is_busy():
		return
	_begin(State.WRITING, r)
	var key := HubRoutes.KEYS[r]
	view.set_log("> SELECT R-%s  %s\n> CARRIER %s ...... 7.3%s MHZ\n> WRITE RELAY TABLE ...... OK\n> OPEN VALVE V-%s ........ OK"
		% [key, HubRoutes.NAMES[r], key, key, key], true)
	view.set_row(r, "WRITING", true)
	view.set_blink(-1)
	view.set_key(r, true)
	_sfx.stream = WRITE_SOUND
	_sfx.play()


## Program the dosimeter onto existing route r.
func program(r: int) -> void:
	if r < 0 or r >= HubRoutes.KEYS.size() or is_busy():
		return
	_begin(State.ROUTING, r)
	view.set_log("> SELECT R-%s  %s\n> DOSIMETER CHANNEL R-%s .. OK\n> FOLLOW RELAYS\n> "
		% [HubRoutes.KEYS[r], HubRoutes.NAMES[r], HubRoutes.KEYS[r]], true)


## A key that cannot do anything yet: a dull clunk and the reason on the log.
func deny(r: int, reason: String) -> void:
	if r < 0 or r >= HubRoutes.KEYS.size() or is_busy():
		return
	view.set_log("> SELECT R-%s  %s\n> %s\n> " % [HubRoutes.KEYS[r], HubRoutes.NAMES[r], reason], false)
	_sfx.stream = DENY_SOUND
	_sfx.play()


## Finish the running write now (dev tools).
func force_finish() -> void:
	if is_busy():
		_finish()


func _begin(next: State, r: int) -> void:
	state = next
	route = r
	_t = 0.0
	_next_key = 0.0
	set_process(true)


func _process(delta: float) -> void:
	view.blink(Time.get_ticks_msec() * 0.001)
	if state == State.IDLE:
		return
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var total := WRITE_TIME if state == State.WRITING else ROUTE_TIME
	_t += dt
	view.type_to(_t / (total * 0.85))
	_next_key -= dt
	if _next_key <= 0.0 and _t < total * 0.85:
		_next_key = randf_range(KEY_GAP.x, KEY_GAP.y)
		_keys.stream = CLICKS[randi() % CLICKS.size()]
		_keys.pitch_scale = randf_range(0.85, 1.15)
		_keys.play()
	if _t >= total:
		_finish()


func _finish() -> void:
	var was := state
	state = State.IDLE
	_sfx.stream = DONE_SOUND if was == State.WRITING else SET_SOUND
	_sfx.play()
	(programmed if was == State.WRITING else routed).emit(route)
