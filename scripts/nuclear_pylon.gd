class_name NuclearPylon
extends Node3D

signal station_reached(pylon: NuclearPylon)

const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
static var basalt_tex: ImageTexture; static var basalt_norm: ImageTexture; static var metal_norm: ImageTexture

static func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

@export var station_id: int = 1
@export var pylon_color: Color = Color(1.0, 0.65, 0.12)
var is_active: bool = false; var is_cleared: bool = false
var beacon_light: OmniLight3D; var ring_mat: StandardMaterial3D; var pylon_body: StaticBody3D

const BARRIER_RADIUS: float = 20.0
func is_barrier_active() -> bool: return true

func set_pylon_color(col: Color) -> void:
	pylon_color = col
	if ring_mat: ring_mat.albedo_color = col; ring_mat.emission = col
	if beacon_light: beacon_light.light_color = col

func build_pylon(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	if not basalt_tex:
		basalt_tex = _tex("res://textures/dark_basalt_natural.png")
		basalt_norm = _tex("res://textures/dark_basalt_normal.png")
		metal_norm = _tex("res://textures/worn_metal_normal.png")
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy - 0.25, pos_z)

	var c_mat = StandardMaterial3D.new(); c_mat.albedo_texture = basalt_tex; c_mat.albedo_color = Color(0.90, 0.92, 0.98)
	c_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; c_mat.uv1_triplanar = true
	c_mat.uv1_scale = Vector3(0.25, 0.25, 0.25); c_mat.roughness = 0.92
	if basalt_norm: c_mat.normal_enabled = true; c_mat.normal_texture = basalt_norm; c_mat.normal_scale = 1.2

	var m_mat = StandardMaterial3D.new(); m_mat.albedo_texture = METAL_TEX; m_mat.albedo_color = Color(0.35, 0.38, 0.40)
	m_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; m_mat.roughness = 0.7; m_mat.metallic = 0.75
	if metal_norm: m_mat.normal_enabled = true; m_mat.normal_texture = metal_norm; m_mat.normal_scale = 1.0

	ring_mat = StandardMaterial3D.new(); ring_mat.albedo_color = pylon_color
	ring_mat.emission_enabled = true; ring_mat.emission = pylon_color; ring_mat.emission_energy_multiplier = 0.0

	# Octagonal basalt base pillar
	_cylinder(Vector3(0.0, 1.6, 0.0), 0.75, 3.2, 8, c_mat)
	# Pulsing indicator collar
	_cylinder(Vector3(0.0, 3.1, 0.0), 0.85, 0.35, 8, ring_mat, false)
	# Antenna mast and sensor dish
	_cylinder(Vector3(0.0, 4.0, 0.0), 0.14, 1.6, 8, m_mat)
	_cylinder(Vector3(0.0, 4.8, 0.0), 0.45, 0.15, 8, m_mat)

	beacon_light = OmniLight3D.new(); beacon_light.position = Vector3(0.0, 4.2, 0.0)
	beacon_light.light_color = pylon_color; beacon_light.light_energy = 0.0; beacon_light.omni_range = 46.0
	add_child(beacon_light)

func _cylinder(pos: Vector3, rad: float, h: float, sides: int, mat: Material, col: bool = true) -> void:
	var mi = MeshInstance3D.new(); var cm = CylinderMesh.new()
	cm.top_radius = rad; cm.bottom_radius = rad; cm.height = h; cm.radial_segments = sides
	mi.mesh = cm; mi.position = pos; mi.material_override = mat; add_child(mi)
	if col:
		if not pylon_body: pylon_body = StaticBody3D.new(); add_child(pylon_body)
		var cs = CollisionShape3D.new(); var shape = CylinderShape3D.new()
		shape.radius = rad; shape.height = h; cs.shape = shape; cs.position = pos; pylon_body.add_child(cs)

func set_station_active(active: bool) -> void:
	is_active = active
	if is_active and not is_cleared:
		beacon_light.light_color = pylon_color
		ring_mat.emission = pylon_color
	elif is_cleared:
		beacon_light.light_color = pylon_color; beacon_light.light_energy = 1.4
		ring_mat.emission = pylon_color; ring_mat.emission_energy_multiplier = 1.5
	else:
		beacon_light.light_energy = 0.0; ring_mat.emission_energy_multiplier = 0.0

func _process(delta: float) -> void:
	if is_active and not is_cleared and beacon_light:
		var pulse = (sin(Time.get_ticks_msec() * 0.007) + 1.0) * 0.5
		beacon_light.light_energy = lerpf(1.5, 6.0, pulse)
		beacon_light.omni_range = lerpf(24.0, 46.0, pulse)
		if ring_mat: ring_mat.emission_energy_multiplier = lerpf(2.0, 7.0, pulse)

func check_player_proximity(p_pos: Vector3) -> bool:
	if not is_active or is_cleared: return false
	if global_position.distance_to(p_pos) < 7.0:
		is_cleared = true
		beacon_light.light_color = pylon_color; beacon_light.light_energy = 1.4
		if ring_mat: ring_mat.emission = pylon_color; ring_mat.emission_energy_multiplier = 1.5
		station_reached.emit(self)
		return true
	return false
