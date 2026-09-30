extends SceneTree

var frame = 0
var root_node: Node3D
var cam: Camera3D
var c_mat: StandardMaterial3D
var cp_mat: StandardMaterial3D
var m_mat: StandardMaterial3D
var glow_amber: StandardMaterial3D
var glow_visor: StandardMaterial3D
var grate_mat: StandardMaterial3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	root_node = Node3D.new()
	root.add_child(root_node)
	_init_materials()
	_build_bunker()
	
	cam = Camera3D.new()
	cam.current = true
	root_node.add_child(cam)
	
	# Add natural directional sun light
	var sun = DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(135.0), 0.0)
	sun.light_color = Color(0.85, 0.85, 0.90)
	sun.light_energy = 1.2
	root_node.add_child(sun)
	
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.25, 0.28, 0.32)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.38, 0.42)
	e.ambient_light_energy = 1.0
	env.environment = e
	root_node.add_child(env)

func _init_materials() -> void:
	var BunkerBuilder = load("res://scripts/bunker_builder.gd")
	c_mat = BunkerBuilder.mat_concrete()
	cp_mat = BunkerBuilder.mat_concrete_panel()
	m_mat = BunkerBuilder.mat_metal()
	glow_amber = BunkerBuilder.mat_glow(Color(1.0, 0.72, 0.15), 3.0, BunkerBuilder.meter_tex)
	glow_visor = BunkerBuilder.mat_glow(Color(1.0, 0.65, 0.12), 4.2)
	var grate_tex = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://textures/floor_grate_rust.png")))
	grate_mat = BunkerBuilder.mat(grate_tex, Color(0.75, 0.72, 0.70), 0.8, 0.5, Vector3(2.0, 1.0, 8.0))

