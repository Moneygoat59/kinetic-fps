class_name DeadForestTerrain
extends Node3D

signal chunk_recycled(chunk_node: Node3D, cx: int, cz: int)

const CHUNK_SIZE: float = 48.0
const STEP: float = 3.0
const DIRT_TEX = preload("res://textures/dead_dirt_seamless.jpg")

var noise: FastNoiseLite
var micro_noise: FastNoiseLite
var terrain_mat: StandardMaterial3D

var chunks: Array[Node3D] = []
var chunk_coords: Array[Vector2i] = []
var last_player_chunk: Vector2i = Vector2i(999999, 999999)

func _ready() -> void:
	_init_noise()
	_init_material()
	_init_chunk_pool()

func _init_noise() -> void:
	noise = FastNoiseLite.new(); noise.seed = 1337
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH; noise.frequency = 0.018; noise.fractal_octaves = 3
	micro_noise = FastNoiseLite.new(); micro_noise.seed = 42
	micro_noise.noise_type = FastNoiseLite.TYPE_PERLIN; micro_noise.frequency = 0.14

func _init_material() -> void:
	terrain_mat = StandardMaterial3D.new()
	terrain_mat.albedo_texture = DIRT_TEX
	terrain_mat.albedo_color = Color(0.42, 0.36, 0.30)
	terrain_mat.roughness = 0.95; terrain_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	terrain_mat.uv1_scale = Vector3(0.35, 0.35, 0.35); terrain_mat.uv1_triplanar = true

func _init_chunk_pool() -> void:
	for i in range(9):
		var body = StaticBody3D.new(); body.name = "Chunk_%d" % i
		var mi = MeshInstance3D.new(); mi.name = "Mesh"; mi.material_override = terrain_mat
		mi.mesh = ArrayMesh.new()
		var col = CollisionShape3D.new(); col.name = "Collision"
		var props = Node3D.new(); props.name = "Props"
		body.add_child(mi); body.add_child(col); body.add_child(props); add_child(body)
		chunks.append(body); chunk_coords.append(Vector2i(999999, 999999))

var flat_zones: Array[Dictionary] = []

func add_flat_zone(x: float, z: float, radius: float, target_y: float) -> void:
	flat_zones.append({"x": x, "z": z, "r": radius, "y": target_y})
	for i in range(chunks.size()):
		var coord = chunk_coords[i]
		if coord.x != 999999:
			var cx = coord.x * CHUNK_SIZE; var cz = coord.y * CHUNK_SIZE
			if sqrt((x - cx) * (x - cx) + (z - cz) * (z - cz)) < radius + CHUNK_SIZE:
				_rebuild_chunk(chunks[i], coord.x, coord.y)

static func get_chunk_pools(cx: int, cz: int) -> Array[Dictionary]:
	var pools: Array[Dictionary] = []
	var rng = RandomNumberGenerator.new()
	rng.seed = (cx * 73856093) ^ (cz * 19349663) ^ 442211
	var min_x = cx * CHUNK_SIZE - CHUNK_SIZE * 0.5; var min_z = cz * CHUNK_SIZE - CHUNK_SIZE * 0.5
	for i in range(rng.randi_range(1, 2)):
		var px = min_x + rng.randf_range(9.0, 39.0); var pz = min_z + rng.randf_range(9.0, 39.0)
		if px * px + pz * pz < 400.0: continue
		pools.append({"x": px, "z": pz, "r": rng.randf_range(2.8, 3.8), "d": rng.randf_range(0.70, 0.95), "seed": rng.randi()})
	return pools

func get_height(x: float, z: float) -> float:
	var base_lump = noise.get_noise_2d(x, z) * 3.5
	var micro = micro_noise.get_noise_2d(x, z) * 0.45
	var h = base_lump + micro

	var spawn_dist = sqrt(x * x + z * z)
	if spawn_dist < 18.0:
		var factor = spawn_dist / 18.0; h = lerp(0.0, h, factor * factor)

	var cell_x = int(floor((x + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	var cell_z = int(floor((z + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	for p in get_chunk_pools(cell_x, cell_z):
		var d = sqrt((x - p.x) * (x - p.x) + (z - p.z) * (z - p.z))
		var bowl_r = p.r * 1.35
		if d < bowl_r:
			var base_c = (noise.get_noise_2d(p.x, p.z) * 3.5) + (micro_noise.get_noise_2d(p.x, p.z) * 0.45)
			var target_y = base_c - p.d
			var t = clampf(d / bowl_r, 0.0, 1.0)
			h = lerpf(target_y, h, t * t)

	for fz in flat_zones:
		var d = sqrt((x - fz.x) * (x - fz.x) + (z - fz.z) * (z - fz.z))
		if d < fz.r:
			var factor = clampf(d / fz.r, 0.0, 1.0); h = lerpf(fz.y, h, factor * factor)
	return h

func update_player_pos(pos: Vector3) -> void:
	var cur_cx = int(floor((pos.x + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	var cur_cz = int(floor((pos.z + CHUNK_SIZE * 0.5) / CHUNK_SIZE))
	var cur_chunk = Vector2i(cur_cx, cur_cz)
	if cur_chunk == last_player_chunk: return
	last_player_chunk = cur_chunk

	var needed: Array[Vector2i] = []
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			needed.append(Vector2i(cur_cx + dx, cur_cz + dz))

	var available_indices: Array[int] = []
	for i in range(9):
		if not chunk_coords[i] in needed: available_indices.append(i)

	for coord in needed:
		if not coord in chunk_coords:
			var idx = available_indices.pop_back()
			chunk_coords[idx] = coord
			_rebuild_chunk(chunks[idx], coord.x, coord.y)

func _rebuild_chunk(chunk_node: Node3D, cx: int, cz: int) -> void:
	var origin_x = cx * CHUNK_SIZE - CHUNK_SIZE * 0.5
	var origin_z = cz * CHUNK_SIZE - CHUNK_SIZE * 0.5
	var quads = int(CHUNK_SIZE / STEP)

	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi in range(quads):
		for xi in range(quads):
			var x0 = origin_x + xi * STEP; var x1 = x0 + STEP
			var z0 = origin_z + zi * STEP; var z1 = z0 + STEP
			var p00 = Vector3(x0, get_height(x0, z0), z0)
			var p10 = Vector3(x1, get_height(x1, z0), z0)
			var p01 = Vector3(x0, get_height(x0, z1), z1)
			var p11 = Vector3(x1, get_height(x1, z1), z1)

			st.add_vertex(p00); st.add_vertex(p10); st.add_vertex(p01)
			st.add_vertex(p10); st.add_vertex(p11); st.add_vertex(p01)

	st.generate_normals(); var mesh = st.commit()
	var mi = chunk_node.get_node("Mesh") as MeshInstance3D
	mi.mesh = mesh

	var col = chunk_node.get_node("Collision") as CollisionShape3D
	col.shape = mesh.create_trimesh_shape()

	chunk_recycled.emit(chunk_node.get_node("Props"), cx, cz)
