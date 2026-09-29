class_name WraithView
extends Node3D
## What the wraith looks like: models/generated/wraith.glb (tools/blender/wraith/build.py: a starved body drawn tight over
## its skeleton, skull-faced, lips gone to the teeth, long wet hair; rigged), every surface given shaders/wraith.gdshader
## (hair: wraith_hair.gdshader) by material name (MATS). Dark wisps rise off it and a faint cold light falls round it.
## Motion (WraithRig): it hovers and bobs, its cocked head twitches to a new angle every few seconds, the long arms sway,
## reach (0..1) lifts them toward whoever it faces (only arm `reach_arm` when 0 / 1), grip (0..1) bends that wrist down,
## rage (0..1) thrashes the head, gape (0..1) drops the jaw. Red eyes (WraithEyes) sit on the model's glow_l / glow_r markers. Animates only while visible.

const MODEL = preload("res://models/generated/wraith.glb")
const SHADER = preload("res://shaders/wraith.gdshader")
const SHADER_HAIR = preload("res://shaders/wraith_hair.gdshader")
## material name -> [hair, textured, tint, roughness, specular, rim]
const MATS := {
	"wraith_skin": [false, true, Color(0.9, 0.9, 0.88), 0.5, 0.32, 0.12],
	"wraith_hair": [true, true, Color(1, 1, 1), 0.7, 0.15, 0.02],
	"wraith_teeth": [false, false, Color(0.3, 0.23, 0.13), 0.45, 0.35, 0.0],
	"wraith_eye": [false, false, Color(0.008, 0.006, 0.006), 0.04, 0.7, 0.0],
	"wraith_throat": [false, false, Color(0.012, 0.002, 0.002), 1.0, 0.0, 0.0],
}
const HOVER := 0.22                # metres its pointed feet hang off the ground
const LIGHT_ENERGY := 0.6

var presence := 0.0
var reach := 0.0
var reach_arm := -1                # -1 both arms, 0 arm_l (its +X side), 1 arm_r
var rage := 0.0
var gape := 0.0
var grip := 0.0                    # the reaching arm's wrist bends down (0..1)
var eyes: WraithEyes
var rig: WraithRig
var _mats: Array[ShaderMaterial] = []
var _model: Node3D
var _wisps: GPUParticles3D
var _light: OmniLight3D
var _tilt := Vector3.ZERO          # head nod, turn, roll it is holding
var _tilt_to := Vector3.ZERO
var _twitch_t := 2.0
var _phase := 0.0


func _ready() -> void:
	_phase = randf() * 50.0
	_model = MODEL.instantiate() as Node3D
	add_child(_model)
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		_dress(mi as MeshInstance3D)
	rig = WraithRig.new(_model.find_child("Skeleton3D", true, false) as Skeleton3D)
	eyes = WraithEyes.new()
	if rig.head_bone >= 0:
		var at := BoneAttachment3D.new()
		at.bone_name = "head"
		rig.skel.add_child(at)
		at.add_child(eyes)
		var pts: Array[Vector3] = []
		for n in ["glow_l", "glow_r"]:
			var m := _model.find_child(n, true, false) as Node3D
			if m:
				pts.append(rig.to_head(m.position))
		eyes.setup(pts, rig.dir_to_head(Vector3.BACK))
	_wisps = WraithWisps.make()
	add_child(_wisps)
	_light = OmniLight3D.new()
	_light.position = Vector3(0.0, 2.3, 1.0)
	_light.light_color = Color(0.55, 0.64, 0.85)
	_light.omni_range = 6.0
	add_child(_light)
	set_presence(0.0)


func _dress(mi: MeshInstance3D) -> void:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in mi.mesh.get_surface_count():
		var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
		var spec: Array = MATS.get(src.resource_name if src else "", MATS["wraith_skin"])
		var m := ShaderMaterial.new()
		m.shader = SHADER_HAIR if spec[0] else SHADER
		m.set_shader_parameter("use_texture", spec[1] and src != null and src.albedo_texture != null)
		m.set_shader_parameter("tint", spec[2])
		m.set_shader_parameter("roughness", spec[3])
		m.set_shader_parameter("specular", spec[4])
		m.set_shader_parameter("rim_strength", spec[5])
		m.set_shader_parameter("alpha_cut", 0.25 if spec[0] else 0.0)
		if spec[1] and src:
			m.set_shader_parameter("albedo_tex", src.albedo_texture)
			m.set_shader_parameter("use_normal", src.normal_texture != null)
			m.set_shader_parameter("normal_tex", src.normal_texture)
		mi.set_surface_override_material(i, m)
		_mats.append(m)


func set_presence(p: float) -> void:
	presence = clampf(p, 0.0, 1.0)
	visible = presence > 0.0
	for m in _mats:
		m.set_shader_parameter("presence", presence)
	_wisps.emitting = presence > 0.3
	_light.light_energy = LIGHT_ENERGY * presence
	set_process(visible)


func set_flicker(f: float) -> void:
	for m in _mats:
		m.set_shader_parameter("flicker", f)


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.1)
	var t := Time.get_ticks_msec() * 0.001 + _phase
	_model.position.y = HOVER + 0.06 * sin(t * 0.9)
	for m in _mats:
		m.set_shader_parameter("base_y", global_position.y + _model.position.y)
	_twitch_t -= dt
	if _twitch_t <= 0.0:                                        # snap to a new angle, as if something pulled it
		_twitch_t = randf_range(1.2, 4.5)
		_tilt_to = Vector3(randf_range(-0.12, 0.12), randf_range(-0.3, 0.3), randf_range(-0.35, 0.4))
	_tilt = _tilt.lerp(_tilt_to, 1.0 - exp(-dt * 14.0))
	var thrash := Vector3(randf_range(-0.1, 0.1), randf_range(-0.14, 0.14), randf_range(-0.18, 0.18)) * rage
	rig.head(_tilt + Vector3(0.03 * sin(t * 1.3), 0.0, 0.0) + thrash)
	rig.jaw(gape)
	for i in 2:
		var mine := reach_arm < 0 or reach_arm == i
		rig.arm(i, reach if mine else 0.0, 0.06 * sin(t * 0.7 + i * 2.1))
		rig.hand(i, grip if mine else 0.0)
