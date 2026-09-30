class_name AbyssFog
extends RefCounted
## Makes a pit read bottomless in the pale-fog forest: every imported material under a node is rebuilt as an abyss-fog
## shader (shaders/abyss_fog*.gdshader) whose fog matches the level's depth fog at the rim and turns black with depth.
## Per-instance surface overrides, so the shared model stays untouched. Reusable for any shaft, pit or cave mouth:
##   AbyssFog.apply(model.get_node("silo_bore"), global_position.y, get_world_3d().environment)
## Animated surfaces (scrolling liquid, pulsing glow) are then driven through AbyssFog.find(...).set_shader_parameter.

const OPAQUE := preload("res://shaders/abyss_fog.gdshader")
const BLEND := preload("res://shaders/abyss_fog_blend.gdshader")
const GLOW_REACH := 0.4     # emissive surfaces: fog takes them this much slower, so glowing lines lead the eye down


## Converts every surface under `node`. rim_y = world height where the pit starts; env = the level Environment whose depth
## fog the rim blends into (null: defaults); look = shader parameter overrides for this pit (abyss_depth, abyss_end,
## ambient_floor: a deep shaft that should read to the bottom). Returns the number of surfaces converted.
static func apply(node: Node, rim_y: float, env: Environment = null, look: Dictionary = {}) -> int:
	if node == null:
		return 0
	var made := {}
	return _walk(node, rim_y, env, made, look)


## apply() over several nodes with one material cache: many instances of the same kit pieces share the converted materials.
## keep_live: leave surfaces that already carry an override alone (live kit: KitProp's screens and blinking lamps,
## O73Kit.own_material), so whatever animates them keeps working.
static func apply_many(nodes: Array[Node], rim_y: float, env: Environment = null, look: Dictionary = {},
		keep_live := false) -> int:
	var made := {}
	var count := 0
	for node in nodes:
		if node:
			count += _walk(node, rim_y, env, made, look, keep_live)
	return count


static func _walk(node: Node, rim_y: float, env: Environment, made: Dictionary, look: Dictionary, keep_live := false) -> int:
	var count := 0
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if src == null or (keep_live and mi.get_surface_override_material(i) != null):
				continue
			if not made.has(src):
				made[src] = _convert(src, rim_y, env, look)
			mi.set_surface_override_material(i, made[src])
			count += 1
	var mmi := node as MultiMeshInstance3D           # KitBatch output: no per-surface overrides, so fog a copy of its mesh
	if mmi and mmi.multimesh and mmi.multimesh.mesh:
		var mesh := mmi.multimesh.mesh.duplicate() as Mesh
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as BaseMaterial3D
			if src == null:
				continue
			if not made.has(src):
				made[src] = _convert(src, rim_y, env, look)
			mesh.surface_set_material(i, made[src])
			count += 1
		mmi.multimesh.mesh = mesh
	for child in node.get_children():
		count += _walk(child, rim_y, env, made, look, keep_live)
	return count


static func _convert(src: BaseMaterial3D, rim_y: float, env: Environment, look: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.resource_name = src.resource_name
	m.shader = BLEND if src.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED else OPAQUE
	m.set_shader_parameter("albedo_color", src.albedo_color)
	m.set_shader_parameter("use_tex", src.albedo_texture != null)
	if src.albedo_texture:
		m.set_shader_parameter("albedo_tex", src.albedo_texture)
	m.set_shader_parameter("use_vcol", src.vertex_color_use_as_albedo)
	if src.emission_enabled:
		m.set_shader_parameter("emission_color", src.emission)
		m.set_shader_parameter("emission_energy", src.emission_energy_multiplier)
		m.set_shader_parameter("use_emission_tex", src.emission_texture != null)
		if src.emission_texture:
			m.set_shader_parameter("emission_tex", src.emission_texture)
		m.set_shader_parameter("reach", GLOW_REACH)
	m.set_shader_parameter("rim_y", rim_y)
	if env and env.fog_enabled:
		m.set_shader_parameter("surface_fog", env.fog_light_color * env.fog_light_energy)
		m.set_shader_parameter("fog_begin", env.fog_depth_begin)
		m.set_shader_parameter("fog_end", env.fog_depth_end)
		m.set_shader_parameter("fog_curve", env.fog_depth_curve)
	for param in look:
		m.set_shader_parameter(param, look[param])
	return m


## The converted material named `mat_name` under `node` (first match), or null.
static func find(node: Node, mat_name: String) -> ShaderMaterial:
	var mi := node as MeshInstance3D
	if mi and mi.mesh:
		for i in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(i) as ShaderMaterial
			if m and m.resource_name == mat_name:
				return m
	for child in node.get_children():
		var found := find(child, mat_name)
		if found:
			return found
	return null
