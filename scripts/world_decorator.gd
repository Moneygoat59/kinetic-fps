class_name WorldDecorator
extends Node3D

# Preloaded PS1 Shader
const PS1_SHADER: Shader = preload("res://shaders/ps1_model.gdshader")

# Preloaded Textures
const FOLIAGE_TEX: Texture2D = preload("res://models/foliage/Textures/colormap.png")
const INDUSTRIAL_TEX: Texture2D = preload("res://models/industrial/Textures/colormap.png")

# Preloaded Foliage Models
const TreeModel: PackedScene = preload("res://models/foliage/tree.glb")
const TreeHighModel: PackedScene = preload("res://models/foliage/tree-high.glb")
const PlantModel: PackedScene = preload("res://models/foliage/plant.glb")
const RocksHighModel: PackedScene = preload("res://models/foliage/rocks-high.glb")
const RocksLowModel: PackedScene = preload("res://models/foliage/rocks-low.glb")
const FenceModel: PackedScene = preload("res://models/foliage/fence.glb")

# Preloaded Industrial Models
const PipeModel: PackedScene = preload("res://models/industrial/pipe-large.glb")
const PipeLongModel: PackedScene = preload("res://models/industrial/pipe-large-long.glb")
const PipeBendModel: PackedScene = preload("res://models/industrial/pipe-large-bend.glb")
const PipeValveModel: PackedScene = preload("res://models/industrial/pipe-large-valve.glb")
const PipeJunctionModel: PackedScene = preload("res://models/industrial/pipe-large-junction.glb")
const WarningOrangeModel: PackedScene = preload("res://models/industrial/warning-orange.glb")
const WarningTrafficModel: PackedScene = preload("res://models/industrial/warning-traffic.glb")
const ConeModel: PackedScene = preload("res://models/industrial/cone.glb")
const BoxLargeModel: PackedScene = preload("res://models/industrial/box-large.glb")
const BoxWideModel: PackedScene = preload("res://models/industrial/box-wide.glb")
const MachineBedModel: PackedScene = preload("res://models/industrial/machine-bed.glb")
const RobotArmModel: PackedScene = preload("res://models/industrial/robot-arm-a.glb")
const HopperModel: PackedScene = preload("res://models/industrial/hopper-high-round.glb")
const ScreenModel: PackedScene = preload("res://models/industrial/screen-wide.glb")
const CatwalkModel: PackedScene = preload("res://models/industrial/catwalk-straight.glb")

var foliage_mat: ShaderMaterial
var industrial_mat: ShaderMaterial

var total_props_spawned: int = 0

func _ready() -> void:
	_init_materials()
	_decorate_world()
	print("[WorldDecorator] Successfully populated mega level with %d PS1 foliage & industrial props." % total_props_spawned)

func _init_materials() -> void:
	foliage_mat = ShaderMaterial.new()
	foliage_mat.shader = PS1_SHADER
	foliage_mat.set_shader_parameter("albedo_texture", FOLIAGE_TEX)
	foliage_mat.set_shader_parameter("jitter_resolution", 180.0)
	foliage_mat.set_shader_parameter("metallic", 0.05)
	foliage_mat.set_shader_parameter("roughness", 0.95)
	foliage_mat.set_shader_parameter("tint_color", Color(0.72, 0.78, 0.72, 1.0)) # Desaturated cold ash pine

	industrial_mat = ShaderMaterial.new()
	industrial_mat.shader = PS1_SHADER
	industrial_mat.set_shader_parameter("albedo_texture", INDUSTRIAL_TEX)
	industrial_mat.set_shader_parameter("jitter_resolution", 180.0)
	industrial_mat.set_shader_parameter("metallic", 0.40)
	industrial_mat.set_shader_parameter("roughness", 0.75)
	industrial_mat.set_shader_parameter("tint_color", Color(0.85, 0.85, 0.88, 1.0)) # Weathered slate steel

func _decorate_world() -> void:
	total_props_spawned = 0
	_spawn_sector_00_citadel_gardens()
	_spawn_sector_01_canyon_pines()
	_spawn_sector_02_slide_forest()
	_spawn_sector_03_foundry_props()
	_spawn_sector_04_highway_markers()

