extends Node3D
## Item station of Outposts 02 / 03: the well's route key in its open case on the desk beside the relay CRT (kit piece
## `route_key`) and its [E] prompt. The case lamp blinks in the route's channel colour while the key is in the foam; taking
## it frees the `key` node, the lamp drops to a dim steady glow. Emits `claimed` once, then goes inert.
## Sits under the bunker's marker_pickup (the case base on the tabletop; the node's +Z is the case front).

signal claimed

enum State { AVAILABLE, CLAIMED }

const DEVICE := &"route_key"
const LAMP_MAT := "kit_glow_key"
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")
const REACH := 2.4             # prompt shows and [E] works inside this distance
const FADE_DIST := 0.6
const BLINK_RATE := 2.2        # rad/s
const LAMP_LO := 0.25
const LAMP_HI := 2.4
const LAMP_TAKEN := 0.15
const GLOW_HI := 0.45
const KEY_OFFSET := Vector3(0.0, 0.06, 0.0)   # the key's height above the case base (the prompt distance is measured to it)

var state: State = State.AVAILABLE
var _key: Node3D
var _lamp: BaseMaterial3D
var _glow: OmniLight3D
var _title := ""
var _sub := ""
var _thought := ""


## route: the well's number as shown ("02"); color: the route's channel colour (HubRoutes.COLORS).
func setup(route: String, color: Color) -> void:
	var case := O73Kit.spawn(DEVICE, self)
	if case:
		_key = case.get_node_or_null("key") as Node3D
		_lamp = O73Kit.own_material(case, LAMP_MAT)
	if _lamp:
		_lamp.emission = color
	_glow = OmniLight3D.new()
	_glow.light_color = color
	_glow.omni_range = 1.3
	_glow.position = Vector3(0.0, 0.18, 0.0)
	add_child(_glow)
	_title = "TAKE ROUTE KEY " + route
	_sub = "RELAY HANDSHAKE  //  WELL " + route
	_thought = "Route key %s. The hub won't carry this well without it." % route


func _process(_delta: float) -> void:
	var blink := (sin(Time.get_ticks_msec() * 0.001 * BLINK_RATE) + 1.0) * 0.5
	if _lamp:
		_lamp.emission_energy_multiplier = lerpf(LAMP_LO, LAMP_HI, blink)
	if _glow:
		_glow.light_energy = GLOW_HI * blink


## Called every physics frame by the bunker. Returns true on the frame the key is taken.
func update_proximity(player_pos: Vector3, force: bool = false) -> bool:
	if state == State.CLAIMED:
		return false
	var dist := to_global(KEY_OFFSET).distance_to(player_pos)
	if dist >= REACH and not force:
		return false
	InteractPrompt.offer(self, _title, _sub, (REACH - dist) / FADE_DIST)
	if force or Input.is_action_just_pressed("interact"):
		_claim()
		return true
	return false


func _claim() -> void:
	state = State.CLAIMED
	set_process(false)
	if is_instance_valid(_key):
		_key.queue_free()
	if _lamp:
		_lamp.emission_energy_multiplier = LAMP_TAKEN
	_glow.visible = false
	for snd in [[PICKUP_SOUND, 0.0], [SWITCH_SOUND, -3.0]]:
		var p := AudioStreamPlayer.new()
		p.stream = snd[0]
		p.volume_db = snd[1]
		add_child(p)
		p.play()
	FieldHud.speak(_thought)
	claimed.emit()
