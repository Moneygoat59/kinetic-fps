class_name BunkerBuilder
extends RefCounted

const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
static var concrete_tex: ImageTexture; static var concrete_panel_tex: ImageTexture; static var concrete_norm: ImageTexture
static var basalt_tex: ImageTexture; static var basalt_panel_tex: ImageTexture; static var basalt_norm: ImageTexture
static var meter_tex: ImageTexture; static var hazard_tex: ImageTexture; static var metal_norm: ImageTexture
static var crt_amber_tex: ImageTexture; static var crt_static_tex: ImageTexture; static var danger_tex: ImageTexture
static var crt_radar_tex: ImageTexture; static var graffiti_tex: ImageTexture; static var luminaire_tex: ImageTexture
static var _cache: Dictionary = {}

static func _init_tex() -> void:
	if concrete_tex: return
	concrete_tex = _tex("res://textures/distressed_dark_concrete.png")
	concrete_panel_tex = _tex("res://textures/distressed_concrete_panel.png")
	concrete_norm = _tex("res://textures/distressed_dark_concrete_normal.png")
	basalt_tex = _tex("res://textures/dark_basalt_natural.png")
	basalt_panel_tex = _tex("res://textures/dark_basalt_panel.png")
	basalt_norm = _tex("res://textures/dark_basalt_normal.png")
	meter_tex = _tex("res://textures/device_meter_analog.png"); hazard_tex = _tex("res://textures/hazard_stripes.png")
	metal_norm = _tex("res://textures/worn_metal_normal.png")
	crt_amber_tex = _tex("res://textures/bunker_crt_amber.png")
	crt_static_tex = _tex("res://textures/bunker_crt_static.png")
	danger_tex = _tex("res://textures/bunker_danger_sign.png")
	crt_radar_tex = _tex("res://textures/silo_crt_radar.png")
	graffiti_tex = _tex("res://textures/silo_graffiti_panel.png")
	luminaire_tex = _tex("res://textures/silo_luminaire_amber.png")

static func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

static func load_glb(res_path: String) -> Node3D:
	if _cache.has(res_path): return _cache[res_path].duplicate()
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(res_path), state) != OK: return null
	var scn = doc.generate_scene(state) as Node3D; var tmp = scn.find_child("tmpParent", true, false)
	if tmp: for ch in tmp.get_children(): if ch is Node3D: ch.position = Vector3.ZERO
	_cache[res_path] = scn; return scn.duplicate()

static func add_collisions(n: Node) -> void:
	if n is MeshInstance3D: (n as MeshInstance3D).create_trimesh_collision()
	for c in n.get_children(): add_collisions(c)

static func recolor(n: Node, primary: Material, secondary: Material) -> void:
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			mi.set_surface_override_material(s, secondary if s % 2 == 1 else primary)
	for c in n.get_children(): recolor(c, primary, secondary)

static func mat(tex: Texture2D, col: Color, rough: float, met: float = 0.0, uv: Vector3 = Vector3.ONE, norm: Texture2D = null) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = col; m.roughness = rough; m.metallic = met
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; m.uv1_scale = uv; m.uv1_triplanar = true
	if norm: m.normal_enabled = true; m.normal_texture = norm; m.normal_scale = 1.0
	return m

static func mat_concrete() -> StandardMaterial3D:
	_init_tex(); return mat(concrete_tex, Color(0.92, 0.94, 0.96), 0.92, 0.0, Vector3(0.35, 0.35, 0.35), concrete_norm)

static func mat_concrete_panel() -> StandardMaterial3D:
	_init_tex(); return mat(concrete_panel_tex, Color(0.92, 0.94, 0.96), 0.88, 0.0, Vector3(0.5, 0.5, 0.5), concrete_norm)

static func mat_basalt() -> StandardMaterial3D:
	_init_tex(); return mat(basalt_tex if basalt_tex else concrete_tex, Color(0.72, 0.74, 0.78), 0.92, 0.05, Vector3(0.35, 0.35, 0.35), basalt_norm if basalt_norm else concrete_norm)

static func mat_basalt_panel() -> StandardMaterial3D:
	_init_tex(); return mat(basalt_panel_tex if basalt_panel_tex else concrete_panel_tex, Color(0.75, 0.77, 0.82), 0.88, 0.05, Vector3(0.45, 0.45, 0.45), basalt_norm if basalt_norm else concrete_norm)

static func mat_panel() -> StandardMaterial3D:
	return mat_basalt_panel()

static func mat_metal() -> StandardMaterial3D:
	_init_tex(); return mat(METAL_TEX, Color(0.42, 0.44, 0.48), 0.70, 0.80, Vector3.ONE, metal_norm)

static func mat_dark_iron() -> StandardMaterial3D:
	_init_tex(); return mat(METAL_TEX, Color(0.28, 0.30, 0.34), 0.75, 0.82, Vector3(1.8, 1.8, 1.8), metal_norm)

static func mat_blast_door() -> StandardMaterial3D:
	_init_tex(); return mat(METAL_TEX, Color(0.36, 0.38, 0.42), 0.72, 0.85, Vector3(1.5, 1.5, 1.5), metal_norm)

static func mat_hazard() -> StandardMaterial3D:
	_init_tex(); var m = mat(hazard_tex if hazard_tex else METAL_TEX, Color(1.0, 0.92, 0.25), 0.65, 0.4, Vector3(4.0, 1.0, 4.0))
	m.uv1_triplanar = false; return m