# --- SECTOR 00: CITADEL GARDENS & CONDUITS ---
func _spawn_sector_00_citadel_gardens() -> void:
	var root = Node3D.new()
	root.name = "Sector00_Decorations"
	add_child(root)

	# Overgrown Plaza Planters flanking start gate
	var tree_locs = [
		Vector3(-16.0, 0.0, 16.0),
		Vector3(16.0, 0.0, 16.0),
		Vector3(-22.0, 0.0, 28.0),
		Vector3(22.0, 0.0, 28.0),
		Vector3(-12.0, 0.0, 36.0),
		Vector3(12.0, 0.0, 36.0),
		Vector3(-26.0, 0.0, 6.0),
		Vector3(26.0, 0.0, 6.0),
	]

	for i in range(tree_locs.size()):
		var pos = tree_locs[i]
		var model = TreeHighModel if i % 2 == 0 else TreeModel
		var scale = Vector3.ONE * randf_range(1.6, 2.3)
		var rot = Vector3(0, randf() * TAU, 0)
		_spawn_prop(root, model, foliage_mat, pos, rot, scale, true)

		# Ground foliage around base
		_spawn_prop(root, PlantModel, foliage_mat, pos + Vector3(1.2, 0, 0.8), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.4, false)
		_spawn_prop(root, RocksLowModel, foliage_mat, pos + Vector3(-1.4, 0, -0.6), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.5, true)

	# Industrial Steam Conduits running along Citadel perimeter
	var pipe_z_positions = [-5.0, -18.0, -32.0]
	for z in pipe_z_positions:
		# West wall pipe
		_spawn_prop(root, PipeLongModel, industrial_mat, Vector3(-33.0, 0.8, z), Vector3(0, 0, 0), Vector3.ONE * 1.5, true)
		_spawn_prop(root, PipeValveModel, industrial_mat, Vector3(-33.0, 0.8, z + 3.0), Vector3(0, 0, 0), Vector3.ONE * 1.5, true)
		# East wall pipe
		_spawn_prop(root, PipeLongModel, industrial_mat, Vector3(33.0, 0.8, z), Vector3(0, 0, 0), Vector3.ONE * 1.5, true)

	# Warning cones around Hyper-Lift intake
	_spawn_prop(root, WarningTrafficModel, industrial_mat, Vector3(-5.0, 0.0, -12.0), Vector3(0, deg_to_rad(15), 0), Vector3.ONE * 1.4, true)
	_spawn_prop(root, WarningTrafficModel, industrial_mat, Vector3(5.0, 0.0, -12.0), Vector3(0, deg_to_rad(-15), 0), Vector3.ONE * 1.4, true)
	_spawn_prop(root, ConeModel, industrial_mat, Vector3(-6.5, 0.0, -9.0), Vector3.ZERO, Vector3.ONE * 1.6, false)
	_spawn_prop(root, ConeModel, industrial_mat, Vector3(6.5, 0.0, -9.0), Vector3.ZERO, Vector3.ONE * 1.6, false)

# --- SECTOR 01: VOID CANYON PINES ---
func _spawn_sector_01_canyon_pines() -> void:
	var root = Node3D.new()
	root.name = "Sector01_Decorations"
	add_child(root)

	# Clifftop pines overlooking the 300m void chasm
	var z_offsets = [-80.0, -125.0, -170.0, -215.0, -260.0, -305.0]
	for z in z_offsets:
		# West cliff edge
		var w_pos = Vector3(-46.0 + randf_range(-3.0, 3.0), 12.0, z)
		var w_scale = Vector3.ONE * randf_range(1.8, 2.7)
		_spawn_prop(root, TreeHighModel, foliage_mat, w_pos, Vector3(0, randf() * TAU, randf_range(-0.1, 0.1)), w_scale, true)
		_spawn_prop(root, RocksHighModel, foliage_mat, w_pos + Vector3(3.5, -1.0, 1.5), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.8, true)

		# East cliff edge
		var e_pos = Vector3(46.0 + randf_range(-3.0, 3.0), 12.0, z)
		var e_scale = Vector3.ONE * randf_range(1.8, 2.7)
		_spawn_prop(root, TreeHighModel, foliage_mat, e_pos, Vector3(0, randf() * TAU, randf_range(-0.1, 0.1)), e_scale, true)
		_spawn_prop(root, RocksHighModel, foliage_mat, e_pos + Vector3(-3.5, -1.0, 1.5), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.8, true)

		# Staged cable cargo boxes near crane bases
		if int(z) % 90 == 0:
			_spawn_prop(root, BoxLargeModel, industrial_mat, Vector3(-38.0, 12.0, z), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.5, true)
			_spawn_prop(root, BoxWideModel, industrial_mat, Vector3(38.0, 12.0, z), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.5, true)

