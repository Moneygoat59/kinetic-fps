extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state)
	var scn = doc.generate_scene(state)
	print("scn pos: ", scn.position)
	for c in scn.get_children():
		print("  child: ", c.name, " pos: ", c.position)
		for c2 in c.get_children():
			print("    c2: ", c2.name, " pos: ", c2.position)
	quit()
