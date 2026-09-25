extends SceneTree

const BunkerBuilder = preload("res://scripts/bunker_builder.gd")
var frame_count = 0
var bunker_root: Node3D
var cam: Camera3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	bunker_root = Node3D.new()
	root.add_child(bunker_root)
	
	var b_mat = BunkerBuilder.mat_basalt()
	var p_mat = BunkerBuilder.mat_panel()
	var m_mat = BunkerBuilder.mat_metal()
	var glow_amber = BunkerBuilder.mat_glow(Color(1.0, 0.72, 0.15), 2.2, BunkerBuilder.meter_tex)
	
	# 1. Foundation apron & threshold
	BunkerBuilder.box(bunker_root, Vector3(0.0, -0.4, 0.0), Vector3(9.2, 0.8, 9.2), b_mat)
	BunkerBuilder.box(bunker_root, Vector3(0.0, 0.02, 0.0), Vector3(8.4, 0.06, 8.4), p_mat)
	BunkerBuilder.box(bunker_root, Vector3(0.0, 0.03, 5.2), Vector3(2.6, 0.06, 1.8), m_mat)
	
	# 2. Main quonset shell with rear bulkhead gate kept
	var bunker = BunkerBuilder.load_glb("res://models/bunker_small.glb")
	var h = bunker.find_child("hangar_smallA", true, false) as Node3D
	if h: h.position = Vector3.ZERO
	var g2 = bunker.find_child("gate2", true, false)
	if g2: g2.queue_free()
	bunker.scale = Vector3(4.2, 3.6, 4.2)
	_set_nearest(bunker)
	bunker_root.add_child(bunker)
	
	# 3. Fortified Front Facade (Doorway + Walls + Shutter + Wing walls)
	var dw = BunkerBuilder.spawn(bunker_root, "res://models/industrial/structure-doorway-wide.glb", Vector3(0.0, 0.04, 4.2))
	var w_l = BunkerBuilder.spawn(bunker_root, "res://models/industrial/structure-wall.glb", Vector3(-1.5, 0.04, 4.2))
	var w_r = BunkerBuilder.spawn(bunker_root, "res://models/industrial/structure-wall.glb", Vector3(1.5, 0.04, 4.2))
	var sh = BunkerBuilder.spawn(bunker_root, "res://models/industrial/door-wide-open.glb", Vector3(0.0, 0.04, 4.2))
	_set_nearest(dw); _set_nearest(w_l); _set_nearest(w_r); _set_nearest(sh)
	
	BunkerBuilder.box(bunker_root, Vector3(-3.05, 1.7, 4.2), Vector3(2.2, 3.4, 1.4), b_mat)
	BunkerBuilder.box(bunker_root, Vector3(3.05, 1.7, 4.2), Vector3(2.2, 3.4, 1.4), b_mat)
	# Armored roof parapet capping beam
	BunkerBuilder.box(bunker_root, Vector3(0.0, 3.45, 4.2), Vector3(8.4, 0.45, 1.4), b_mat)
	
	# 4. Roof satellite array
	BunkerBuilder.cylinder(bunker_root, Vector3(0.0, 3.55, -1.8), 1.1, 1.2, 0.2, 10, m_mat)
	var sat = BunkerBuilder.spawn(bunker_root, "res://models/bunker_satellite.glb", Vector3(0.0, 3.65, -1.8), Vector3(1.8, 1.8, 1.8))
	_set_nearest(sat)
	
	# 5. Interior Equipment
	# Main research workbench
	var bench = BunkerBuilder.spawn(bunker_root, "res://models/industrial/machine-bed.glb", Vector3(0.0, 0.04, -1.8), Vector3(1.3, 1.0, 1.1), deg_to_rad(180))
	_set_nearest(bench)
	
	# Computer terminal on desk with glowing amber CRT readout
	var term = BunkerBuilder.spawn(bunker_root, "res://models/industrial/screen-panel-wide.glb", Vector3(0.0, 1.05, -2.15), Vector3(1.2, 1.2, 1.2), deg_to_rad(180))
	_set_nearest(term)
	# Glowing screen face
	var scrn_quad = MeshInstance3D.new()
	var qm = QuadMesh.new(); qm.size = Vector2(0.85, 0.42)
	scrn_quad.mesh = qm; scrn_quad.position = Vector3(0.0, 1.48, -2.05)
	scrn_quad.material_override = glow_amber
	bunker_root.add_child(scrn_quad)
	
	# Left side: Power generator / reinforced machine
	var gen = BunkerBuilder.spawn(bunker_root, "res://models/industrial/machine-fortified.glb", Vector3(-2.6, 0.04, 0.2), Vector3(1.0, 1.1, 1.0), deg_to_rad(90))
	_set_nearest(gen)
	
	# Right side: Supply crates
	var cr1 = BunkerBuilder.spawn(bunker_root, "res://models/industrial/box-large.glb", Vector3(2.5, 0.04, 0.2), Vector3(1.2, 1.2, 1.2), deg_to_rad(-15))
	var cr2 = BunkerBuilder.spawn(bunker_root, "res://models/industrial/box-wide.glb", Vector3(2.5, 0.70, 0.2), Vector3(1.0, 1.0, 1.0), deg_to_rad(10))
	_set_nearest(cr1); _set_nearest(cr2)
	
	# Desk props: Alien specimen containment & Field Tracker
	var vat = BunkerBuilder.spawn(bunker_root, "res://models/prop_containment_vat.glb", Vector3(-0.75, 1.05, -1.8), Vector3(0.5, 0.5, 0.5))
	_set_nearest(vat)
	var relic = BunkerBuilder.spawn(bunker_root, "res://models/prop_alien_floating_artifact.glb", Vector3(-0.75, 1.38, -1.8), Vector3(0.18, 0.18, 0.18))
	_set_nearest(relic)
	
	# Tracker dock
	BunkerBuilder.cylinder(bunker_root, Vector3(0.65, 1.06, -1.7), 0.24, 0.26, 0.04, 8, m_mat)
	var dev = BunkerBuilder.spawn(bunker_root, "res://models/finder_device.glb", Vector3(0.65, 1.12, -1.7), Vector3(0.42, 0.42, 0.42), 0.0)
	if dev:
		dev.rotation = Vector3(deg_to_rad(65.0), deg_to_rad(15.0), 0)
		var mi = dev.find_child("Multmeter_Cube", true, false) as MeshInstance3D
		if mi:
			mi.set_surface_override_material(2, glow_amber)
	
	# 6. Lighting
	# Interior warm amber ambient fill
	BunkerBuilder.omni(bunker_root, Vector3(0.0, 2.5, -0.5), Color(1.0, 0.75, 0.35), 2.8, 8.0)
	# Desk task light
	BunkerBuilder.omni(bunker_root, Vector3(0.0, 1.8, -1.8), Color(1.0, 0.85, 0.5), 1.8, 3.5)
	# Device pickup beacon light
	BunkerBuilder.omni(bunker_root, Vector3(0.65, 1.35, -1.7), Color(1.0, 0.75, 0.2), 2.2, 2.5)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.42, 0.45)
	env_node.environment = env
	root.add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.0
	root.add_child(sun)
	
	cam = Camera3D.new()
	cam.current = true
	root.add_child(cam)

func _set_nearest(n: Node) -> void:
	if not n: return
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		if mi.mesh:
			for s in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var dup = mat.duplicate() as StandardMaterial3D
					dup.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					mi.set_surface_override_material(s, dup)
	for c in n.get_children():
		_set_nearest(c)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		# Angle 1: Front exterior entrance
		cam.look_at_from_position(Vector3(0.0, 2.0, 8.0), Vector3(0.0, 1.5, 3.5), Vector3.UP)
	elif frame_count == 5:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_bunker_new_front.png")
		# Angle 2: Inside interior lab workbench
		cam.look_at_from_position(Vector3(0.0, 1.6, 2.0), Vector3(0.0, 1.3, -1.8), Vector3.UP)
	elif frame_count == 10:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_bunker_new_inside.png")
		# Angle 3: Side 3/4 aerial view
		cam.look_at_from_position(Vector3(7.0, 5.0, 6.0), Vector3(0.0, 1.5, 0.0), Vector3.UP)
	elif frame_count == 15:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_bunker_new_side.png")
		quit()
		return true
	return false