# --- SECTOR 02: VELOCITY CHUTE CANYON FOREST ---
func _spawn_sector_02_slide_forest() -> void:
	var root = Node3D.new()
	root.name = "Sector02_Decorations"
	add_child(root)

	# Trees flanking the downhill slide (X around 90-110, descending from Y=62 down to Y=14)
	var steps = 14
	for i in range(steps):
		var t = float(i) / float(steps)
		var y = lerp(62.0, 14.0, t)
		var z = lerp(-95.0, 45.0, t)

		# Left shoulder trees
		var left_pos = Vector3(88.0 + randf_range(-2.0, 2.0), y, z)
		var l_scale = Vector3.ONE * randf_range(1.7, 2.5)
		_spawn_prop(root, TreeHighModel if i % 2 == 0 else TreeModel, foliage_mat, left_pos, Vector3(0, randf() * TAU, 0), l_scale, true)

		# Right shoulder trees
		var right_pos = Vector3(112.0 + randf_range(-2.0, 2.0), y, z)
		var r_scale = Vector3.ONE * randf_range(1.7, 2.5)
		_spawn_prop(root, TreeHighModel if i % 3 == 0 else TreeModel, foliage_mat, right_pos, Vector3(0, randf() * TAU, 0), r_scale, true)

		# Shrubs & low rocks between trees
		_spawn_prop(root, PlantModel, foliage_mat, left_pos + Vector3(1.5, 0, 1.0), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.4, false)
		_spawn_prop(root, PlantModel, foliage_mat, right_pos + Vector3(-1.5, 0, 1.0), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.4, false)

	# Overhead Industrial Pipe Arch crossing the Chute at mid-point
	var arch_y = 38.0
	var arch_z = -25.0
	_spawn_prop(root, PipeLongModel, industrial_mat, Vector3(92.0, arch_y, arch_z), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 2.0, true)
	_spawn_prop(root, PipeLongModel, industrial_mat, Vector3(106.0, arch_y, arch_z), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 2.0, true)
	_spawn_prop(root, PipeBendModel, industrial_mat, Vector3(116.0, arch_y, arch_z), Vector3(0, 0, deg_to_rad(-90)), Vector3.ONE * 2.0, true)

	# Warning traffic hazard markers above low slide overhangs
	_spawn_prop(root, WarningTrafficModel, industrial_mat, Vector3(96.0, 52.0, -70.0), Vector3(0, 0, 0), Vector3.ONE * 1.6, true)
	_spawn_prop(root, WarningTrafficModel, industrial_mat, Vector3(104.0, 52.0, -70.0), Vector3(0, 0, 0), Vector3.ONE * 1.6, true)

# --- SECTOR 03: INDUSTRIAL FOUNDRY & BASIN ---
func _spawn_sector_03_foundry_props() -> void:
	var root = Node3D.new()
	root.name = "Sector03_Decorations"
	add_child(root)

	# Heavy Silos & Hoppers along the western wall
	var silo_z = [110.0, 140.0, 170.0, 200.0]
	for z in silo_z:
		_spawn_prop(root, HopperModel, industrial_mat, Vector3(-55.0, 10.0, z), Vector3.ZERO, Vector3.ONE * 2.8, true)
		_spawn_prop(root, PipeJunctionModel, industrial_mat, Vector3(-55.0, 18.0, z), Vector3(0, 0, 0), Vector3.ONE * 1.8, true)

	# Manufacturing Machinery & Robotic Arms in warehouse bays
	_spawn_prop(root, MachineBedModel, industrial_mat, Vector3(-25.0, 10.0, 130.0), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 2.2, true)
	_spawn_prop(root, RobotArmModel, industrial_mat, Vector3(-25.0, 14.5, 130.0), Vector3(0, deg_to_rad(45), 0), Vector3.ONE * 1.6, true)

	_spawn_prop(root, MachineBedModel, industrial_mat, Vector3(25.0, 10.0, 160.0), Vector3(0, deg_to_rad(-90), 0), Vector3.ONE * 2.2, true)
	_spawn_prop(root, RobotArmModel, industrial_mat, Vector3(25.0, 14.5, 160.0), Vector3(0, deg_to_rad(-60), 0), Vector3.ONE * 1.6, true)

	# Cargo Crate Stacks for combat cover
	var crate_clusters = [
		Vector3(-15.0, 10.0, 115.0),
		Vector3(18.0, 10.0, 135.0),
		Vector3(-20.0, 10.0, 175.0),
		Vector3(12.0, 10.0, 195.0),
		Vector3(0.0, 10.0, 150.0)
	]
	for c in crate_clusters:
		_spawn_prop(root, BoxLargeModel, industrial_mat, c, Vector3(0, randf_range(-0.3, 0.3), 0), Vector3.ONE * 1.8, true)
		_spawn_prop(root, BoxWideModel, industrial_mat, c + Vector3(0, 2.7, 0), Vector3(0, randf_range(0.4, 1.2), 0), Vector3.ONE * 1.6, true)
		_spawn_prop(root, BoxLargeModel, industrial_mat, c + Vector3(2.2, 0, 0.4), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.5, true)

	# Industrial Catwalks overlooking the foundry combat floor
	_spawn_prop(root, CatwalkModel, industrial_mat, Vector3(-35.0, 18.0, 145.0), Vector3(0, 0, 0), Vector3.ONE * 2.5, true)
	_spawn_prop(root, CatwalkModel, industrial_mat, Vector3(-35.0, 18.0, 155.0), Vector3(0, 0, 0), Vector3.ONE * 2.5, true)
	_spawn_prop(root, ScreenModel, industrial_mat, Vector3(-34.5, 20.2, 150.0), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 1.4, false)

	# Overgrown weeds & toxic trench vegetation in cracked concrete corners
	var plant_spots = [
		Vector3(-45.0, 10.0, 125.0),
		Vector3(-42.0, 10.0, 185.0),
		Vector3(45.0, 10.0, 135.0),
		Vector3(42.0, 10.0, 175.0),
		Vector3(5.0, 10.0, 175.0),
	]
	for p in plant_spots:
		_spawn_prop(root, PlantModel, foliage_mat, p, Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.8, false)
		_spawn_prop(root, PlantModel, foliage_mat, p + Vector3(0.8, 0, 0.6), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.4, false)
		_spawn_prop(root, RocksLowModel, foliage_mat, p + Vector3(-1.0, 0, -0.5), Vector3(0, randf() * TAU, 0), Vector3.ONE * 1.6, true)

