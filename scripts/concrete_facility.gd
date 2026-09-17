class_name ConcreteFacility
extends Node3D

var concrete_mat: StandardMaterial3D
var metal_mat: StandardMaterial3D
var hazard_mat: StandardMaterial3D

func build_facility(terrain: Node3D) -> void:
	_init_materials()
	var ground_y = terrain.get_height(0.0, -180.0) if terrain else -0.25
	position = Vector3(0.0, ground_y, -180.0)

	_create_apron()
	_create_main_monolith()
	_create_entrance_portal()
	_create_blast_door()
	_create_bollards()
	_create_beacon_light()

func _get_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D: return res
	var global_p = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(global_p):
		var img = Image.load_from_file(global_p)
		if img: return ImageTexture.create_from_image(img)
	return null

func _init_materials() -> void:
	concrete_mat = StandardMaterial3D.new()
	concrete_mat.albedo_texture = _get_texture("res://textures/concrete_seamless.png")
	concrete_mat.albedo_color = Color(0.68, 0.70, 0.72)
	concrete_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	concrete_mat.uv1_triplanar = true
	concrete_mat.uv1_scale = Vector3(0.18, 0.18, 0.18)
	concrete_mat.roughness = 0.95

	metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_texture = _get_texture("res://textures/gun_metal_scratched.png")
	metal_mat.albedo_color = Color(0.35, 0.38, 0.42)
	metal_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	metal_mat.roughness = 0.65; metal_mat.metallic = 0.75

	hazard_mat = StandardMaterial3D.new()
	hazard_mat.albedo_texture = _get_texture("res://textures/hazard_stripes.png")
	hazard_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hazard_mat.roughness = 0.85

func _add_box(pos: Vector3, size: Vector3, mat: Material, add_col: bool = true) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = size
	mi.mesh = box; mi.position = pos
	mi.material_override = mat
	add_child(mi)

	if add_col:
		var body = StaticBody3D.new()
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new(); shape.size = size
		col.shape = shape; body.add_child(col)
		mi.add_child(body)
	return mi

func _create_apron() -> void:
	# Raised concrete apron slab & entrance step
	_add_box(Vector3(0.0, 0.25, 7.5), Vector3(32.0, 0.5, 15.0), concrete_mat)
	_add_box(Vector3(0.0, 0.12, 15.6), Vector3(10.0, 0.25, 1.2), concrete_mat)

func _create_main_monolith() -> void:
	# Main brutalist concrete block (30m wide, 16m tall, 32m deep)
	_add_box(Vector3(0.0, 8.0, -16.0), Vector3(30.0, 16.0, 32.0), concrete_mat)
	# Parapet / roof cap
	_add_box(Vector3(0.0, 16.3, -16.0), Vector3(31.2, 0.6, 33.2), concrete_mat)
	# Side concrete buttress wings
	_add_box(Vector3(-14.5, 6.0, -2.0), Vector3(3.0, 12.0, 6.0), concrete_mat)
	_add_box(Vector3(14.5, 6.0, -2.0), Vector3(3.0, 12.0, 6.0), concrete_mat)

func _create_entrance_portal() -> void:
	# Overhead cantilever canopy
	_add_box(Vector3(0.0, 6.4, 1.8), Vector3(9.0, 0.8, 4.2), concrete_mat)
	# Left & right door portal pillars
	_add_box(Vector3(-3.8, 3.0, 0.8), Vector3(1.6, 6.0, 2.0), concrete_mat)
	_add_box(Vector3(3.8, 3.0, 0.8), Vector3(1.6, 6.0, 2.0), concrete_mat)
	# Header beam
	_add_box(Vector3(0.0, 5.6, 0.8), Vector3(6.0, 0.8, 2.0), concrete_mat)

func _create_blast_door() -> void:
	# Heavy steel security blast door
	_add_box(Vector3(0.0, 2.6, 0.05), Vector3(4.8, 5.2, 0.4), metal_mat)
	# Hazard stripe trim
	_add_box(Vector3(0.0, 5.3, 0.15), Vector3(5.0, 0.35, 0.15), hazard_mat, false)
	# Keycard terminal pedestal
	_add_box(Vector3(2.9, 1.4, 1.0), Vector3(0.3, 1.2, 0.3), metal_mat)
	# Glowing red terminal light
	var led = OmniLight3D.new()
	led.position = Vector3(2.9, 1.85, 1.2)
	led.light_color = Color(1.0, 0.15, 0.1)
	led.light_energy = 1.4; led.omni_range = 3.5
	add_child(led)

func _create_bollards() -> void:
	for x in [-12.0, -4.0, 4.0, 12.0]:
		_add_box(Vector3(x, 0.85, 14.2), Vector3(0.65, 1.2, 0.65), concrete_mat)

func _create_beacon_light() -> void:
	# Heavy industrial entryway lamp illuminating the mist
	var lamp = OmniLight3D.new()
	lamp.name = "EntryBeacon"
	lamp.position = Vector3(0.0, 5.8, 2.5)
	lamp.light_color = Color(0.85, 0.90, 0.98)
	lamp.light_energy = 2.2
	lamp.omni_range = 22.0
	lamp.shadow_enabled = true
	add_child(lamp)
