extends SceneTree

var frame_count = 0
var root_node: Node3D
var cam: Camera3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	root_node = Node3D.new()
	root.add_child(root_node)
	
	var models = [
		["res://models/industrial/structure-wall.glb", Vector3(-2.5, 0, 0)],
		["res://models/industrial/structure-wall.glb", Vector3(-1.5, 0, 0)],
		["res://models/industrial/structure-doorway-wide.glb", Vector3(0, 0, 0)],
		["res://models/industrial/structure-wall.glb", Vector3(1.5, 0, 0)],
		["res://models/industrial/structure-wall.glb", Vector3(2.5, 0, 0)],
	]
	for m in models:
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		doc.append_from_file(ProjectSettings.globalize_path(m[0]), state)
		var scn = doc.generate_scene(state)
		scn.position = m[1]
		root_node.add_child(scn)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env_node.environment = env
	root.add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	root.add_child(sun)
	
	cam = Camera3D.new()
	cam.current = true
	root.add_child(cam)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		cam.look_at_from_position(Vector3(0.0, 2.0, 6.0), Vector3(0.0, 1.5, 0.0), Vector3.UP)
	elif frame_count == 5:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_snapped_wall.png")
		quit()
		return true
	return false
