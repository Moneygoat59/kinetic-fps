extends SceneTree

var frame: int = 0
var silo: Node3D
var cam: Camera3D
var env: WorldEnvironment
var sun: DirectionalLight3D
var rim_light: DirectionalLight3D

func _init() -> void:
	root.size = Vector2i(1920, 1080)
	
	# Atmosphere environment
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.07, 0.08, 0.10)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.24, 0.26, 0.32)
	e.ambient_light_energy = 1.2
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.fog_enabled = true
	e.fog_light_color = Color(0.12, 0.13, 0.16)
	e.fog_density = 0.002
	env = WorldEnvironment.new()
	env.environment = e
	root.add_child(env)
	
	# Sunlight
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 48.0, 0.0)
	sun.light_color = Color(1.0, 0.94, 0.85)
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	root.add_child(sun)
	
	rim_light = DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-25.0, -135.0, 0.0)
	rim_light.light_color = Color(1.0, 0.70, 0.22)
	rim_light.light_energy = 0.9
	root.add_child(rim_light)
	
	cam = Camera3D.new()
	cam.current = true
	cam.near = 0.1
	cam.far = 1000.0
	root.add_child(cam)
	
	var silo_cls = load("res://scripts/missile_silo.gd")
	silo = silo_cls.new()
	silo.build_silo(null, 0.0, 0.0)
	root.add_child(silo)

func _process(delta: float) -> bool:
	frame += 1
	
	# -------------------------------------------------------------
	# Frame 3: 1. EXTERIOR OVERVIEW & SCALE (Aperture, Buttresses & Outpost 73)
	# -------------------------------------------------------------
	if frame == 3:
		cam.look_at_from_position(
			Vector3(62.0, 28.0, 42.0),
			Vector3(14.0, 2.0, 8.0),
			Vector3.UP
		)
		print("Camera: 1. Exterior Overview & Scale")

	elif frame == 6:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_exterior_scale.png")
		print("Saved scratch/silo_exterior_scale.png")
		
		# ---------------------------------------------------------
		# Frame 7: 2. CROSS-SECTIONAL ELEVATION / DEEP ABYSS VIEW
		# ---------------------------------------------------------
		cam.look_at_from_position(
			Vector3(-2.0, -10.0, 22.0),
			Vector3(0.0, -52.0, 2.0),
			Vector3.UP
		)
		print("Camera: 2. Deep Abyss View")

	elif frame == 10:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_deep_abyss.png")
		print("Saved scratch/silo_deep_abyss.png")
		
		# ---------------------------------------------------------
		# Frame 11: 3. MID-LEVEL INTERIOR DETAIL (Gantry, Consoles, Luminaires)
		# ---------------------------------------------------------
		cam.look_at_from_position(
			Vector3(0.0, -32.2, 17.5),
			Vector3(0.0, -32.6, 10.5),
			Vector3.UP
		)
		print("Camera: 3. Mid-Level Interior Detail")

	elif frame == 14:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_mid_interior.png")
		print("Saved scratch/silo_mid_interior.png")
		
		# ---------------------------------------------------------
		# Frame 15: 4. BASE & EMPTY MOUNT DETAIL (Launch Table, Isolators, Sludge)
		# ---------------------------------------------------------
		cam.look_at_from_position(
			Vector3(14.0, -60.0, 14.0),
			Vector3(0.0, -66.8, 0.0),
			Vector3.UP
		)
		print("Camera: 4. Base & Empty Mount Detail")

	elif frame == 18:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_base_mount.png")
		print("Saved scratch/silo_base_mount.png")
		
		# ---------------------------------------------------------
		# Frame 19: 5. STAIRCASE & WALL STRATA (Continuous Zigzag Walkway)
		# ---------------------------------------------------------
		cam.look_at_from_position(
			Vector3(-6.0, -28.0, 2.0),
			Vector3(14.0, -32.0, 10.0),
			Vector3.UP
		)
		print("Camera: 5. Staircase & Wall Strata")

	elif frame == 22:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_staircase.png")
		print("Saved scratch/silo_staircase.png")
		print("ALL COLOSSAL SILO RENDERS COMPLETE!")
		quit()
		return true

	return false