static func mat_glow(col: Color, mult: float = 2.4, tex: Texture2D = null) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = col; m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = mult
	if tex: m.albedo_texture = tex; m.emission_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_visor(col: Color = Color(1.0, 0.65, 0.10)) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 4.5
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return m

static func mat_crt_amber() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = crt_amber_tex; m.albedo_color = Color(1.0, 1.0, 1.0)
	m.emission_enabled = true; m.emission_texture = crt_amber_tex
	m.emission = Color(1.0, 0.72, 0.18); m.emission_energy_multiplier = 3.2
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_crt_static() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = crt_static_tex; m.albedo_color = Color(0.95, 1.0, 0.95)
	m.emission_enabled = true; m.emission_texture = crt_static_tex
	m.emission = Color(0.7, 0.85, 0.75); m.emission_energy_multiplier = 2.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_danger() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = danger_tex; m.albedo_color = Color(1.0, 1.0, 1.0)
	m.roughness = 0.55; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_cable() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.35, 0.08); m.roughness = 0.85; m.metallic = 0.1; return m

static func mat_crt_radar() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = crt_radar_tex; m.albedo_color = Color(1.0, 1.0, 1.0)
	m.emission_enabled = true; m.emission_texture = crt_radar_tex
	m.emission = Color(0.35, 1.0, 0.45); m.emission_energy_multiplier = 3.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_graffiti() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = graffiti_tex; m.albedo_color = Color(1.0, 1.0, 1.0)
	m.roughness = 0.75; m.metallic = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_luminaire() -> StandardMaterial3D:
	_init_tex(); var m = StandardMaterial3D.new()
	m.albedo_texture = luminaire_tex; m.albedo_color = Color(1.0, 1.0, 1.0)
	m.emission_enabled = true; m.emission_texture = luminaire_tex
	m.emission = Color(1.0, 0.68, 0.16); m.emission_energy_multiplier = 4.2
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; return m

static func mat_sludge() -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.08, 0.11, 0.07, 0.95); m.roughness = 0.12; m.metallic = 0.5
	m.clearcoat_enabled = true; m.clearcoat = 1.0; return m

static func mat_rust_gantry() -> StandardMaterial3D:
	_init_tex(); var gt = _tex("res://textures/floor_grate_rust.png")
	return mat(gt if gt else METAL_TEX, Color(0.55, 0.40, 0.32), 0.85, 0.65, Vector3(2.5, 2.5, 2.5), metal_norm)

static func mat_basalt_strata() -> StandardMaterial3D:
	_init_tex()
	return mat(basalt_tex if basalt_tex else concrete_tex, Color(0.68, 0.70, 0.74), 0.95, 0.05, Vector3(0.2, 0.1, 0.2), basalt_norm if basalt_norm else concrete_norm)

static func set_nearest(n: Node) -> void:
	if not n or DisplayServer.get_name() == "headless": return
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				var m = mi.get_surface_override_material(s)
				if not m: m = mi.mesh.surface_get_material(s)
				if m is StandardMaterial3D:
					var dup = m.duplicate() as StandardMaterial3D
					dup.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					mi.set_surface_override_material(s, dup)
	for c in n.get_children(): set_nearest(c)

static func spawn(parent: Node3D, path: String, pos: Vector3, sc: Vector3 = Vector3.ONE, rot_y: float = 0.0, m1: Material = null, m2: Material = null, col: bool = true) -> Node3D:
	var node = load_glb(path); if not node: return null
	node.position = pos; node.scale = sc; node.rotation.y = rot_y
	if m1 and m2: recolor(node, m1, m2)
	elif m1: recolor(node, m1, m1)
	else: set_nearest(node)
	if col: add_collisions(node)
	parent.add_child(node); return node

static func mat_grate() -> StandardMaterial3D:
	_init_tex(); var gt = _tex("res://textures/floor_grate_rust.png")
	return mat(gt if gt else concrete_panel_tex, Color(0.75, 0.72, 0.70), 0.8, 0.5, Vector3(2.0, 1.0, 8.0), metal_norm)

static func box(parent: Node3D, pos: Vector3, sz: Vector3, m: Material, rot_y: float = 0.0, col: bool = true) -> MeshInstance3D:
	return box_rot(parent, pos, sz, Vector3(0.0, rot_y, 0.0), m, col)

static func box_rot(parent: Node3D, pos: Vector3, sz: Vector3, rot: Vector3, m: Material, col: bool = true) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.position = pos; mi.rotation = rot; mi.material_override = m; parent.add_child(mi)
	if col:
		var sb = StaticBody3D.new(); var cs = CollisionShape3D.new(); var sh = BoxShape3D.new()
		sh.size = sz; cs.shape = sh; cs.position = pos; sb.rotation = rot; sb.add_child(cs); parent.add_child(sb)
	return mi

static func cylinder(parent: Node3D, pos: Vector3, rt: float, rb: float, h: float, sides: int, m: Material, col: bool = true) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var cm = CylinderMesh.new()
	cm.top_radius = rt; cm.bottom_radius = rb; cm.height = h; cm.radial_segments = sides
	mi.mesh = cm; mi.position = pos; mi.material_override = m; parent.add_child(mi)
	if col:
		var sb = StaticBody3D.new(); var cs = CollisionShape3D.new(); var sh = CylinderShape3D.new()
		sh.radius = maxf(rt, rb); sh.height = h; cs.shape = sh; cs.position = pos; sb.add_child(cs); parent.add_child(sb)
	return mi

static func omni(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float) -> OmniLight3D:
	var l = OmniLight3D.new(); l.position = pos; l.light_color = col; l.light_energy = energy; l.omni_range = rng
	parent.add_child(l); return l
