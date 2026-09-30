class_name KitProp
extends Node3D
## Runtime for Outpost 73 kit props (models/generated/o73_kit/*.glb). tools/o73_kit_import.gd attaches it to every imported
## root, so a kit prop dropped into any scene is live. Node contract: tools/blender/kit/kit_lib.py.
##   kit_scr_* surfaces cycle frame textures (SCREENS); kit_glow_blink surfaces blink; kit_glow_liquid surfaces flow and pulse;
##   spin_* nodes turn about their local Z (tape reels); marker_light_<kind>* get an OmniLight3D, marker_spot* a SpotLight3D.
## Animated materials are copied per instance so props of one type are out of step. Animation runs only while on screen;
## props with nothing to animate (tables, crates, barriers) never process.

enum State { DORMANT, ACTIVE }

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitLights = preload("res://scripts/props/kit_lights.gd")
const TEX_DIR := "res://models/generated/tex/"
## screen material -> [frame texture names, seconds per frame]
const SCREENS := {
	"kit_scr_log": [["kit_screen_log_a", "kit_screen_log_b"], 0.55],
	"kit_scr_radar": [["kit_screen_radar_0", "kit_screen_radar_1", "kit_screen_radar_2", "kit_screen_radar_3",
		"kit_screen_radar_4", "kit_screen_radar_5", "kit_screen_radar_6", "kit_screen_radar_7", "kit_screen_radar_8",
		"kit_screen_radar_9", "kit_screen_radar_10", "kit_screen_radar_11"], 0.2],
	"kit_scr_seal": [["kit_screen_seal_a", "kit_screen_seal_b", "kit_screen_seal_a", "kit_screen_seal_b",
		"kit_screen_seal_a", "kit_screen_seal_c"], 0.6],
	"kit_scr_tape": [["kit_screen_tape_a", "kit_screen_tape_b"], 1.1],
	"kit_scr_alarm": [["apt_alarm_a", "apt_alarm_b"], 1.0],
	"kit_scr_rack": [["kit_screen_rack_a", "kit_screen_rack_b", "kit_screen_rack_c"], 0.17],
	"kit_scr_rack_dead": [["kit_screen_rack_dead_a", "kit_screen_rack_dead_b"], 0.8],
	"kit_scr_nodes": [["kit_screen_nodes_a", "kit_screen_nodes_b", "kit_screen_nodes_a", "kit_screen_nodes_c"], 0.7],
	"kit_scr_crac": [["kit_screen_crac_a", "kit_screen_crac_a", "kit_screen_crac_b"], 0.9],
	"kit_scr_indicator": [["tun_indicator_a", "tun_indicator_a", "tun_indicator_a", "tun_indicator_b"], 1.2],
}
const BLINK_MAT := "kit_glow_blink"
const FLOW_MAT := "kit_glow_liquid"
const SPIN_RATE := 1.8                         # rad/s
const BLINK_RATE := 2.4                        # rad/s
const FLOW_SPEED := 0.35
const MAX_DELTA := 0.1

var state := State.DORMANT
var _screen_mats: Array[BaseMaterial3D] = []
var _screen_frames: Array[Array] = []
var _screen_period := PackedFloat32Array()
var _screen_shown := PackedInt32Array()
var _blink: Array[BaseMaterial3D] = []
var _flow: Array[BaseMaterial3D] = []
var _spin: Array[Node3D] = []
var _lights: Array[Light3D] = []
var _light_base := PackedFloat32Array()
var _light_anim := PackedInt32Array()
var _phase := 0.0


func _ready() -> void:
	set_process(false)
	_phase = randf() * 100.0
	var bounds := AABB()
	for child in get_children():
		var n := String(child.name)
		if KitLights.is_marker(n):
			_add_light(child as Node3D)
		elif child is MeshInstance3D:
			var mi := child as MeshInstance3D
			bounds = bounds.merge(mi.transform * mi.mesh.get_aabb()) if mi.mesh else bounds
			if n.begins_with("spin_"):
				_spin.append(mi)
			_claim_materials(mi)
	if _screen_mats.is_empty() and _blink.is_empty() and _flow.is_empty() and _spin.is_empty() and _lights.is_empty():
		return
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.aabb = bounds.grow(0.5)
	notifier.screen_entered.connect(_set_state.bind(State.ACTIVE))
	notifier.screen_exited.connect(_set_state.bind(State.DORMANT))
	add_child(notifier)


func _set_state(next: State) -> void:
	if next == state:
		return
	state = next
	set_process(state == State.ACTIVE)


## Per-instance copies of every animated surface material, sorted into the screen / blink / flow lists.
func _claim_materials(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
		if mat == null:
			continue
		var key := mat.resource_name
		if not (SCREENS.has(key) or key == BLINK_MAT or key == FLOW_MAT):
			continue
		var own := mat.duplicate() as BaseMaterial3D
		mi.set_surface_override_material(i, own)
		if key == BLINK_MAT:
			_blink.append(own)
		elif key == FLOW_MAT:
			_flow.append(own)
		else:
			var frames: Array[Texture2D] = []
			for tex_name in SCREENS[key][0]:
				frames.append(load(TEX_DIR + tex_name + ".png") as Texture2D)
			_screen_mats.append(own)
			_screen_frames.append(frames)
			_screen_period.append(SCREENS[key][1])
			_screen_shown.append(-1)


func _add_light(anchor: Node3D) -> void:
	var made := KitLights.make(anchor)
	if made.is_empty() or made[1] == KitLights.Anim.STEADY:
		return
	_lights.append(made[0])
	_light_base.append(made[0].light_energy)
	_light_anim.append(made[1])


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var t := Time.get_ticks_msec() * 0.001 + _phase
	for i in _screen_mats.size():
		var frames := _screen_frames[i]
		var idx := int(t / _screen_period[i]) % frames.size()
		if idx != _screen_shown[i]:
			_screen_shown[i] = idx
			_screen_mats[i].emission_texture = frames[idx]
	var blink := 1.6 if sin(t * BLINK_RATE) > -0.2 else 0.12
	for mat in _blink:
		mat.emission_energy_multiplier = blink
	var flow := fposmod(-t * FLOW_SPEED, 1.0)
	var glow := 1.45 + 0.35 * sin(t * 1.7)
	for mat in _flow:
		mat.uv1_offset = Vector3(mat.uv1_offset.x, flow, mat.uv1_offset.z)
		mat.emission_energy_multiplier = glow
	for i in _spin.size():
		_spin[i].rotate_object_local(Vector3.BACK, SPIN_RATE * dt * (1.0 - 0.35 * i))
	for i in _lights.size():
		var k := Fx.flicker(t, float(i)) if _light_anim[i] == KitLights.Anim.FLICKER else 0.75 + 0.25 * sin(t * 2.1 + i)
		_lights[i].light_energy = _light_base[i] * k
