extends SceneTree

var frame_count = 0
var bunker_root: Node3D
var cam: Camera3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	bunker_root = Node3D.new()
	root.add_child(bunker_root)
	
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state)
	var bunker = doc.generate_scene(state)
	var h = bunker.find_child("hangar_smallA", true, false) as Node3D
	if h: h.position = Vector3.ZERO
	var g2 = bunker.find_child("gate2", true, false)
	if g2: g2.queue_free()
	bunker.scale = Vector3(4.2, 3.6, 4.2)
	bunker_root.add_child(bunker)
	
	# Add doorway and flanking walls
	for item in [
		["res://models/industrial/structure-wall.glb", Vector3(-1.5, 0.0, 4.2)],
		["res://models/industrial/structure-doorway-wide.glb", Vector3(0.0, 0.0, 4.2)],
		["res://models/industrial/structure-wall.glb", Vector3(1.5, 0.0, 4.2)],
	]:
		doc = GLTFDocument.new()
		state = GLTFState.new()
		doc.append_from_file(ProjectSettings.globalize_path(item[0]), state)
		var scn = doc.generate_scene(state)
		scn.position = item[1]
		bunker_root.add_child(scn)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.7)
	env_node.environment = env
	root.add_child(env_node)
	
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.light_energy = 1.2
	root.add_child(sun)
	
	cam = Camera3D.new()
	cam.current = true
	root.add_child(cam)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		cam.look_at_from_position(Vector3(0.0, 2.5, 9.0), Vector3(0.0, 1.5, 3.5), Vector3.UP)
	elif frame_count == 5:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/test_front_flanked.png")
		quit()
		return true
	return false
