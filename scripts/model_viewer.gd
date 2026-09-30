class_name ModelViewer
extends Node3D

const FACILITY_SCRIPT = preload("res://scripts/concrete_facility.gd")
const BUNKER_SCRIPT = preload("res://scripts/small_bunker.gd")
const PYLON_SCRIPT = preload("res://scripts/nuclear_pylon.gd")
const SILO_SCRIPT = preload("res://scripts/silo/missile_silo.gd")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")

var cam: Camera3D; var cam_rot: Vector2 = Vector2.ZERO; var move_speed: float = 16.0
var mouse_captured: bool = true; var exhibits: Array[Dictionary] = []; var label_ui: Label
var m_mat: StandardMaterial3D; var rust_mat: StandardMaterial3D; var b_mat: StandardMaterial3D; var amber_mat: StandardMaterial3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_setup_materials(); _setup_environment(); _setup_camera(); _setup_floor(); _setup_exhibits(); _setup_ui()

func _setup_materials() -> void:
	var b_norm = _tex("res://textures/dark_basalt_normal.png"); var m_norm = _tex("res://textures/worn_metal_normal.png")
	var m_rough = _tex("res://textures/worn_metal_roughness.png"); var b_tex = _tex("res://textures/dark_basalt_natural.png")
	b_mat = _mat(b_tex, Color(0.85, 0.88, 0.95), 0.92, Vector3(0.2, 0.2, 0.2), true, 0.0, b_norm)
	m_mat = _mat(METAL_TEX, Color(0.24, 0.26, 0.28), 0.72, Vector3.ONE, false, 0.75, m_norm, m_rough)
	rust_mat = _mat(METAL_TEX, Color(0.28, 0.23, 0.19), 0.92, Vector3.ONE, false, 0.35, m_norm, m_rough)
	amber_mat = StandardMaterial3D.new(); amber_mat.albedo_color = Color(1.0, 0.68, 0.12); amber_mat.emission_enabled = true
	amber_mat.emission = Color(1.0, 0.68, 0.12); amber_mat.emission_energy_multiplier = 2.4

func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

func _mat(tex: Texture2D, col: Color, rough: float, uv: Vector3, tri: bool, met: float, norm: Texture2D = null, rough_t: Texture2D = null) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = col; m.roughness = rough; m.metallic = met
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; m.uv1_scale = uv; m.uv1_triplanar = tri
	if norm: m.normal_enabled = true; m.normal_texture = norm; m.normal_scale = 1.25
	if rough_t: m.roughness_texture = rough_t
	return m

func _setup_environment() -> void:
	var env = Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.08, 0.09, 0.11)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.24, 0.26, 0.30); env.ambient_light_energy = 1.1; env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-42.0, 38.0, 0.0); sun.light_color = Color(1.0, 0.94, 0.86); sun.light_energy = 1.6; sun.shadow_enabled = true; add_child(sun)
	var rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-25.0, -145.0, 0.0); rim.light_color = Color(1.0, 0.70, 0.20); rim.light_energy = 0.6; add_child(rim)

func _setup_camera() -> void:
	cam = Camera3D.new(); cam.position = Vector3(0.0, 6.0, 28.0); cam.current = true; cam.near = 0.05; cam.far = 700.0; add_child(cam)

func _setup_floor() -> void:
	var floor_mi = MeshInstance3D.new(); var plane = PlaneMesh.new(); plane.size = Vector2(400.0, 400.0); floor_mi.mesh = plane
	var mat = StandardMaterial3D.new(); mat.albedo_color = Color(0.11, 0.12, 0.14); mat.roughness = 0.9; mat.metallic = 0.1; mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var norm = Image.load_from_file(ProjectSettings.globalize_path("res://textures/dark_basalt_normal.png"))
	if norm and not norm.is_empty():
		mat.normal_enabled = true; mat.normal_texture = ImageTexture.create_from_image(norm); mat.normal_scale = 0.8; mat.uv1_scale = Vector3(45.0, 45.0, 45.0)
	floor_mi.material_override = mat; add_child(floor_mi)

