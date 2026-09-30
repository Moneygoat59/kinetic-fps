class_name HubAmbience
extends Node
## Presenter for Relay Hub 00's lights and screens: builds the marker lights (Fx.add_lights with the hub's table), then
## per frame pulses the roof beacon, breathes the amber lights, flickers the failing lamps and flips the wall map frames.
## No state beyond the resources it animates; RelayHub owns it.

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const BEACON_RATE := 2.2
const BEACON_MAT := "hub_glow_beacon"
const MAP_MAT := "hub_scr_map"
const MAP_FRAMES := ["res://models/generated/tex/hub_screen_map_a.png", "res://models/generated/tex/hub_screen_map_b.png"]
const MAP_PERIOD := 0.8
## marker name -> [colour, energy, range, casts_shadow]
const LIGHTS := {
	"marker_light_ceiling_c": [Color(1.0, 0.68, 0.2), 5.0, 12.0, true],
	"marker_light_ceiling_l": [Fx.AMBER, 2.8, 8.5, false],
	"marker_light_ceiling_r": [Fx.AMBER, 2.8, 8.5, false],
	"marker_light_wall": [Fx.WELL_AMBER, 2.2, 8.0, false],
	"marker_light_tank": [Fx.WELL_AMBER, 0.9, 3.5, false],
	"marker_light_front": [Fx.AMBER, 2.0, 8.0, true],
	"marker_light_roof": [Fx.AMBER, 4.0, 60.0, false],
}
const PULSE_LIGHTS := ["light_wall", "light_tank"]
const FLICKER_LIGHTS := ["light_ceiling_c", "light_ceiling_l", "light_ceiling_r", "light_front"]

var _roof_light: OmniLight3D
var _beacon: BaseMaterial3D
var _map: BaseMaterial3D
var _map_tex: Array[Texture2D] = []
var _map_frame := 0
var _pulse: Array[OmniLight3D] = []
var _pulse_base := PackedFloat32Array()
var _flick: Array[OmniLight3D] = []
var _flick_base := PackedFloat32Array()


func setup(model: Node3D) -> void:
	var made := Fx.add_lights(model, LIGHTS)
	_roof_light = made.get("light_roof") as OmniLight3D
	Fx.collect(made, PULSE_LIGHTS, _pulse, _pulse_base)
	Fx.collect(made, FLICKER_LIGHTS, _flick, _flick_base)
	_beacon = Fx.find_material(model, BEACON_MAT)
	_map = O73Kit.own_material(model.get_node_or_null("hub_screens"), MAP_MAT)
	for path in MAP_FRAMES:
		_map_tex.append(load(path) as Texture2D)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var blink := (sin(t * BEACON_RATE) + 1.0) * 0.5
	if _roof_light:
		_roof_light.light_energy = lerpf(1.2, 5.0, blink)
	if _beacon:
		_beacon.emission_energy_multiplier = lerpf(0.3, 2.8, blink)
	for i in _pulse.size():
		_pulse[i].light_energy = _pulse_base[i] * (0.75 + 0.25 * sin(t * 2.1 + i * 1.3))
	for i in _flick.size():
		_flick[i].light_energy = _flick_base[i] * Fx.flicker(t, i * 1.7)
	var frame := int(t / MAP_PERIOD) % 2
	if _map and frame != _map_frame and _map_tex.size() == 2:
		_map_frame = frame
		_map.emission_texture = _map_tex[frame]
