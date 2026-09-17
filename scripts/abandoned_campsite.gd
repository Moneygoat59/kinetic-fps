class_name AbandonedCampsite
extends Node3D

const STONE_TEX = preload("res://textures/mossy_stone_seamless.png")
const BARK_TEX = preload("res://textures/decayed_bark_seamless.png")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")

var lantern_light: OmniLight3D

func build_campsite(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var canvas_mat = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.30, 0.35, 0.26); canvas_mat.roughness = 0.92
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_texture = BARK_TEX; wood_mat.albedo_color = Color(0.35, 0.28, 0.22); wood_mat.roughness = 0.95
	var char_mat = StandardMaterial3D.new()
	char_mat.albedo_color = Color(0.10, 0.09, 0.08); char_mat.roughness = 0.98
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_texture = STONE_TEX; stone_mat.albedo_color = Color(0.52, 0.50, 0.46); stone_mat.roughness = 0.9
	var tarp_mat = StandardMaterial3D.new()
	tarp_mat.albedo_color = Color(0.18, 0.22, 0.20); tarp_mat.roughness = 0.9
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_texture = METAL_TEX; metal_mat.albedo_color = Color(0.38, 0.34, 0.30); metal_mat.roughness = 0.65

	# Foundation & floor (no collision so player walks smoothly on flat terrain)
	_box(Vector3(0.0, -0.3, 0.0), Vector3(3.6, 0.6, 4.0), tarp_mat, false)
	_box(Vector3(0.0, 0.02, 0.0), Vector3(3.4, 0.04, 3.8), tarp_mat, false)

	# Ridge pole along peak (2.38m high)
	_box(Vector3(0.0, 2.38, 0.0), Vector3(0.12, 0.12, 4.2), wood_mat, false)

	# Left and right sloped canvas roof walls
	_box(Vector3(-0.95, 1.25, 0.0), Vector3(0.08, 2.55, 3.8), canvas_mat, true, Vector3(0, 0, deg_to_rad(47.0)))
	_box(Vector3(0.95, 1.25, 0.0), Vector3(0.08, 2.55, 3.8), canvas_mat, true, Vector3(0, 0, deg_to_rad(-47.0)))

	# Closed rear wall (z = -1.9m)
	_box(Vector3(0.0, 1.15, -1.9), Vector3(2.4, 2.3, 0.08), canvas_mat, true)

	# Front entrance with open 1.6m wide doorway (z = +1.9m)
	_box(Vector3(-1.15, 1.1, 1.9), Vector3(0.7, 2.2, 0.06), canvas_mat, true)
	_box(Vector3(1.15, 1.1, 1.9), Vector3(0.7, 2.2, 0.06), canvas_mat, true)
	_box(Vector3(0.0, 2.25, 1.9), Vector3(1.8, 0.25, 0.06), canvas_mat, false)

	# Interior: bedroll, supply crate, faint camping lantern
	_box(Vector3(-0.75, 0.14, -0.3), Vector3(0.85, 0.16, 1.9), canvas_mat, false)
	_box(Vector3(0.8, 0.25, -0.8), Vector3(0.6, 0.45, 0.6), wood_mat)
	_box(Vector3(0.8, 0.58, -0.8), Vector3(0.2, 0.25, 0.2), metal_mat, false)

	lantern_light = OmniLight3D.new(); lantern_light.position = Vector3(0.8, 0.66, -0.8)
	lantern_light.light_color = Color(1.0, 0.72, 0.30); lantern_light.light_energy = 0.85; lantern_light.omni_range = 4.2
	add_child(lantern_light)

	# Dead campfire ring (at x = 3.6, z = 0.6)
	var ash_mi = MeshInstance3D.new(); var cyl = CylinderMesh.new()
	cyl.top_radius = 0.85; cyl.bottom_radius = 0.85; cyl.height = 0.08
	ash_mi.mesh = cyl; ash_mi.material_override = char_mat; ash_mi.position = Vector3(3.6, 0.04, 0.6); add_child(ash_mi)

	# Stone ring: 9 stones forming a 1.7m circle
	for i in range(9):
		var ang = float(i) * TAU / 9.0
		var s_pos = Vector3(3.6 + cos(ang) * 0.85, 0.12, 0.6 + sin(ang) * 0.85)
		_box(s_pos, Vector3(0.32, 0.24, 0.28), stone_mat, true, Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3))

	# Charred dead firewood logs criss-crossed over ash
	_box(Vector3(3.6, 0.11, 0.6), Vector3(0.18, 0.16, 1.0), char_mat, false, Vector3(0.08, 0.4, 0.0))
	_box(Vector3(3.6, 0.14, 0.6), Vector3(0.16, 0.14, 0.9), char_mat, false, Vector3(-0.06, -0.8, 0.0))
	_box(Vector3(3.6, 0.17, 0.6), Vector3(0.15, 0.15, 0.85), char_mat, false, Vector3(0.05, 1.3, 0.0))

	# Sitting logs beside campfire
	_box(Vector3(3.6, 0.20, 2.0), Vector3(0.34, 0.34, 1.8), wood_mat, true, Vector3(0.0, deg_to_rad(15.0), 0.0))
	_box(Vector3(2.1, 0.20, 0.6), Vector3(1.6, 0.32, 0.32), wood_mat, true, Vector3(0.0, deg_to_rad(85.0), 0.0))

func _box(pos: Vector3, size: Vector3, mat: Material, add_col: bool = true, rot: Vector3 = Vector3.ZERO) -> void:
	var mi = MeshInstance3D.new(); var box = BoxMesh.new(); box.size = size
	mi.mesh = box; mi.material_override = mat; mi.position = pos; mi.rotation = rot; add_child(mi)
	if add_col:
		var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shape = BoxShape3D.new()
		shape.size = size; col.shape = shape; sb.position = pos; sb.rotation = rot; sb.add_child(col); add_child(sb)