func _setup_exhibits() -> void:
	# 1: 24m Substation Tower & Heavy Transformer
	_place("res://models/prop_substation_tower.glb", Vector3(-55.0, 0.0, 0.0), Vector3(3.5, 3.5, 3.5), 20.0, m_mat, rust_mat)
	_place("res://models/prop_complex_transformer.glb", Vector3(-42.0, 0.0, 0.0), Vector3(1.6, 1.6, 1.6), 0.0, m_mat, rust_mat)
	_omni(Vector3(-48.5, 8.0, 5.0), Color(1.0, 0.68, 0.15), 4.0, 30.0)
	exhibits.append({"name": "24m Substation Tower & Transformer", "pos": Vector3(-48.5, 8.0, 30.0), "target": Vector3(-48.5, 6.0, 0.0)})
	# 2: 18m Particle Accelerator & Pressure Vats
	_place("res://models/prop_particle_accelerator.glb", Vector3(-12.0, 0.0, 0.0), Vector3(22.0, 22.0, 22.0), 90.0, m_mat, amber_mat)
	_place("res://models/prop_containment_vat.glb", Vector3(-24.0, 0.0, 0.0), Vector3(5.5, 6.0, 5.5), -20.0, rust_mat, m_mat)
	_omni(Vector3(-18.0, 5.0, 4.0), Color(1.0, 0.72, 0.16), 3.5, 25.0)
	exhibits.append({"name": "18m Particle Accelerator & Vats", "pos": Vector3(-18.0, 6.0, 22.0), "target": Vector3(-18.0, 4.0, 0.0)})
	# 3: Concentric Gimbal Energy Core & Multi-Chamber Reactor Core
	_place("res://models/prop_energy_core.glb", Vector3(18.0, 0.0, 0.0), Vector3(7.0, 8.0, 7.0), 45.0, m_mat, amber_mat)
	_place("res://models/prop_reactor_core.glb", Vector3(32.0, 0.0, 0.0), Vector3(6.5, 6.0, 6.5), -40.0, rust_mat, amber_mat)
	_omni(Vector3(25.0, 5.0, 4.0), Color(1.0, 0.70, 0.16), 3.5, 25.0)
	exhibits.append({"name": "Concentric Energy Core & Reactor", "pos": Vector3(25.0, 7.0, 22.0), "target": Vector3(25.0, 4.0, 0.0)})
	# 4: 25m Brutalist Resonance Monolith & 19m Cooling Stack
	_place("res://models/prop_monolith.glb", Vector3(60.0, 0.0, 0.0), Vector3(14.0, 16.0, 14.0), 15.0, b_mat, amber_mat)
	_place("res://models/prop_cooling_tower.glb", Vector3(76.0, 0.0, 0.0), Vector3(8.5, 9.5, 8.5), 0.0, b_mat, rust_mat)
	_omni(Vector3(68.0, 6.0, 5.0), Color(1.0, 0.75, 0.20), 3.5, 28.0)
	exhibits.append({"name": "25m Monolith & Cooling Stack", "pos": Vector3(68.0, 10.0, 26.0), "target": Vector3(68.0, 6.0, 0.0)})
	# 5: Full Concrete Facility Complex
	var fac = FACILITY_SCRIPT.new(); fac.build_facility(null, 0.0, -130.0); add_child(fac)
	exhibits.append({"name": "Full Facility & Warehouse Bay", "pos": Vector3(0.0, 16.0, -85.0), "target": Vector3(0.0, 10.0, -135.0)})
	# 6: 17.5m Slumped Industrial Mech Chassis & Heavy Crawler
	_place("res://models/prop_mech_walker.glb", Vector3(-45.0, 6.0, -45.0), Vector3(0.9, 0.9, 0.9), -30.0, rust_mat, m_mat)
	_place("res://models/prop_turret_walker.glb", Vector3(-20.0, 0.0, -45.0), Vector3(9.5, 9.5, 9.5), 30.0, m_mat, amber_mat)
	_omni(Vector3(-32.5, 6.0, -40.0), Color(1.0, 0.68, 0.14), 3.2, 22.0)
	exhibits.append({"name": "17.5m Slumped Mech & Crawler", "pos": Vector3(-32.5, 7.0, -25.0), "target": Vector3(-32.5, 4.0, -45.0)})
	# 7: 21m Heavy Drone Craft & Deep-Space Telemetry Dish
	_place("res://models/prop_heavy_drone.glb", Vector3(15.0, 0.2, -45.0), Vector3(8.0, 7.0, 8.0), -20.0, rust_mat, m_mat)
	_place("res://models/prop_dish_large.glb", Vector3(36.0, 0.0, -45.0), Vector3(8.5, 8.5, 8.5), -45.0, m_mat, amber_mat)
	_place("res://models/prop_generator_large.glb", Vector3(25.0, 0.0, -45.0), Vector3(5.5, 5.0, 5.5), -90.0, m_mat, amber_mat)
	_omni(Vector3(25.0, 5.0, -40.0), Color(1.0, 0.70, 0.16), 3.5, 24.0)
	exhibits.append({"name": "21m Drone, Dish & Generator", "pos": Vector3(25.0, 8.0, -25.0), "target": Vector3(25.0, 4.0, -45.0)})
	# 8: Small Radar Bunker Complex
	var b = BUNKER_SCRIPT.new(); b.build_bunker(null, -25.0, 40.0); add_child(b)
	exhibits.append({"name": "Small Radar Bunker Complex", "pos": Vector3(-25.0, 3.5, 52.0), "target": Vector3(-25.0, 1.5, 40.0)})
	# 9: Analog Field Tracker & Waypoint Pylon
	_place("res://models/finder_device.glb", Vector3(15.0, 1.3, 40.0), Vector3(1.6, 1.6, 1.6), 25.0)
	var pylon = PYLON_SCRIPT.new(); pylon.build_pylon(null, 22.0, 40.0); pylon.set_station_active(true); add_child(pylon)
	_omni(Vector3(18.5, 1.8, 42.0), Color(1.0, 0.72, 0.16), 2.2, 8.0)
	exhibits.append({"name": "Field Tracker & Waypoint Pylon", "pos": Vector3(18.5, 2.0, 46.0), "target": Vector3(18.5, 1.5, 40.0)})
	# 10: Colossal Basalt Missile Silo Complex (Abandoned)
	var silo = SILO_SCRIPT.new(); silo.build_silo(null, 0.0, 300.0); add_child(silo)   # past the floor: 164 m blast ring
	exhibits.append({"name": "Missile Silo 00", "pos": Vector3(-62.0, 38.0, 405.0), "target": Vector3(0.0, 0.0, 300.0)})

