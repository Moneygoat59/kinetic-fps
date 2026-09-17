class_name DeadForestProps
extends Node3D

const TREE_1 = preload("res://models/dead_forest/dead_tree_1.glb")
const TREE_2 = preload("res://models/dead_forest/dead_tree_2.glb")
const TREE_3 = preload("res://models/dead_forest/dead_tree_3.glb")
const TREE_4 = preload("res://models/dead_forest/dead_tree_4.glb")
const TREE_5 = preload("res://models/dead_forest/dead_tree_5.glb")
const TRUNK_LONG = preload("res://models/dead_forest/trunk-long.glb")
const TRUNK = preload("res://models/dead_forest/trunk.glb")
const ROCKS_TALL = preload("res://models/dead_forest/rocks-tall.glb")
const ROCKS = preload("res://models/dead_forest/rocks.glb")
const ROCKS_LOW = preload("res://models/foliage/rocks-low.glb")
const STONES = preload("res://models/foliage/stones.glb")
const PINE_FALL = preload("res://models/dead_forest/pine-fall.glb")
const DEBRIS_WOOD = preload("res://models/dead_forest/debris-wood.glb")
const ALTAR_STONE = preload("res://models/dead_forest/altar-stone.glb")

const BARK_TEX = preload("res://textures/decayed_bark_seamless.png")
const STONE_TEX = preload("res://textures/mossy_stone_seamless.png")
const CRAG_SHADER = preload("res://shaders/ps1_crag.gdshader")

const TREE_POOL: Array[PackedScene] = [TREE_1, TREE_2, TREE_3, TREE_4, TREE_5]
const ROCK_POOL: Array[PackedScene] = [ROCKS_TALL, ROCKS, ROCKS_LOW, STONES]

const TREE_TINTS: Array[Color] = [
	Color(0.92, 0.88, 0.82), Color(0.62, 0.58, 0.54), Color(0.76, 0.80, 0.70),
	Color(0.82, 0.74, 0.66), Color(0.65, 0.70, 0.74), Color(0.48, 0.44, 0.42)
]
const WOOD_TINTS: Array[Color] = [
	Color(0.38, 0.33, 0.28), Color(0.48, 0.44, 0.40), Color(0.30, 0.35, 0.28),
	Color(0.24, 0.22, 0.20), Color(0.42, 0.36, 0.30)
]
const ROCK_TINTS: Array[Color] = [
	Color(0.55, 0.57, 0.58), Color(0.42, 0.45, 0.46), Color(0.35, 0.38, 0.36),
	Color(0.28, 0.30, 0.32), Color(0.48, 0.50, 0.52)
]

var wood_mats: Array[ShaderMaterial] = []
var rock_mats: Array[ShaderMaterial] = []
var terrain_ref: Node3D

func init_props(terrain: Node3D) -> void:
	terrain_ref = terrain
	_init_materials()
	if terrain.has_signal("chunk_recycled"):
		terrain.chunk_recycled.connect(_on_chunk_recycled)

func _init_materials() -> void:
	for c in WOOD_TINTS:
		var m = ShaderMaterial.new(); m.shader = CRAG_SHADER
		m.set_shader_parameter("albedo_texture", BARK_TEX); m.set_shader_parameter("albedo_color", c)
		m.set_shader_parameter("uv_scale", Vector3(0.45, 0.45, 0.45)); wood_mats.append(m)
	for c in ROCK_TINTS:
		var m = ShaderMaterial.new(); m.shader = CRAG_SHADER
		m.set_shader_parameter("albedo_texture", STONE_TEX); m.set_shader_parameter("albedo_color", c)
		m.set_shader_parameter("uv_scale", Vector3(0.35, 0.35, 0.35)); rock_mats.append(m)

