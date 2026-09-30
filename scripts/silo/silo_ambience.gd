class_name SiloAmbience
extends Node
## Presenter for Missile Silo 00's lights: builds the marker lights (Fx.add_lights with the silo's table) and the work
## floods (a SpotLight3D per marker_spot_<name>, aimed at marker_spot_<name>_target), then per frame
## breathes the petal-tip beacons and rim alarms, flickers the failing stair lamps, scrolls the amber in the mains and
## blinks the launch key. alarm() (override engaged) speeds the beacons up and brings the alarms to full. Runs only while
## the player is near (set_active). No state beyond the resources it animates; MissileSilo owns it.

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitLights = preload("res://scripts/props/kit_lights.gd")
const LAMP := Color(1.0, 0.66, 0.2)
const FLOOD := Color(1.0, 0.8, 0.55)
const FLOOD_ENERGY := 14.0
const FLOOD_ANGLE := 28.0
const SPOT_PREFIX := "marker_spot_"
const BEACON_MAT := "silo_glow_beacon"
const KEY_MAT := "silo_glow_key"
const LIQUID_MAT := "silo_amber_liquid"
enum Mode { IDLE, ALARM }

const FLOW_SPEED := 0.35            # uv / s down the mains
const BEACON_RATE := 0.9
const ALARM_RATE := 4.5
const KEY_RATE := 3.0
## marker name -> [colour, energy, range, casts_shadow]
const LIGHTS := {
	"marker_light_tower_0": [LAMP, 3.4, 12.0, true], "marker_light_tower_1": [LAMP, 3.0, 11.0, false],
	"marker_light_tower_2": [LAMP, 3.0, 11.0, false], "marker_light_tower_3": [LAMP, 2.6, 10.0, false],
	"marker_light_tower_5": [LAMP, 3.0, 11.0, false], "marker_light_tower_6": [LAMP, 2.4, 10.0, false],
	"marker_light_tower_8": [LAMP, 3.0, 11.0, false], "marker_light_tower_9": [LAMP, 3.4, 12.0, false],
	"marker_light_deck": [LAMP, 3.8, 15.0, true],
	"marker_light_room_c": [Color(1.0, 0.68, 0.2), 3.6, 10.0, true], "marker_light_room_desk": [Fx.AMBER, 1.6, 6.0, false],
	"marker_light_srv_0": [Color(1.0, 0.68, 0.2), 2.4, 7.5, true], "marker_light_srv_1": [Color(1.0, 0.68, 0.2), 1.8, 6.5, false],
	"marker_light_fallen": [Fx.WELL_AMBER, 1.2, 14.0, false],
	"marker_light_alarm_300": [Fx.AMBER, 2.0, 20.0, false], "marker_light_alarm_0": [Fx.AMBER, 2.0, 20.0, false],
	"marker_light_alarm_60": [Fx.AMBER, 2.0, 20.0, false], "marker_light_alarm_120": [Fx.AMBER, 2.0, 20.0, false],
	"marker_light_alarm_180": [Fx.AMBER, 2.0, 20.0, false],
	"marker_light_beacon_0": [Fx.AMBER, 2.5, 26.0, false], "marker_light_beacon_1": [Fx.AMBER, 2.5, 26.0, false],
	"marker_light_beacon_2": [Fx.AMBER, 2.5, 26.0, false], "marker_light_beacon_3": [Fx.AMBER, 2.5, 26.0, false],
	"marker_light_beacon_4": [Fx.AMBER, 2.5, 26.0, false],
}
const FLICKER_LIGHTS := ["light_tower_1", "light_tower_3", "light_tower_6", "light_tower_9", "light_deck", "light_room_c",
	"light_srv_1"]
const BEACON_LIGHTS := ["light_beacon_0", "light_beacon_1", "light_beacon_2", "light_beacon_3", "light_beacon_4"]
const ALARM_LIGHTS := ["light_alarm_300", "light_alarm_0", "light_alarm_60", "light_alarm_120", "light_alarm_180"]

