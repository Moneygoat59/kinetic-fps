class_name EmergencyPylon
extends Node3D
## The underground line's emergency post (kit piece emergency_pylon, tools/blender/kit/rail_props.py): the tunnels' own
## cousin of the surface relay mast, in the one colour nothing else in the world uses (COLOR, violet). Its band, beacon and
## status lamp (material kit_glow_emergency) and a violet omni light at marker_beacon show one State:
##   DARK     dead: no light, the glass barely there.
##   STANDBY  the emergency circuit holding: a low glow that breathes slowly (each post out of step with the next).
##   ALERT    the beacon strobing, the light throwing the post's shadow round the refuge.
## TunnelLine.pylons(pieces) stands one in every tunnel_refuge niche; or add one anywhere (origin = base centre, front +Z).
## set_state() from gameplay; the post owns no rules of its own yet.

enum State { DARK, STANDBY, ALERT }

const KitLights = preload("res://scripts/props/kit_lights.gd")
const MODEL := &"emergency_pylon"
const GLOW_MAT := "kit_glow_emergency"
const COLOR := Color(0.62, 0.3, 1.0)
const LIGHT_OUT := Vector3(0.0, 0.0, 0.85)    # the light hangs this far in front of the lens: out at a refuge niche's
                                              # mouth, so it floods the tunnel (inside the glass it was shut in)
const STANDBY_LIGHT := Vector2(4.5, 6.0)      # energy at the bottom / top of a breath
const STANDBY_GLOW := Vector2(1.2, 2.4)
const STANDBY_RATE := 0.9                     # rad/s
const STANDBY_RANGE := 16.0
const ALERT_HZ := 1.6                         # strobes a second
const ALERT_LIGHT := 9.0
const ALERT_GLOW := 7.0
const ALERT_RANGE := 22.0
const DARK_GLOW := 0.03
const MAX_DELTA := 0.1

@export var state := State.STANDBY
@export var cast_shadows := true

var light: OmniLight3D
var glow: BaseMaterial3D
var _t := 0.0


func _ready() -> void:
	_t = randf() * TAU
	var post := O73Kit.spawn(MODEL, self)
	glow = O73Kit.own_material(post, GLOW_MAT)
	light = OmniLight3D.new()
	light.name = "Beacon"
	var anchor := post.get_node_or_null("marker_beacon") as Node3D if post else null
	light.position = (anchor.position if anchor else Vector3(0.0, 2.1, 0.0)) + LIGHT_OUT
	light.light_color = COLOR
	light.shadow_enabled = cast_shadows
	light.shadow_bias = 0.04
	KitLights.fade(light)
	add_child(light)
	_apply(0.0)


func set_state(next: State) -> void:
	if next == state or not is_inside_tree():
		state = next
		return
	state = next
	_apply(0.0)


func _process(delta: float) -> void:
	_t += clampf(delta, 0.0, MAX_DELTA)
	_apply(_t)


func _apply(t: float) -> void:
	set_process(state != State.DARK)
	match state:
		State.DARK:
			_look(0.0, STANDBY_RANGE, DARK_GLOW)
		State.STANDBY:
			var breath := (sin(t * STANDBY_RATE) + 1.0) * 0.5
			_look(lerpf(STANDBY_LIGHT.x, STANDBY_LIGHT.y, breath), STANDBY_RANGE, lerpf(STANDBY_GLOW.x, STANDBY_GLOW.y, breath))
		State.ALERT:
			var on := fposmod(t * ALERT_HZ, 1.0) < 0.35
			_look(ALERT_LIGHT if on else 0.15, ALERT_RANGE, ALERT_GLOW if on else 0.4)


func _look(energy: float, reach: float, glow_level: float) -> void:
	if light:
		light.light_energy = energy
		light.omni_range = reach
		light.visible = energy > 0.0
	if glow:
		glow.emission = COLOR
		glow.emission_energy_multiplier = glow_level
