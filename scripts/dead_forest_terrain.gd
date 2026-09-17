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

func get_height(x: float, z: float) -> float:
	var base_lump = noise.get_noise_2d(x, z) * 3.5
	var micro = micro_noise.get_noise_2d(x, z) * 0.45
	var h = base_lump + micro

	var spawn_dist = sqrt(x * x + z * z)
	if spawn_dist < 18.0:
		var factor = spawn_dist / 18.0; h = lerp(0.0, h, factor * factor)

	var bldg_dist = sqrt(x * x + (z + 180.0) * (z + 180.0))
	if bldg_dist < 26.0:
		var bf = clampf(bldg_dist / 26.0, 0.0, 1.0); h = lerp(-0.25, h, bf * bf)
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
