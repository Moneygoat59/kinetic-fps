class_name ConcreteFacility
extends Node3D

const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
static var basalt_nat_tex: ImageTexture; static var basalt_pnl_tex: ImageTexture
static var basalt_norm: ImageTexture; static var metal_norm: ImageTexture; static var metal_rough: ImageTexture
static var _cache: Dictionary = {}

static func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

static func preload_models() -> void:
	for p in [
		"res://models/bunker_hangar_large.glb", "res://models/prop_substation_tower.glb",
		"res://models/prop_complex_transformer.glb", "res://models/prop_particle_accelerator.glb",
		"res://models/prop_mech_walker.glb", "res://models/prop_monolith.glb",
		"res://models/prop_reactor_core.glb", "res://models/prop_cooling_tower.glb",
		"res://models/prop_dish_large.glb", "res://models/prop_heavy_drone.glb",
		"res://models/prop_energy_core.glb", "res://models/prop_generator_large.glb",
		"res://models/prop_containment_vat.glb"
	]: _load_glb(p)

static func _load_glb(res_path: String) -> Node3D:
	if _cache.has(res_path): return _cache[res_path].duplicate()
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(res_path), state) != OK: return null
	var scn = doc.generate_scene(state) as Node3D; var tmp = scn.find_child("tmpParent", true, false)
	if tmp: for ch in tmp.get_children(): if ch is Node3D: ch.position = Vector3.ZERO
	_cache[res_path] = scn; return scn.duplicate()

static func _add_collisions(n: Node) -> void:
	if n is MeshInstance3D: (n as MeshInstance3D).create_trimesh_collision()
	for c in n.get_children(): _add_collisions(c)

var b_mat: StandardMaterial3D; var p_mat: StandardMaterial3D; var m_mat: StandardMaterial3D
var drab_mat: StandardMaterial3D; var rust_mat: StandardMaterial3D; var amber_mat: StandardMaterial3D

func build_facility(terrain: Node3D, pos_x: float = 0.0, pos_z: float = -180.0) -> void:
	_init_materials()
	var gy = terrain.get_height(pos_x, pos_z) if terrain else -0.25
	position = Vector3(pos_x, gy, pos_z)
	_create_apron()
	_create_warehouse_hangar()
	_create_exterior_props()
	_create_interior_machinery()
	_create_bollards()
	_create_amber_lighting()

func _init_materials() -> void:
	if not basalt_nat_tex: basalt_nat_tex = _tex("res://textures/dark_basalt_natural.png")
	if not basalt_pnl_tex: basalt_pnl_tex = _tex("res://textures/dark_basalt_panel_natural.png")
	if not basalt_norm: basalt_norm = _tex("res://textures/dark_basalt_normal.png")
	if not metal_norm: metal_norm = _tex("res://textures/worn_metal_normal.png")
	if not metal_rough: metal_rough = _tex("res://textures/worn_metal_roughness.png")

	b_mat = _mat(basalt_nat_tex, Color(0.85, 0.88, 0.95), 0.92, Vector3(0.2, 0.2, 0.2), true, 0.0, basalt_norm)
	p_mat = _mat(basalt_pnl_tex, Color(0.88, 0.90, 0.98), 0.85, Vector3(0.22, 0.22, 0.22), true, 0.0, basalt_norm)
	m_mat = _mat(METAL_TEX, Color(0.24, 0.26, 0.28), 0.72, Vector3.ONE, false, 0.75, metal_norm, metal_rough)
	drab_mat = _mat(METAL_TEX, Color(0.22, 0.26, 0.22), 0.80, Vector3.ONE, false, 0.50, metal_norm, metal_rough)
	rust_mat = _mat(METAL_TEX, Color(0.28, 0.23, 0.19), 0.92, Vector3.ONE, false, 0.35, metal_norm, metal_rough)
	amber_mat = StandardMaterial3D.new(); amber_mat.albedo_color = Color(1.0, 0.68, 0.12); amber_mat.emission_enabled = true
	amber_mat.emission = Color(1.0, 0.68, 0.12); amber_mat.emission_energy_multiplier = 2.4

func _mat(tex: Texture2D, col: Color, rough: float, uv_sc: Vector3 = Vector3.ONE, tri: bool = false, met: float = 0.0, norm: Texture2D = null, rough_t: Texture2D = null) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = col; m.roughness = rough; m.metallic = met
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; m.uv1_scale = uv_sc; m.uv1_triplanar = tri
	if norm: m.normal_enabled = true; m.normal_texture = norm; m.normal_scale = 1.25
	if rough_t: m.roughness_texture = rough_t
	return m

func _cylinder(pos: Vector3, rad: float, h: float, sides: int, mat: Material) -> void:
	var mi = MeshInstance3D.new(); var cm = CylinderMesh.new()
	cm.top_radius = rad; cm.bottom_radius = rad; cm.height = h; cm.radial_segments = sides
	mi.mesh = cm; mi.position = pos; mi.material_override = mat; add_child(mi)
	var sb = StaticBody3D.new(); var cs = CollisionShape3D.new(); var sh = CylinderShape3D.new()
	sh.radius = rad; sh.height = h; cs.shape = sh; cs.position = pos; sb.add_child(cs); add_child(sb)

func _create_apron() -> void:
	_cylinder(Vector3(0.0, -0.7, 5.0), 21.0, 1.6, 16, b_mat)
	_cylinder(Vector3(0.0, 0.12, 5.0), 18.5, 0.25, 16, p_mat)