func _ground_y(x: float, z: float, rad: float, embed: float) -> float:
	if not terrain_ref: return -embed
	var h0 = terrain_ref.get_height(x, z); var h1 = terrain_ref.get_height(x + rad, z); var h2 = terrain_ref.get_height(x - rad, z)
	var h3 = terrain_ref.get_height(x, z + rad); var h4 = terrain_ref.get_height(x, z - rad)
	return minf(h0, minf(minf(h1, h2), minf(h3, h4))) - embed

func _on_chunk_recycled(props_node: Node3D, cx: int, cz: int) -> void:
	for c in props_node.get_children(): c.queue_free()
	var rng = RandomNumberGenerator.new()
	rng.seed = (cx * 73856093) ^ (cz * 19349663) ^ 442211
	var min_x = cx * 48.0 - 24.0; var min_z = cz * 48.0 - 24.0

	if cx == 0 and cz == 0:
		_spawn_clearing(props_node)
	elif cx == 0 and cz < 0:
		for zm in [-26.0, -46.0, -66.0, -82.0]:
			if zm >= min_z and zm < min_z + 48.0:
				var sx = -3.8 if int(zm) % 2 == 0 else 3.8
				_spawn_prop(ROCKS_TALL, props_node, Vector3(sx, 0.0, zm), Vector3(1.2, 2.4, 1.2), 0.0, 0.6, 0.25, true, false, rock_mats[0])

	for i in range(14):
		var x = min_x + rng.randf() * 48.0; var z = min_z + rng.randf() * 48.0
		if (x * x + z * z < 250.0) or (cz < 0 and absf(x) < 4.5) or (sqrt(x * x + (z + 180.0) * (z + 180.0)) < 22.0): continue
		var sc = Vector3.ONE * rng.randf_range(1.15, 2.0)
		_spawn_prop(TREE_POOL[rng.randi_range(0, TREE_POOL.size() - 1)], props_node, Vector3(x, 0.0, z), sc, rng.randf() * TAU, 0.4 * sc.x, 0.35 * sc.y, true, true, null)
	for i in range(3):
		var x = min_x + rng.randf() * 48.0; var z = min_z + rng.randf() * 48.0
		if (cz < 0 and absf(x) < 4.0) or (sqrt(x * x + (z + 180.0) * (z + 180.0)) < 20.0): continue
		var sc = Vector3.ONE * rng.randf_range(1.1, 2.0)
		_spawn_prop(ROCK_POOL[rng.randi_range(0, ROCK_POOL.size() - 1)], props_node, Vector3(x, 0.0, z), sc, rng.randf() * TAU, 0.6 * sc.x, 0.28 * sc.y, true, false, rock_mats[rng.randi_range(0, rock_mats.size() - 1)])
	for i in range(3):
		var x = min_x + rng.randf() * 48.0; var z = min_z + rng.randf() * 48.0
		if (cz < 0 and absf(x) < 4.0) or (sqrt(x * x + (z + 180.0) * (z + 180.0)) < 20.0): continue
		var r = rng.randf(); var scn = TRUNK if r < 0.35 else (TRUNK_LONG if r < 0.65 else PINE_FALL)
		var sc = Vector3.ONE * rng.randf_range(1.1, 1.5)
		_spawn_prop(scn, props_node, Vector3(x, 0.0, z), sc, rng.randf() * TAU, 0.5 * sc.x, 0.20 * sc.y, true, false, wood_mats[rng.randi_range(0, wood_mats.size() - 1)])
	for i in range(5):
		var x = min_x + rng.randf() * 48.0; var z = min_z + rng.randf() * 48.0
		_spawn_prop(DEBRIS_WOOD, props_node, Vector3(x, 0.0, z), Vector3.ONE * rng.randf_range(1.0, 1.8), rng.randf() * TAU, 0.3, 0.05, false, false, wood_mats[rng.randi_range(0, wood_mats.size() - 1)])
	for i in range(4):
		var x = min_x + rng.randf() * 48.0; var z = min_z + rng.randf() * 48.0
		_spawn_prop(TREE_POOL[rng.randi_range(0, TREE_POOL.size() - 1)], props_node, Vector3(x, 0.0, z), Vector3.ONE * rng.randf_range(0.15, 0.25), rng.randf() * TAU, 0.25, 0.15, false, true, null)

