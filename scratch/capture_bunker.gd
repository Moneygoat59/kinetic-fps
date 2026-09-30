extends SceneTree

const SmallBunker = preload("res://scripts/small_bunker.gd")
var frame_count = 0
var bunker: SmallBunker
var cam: Camera3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	bunker = SmallBunker.new()
	root.add_child(bunker)
	bunker.build_bunker(null, 0.0, 0.0)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.46, 0.5)
	env_node.environment = env
	root.add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.0
	root.add_child(sun)
	
	cam = Camera3D.new()
	cam.current = true
	root.add_child(cam)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		# Angle 1: Front entrance approach
		cam.look_at_from_position(Vector3(0.0, 2.0, 8.5), Vector3(0.0, 1.5, 3.5), Vector3.UP)
	elif frame_count == 5:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/bunker_live_front.png")
		# Angle 2: Inside bunker laboratory
		cam.look_at_from_position(Vector3(0.0, 1.6, 2.0), Vector3(0.0, 1.2, -1.8), Vector3.UP)
	elif frame_count == 10:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/bunker_live_inside.png")
		# Angle 3: Side 3/4 view
		cam.look_at_from_position(Vector3(7.0, 5.0, 6.0), Vector3(0.0, 1.5, 0.0), Vector3.UP)
	elif frame_count == 15:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/bunker_live_side.png")
		print("CAPTURES COMPLETED SUCCESSFULLY")
		quit()
		return true
	return false
