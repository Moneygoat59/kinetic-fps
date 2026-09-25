extends Node
## Animates the bunker's CRT screens by swapping / scrolling emission textures (blinking cursor, changing readings,
## rolling static, beacon blink) and the glowing amber liquid (flow along the pipes, pulsing pool).
## Materials come from the model's "bunker_screens" / "bunker_liquid" meshes. Runs only while the player is near.

const TEX_DIR := "res://models/generated/tex/"
const SCREENS_NODE := "bunker_screens"
## material name -> [frame A, frame B, seconds per flip]
const FLIPS := {
	"bunker_scr_term": ["screen_term_a", "screen_term_b", 0.5],
	"bunker_scr_scan": ["screen_scan_a", "screen_scan_b", 0.9],
	"bunker_scr_map": ["screen_map_a", "screen_map_b", 0.7],
	"bunker_scr_gen": ["screen_gen_a", "screen_gen_b", 1.7],
}
const STATIC_MAT := "bunker_scr_static"
const STATIC_SPEED := 0.7
const STATIC_BASE := 0.6
const STATIC_FLICKER := 0.5
const LIQUID_NODE := "bunker_liquid"
const FLOW_MAT := "bunker_amber_liquid"
const POOL_MAT := "bunker_amber_pool"
const FLOW_SPEED := 0.35

var _flow: BaseMaterial3D
var _pool: BaseMaterial3D
var _mats: Array[BaseMaterial3D] = []
var _tex_a: Array[Texture2D] = []
var _tex_b: Array[Texture2D] = []
var _period := PackedFloat32Array()
var _timer := PackedFloat32Array()
var _frame := PackedInt32Array()  # 0 = frame A showing, 1 = frame B
var _static: BaseMaterial3D


func setup(model: Node) -> void:
	set_process(false)
	var liquid := model.get_node_or_null(LIQUID_NODE) as MeshInstance3D
	if liquid and liquid.mesh:
		for i in liquid.mesh.get_surface_count():
			var lmat := liquid.mesh.surface_get_material(i) as BaseMaterial3D
			if lmat and lmat.resource_name == FLOW_MAT:
				_flow = lmat
			elif lmat and lmat.resource_name == POOL_MAT:
				_pool = lmat
	var mesh_node := model.get_node_or_null(SCREENS_NODE) as MeshInstance3D
	if mesh_node == null or mesh_node.mesh == null:
		push_warning("BunkerScreens: '%s' missing from model" % SCREENS_NODE)
		return
	for i in mesh_node.mesh.get_surface_count():
		var mat := mesh_node.mesh.surface_get_material(i) as BaseMaterial3D
		if mat == null:
			continue
		if mat.resource_name == STATIC_MAT:
			_static = mat
		elif FLIPS.has(mat.resource_name):
			var spec: Array = FLIPS[mat.resource_name]
			_mats.append(mat)
			_tex_a.append(load(TEX_DIR + spec[0] + ".png") as Texture2D)
			_tex_b.append(load(TEX_DIR + spec[1] + ".png") as Texture2D)
			_period.append(spec[2])
			_timer.append(0.0)
			_frame.append(0)


## Called every physics frame by the bunker with "is the player close". Only toggles on change.
func set_active(near: bool) -> void:
	if is_processing() != near:
		set_process(near)


func _process(delta: float) -> void:
	for i in _mats.size():
		_timer[i] += delta
		if _timer[i] >= _period[i]:
			_timer[i] = 0.0
			_frame[i] = 1 - _frame[i]
			_mats[i].emission_texture = _tex_b[i] if _frame[i] == 1 else _tex_a[i]
	var t := Time.get_ticks_msec() * 0.001
	if _flow:
		var flow_offset := _flow.uv1_offset
		flow_offset.y = fposmod(flow_offset.y - delta * FLOW_SPEED, 1.0)
		_flow.uv1_offset = flow_offset
		_flow.emission_energy_multiplier = 1.5 + 0.4 * sin(t * 1.7)
	if _pool:
		_pool.emission_energy_multiplier = 1.0 + 0.3 * sin(t * 1.3 + 1.0)
	if _static:
		var offset := _static.uv1_offset
		offset.y = fposmod(offset.y + delta * STATIC_SPEED, 1.0)
		_static.uv1_offset = offset
		_static.emission_energy_multiplier = STATIC_BASE + STATIC_FLICKER * randf()
