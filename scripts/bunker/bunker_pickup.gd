extends Node3D
## Item station: the field dosimeter hanging on slot 03 of the field-kit rack (kit piece `dosimeter`) and its [E] prompt.
## Left on charge beside the amber well, it ticks like any Geiger counter: quiet random clicks heard only inside the room,
## each flicking the needle and the click LED. Taken only with the interact key. Emits `claimed` once; then goes inert.
## Sits under the bunker's marker_pickup (the device base; the node's +Z is the device front). The long-range lure to the
## bunker is the pump jack (bunker_pump.gd), not this.

signal claimed

enum State { AVAILABLE, CLAIMED }

const DEVICE := &"dosimeter"
const DEVICE_PATH := "res://models/generated/o73_kit/dosimeter.glb"
const LED_MAT := "kit_glow_dosi_led"
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")
const PROMPT_TITLE := "TAKE FIELD DOSIMETER"
const PROMPT_SUB := "FIELD KIT 03  //  CHARGE 100%"
const TAKEN_THOUGHT := "Field kit 03. Nobody signed this one out."
const REACH := 2.6             # prompt shows and [E] works inside this distance
const FADE_DIST := 0.6
const TICK_MEAN := 0.55        # s between Geiger ticks on average (random, like real background counts)
const TICK_MIN := 0.04
const TICK_RANGE := 8.0        # m: only audible in the room
const TICK_DECAY := 9.0        # 1/s: needle / LED fall back after a tick
const NEEDLE_REST_DEG := 50.0  # needle parked at 0 (left end of the scale)
const NEEDLE_KICK_DEG := 14.0
const LED_ON := 5.0
const LED_OFF := 0.15
const MAX_DELTA := 0.1

var state: State = State.AVAILABLE
var _item: Node3D              # pivot on the hook; the device hangs below it
var _needle: Node3D
var _led: BaseMaterial3D
var _ticker: AudioStreamPlayer3D
var _next_tick: float = 0.5
var _kick: float = 0.0         # 1 on a tick, decays


func setup() -> void:
	_item = Node3D.new()
	_item.position = Vector3(0.0, O73Kit.DOSIMETER_HANG, 0.0)
	add_child(_item)
	var device := O73Kit.spawn(DEVICE, _item, Transform3D(Basis(), Vector3(0.0, -O73Kit.DOSIMETER_HANG, 0.0)))
	if device:
		_needle = device.get_node_or_null("needle") as Node3D
		_led = O73Kit.own_material(device, LED_MAT)
	var glow := OmniLight3D.new()                              # the display's own spill on the rack
	glow.position = Vector3(0.05, 0.1 - O73Kit.DOSIMETER_HANG, 0.12)
	glow.light_color = Color(1.0, 0.62, 0.2)
	glow.light_energy = 0.35
	glow.omni_range = 1.2
	_item.add_child(glow)
	_ticker = AudioStreamPlayer3D.new()
	_ticker.stream = ProceduralSfx.geiger_tick()
	_ticker.unit_size = 1.5
	_ticker.max_distance = TICK_RANGE
	_ticker.volume_db = -4.0
	_ticker.max_polyphony = 3
	_item.add_child(_ticker)
	_show_kick()


func _process(delta: float) -> void:
	if state == State.CLAIMED:
		return
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_next_tick -= dt
	if _next_tick <= 0.0:
		_next_tick = maxf(-log(maxf(randf(), 0.001)) * TICK_MEAN, TICK_MIN)   # exponential gaps: random like decay
		_kick = randf_range(0.5, 1.0)
		_ticker.pitch_scale = randf_range(0.9, 1.15)
		_ticker.play()
	_kick = maxf(_kick - dt * TICK_DECAY, 0.0)
	_show_kick()


func _show_kick() -> void:
	if _needle:
		_needle.rotation.z = deg_to_rad(NEEDLE_REST_DEG - NEEDLE_KICK_DEG * _kick)
	if _led:
		_led.emission_energy_multiplier = lerpf(LED_OFF, LED_ON, _kick)


## Called every physics frame by the level. Returns true on the frame the item is taken.
func update_proximity(player_pos: Vector3, force: bool = false) -> bool:
	if state == State.CLAIMED or _item == null:
		return false
	var dist := _item.global_position.distance_to(player_pos)
	if dist >= REACH and not force:
		return false
	InteractPrompt.offer(self, PROMPT_TITLE, PROMPT_SUB, (REACH - dist) / FADE_DIST)
	if force or Input.is_action_just_pressed("interact"):
		_claim()
		return true
	return false


func _claim() -> void:
	state = State.CLAIMED
	_item.queue_free()
	for snd in [[PICKUP_SOUND, 0.0], [SWITCH_SOUND, -3.0]]:
		var p := AudioStreamPlayer.new()
		p.stream = snd[0]
		p.volume_db = snd[1]
		add_child(p)
		p.play()
	FieldHud.speak(TAKEN_THOUGHT)
	claimed.emit()