func _spawn_clearing(parent: Node3D) -> void:
	_spawn_prop(ALTAR_STONE, parent, Vector3(0.0, 0.0, -6.5), Vector3(1.4, 1.4, 1.4), 0.2, 0.7, 0.15, true, false, rock_mats[0])
	_spawn_prop(TRUNK_LONG, parent, Vector3(-5.5, 0.0, 4.0), Vector3(1.5, 1.5, 1.5), 1.2, 0.8, 0.18, true, false, wood_mats[1])
	_spawn_prop(TRUNK, parent, Vector3(5.0, 0.0, -3.0), Vector3(1.3, 1.3, 1.3), 0.5, 0.4, 0.15, true, false, wood_mats[0])
	_spawn_prop(ROCKS, parent, Vector3(-6.0, 0.0, -4.5), Vector3(1.2, 1.2, 1.2), 1.8, 0.7, 0.25, true, false, rock_mats[1])
	_spawn_prop(ROCKS_LOW, parent, Vector3(6.5, 0.0, 3.5), Vector3(1.4, 1.4, 1.4), 0.7, 0.8, 0.25, true, false, rock_mats[2])
	_spawn_prop(DEBRIS_WOOD, parent, Vector3(3.5, 0.0, -5.5), Vector3(1.4, 1.4, 1.4), 0.7, 0.4, 0.05, false, false, wood_mats[2])
	for a in [0.0, 0.55, 1.1, 1.65, 2.2, 2.75, 3.3, 3.85, 4.4, 4.95, 5.5, 6.0]:
		var d = randf_range(17.0, 22.0); var sc = Vector3.ONE * randf_range(1.2, 1.7); var scn = TREE_5 if randf() > 0.45 else TREE_4
		_spawn_prop(scn, parent, Vector3(cos(a) * d, 0.0, sin(a) * d), sc, randf() * TAU, 0.4 * sc.x, 0.35 * sc.y, true, true, null)

func _spawn_prop(scene: PackedScene, parent: Node3D, pos: Vector3, sc: Vector3, rot_y: float, rad: float, embed: float, add_col: bool, is_tree: bool, mat: Material) -> void:
	if not scene or not parent: return
	var y = _ground_y(pos.x, pos.z, rad, embed)
	var inst = scene.instantiate() as Node3D
	inst.position = Vector3(pos.x, y, pos.z); inst.scale = sc; inst.rotation.y = rot_y; parent.add_child(inst)
	if is_tree:
		var tint = TREE_TINTS[randi() % TREE_TINTS.size()]
		for child in inst.find_children("*", "MeshInstance3D"):
			var mi = child as MeshInstance3D
			if mi and mi.get_active_material(0) is StandardMaterial3D:
				var m = StandardMaterial3D.new(); m.albedo_texture = mi.get_active_material(0).albedo_texture
				m.albedo_color = tint; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP; m.roughness = 0.95
				m.cull_mode = BaseMaterial3D.CULL_BACK; mi.material_override = m
	elif mat:
		for child in inst.find_children("*", "MeshInstance3D"):
			var mi = child as MeshInstance3D
			if mi: mi.material_override = mat
	if add_col:
		var body = StaticBody3D.new()
		if is_tree:
			var col = CollisionShape3D.new(); var cyl = CylinderShape3D.new()
			cyl.height = 6.0 * sc.y; cyl.radius = 0.28 * sc.x; col.shape = cyl; col.position.y = cyl.height * 0.5
			body.add_child(col)
		else:
			for child in inst.find_children("*", "MeshInstance3D"):
				var mi = child as MeshInstance3D
				if mi and mi.mesh:
					var shape = mi.mesh.create_convex_shape()
					if shape:
						var col = CollisionShape3D.new(); col.shape = shape; col.transform = mi.transform
						body.add_child(col)
		inst.add_child(body)