func _box(pos: Vector3, sz: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.position = pos; mi.rotation = rot; mi.material_override = mat
	root_node.add_child(mi)
	return mi

func _cyl(pos: Vector3, rt: float, rb: float, h: float, sides: int, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var cm = CylinderMesh.new()
	cm.top_radius = rt; cm.bottom_radius = rb; cm.height = h; cm.radial_segments = sides
	mi.mesh = cm; mi.position = pos; mi.material_override = mat
	root_node.add_child(mi)
	return mi

func _build_bunker() -> void:
	var bb = load("res://scripts/bunker_builder.gd")
	# 1. Foundation & Floor
	_box(Vector3(0.0, -0.4, 0.0), Vector3(10.6, 0.8, 11.2), c_mat)
	_box(Vector3(0.0, 0.02, 0.0), Vector3(8.0, 0.04, 8.4), cp_mat)
	_box(Vector3(0.0, 0.03, 0.0), Vector3(1.6, 0.04, 7.2), grate_mat)
	_box(Vector3(0.0, 0.02, 4.8), Vector3(2.8, 0.08, 1.8), m_mat)

	# 2. Main Bastion Walls
	_box(Vector3(-3.6, 1.9, 0.0), Vector3(1.0, 3.8, 8.4), cp_mat) # Left wall
	_box(Vector3(3.6, 1.9, 0.0), Vector3(1.0, 3.8, 8.4), cp_mat)  # Right wall
	_box(Vector3(0.0, 1.9, -4.2), Vector3(8.2, 3.8, 1.0), c_mat)   # Back wall
	_box(Vector3(0.0, 3.85, 0.0), Vector3(8.6, 0.45, 9.6), c_mat)  # Roof slab

	# Roof Parapet Rims
	_box(Vector3(-4.2, 4.15, 0.0), Vector3(0.4, 0.35, 9.8), cp_mat)
	_box(Vector3(4.2, 4.15, 0.0), Vector3(0.4, 0.35, 9.8), cp_mat)
	_box(Vector3(0.0, 4.15, 4.8), Vector3(8.6, 0.35, 0.4), cp_mat)
	_box(Vector3(0.0, 4.15, -4.8), Vector3(8.6, 0.35, 0.4), cp_mat)

	# 3. 4 Corner Pilasters
	for cx in [-3.8, 3.8]:
		for cz in [-4.2, 4.2]:
			_box(Vector3(cx, 2.0, cz), Vector3(1.3, 4.1, 1.3), c_mat)

	# 4. Slanted Buttress Armor Slabs (3 on each flank)
	for z_pos in [-2.2, 0.0, 2.2]:
		# Left flank (tilted +16 deg)
		_box(Vector3(-4.25, 1.85, z_pos), Vector3(0.42, 3.7, 0.95), cp_mat, Vector3(0.0, 0.0, deg_to_rad(16.0)))
		_box(Vector3(-4.30, 0.50, z_pos), Vector3(0.48, 1.0, 1.05), m_mat, Vector3(0.0, 0.0, deg_to_rad(16.0)))
		# Right flank (tilted -16 deg)
		_box(Vector3(4.25, 1.85, z_pos), Vector3(0.42, 3.7, 0.95), cp_mat, Vector3(0.0, 0.0, deg_to_rad(-16.0)))
		_box(Vector3(4.30, 0.50, z_pos), Vector3(0.48, 1.0, 1.05), m_mat, Vector3(0.0, 0.0, deg_to_rad(-16.0)))

	# 5. Front Facade & Entryway
	_box(Vector3(-2.5, 1.9, 4.2), Vector3(2.4, 3.8, 1.0), cp_mat) # Left portal wall
	_box(Vector3(2.5, 1.9, 4.2), Vector3(2.4, 3.8, 1.0), cp_mat)  # Right portal wall
	_box(Vector3(0.0, 3.2, 4.2), Vector3(2.6, 1.2, 1.0), cp_mat)  # Upper lintel

	# Recessed Amber Visor Slot with Protective Steel Shroud Brow
	_box(Vector3(0.0, 3.25, 4.75), Vector3(3.2, 0.45, 0.18), c_mat)
	_box(Vector3(0.0, 3.48, 4.86), Vector3(3.3, 0.08, 0.28), m_mat) # Overhanging brow
	_box(Vector3(0.0, 3.25, 4.82), Vector3(2.7, 0.20, 0.06), glow_visor)

	# Bulkhead Doorway Frame
	_box(Vector3(-1.25, 1.3, 4.72), Vector3(0.32, 2.6, 0.35), m_mat) # Left jamb
	_box(Vector3(1.25, 1.3, 4.72), Vector3(0.32, 2.6, 0.35), m_mat)  # Right jamb
	_box(Vector3(0.0, 2.62, 4.72), Vector3(2.65, 0.32, 0.35), m_mat) # Door header
	# Parted Blast Doors (recessed in wall pockets with embossed X ribbing)
	_box(Vector3(-1.12, 1.3, 4.45), Vector3(0.24, 2.5, 0.38), m_mat)
	_box(Vector3(-1.08, 1.3, 4.45), Vector3(0.06, 2.3, 0.06), c_mat, Vector3(0.0, 0.0, deg_to_rad(35.0)))
	_box(Vector3(1.12, 1.3, 4.45), Vector3(0.24, 2.5, 0.38), m_mat)
	_box(Vector3(1.08, 1.3, 4.45), Vector3(0.06, 2.3, 0.06), c_mat, Vector3(0.0, 0.0, deg_to_rad(-35.0)))
	# Amber Indicator Lamp above Door
	_box(Vector3(0.0, 2.82, 4.78), Vector3(0.72, 0.18, 0.08), m_mat) # Lamp housing
	_box(Vector3(0.0, 2.82, 4.84), Vector3(0.60, 0.12, 0.04), glow_amber)

	# Industrial Piping & Diagnostic Terminal (Left of doorway)
	_box(Vector3(-2.0, 1.45, 4.75), Vector3(0.58, 0.78, 0.28), m_mat) # Terminal housing
	_box(Vector3(-2.0, 1.58, 4.90), Vector3(0.42, 0.34, 0.04), glow_amber)
	_box(Vector3(-2.0, 1.25, 4.90), Vector3(0.38, 0.14, 0.02), c_mat)
	_cyl(Vector3(-1.58, 1.9, 4.75), 0.04, 0.04, 3.8, 8, m_mat)
	_cyl(Vector3(-1.68, 1.9, 4.75), 0.035, 0.035, 3.8, 8, m_mat)
	_cyl(Vector3(-2.45, 1.9, 4.75), 0.04, 0.04, 3.8, 8, m_mat)

	# Access Keypad (Right of doorway)
	_box(Vector3(1.85, 1.4, 4.75), Vector3(0.34, 0.58, 0.18), m_mat)
	_box(Vector3(1.85, 1.52, 4.85), Vector3(0.24, 0.20, 0.04), glow_amber)
	_cyl(Vector3(1.65, 1.9, 4.75), 0.04, 0.04, 3.8, 8, m_mat)

	# 6. Roof Telemetry & Hardware
	var sat = bb.load_glb("res://models/bunker_satellite.glb")
	if sat:
		sat.position = Vector3(2.3, 4.15, -2.4); sat.scale = Vector3(1.6, 1.6, 1.6)
		bb.recolor(sat, m_mat, c_mat); root_node.add_child(sat)
	_cyl(Vector3(-2.4, 5.5, -1.8), 0.03, 0.04, 3.0, 6, m_mat)
	_cyl(Vector3(-2.0, 5.2, -2.6), 0.025, 0.035, 2.5, 6, m_mat)
	_box(Vector3(-0.6, 4.35, -1.5), Vector3(1.8, 0.6, 1.8), m_mat)

	# 7. Interior Architecture: Ceiling Bulkhead Arches
	for z_arch in [-0.8, 1.6]:
		_box(Vector3(0.0, 3.4, z_arch), Vector3(6.2, 0.45, 0.45), c_mat)
		_box(Vector3(-2.8, 3.1, z_arch), Vector3(0.45, 0.55, 0.45), c_mat, Vector3(0.0, 0.0, deg_to_rad(45.0)))
		_box(Vector3(2.8, 3.1, z_arch), Vector3(0.45, 0.55, 0.45), c_mat, Vector3(0.0, 0.0, deg_to_rad(-45.0)))
	# Overhead pipes running through arches
	_cyl(Vector3(-2.6, 3.3, 0.0), 0.05, 0.05, 7.8, 8, m_mat)
	_cyl(Vector3(-2.72, 3.3, 0.0), 0.04, 0.04, 7.8, 8, m_mat)
	_cyl(Vector3(2.65, 3.3, 0.0), 0.05, 0.05, 7.8, 8, m_mat)

	# 8. Rear Workstation Console & Angled CRT Setup
	_box(Vector3(0.0, 0.45, -2.8), Vector3(2.8, 0.9, 1.1), c_mat)
	_box(Vector3(0.0, 0.91, -2.8), Vector3(2.9, 0.04, 1.15), m_mat)
	# Console Wings (Left and Right chamfered flanks)
	_box(Vector3(-1.35, 0.70, -2.55), Vector3(0.25, 1.4, 0.75), m_mat)
	_box(Vector3(1.35, 0.70, -2.55), Vector3(0.25, 1.4, 0.75), m_mat)
	_box(Vector3(0.0, 1.35, -3.15), Vector3(2.5, 0.95, 0.5), c_mat)
	# Main CRT Housing & Tilted Bezel
	_box(Vector3(0.05, 1.45, -2.90), Vector3(1.22, 0.66, 0.16), m_mat, Vector3(deg_to_rad(-12.0), 0.0, 0.0))
	_box(Vector3(0.05, 1.46, -2.82), Vector3(1.08, 0.52, 0.04), glow_amber, Vector3(deg_to_rad(-12.0), 0.0, 0.0))
	# Slanted keyboard / control deck
	_box(Vector3(0.05, 0.94, -2.55), Vector3(1.15, 0.10, 0.42), m_mat, Vector3(deg_to_rad(16.0), 0.0, 0.0))
	_box(Vector3(0.05, 0.98, -2.55), Vector3(0.95, 0.03, 0.32), c_mat, Vector3(deg_to_rad(16.0), 0.0, 0.0))
	# Secondary angled monitor
	_box(Vector3(-0.85, 1.38, -2.82), Vector3(0.56, 0.46, 0.12), m_mat, Vector3(deg_to_rad(-10.0), deg_to_rad(18.0), 0.0))
	_box(Vector3(-0.85, 1.38, -2.76), Vector3(0.46, 0.36, 0.04), glow_amber, Vector3(deg_to_rad(-10.0), deg_to_rad(18.0), 0.0))

	# Desk Relic & Field Tracker
	var vat = bb.load_glb("res://models/prop_containment_vat.glb")
	if vat:
		vat.position = Vector3(-0.95, 0.93, -2.4); vat.scale = Vector3(0.40, 0.40, 0.40)
		bb.recolor(vat, m_mat, cp_mat); root_node.add_child(vat)
	var relic = bb.load_glb("res://models/prop_alien_floating_artifact.glb")
	if relic:
		relic.position = Vector3(-0.95, 1.25, -2.4); relic.scale = Vector3(0.18, 0.18, 0.18)
		bb.set_nearest(relic); root_node.add_child(relic)
	var dev = bb.load_glb("res://models/finder_device.glb")
	if dev:
		dev.position = Vector3(0.85, 0.96, -2.45); dev.scale = Vector3(0.42, 0.42, 0.42); dev.rotation = Vector3(deg_to_rad(65.0), deg_to_rad(15.0), 0)
		var mi = dev.find_child("Multmeter_Cube", true, false) as MeshInstance3D
		if mi:
			mi.set_surface_override_material(2, glow_amber); mi.set_surface_override_material(1, c_mat); mi.set_surface_override_material(0, m_mat)
		root_node.add_child(dev)

	# 9. Flank Machinery & Storage (Sector A Extrapolation Unit)
	var gen = bb.load_glb("res://models/industrial/machine-fortified.glb")
	if gen:
		gen.position = Vector3(-2.6, 0.04, -0.6); gen.scale = Vector3(1.15, 1.15, 1.15); gen.rotation.y = deg_to_rad(90)
		bb.recolor(gen, m_mat, c_mat); root_node.add_child(gen)
	_cyl(Vector3(-2.6, 2.5, -0.6), 0.06, 0.06, 1.6, 8, m_mat) # Vertical pipe connecting machine to ceiling
	var cr1 = bb.load_glb("res://models/industrial/box-large.glb")
	if cr1:
		cr1.position = Vector3(2.5, 0.04, 0.8); cr1.scale = Vector3(1.2, 1.2, 1.2); cr1.rotation.y = deg_to_rad(-12)
		bb.recolor(cr1, m_mat, cp_mat); root_node.add_child(cr1)
	var cr2 = bb.load_glb("res://models/industrial/box-wide.glb")
	if cr2:
		cr2.position = Vector3(2.5, 0.70, 0.8); cr2.scale = Vector3(1.0, 1.0, 1.0); cr2.rotation.y = deg_to_rad(8)
		bb.recolor(cr2, m_mat, cp_mat); root_node.add_child(cr2)
	# Secondary Wall Monitor on Right Wall (Panel 3 & 5)
	_box(Vector3(3.04, 1.65, -1.5), Vector3(0.12, 0.65, 0.95), m_mat)
	_box(Vector3(3.00, 1.65, -1.5), Vector3(0.04, 0.52, 0.80), glow_amber)

	# 10. Atmospheric Interior & Exterior Lighting
	bb.omni(root_node, Vector3(0.0, 2.7, 0.0), Color(0.75, 0.82, 0.90), 1.2, 8.0) # Cold ambient fill
	bb.omni(root_node, Vector3(0.0, 1.5, -2.2), Color(1.0, 0.72, 0.16), 2.8, 4.5) # Warm CRT glow
	bb.omni(root_node, Vector3(0.0, 2.9, 5.0), Color(1.0, 0.75, 0.20), 2.4, 6.0)  # Exterior door lamp
	bb.omni(root_node, Vector3(0.0, 3.4, 5.0), Color(1.0, 0.65, 0.12), 3.0, 5.0)  # Visor glow

func _process(delta: float) -> bool:
	frame += 1
	if frame == 2:
		# Angle 1: Exterior 3/4 Perspective (Matching Concept Panel 4)
		cam.look_at_from_position(Vector3(7.5, 5.2, 9.5), Vector3(0.0, 1.8, 0.5), Vector3.UP)
		print("Set View 1: Exterior Perspective")
	elif frame == 4:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_exterior_perspective.png")
		print("Saved test_exterior_perspective.png")
		# Angle 2: Entryway Close-up Detail (Matching Concept Panel 2)
		cam.look_at_from_position(Vector3(1.2, 1.8, 7.8), Vector3(-0.2, 1.7, 4.5), Vector3.UP)
		print("Set View 2: Entryway Detail")
	elif frame == 6:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_entryway_detail.png")
		print("Saved test_entryway_detail.png")
		# Angle 3: Interior Looking At Workstation (Matching Concept Panel 3)
		cam.look_at_from_position(Vector3(0.8, 1.6, 1.2), Vector3(-0.2, 1.4, -2.8), Vector3.UP)
		print("Set View 3: Interior Workstation")
	elif frame == 8:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_interior_main.png")
		print("Saved test_interior_main.png")
		# Angle 4: Interior Alt Wide View (Matching Concept Panel 5)
		cam.look_at_from_position(Vector3(2.2, 1.5, 2.4), Vector3(-1.0, 1.3, -1.0), Vector3.UP)
		print("Set View 4: Interior Alt View")
	elif frame == 10:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_interior_alt.png")
		print("Saved test_interior_alt.png")
		print("ALL 4 VIEWS RENDERED SUCCESSFULLY!")
		quit()
		return true
	return false
