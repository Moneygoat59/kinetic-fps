extends Node3D
## Dev showroom for the Outpost 73 prop kit (scenes/dev/o73_kit_showcase.tscn): the kit set dressed in bunker-like light.
## Left: a relay office against a wall. Middle: storage. Right: a pipe run into the ground, barriers, a floodlight.
## Capture: tools\capture.ps1 -Scene res://scenes/dev/o73_kit_showcase.tscn -Cam -4,1.6,3.2 -Look -4.2,1,-1.8 -NoUi

const FLOOR_TEX := "res://models/generated/tex/floor.png"
const WALL_TEX := "res://models/generated/tex/plate.png"
const WALL_Z := -3.0
const AMBER := Color(1.0, 0.66, 0.24)

## [prop, position, yaw degrees]
const LAYOUT := [
	[&"shelf_rack", Vector3(-6.3, 0, WALL_Z + 0.225), 0.0],
	[&"locker", Vector3(-5.0, 0, WALL_Z + 0.25), 0.0],
	[&"terminal_wall", Vector3(-3.8, 0, WALL_Z), 0.0],
	[&"terminal_mainframe", Vector3(-2.6, 0, WALL_Z + 0.35), 0.0],
	[&"table_steel", Vector3(-5.2, 0, -1.0), 0.0],
	[&"chair_steel", Vector3(-5.0, 0, 0.0), 195.0],
	[&"terminal_console", Vector3(-2.2, 0, -0.9), -35.0],
	[&"crate_large", Vector3(-0.6, 0, -2.4), 0.0],
	[&"crate_large", Vector3(-0.62, 0.6, -2.4), 7.0],
	[&"crate_small", Vector3(0.6, 0, -2.5), -12.0],
	[&"drum_amber", Vector3(0.7, 0, -1.2), 30.0],
	[&"pipe_elbow", Vector3(3.0, 0, -1.5), 180.0],
	[&"pipe_straight", Vector3(5.0, 0, -1.5), 0.0],
	[&"pipe_valve", Vector3(7.0, 0, -1.5), 0.0],
	[&"pipe_riser", Vector3(9.0, 0, -1.5), 0.0],
	[&"barrier_concrete", Vector3(5.0, 0, 1.6), 0.0],
	[&"barrier_concrete", Vector3(7.0, 0, 1.6), 0.0],
	[&"barrier_concrete_broken", Vector3(9.0, 0, 1.6), 0.0],
	[&"floodlight", Vector3(10.6, 0, 3.4), 215.0],
]
## tabletop props: [prop, parent LAYOUT index, local position, yaw]
const ON_TOP := [
	[&"terminal_crt", 4, Vector3(0.05, O73Kit.TABLE_TOP, -0.03), 0.0],
	[&"amber_cell", 9, Vector3(0.05, 0.4, 0.0), 20.0],
]


func _ready() -> void:
	_environment()
	_slab(Vector3(26.0, 0.2, 16.0), Vector3(2.0, -0.1, 0.0), FLOOR_TEX, 0.5)
	_slab(Vector3(9.0, 3.0, 0.3), Vector3(-3.8, 1.5, WALL_Z - 0.15), WALL_TEX, 1.0)
	var placed: Array[Node3D] = []
	for row in LAYOUT:
		placed.append(O73Kit.spawn(row[0], self, _xform(row[1], row[2])))
	for row in ON_TOP:
		var parent: Node3D = placed[row[1]]
		if parent:
			O73Kit.spawn(row[0], parent, _xform(row[2], row[3]))
	for p in [Vector3(-5.2, 2.7, -1.2), Vector3(-2.4, 2.7, -1.6), Vector3(0.2, 2.6, -1.8)]:
		_lamp(p, 2.2, 7.0)


func _xform(pos: Vector3, yaw_deg: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), pos)


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.018, 0.026)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.29, 0.38)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.055, 0.07)
	env.fog_density = 0.02
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	moon.light_color = Color(0.62, 0.66, 0.8)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	add_child(moon)


func _lamp(pos: Vector3, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = AMBER
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = true
	add_child(light)


func _slab(size: Vector3, pos: Vector3, tex_path: String, metres_per_tile: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load(tex_path)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE / metres_per_tile
	mat.roughness = 1.0
	mat.metallic_specular = 0.0
	var mesh := BoxMesh.new()
	mesh.size = size
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(shape)
	body.add_child(mi)
	add_child(body)