func _place(path: String, pos: Vector3, sc: Vector3, rot_y: float, m1: Material = null, m2: Material = null) -> Node3D:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(path), state) != OK: return null
	var scn = doc.generate_scene(state) as Node3D; scn.position = pos; scn.scale = sc; scn.rotation.y = deg_to_rad(rot_y)
	if m1: _recolor_tree(scn, m1, m2 if m2 else m1)
	add_child(scn); return scn

func _recolor_tree(n: Node, primary: Material, secondary: Material) -> void:
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		for s in range(mi.mesh.get_surface_count() if mi.mesh else 0):
			mi.set_surface_override_material(s, secondary if s % 2 == 1 else primary)
	for c in n.get_children(): _recolor_tree(c, primary, secondary)

func _omni(pos: Vector3, col: Color, eng: float, rng: float) -> OmniLight3D:
	var l = OmniLight3D.new(); l.position = pos; l.light_color = col; l.light_energy = eng; l.omni_range = rng; add_child(l); return l

func _setup_ui() -> void:
	var cv = CanvasLayer.new(); cv.layer = 100; add_child(cv)
	label_ui = Label.new()
	label_ui.text = "=== UNFAMILIAR SPECULATIVE MACHINERY SHOWROOM ===\nWASD: Move | Mouse: Look | Shift: Fast | Space/C: Up/Down\n[1-9, 0]: Teleport to Exhibit | Esc: Toggle Cursor"
	label_ui.position = Vector2(20, 20); label_ui.modulate = Color(1.0, 0.82, 0.30); cv.add_child(label_ui)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not mouse_captured:
		mouse_captured = true; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			mouse_captured = !mouse_captured; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
		elif (event.keycode >= KEY_1 and event.keycode <= KEY_9) or event.keycode == KEY_0:
			var idx = 9 if event.keycode == KEY_0 else (event.keycode - KEY_1)
			if idx < exhibits.size():
				cam.position = exhibits[idx]["pos"]; cam.look_at(exhibits[idx]["target"], Vector3.UP)
				cam_rot.x = cam.rotation.x; cam_rot.y = cam.rotation.y
				label_ui.text = "=== EXHIBIT %d: %s ===\nWASD: Move | Mouse: Look | Shift: Fast | Space/C: Up/Down\n[1-9, 0]: Teleport | Esc: Cursor" % [idx + 1, exhibits[idx]["name"]]
	if mouse_captured and event is InputEventMouseMotion:
		cam_rot.y -= event.relative.x * 0.003; cam_rot.x = clampf(cam_rot.x - event.relative.y * 0.003, -1.45, 1.45)
		cam.rotation = Vector3(cam_rot.x, cam_rot.y, 0.0)

func _process(delta: float) -> void:
	if not mouse_captured: return
	var dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): dir += cam.global_transform.basis.z
	if Input.is_key_pressed(KEY_A): dir -= cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): dir += cam.global_transform.basis.x
	if Input.is_key_pressed(KEY_SPACE): dir += Vector3.UP; if Input.is_key_pressed(KEY_C): dir += Vector3.DOWN
	var spd = move_speed * (3.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	if dir.length_squared() > 0.001: cam.position += dir.normalized() * spd * delta