func _create_warehouse_hangar() -> void:
	var hangar = _load_glb("res://models/bunker_hangar_large.glb")
	if hangar:
		hangar.position = Vector3(0.0, 0.2, -12.0); hangar.scale = Vector3(16.0, 14.0, 16.0)
		var g2 = hangar.find_child("gate2", true, false)
		if g2: g2.get_parent().remove_child(g2); g2.queue_free()
		_recolor_tree(hangar, b_mat, p_mat); _add_collisions(hangar); add_child(hangar)

func _create_exterior_props() -> void:
	# 24m High-Voltage Substation Tower with high-voltage insulator discs on left flank
	_place("res://models/prop_substation_tower.glb", Vector3(-20.0, 0.2, 10.0), Vector3(3.5, 3.5, 3.5), 20.0, m_mat, rust_mat)
	# 23m Complex Substation Transformer unit with heavy conduits and radiators
	_place("res://models/prop_complex_transformer.glb", Vector3(-18.5, 0.2, -4.0), Vector3(1.6, 1.6, 1.6), 0.0, drab_mat, rust_mat)
	# 17.5m Colossal Industrial Mech chassis slumped dormant on right flank
	_place("res://models/prop_mech_walker.glb", Vector3(16.5, 6.2, 11.0), Vector3(0.9, 0.9, 0.9), -30.0, drab_mat, m_mat)
	# 25m Brutalist Geometric Resonance Monolith with recessed channels
	_place("res://models/prop_monolith.glb", Vector3(18.0, 0.2, 1.0), Vector3(14.0, 16.0, 14.0), 15.0, b_mat, amber_mat)
	# 18m Exposed Reactor Core assembly with multi-chamber cooling loops
	_place("res://models/prop_reactor_core.glb", Vector3(15.0, 0.2, -8.0), Vector3(6.5, 6.0, 6.5), -40.0, rust_mat, amber_mat)
	# 19m Industrial Cooling Stack
	_place("res://models/prop_cooling_tower.glb", Vector3(-18.0, 0.2, -18.0), Vector3(8.5, 9.5, 8.5), 0.0, b_mat, rust_mat)
	# 8.5m Telemetry Dish on roof
	_place("res://models/prop_dish_large.glb", Vector3(10.0, 14.8, -4.0), Vector3(8.5, 8.5, 8.5), -45.0, m_mat, amber_mat)

func _create_interior_machinery() -> void:
	# 21m Unmanned Heavy Drone craft in center bay
	_place("res://models/prop_heavy_drone.glb", Vector3(0.0, 0.3, -8.0), Vector3(8.0, 7.0, 8.0), -18.0, drab_mat, rust_mat)
	# 18m Particle Accelerator Manifold with deflection coils on left wall
	_place("res://models/prop_particle_accelerator.glb", Vector3(-8.5, 0.2, -14.0), Vector3(22.0, 22.0, 22.0), 90.0, m_mat, amber_mat)
	# Concentric Gimbal Ring Energy Core at rear dais
	_place("res://models/prop_energy_core.glb", Vector3(0.0, 0.2, -18.5), Vector3(6.5, 7.5, 6.5), 45.0, m_mat, amber_mat)
	# High-output power generator on right wall
	_place("res://models/prop_generator_large.glb", Vector3(9.5, 0.2, -14.0), Vector3(5.5, 5.0, 5.5), -90.0, m_mat, amber_mat)
	# Heavy isotope containment pressure vats
	_place("res://models/prop_containment_vat.glb", Vector3(10.5, 0.2, -3.0), Vector3(5.0, 5.5, 5.0), -25.0, drab_mat, m_mat)
	_place("res://models/prop_containment_vat.glb", Vector3(-10.0, 0.2, 4.0), Vector3(4.5, 5.0, 4.5), -40.0, m_mat, rust_mat)

func _place(path: String, pos: Vector3, sc: Vector3, rot_deg: float, m1: Material, m2: Material) -> void:
	var p = _load_glb(path)
	if p:
		p.position = pos; p.scale = sc; p.rotation.y = deg_to_rad(rot_deg)
		_recolor_tree(p, m1, m2); _add_collisions(p); add_child(p)

func _create_bollards() -> void:
	for x in [-12.0, -4.0, 4.0, 12.0]: _cylinder(Vector3(x, 0.6, 17.0), 0.45, 1.2, 8, b_mat)

func _create_amber_lighting() -> void:
	var b = _omni(Vector3(0.0, 9.5, 4.5), Color(1.0, 0.68, 0.12), 5.2, 42.0, true); b.name = "EntryBeacon"
	for px in [-5.5, 5.5]: _omni(Vector3(px, 5.0, 3.5), Color(1.0, 0.65, 0.10), 2.0, 10.0)
	# Substation & Monolith exterior lights
	_omni(Vector3(-20.0, 6.0, 10.0), Color(1.0, 0.68, 0.14), 3.0, 24.0)
	_omni(Vector3(18.0, 5.0, 1.0), Color(1.0, 0.72, 0.16), 2.8, 18.0)
	_omni(Vector3(16.5, 4.0, 11.0), Color(1.0, 0.68, 0.14), 2.4, 16.0)
	# Interior bay floodlights
	_omni(Vector3(0.0, 9.0, -8.0), Color(1.0, 0.66, 0.12), 3.4, 30.0)
	_omni(Vector3(0.0, 8.0, -18.0), Color(1.0, 0.68, 0.14), 3.6, 26.0)

func _omni(pos: Vector3, col: Color, eng: float, rng: float, sh: bool = false) -> OmniLight3D:
	var l = OmniLight3D.new(); l.position = pos; l.light_color = col; l.light_energy = eng; l.omni_range = rng; l.shadow_enabled = sh; add_child(l); return l

func _recolor_tree(n: Node, primary: Material, secondary: Material) -> void:
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			mi.set_surface_override_material(s, secondary if s % 2 == 1 else primary)
	for c in n.get_children(): _recolor_tree(c, primary, secondary)
