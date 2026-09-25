class_name AncientSpikeField
extends RefCounted

# Grainy Basalt Textures & PS1 Triplanar Flat Shader
const BASALT_TEX: Texture2D = preload("res://textures/dark_basalt_natural.png")
const CRAG_SHADER: Shader = preload("res://shaders/ps1_crag.gdshader")

# Natural grainy basalt color tones (deep volcanic charcoal, weathered ash slate, mineral basalt)
const BASALT_TINTS: Array[Color] = [
	Color(0.19, 0.20, 0.22),
	Color(0.24, 0.25, 0.27),
	Color(0.15, 0.16, 0.18),
	Color(0.22, 0.23, 0.25),
	Color(0.27, 0.28, 0.30)
]

static var basalt_mats: Array[ShaderMaterial] = []
static var _initialized: bool = false

static func _ensure_materials() -> void:
	if _initialized: return
	_initialized = true
	for tint in BASALT_TINTS:
		var mat = ShaderMaterial.new()
		mat.shader = CRAG_SHADER
		mat.set_shader_parameter("albedo_texture", BASALT_TEX)
		mat.set_shader_parameter("albedo_color", tint)
		mat.set_shader_parameter("uv_scale", Vector3(0.32, 0.32, 0.32))
		basalt_mats.append(mat)

# High frequency: ~75% of chunks have singular tall skinny spikes
static func has_spike_field(cx: int, cz: int) -> bool:
	if cx == 0 and cz == 0: return false
	var h = (cx * 374761393) ^ (cz * 668265263) ^ 88411
	h = (h ^ (h >> 13)) * 1274126177
	return (abs(h) % 100) < 75

static func spawn_spikes(parent: Node3D, terrain: Node3D, cx: int, cz: int, min_x: float, min_z: float, pools: Array[Vector3]) -> void:
	_ensure_materials()
	var rng = RandomNumberGenerator.new()
	rng.seed = (cx * 91827364) ^ (cz * 46372819) ^ 7162534

	# Spawn 3 to 6 singular tall skinny spikes scattered across the chunk
	var count = rng.randi_range(3, 6)
	for i in range(count):
		var sx = min_x + rng.randf() * 48.0
		var sz = min_z + rng.randf() * 48.0
		if (sx * sx + sz * sz < 280.0) or _is_blocked(sx, sz, pools): continue

		# 100% geometric tall skinny spike: 4-sided diamond, 5-sided thorn, 6-sided hex basalt
		var sides = [4, 5, 6][rng.randi() % 3]

		# Rich height variety across three tiers (6m to 42m)
		var tier = rng.randf()
		var height: float
		var base_rad: float
		var embed: float
		var max_tilt: float

		if tier < 0.28:
			height = rng.randf_range(6.0, 12.0)
			base_rad = rng.randf_range(0.32, 0.46)
			embed = rng.randf_range(1.0, 1.8)
			max_tilt = 0.44
		elif tier < 0.72:
			height = rng.randf_range(14.0, 24.0)
			base_rad = rng.randf_range(0.44, 0.62)
			embed = rng.randf_range(1.6, 2.8)
			max_tilt = 0.34
		else:
			height = rng.randf_range(26.0, 42.0)
			base_rad = rng.randf_range(0.62, 0.88)
			embed = rng.randf_range(2.5, 4.2)
			max_tilt = 0.22

		# Hostile needle tilt in random directions
		var tilt_amt = rng.randf_range(0.08, max_tilt)
		var tilt_dir = rng.randf() * TAU
		var rot = Vector3(cos(tilt_dir) * tilt_amt, rng.randf() * TAU, sin(tilt_dir) * tilt_amt)
		var mat = basalt_mats[rng.randi() % basalt_mats.size()]

		var gy = terrain.get_height(sx, sz) if terrain else 0.0
		var pos = Vector3(sx, gy - embed, sz)

		_spawn_procedural_spike(parent, pos, base_rad, height, sides, rot, mat)

static func _is_blocked(x: float, z: float, pools: Array[Vector3]) -> bool:
	for p in pools:
		if (x - p.x) * (x - p.x) + (z - p.y) * (z - p.y) < (p.z + 2.5) * (p.z + 2.5): return true
	return false

static func _spawn_procedural_spike(parent: Node3D, pos: Vector3, base_rad: float, h: float, sides: int, rot: Vector3, mat: Material) -> void:
	var pivot = Node3D.new()
	pivot.name = "AncientSpike"
	pivot.position = pos
	pivot.rotation = rot
	parent.add_child(pivot)

	# MeshInstance3D: sharp tapering needle spike (top_radius = 0.02)
	var mi = MeshInstance3D.new()
	mi.name = "SpikeMesh"
	var cm = CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = base_rad
	cm.height = h
	cm.radial_segments = sides
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position.y = h * 0.5
	pivot.add_child(mi)

	# Solid CollisionShape3D for grapple tethering and physics collisions
	var body = StaticBody3D.new()
	body.name = "SpikeBody"
	var col = CollisionShape3D.new()
	col.name = "SpikeCol"
	var shape = CylinderShape3D.new()
	shape.radius = base_rad
	shape.height = h
	col.shape = shape
	col.position.y = h * 0.5
	body.add_child(col)
	pivot.add_child(body)
