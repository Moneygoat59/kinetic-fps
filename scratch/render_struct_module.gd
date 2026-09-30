extends SceneTree

var frames = 0
func _init() -> void:
	root.size = Vector2i(1280, 720)
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_structure_module.glb", state) == OK:
		var scn = doc.generate_scene(state)
		scn.scale = Vector3(4.0, 4.0, 4.0)
		root.add_child(scn)
		
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	root.add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	root.add_child(sun)
	
	var cam = Camera3D.new()
	cam.position = Vector3(5.0, 4.0, 7.0)
	cam.look_at(Vector3(0.0, 2.0, 0.0), Vector3.UP)
	cam.current = true
	root.add_child(cam)

func _process(delta: float) -> bool:
	frames += 1
	if frames == 5:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_structure_module.png")
		quit()
		return true
	return false
