class_name NuclearPylon
extends Node3D

signal station_reached(pylon: NuclearPylon)

const CONCRETE_TEX = preload("res://textures/concrete_seamless.png")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
const HAZARD_TEX = preload("res://textures/hazard_stripes.png")

@export var station_id: int = 1
var is_active: bool = false
var is_cleared: bool = false
var beacon_light: OmniLight3D
var ring_mat: StandardMaterial3D
var pylon_body: StaticBody3D

func build_pylon(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy - 0.25, pos_z)

	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_texture = CONCRETE_TEX; c_mat.albedo_color = Color(0.65, 0.67, 0.70)
	c_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; c_mat.uv1_triplanar = true
	c_mat.uv1_scale = Vector3(0.25, 0.25, 0.25); c_mat.roughness = 0.95

	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_texture = METAL_TEX; m_mat.albedo_color = Color(0.35, 0.38, 0.40)
	m_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; m_mat.roughness = 0.7; m_mat.metallic = 0.75

	ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.65, 0.12)
	ring_mat.emission_enabled = true; ring_mat.emission = Color(1.0, 0.65, 0.12)
	ring_mat.emission_energy_multiplier = 0.0

	# Concrete base pillar (1.2m x 3.2m x 1.2m)
	_create_box(Vector3(0.0, 1.6, 0.0), Vector3(1.2, 3.2, 1.2), c_mat)
	# Pulsing amber indicator band
	_create_box(Vector3(0.0, 3.1, 0.0), Vector3(1.35, 0.4, 1.35), ring_mat, false)
	# Lead antenna mast
	_create_box(Vector3(0.0, 4.0, 0.0), Vector3(0.25, 1.6, 0.25), m_mat)
	# Sensor dish
	_create_box(Vector3(0.0, 4.8, 0.0), Vector3(0.7, 0.15, 0.7), m_mat)

	# Pulsing amber atmospheric waypoint beacon
	beacon_light = OmniLight3D.new()
	beacon_light.position = Vector3(0.0, 4.2, 0.0)
	beacon_light.light_color = Color(1.0, 0.65, 0.12)
	beacon_light.light_energy = 0.0; beacon_light.omni_range = 28.0
	add_child(beacon_light)

func _create_box(pos: Vector3, sz: Vector3, mat: Material, col: bool = true) -> void:
	var mi = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.position = pos; mi.material_override = mat; add_child(mi)
	if col:
		if not pylon_body:
			pylon_body = StaticBody3D.new(); add_child(pylon_body)
		var cs = CollisionShape3D.new(); var shape = BoxShape3D.new(); shape.size = sz
		cs.shape = shape; cs.position = pos; pylon_body.add_child(cs)

func set_station_active(active: bool) -> void:
	is_active = active
	if is_active and not is_cleared:
		beacon_light.light_color = Color(1.0, 0.65, 0.12)
		ring_mat.emission = Color(1.0, 0.65, 0.12)
	elif is_cleared:
		beacon_light.light_color = Color(0.2, 1.0, 0.35); beacon_light.light_energy = 1.8
		ring_mat.emission = Color(0.2, 1.0, 0.35); ring_mat.emission_energy_multiplier = 2.0
	else:
		beacon_light.light_energy = 0.0
		ring_mat.emission_energy_multiplier = 0.0

func _process(delta: float) -> void:
	if is_active and not is_cleared and beacon_light:
		var pulse = (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
		beacon_light.light_energy = lerpf(1.2, 4.8, pulse)
		beacon_light.omni_range = lerpf(16.0, 28.0, pulse)
		if ring_mat: ring_mat.emission_energy_multiplier = lerpf(2.0, 7.0, pulse)

func check_player_proximity(p_pos: Vector3) -> bool:
	if not is_active or is_cleared: return false
	if global_position.distance_to(p_pos) < 5.5:
		is_cleared = true
		beacon_light.light_color = Color(0.2, 1.0, 0.35); beacon_light.light_energy = 1.8
		if ring_mat:
			ring_mat.emission = Color(0.2, 1.0, 0.35); ring_mat.emission_energy_multiplier = 2.0
		station_reached.emit(self)
		return true
	return false
