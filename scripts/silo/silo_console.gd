class_name SiloConsole
extends Node
## The launch desk in Missile Silo 00's level 09 control room, where the relay network ends. One FSM: READY (prompt + [E]
## at the desk), ENGAGING (the override types itself out while the keys chatter and the siren winds up), DONE. Emits
## engaged once when the override completes; MissileSilo raises the alarm and reports it. Look: SiloConsoleView.

signal engaged()

enum State { READY, ENGAGING, DONE }

const ANCHOR := "marker_launch"
const REACH := 2.2                  # m (horizontal) from the operator spot: prompt shows, [E] works
const HEIGHT := 2.0                 # m: same level only (the rim is 36 m straight above)
const FADE := 0.6
const ENGAGE_TIME := 4.2
const MAX_DELTA := 0.1
const KEY_GAP := Vector2(0.05, 0.17)
const TITLE := "ENGAGE LAUNCH OVERRIDE"
const SUB := "LAUNCH CONTROL  //  VEHICLE AWAY"
const ENGAGING_TITLE := "OVERRIDE ENGAGING"
const ENGAGING_SUB := "LAUNCH CONTROL  //  HAILING VEHICLE"
const READY_LOG := "> ROUTE 00 CARRIER .... OK\n> VEHICLE TELEMETRY ... LOST\n> ENGAGE OVERRIDE ?\n> "
const ENGAGE_LOG := "> OVERRIDE ............ OK\n> HAIL VEHICLE ........ SENT\n> CARRIER ............ FOUND\n> VEHICLE RESPONDING"
const CLICKS: Array[AudioStream] = [preload("res://audio/ui/Audio/click_001.ogg"), preload("res://audio/ui/Audio/click_002.ogg"),
	preload("res://audio/ui/Audio/click_003.ogg"), preload("res://audio/ui/Audio/click_004.ogg")]
const WRITE_SOUND = preload("res://audio/sci-fi/Audio/computerNoise_001.ogg")
const SIREN_SOUND = preload("res://audio/digital/Audio/zapThreeToneUp.ogg")
const DONE_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")

var state := State.READY
var view := SiloConsoleView.new()
var _anchor: Node3D
var _t := 0.0
var _next_key := 0.0
var _sfx: AudioStreamPlayer3D
var _keys: AudioStreamPlayer3D


func setup(model: Node3D) -> void:
	_anchor = model.get_node_or_null(ANCHOR) as Node3D
	if _anchor == null:
		push_error("SiloConsole: model has no " + ANCHOR)
		return
	view.build(model.get_node_or_null("silo_screens") as MeshInstance3D, self)
	view.set_log(READY_LOG, false)
	_sfx = _player(0.0, 6.0)
	_keys = _player(-6.0, 3.0)
	set_process(false)


func _player(volume: float, unit: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.position = Vector3(0.0, 1.2, 0.0)
	p.unit_size = unit
	p.volume_db = volume
	_anchor.add_child(p)
	return p


## Called every physics frame by MissileSilo with "is the player near": screen and cursor only run then.
func set_active(near: bool) -> void:
	var on := near or state == State.ENGAGING
	set_process(on)
	view.set_live(on)


## Called every physics frame by MissileSilo. force = complete the override now, without the player (dev tools).
func update(p_pos: Vector3, force: bool) -> void:
	if _anchor == null or state == State.DONE:
		return
	if force:
		_finish()
		return
	var at := _anchor.global_position
	var dist := Vector2(p_pos.x - at.x, p_pos.z - at.z).length()
	if dist > REACH or absf(p_pos.y - at.y) > HEIGHT:
		return
	if state == State.ENGAGING:
		InteractPrompt.offer(self, ENGAGING_TITLE, ENGAGING_SUB, (REACH - dist) / FADE)
		return
	InteractPrompt.offer(self, TITLE, SUB, (REACH - dist) / FADE)
	if Input.is_action_just_pressed("interact"):
		_begin()


func _begin() -> void:
	state = State.ENGAGING
	_t = 0.0
	_next_key = 0.0
	view.set_log(ENGAGE_LOG, true)
	_sfx.stream = WRITE_SOUND
	_sfx.play()


func _process(delta: float) -> void:
	view.blink(Time.get_ticks_msec() * 0.001)
	if state != State.ENGAGING:
		return
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_t += dt
	view.type_to(_t / (ENGAGE_TIME * 0.85))
	_next_key -= dt
	if _next_key <= 0.0 and _t < ENGAGE_TIME * 0.85:
		_next_key = randf_range(KEY_GAP.x, KEY_GAP.y)
		_keys.stream = CLICKS[randi() % CLICKS.size()]
		_keys.pitch_scale = randf_range(0.85, 1.15)
		_keys.play()
	if _t >= ENGAGE_TIME:
		_finish()


func _finish() -> void:
	state = State.DONE
	view.set_log(ENGAGE_LOG, false)
	_sfx.stream = SIREN_SOUND
	_sfx.play()
	_keys.stream = DONE_SOUND
	_keys.pitch_scale = 1.0
	_keys.play()
	engaged.emit()