var _flick: Array[OmniLight3D] = []
var _flick_base := PackedFloat32Array()
var _beacons: Array[OmniLight3D] = []
var _beacon_base := PackedFloat32Array()
var _alarms: Array[OmniLight3D] = []
var _alarm_base := PackedFloat32Array()
var _floods: Array[SpotLight3D] = []
var _flood_base := PackedFloat32Array()
var _beacon_mat: BaseMaterial3D
var _liquid: ShaderMaterial
var _key: ShaderMaterial
var _mode := Mode.IDLE


func setup(model: Node3D) -> void:
	var made := Fx.add_lights(model, LIGHTS)
	Fx.collect(made, FLICKER_LIGHTS, _flick, _flick_base)
	Fx.collect(made, BEACON_LIGHTS, _beacons, _beacon_base)
	Fx.collect(made, ALARM_LIGHTS, _alarms, _alarm_base)
	_add_floods(model)
	_beacon_mat = O73Kit.own_material(model.get_node_or_null("silo_surface"), BEACON_MAT)
	set_process(false)


func _add_floods(model: Node3D) -> void:
	for spot in add_spots(model, SPOT_PREFIX, FLOOD, FLOOD_ENERGY, FLOOD_ANGLE):
		_floods.append(spot)
		_flood_base.append(FLOOD_ENERGY)


## A SpotLight3D per <prefix><name> marker under model, aimed at its <prefix><name>_target (silo_tower.py flood()).
## Reusable for any aimed lamp in the silo (the generator hall's uplights use their own prefix and colour).
static func add_spots(model: Node3D, prefix: String, color: Color, energy: float, angle: float) -> Array[SpotLight3D]:
	var made: Array[SpotLight3D] = []
	for child in model.get_children():
		var n := String(child.name)
		var target := model.get_node_or_null(n + "_target") as Node3D
		if not n.begins_with(prefix) or target == null:
			continue
		var from := (child as Node3D).position
		var dir := target.position - from
		if dir.length_squared() < 0.01:
			continue
		var spot := SpotLight3D.new()
		spot.name = n.trim_prefix("marker_")
		spot.light_color = color
		spot.light_energy = energy
		spot.spot_range = dir.length() * 1.5
		spot.spot_angle = angle
		spot.spot_attenuation = 0.35
		KitLights.fade(spot)
		var up := Vector3.UP if absf(dir.normalized().y) < 0.95 else Vector3.FORWARD
		spot.transform = Transform3D(Basis.looking_at(dir, up), from)
		model.add_child(spot)
		made.append(spot)
	return made


## After AbyssFog has rebuilt the bore materials: pick up the ones animated here.
func bind_fog(model: Node3D) -> void:
	_liquid = AbyssFog.find(model.get_node_or_null("silo_liquid"), LIQUID_MAT)
	_key = AbyssFog.find(model.get_node_or_null("silo_bore"), KEY_MAT)


func set_active(on: bool) -> void:
	set_process(on)


func alarm() -> void:
	_mode = Mode.ALARM


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var alarm_on := _mode == Mode.ALARM
	var rate := ALARM_RATE if alarm_on else BEACON_RATE
	var pulse := (sin(t * rate) + 1.0) * 0.5
	for i in _beacons.size():
		_beacons[i].light_energy = _beacon_base[i] * lerpf(0.25, 1.0, pulse)
	for i in _alarms.size():
		var a := (sin(t * rate + i * 1.3) + 1.0) * 0.5
		_alarms[i].light_energy = _alarm_base[i] * (lerpf(0.5, 2.2, a) if alarm_on else lerpf(0.05, 0.4, a))
	if _beacon_mat:
		_beacon_mat.emission_energy_multiplier = lerpf(0.3, 3.0 if alarm_on else 2.0, pulse)
	for i in _flick.size():
		_flick[i].light_energy = _flick_base[i] * Fx.flicker(t, i * 1.9)
	for i in _floods.size():                        # the floods fail like the lamps do, on their own phase
		_floods[i].light_energy = _flood_base[i] * Fx.flicker(t * 0.7, 11.0 + i * 2.3)
	if _liquid:
		_liquid.set_shader_parameter("uv_offset", Vector2(0.0, fmod(t * FLOW_SPEED, 1.0)))
	if _key:
		_key.set_shader_parameter("emission_energy", 0.2 if alarm_on else lerpf(0.1, 1.6, float(sin(t * KEY_RATE) > 0.0)))
