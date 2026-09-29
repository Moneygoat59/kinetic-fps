class_name SiloBlast
extends RefCounted
## What the launch did to the forest round Missile Silo 00: a scorch decal over the apron and the ground, and a ring of
## dead trees laid flat, crowns pointing away from the bore, among snapped stumps, beyond the apron. Built once when the silo enters the tree
## (MissileSilo._ready, so its final rotation is known); a clear corridor stays open in front for the approach.

const TREES: Array[PackedScene] = [preload("res://models/dead_forest/dead_tree_1.glb"),
	preload("res://models/dead_forest/dead_tree_3.glb"), preload("res://models/dead_forest/dead_tree_5.glb")]
const STUMP := preload("res://models/dead_forest/trunk-long.glb")   # 1 m standing snapped trunk
const CHAR := Color(0.2, 0.18, 0.17)
const SCORCH_SIZE := 290.0
const SCORCH_PX := 128
const SCORCH_ALPHA := 0.8
const RING := Vector2(84.0, 132.0)      # flattened trees between these radii
const TREE_COUNT := 34
const STUMP_COUNT := 22
const CORRIDOR := 0.16                  # rad either side of the approach (local +Z) kept clear
const SEED := 7300


static func lay(silo: Node3D, terrain: Node3D, props: Node3D) -> void:
	if silo == null or not silo.is_inside_tree():
		return
	_scorch(silo)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var char_mat := StandardMaterial3D.new()
	char_mat.albedo_color = CHAR
	char_mat.roughness = 1.0
	char_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var wood: Array = props.get("wood_mats") if props and props.get("wood_mats") else []
	for i in TREE_COUNT + STUMP_COUNT:
		var a := rng.randf() * TAU
		if absf(wrapf(a, -PI, PI)) < CORRIDOR:
			continue
		var r := rng.randf_range(RING.x, RING.y)
		var is_tree := i < TREE_COUNT
		var scene: PackedScene = TREES[rng.randi() % TREES.size()] if is_tree else STUMP
		var mat: Material = char_mat if wood.is_empty() else wood[rng.randi() % wood.size()]
		_fell(silo, terrain, scene, a + rng.randf_range(-0.2, 0.2), r, rng.randf_range(1.2, 1.9) if is_tree else rng.randf_range(1.3, 2.4), is_tree, mat)


## Launch scorch over apron and ground: dark at the rim, blast rays fanning out, gone by the blast ring's edge.
static func _scorch(silo: Node3D) -> void:
	var img := Image.create(SCORCH_PX, SCORCH_PX, false, Image.FORMAT_RGBA8)
	var rays := FastNoiseLite.new()
	rays.seed = SEED
	rays.frequency = 0.9
	var half := SCORCH_PX * 0.5
	for y in SCORCH_PX:
		for x in SCORCH_PX:
			var d := Vector2(x - half, y - half) / half
			var r := d.length()
			var ray := 0.55 + 0.45 * rays.get_noise_1d(atan2(d.y, d.x) * 6.0)
			var a := clampf(1.0 - smoothstep(0.35, 0.95, r) * (1.4 - ray), 0.0, 1.0) * smoothstep(1.0, 0.8, r) * SCORCH_ALPHA
			img.set_pixel(x, y, Color(0.02, 0.015, 0.012, a))
	var decal := Decal.new()
	decal.texture_albedo = ImageTexture.create_from_image(img)
	decal.size = Vector3(SCORCH_SIZE, 24.0, SCORCH_SIZE)
	silo.add_child(decal)


## One felled tree (lying along the radial, crown outward) or snapped stump at local angle a (0 = approach, local +Z), radius r.
static func _fell(silo: Node3D, terrain: Node3D, scene: PackedScene, a: float, r: float, sc: float, is_tree: bool, mat: Material) -> void:
	var out := Vector3(sin(a), 0.0, cos(a))
	var local := out * r
	var world := silo.to_global(local)
	var gy: float = terrain.get_height(world.x, world.z) if terrain else silo.global_position.y
	var inst := scene.instantiate() as Node3D
	silo.add_child(inst)
	var yaw := Basis(Vector3.UP, a * 7.3).scaled(Vector3.ONE * sc)             # upright, as the forest spawns them
	if is_tree:                                                               # tipped over: crown away from the bore
		var world_out := (silo.global_transform.basis * out).normalized()
		inst.global_transform = Transform3D(Basis(Vector3.UP.cross(world_out).normalized(), PI * 0.5) * yaw, Vector3(world.x, gy + 0.3, world.z))
	else:
		inst.global_transform = Transform3D(yaw, Vector3(world.x, gy - 0.1, world.z))
	for child in inst.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).material_override = mat
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.35 * sc
	cyl.height = (6.0 if is_tree else 1.0) * sc
	shape.shape = cyl
	shape.position = Vector3(0.0, cyl.height * 0.5, 0.0)
	body.add_child(shape)
	inst.add_child(body)