# --- SECTOR 04: BHOP HIGHWAY MARKERS ---
func _spawn_sector_04_highway_markers() -> void:
	var root = Node3D.new()
	root.name = "Sector04_Decorations"
	add_child(root)

	# Warning cones & highway barriers along the 350m straightaway (X = -95, Z from -110 to 140)
	var z_dist = -110.0
	while z_dist <= 140.0:
		# Left shoulder cones
		_spawn_prop(root, ConeModel, industrial_mat, Vector3(-107.0, 12.0, z_dist), Vector3.ZERO, Vector3.ONE * 1.8, false)
		# Right shoulder cones
		_spawn_prop(root, ConeModel, industrial_mat, Vector3(-83.0, 12.0, z_dist), Vector3.ZERO, Vector3.ONE * 1.8, false)

		# Traffic barriers every 40m
		if int(abs(z_dist)) % 40 < 15:
			_spawn_prop(root, WarningOrangeModel, industrial_mat, Vector3(-106.5, 12.0, z_dist + 5.0), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 1.4, true)
			_spawn_prop(root, WarningOrangeModel, industrial_mat, Vector3(-83.5, 12.0, z_dist + 5.0), Vector3(0, deg_to_rad(90), 0), Vector3.ONE * 1.4, true)

		z_dist += 18.0

# --- HELPER: INSTANTIATE & STYLE PROP ---
func _spawn_prop(parent: Node, scene: PackedScene, mat: Material, pos: Vector3, rot: Vector3, scale: Vector3, add_collision: bool) -> Node3D:
	if not scene:
		return null

	var instance: Node3D = scene.instantiate() as Node3D
	if not instance:
		return null

	instance.position = pos
	instance.rotation = rot
	instance.scale = scale
	parent.add_child(instance)

	total_props_spawned += 1

	# Apply PS1 nearest-neighbor jitter material override
	_apply_material_recursive(instance, mat)

	# If solid collider requested, generate a StaticBody3D with collision
	if add_collision:
		_create_prop_collision(instance)

	return instance

func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		var mesh_inst = node as MeshInstance3D
		mesh_inst.material_override = mat

	for child in node.get_children():
		_apply_material_recursive(child, mat)

func _create_prop_collision(instance: Node3D) -> void:
	var sb = StaticBody3D.new()
	sb.name = "PropCollider"
	var meshes = instance.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mesh_inst = m as MeshInstance3D
		if mesh_inst and mesh_inst.mesh:
			var shape = mesh_inst.mesh.create_convex_shape(true, false)
			if shape:
				var col = CollisionShape3D.new()
				col.shape = shape
				col.transform = mesh_inst.transform
				sb.add_child(col)
	if sb.get_child_count() > 0:
		instance.add_child(sb)
