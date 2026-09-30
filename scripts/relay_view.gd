class_name RelayView
extends RefCounted
## Presentation of a relay mast (kit piece `relay_pylon`) for NuclearPylon: builds the model, the beacon light at
## marker_beacon, and shows each relay state through the light and the channel-tinted glow (kit_glow_pylon: band, lamp,
## cabinet status LED). No state of its own; NuclearPylon calls one show_* per frame or per change.

const MODEL := &"relay_pylon"
const GLOW_MAT := "kit_glow_pylon"
const PULSE_RATE := 7.0                      # rad/s while waiting to be aligned
const PULSE_LIGHT := Vector2(1.5, 6.0)
const PULSE_RANGE := Vector2(24.0, 46.0)
const PULSE_GLOW := Vector2(2.0, 7.0)
const ONLINE_LIGHT := 1.4
const ONLINE_RANGE := 30.0
const ONLINE_GLOW := 1.5
const DARK_GLOW := 0.05
const SYNC_HZ := 11.0                        # lamp stutter while aligning

var light: OmniLight3D
var glow: BaseMaterial3D
var color := Color(1.0, 0.65, 0.12)


func build(pylon: Node3D) -> void:
	var mast := O73Kit.spawn(MODEL, pylon)
	glow = O73Kit.own_material(mast, GLOW_MAT)
	light = OmniLight3D.new()
	var anchor: Node3D = mast.get_node_or_null("marker_beacon") as Node3D if mast else null
	light.position = anchor.position if anchor else Vector3(0.0, 6.0, 0.0)
	light.distance_fade_enabled = true
	light.distance_fade_begin = 90.0
	light.distance_fade_length = 20.0
	pylon.add_child(light)


func show_dark() -> void:
	_look(0.0, PULSE_RANGE.y, DARK_GLOW)


func show_online() -> void:
	_look(ONLINE_LIGHT, ONLINE_RANGE, ONLINE_GLOW)


## Waiting for the player: slow breathing pulse that lights the fog around the mast.
func show_waiting(t: float) -> void:
	var pulse := (sin(t * PULSE_RATE) + 1.0) * 0.5
	_look(lerpf(PULSE_LIGHT.x, PULSE_LIGHT.y, pulse), lerpf(PULSE_RANGE.x, PULSE_RANGE.y, pulse),
		lerpf(PULSE_GLOW.x, PULSE_GLOW.y, pulse))


## Aligning: the lamp stutters as the relay syncs, settling toward the steady online level as progress reaches 1.
func show_syncing(t: float, progress: float) -> void:
	var on := fmod(t * SYNC_HZ * (1.0 + progress), 1.0) < lerpf(0.35, 0.9, progress)
	var k := lerpf(0.3, 1.0, progress) if on else 0.08
	_look(ONLINE_LIGHT * 2.0 * k, ONLINE_RANGE, PULSE_GLOW.y * k)


func _look(energy: float, reach: float, glow_level: float) -> void:
	if light:
		light.light_color = color
		light.light_energy = energy
		light.omni_range = reach
	if glow:
		glow.emission = color
		glow.emission_energy_multiplier = glow_level
