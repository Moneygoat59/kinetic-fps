class_name WraithEyes
extends Node3D
## Two red eyes deep in the wraith's sockets. WraithView hangs this on the head bone (BoneAttachment3D) and calls
## setup() with the eyes' points in that space (the model's glow_l / glow_r markers) and the way the face looks. Dark until
## glow rises: a hot core on each wet black eye, a soft additive halo round it (drawn over the hair and the dark), and a
## red light on the face. glow 0..1 (WraithGrab drives it, flickering it as they catch).

const CORE := Color(1.0, 0.42, 0.28)   # white-hot at the centre, the halo does the red
const HALO := 0.26                     # metres across
const LIGHT := 0.35                   # a touch of red on the face, not a floodlight

var glow := 0.0
var _points: Array[Vector3] = []
var _core := StandardMaterial3D.new()
var _halo := StandardMaterial3D.new()
var _light: OmniLight3D


func setup(points: Array[Vector3], forward: Vector3) -> void:
	_points = points
	_core.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_halo.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_halo.no_depth_test = true
	_halo.render_priority = 10
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.55, 0.4, 1), Color(1, 0.06, 0.02, 0.85), Color(0.7, 0.0, 0.0, 0.22), Color(0.4, 0, 0, 0)])
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.35, 1.0])
	tex.gradient = g
	_halo.albedo_texture = tex
	var ball := SphereMesh.new()
	ball.radius = 0.008
	ball.height = 0.013
	ball.material = _core
	var quad := QuadMesh.new()
	quad.size = Vector2(HALO, HALO)
	quad.material = _halo
	for p in points:
		for mesh in [ball, quad]:
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			mi.position = p
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
	_light = OmniLight3D.new()
	_light.position = center_local() + forward * 0.3
	_light.light_color = Color(1.0, 0.12, 0.05)
	_light.omni_range = 0.9
	add_child(_light)
	set_glow(0.0)


func center_local() -> Vector3:
	var c := Vector3.ZERO
	for p in _points:
		c += p
	return c / maxf(_points.size(), 1)


## World point between the eyes.
func center() -> Vector3:
	return to_global(center_local())


func set_glow(g: float) -> void:
	if _light == null:
		return
	glow = clampf(g, 0.0, 1.0)
	visible = glow > 0.0
	_core.albedo_color = Color(0.08, 0.0, 0.0).lerp(CORE, glow)
	_halo.albedo_color = Color(1, 1, 1, glow)
	_light.light_energy = LIGHT * glow
