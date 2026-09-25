extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state) == OK:
		var scn = doc.generate_scene(state)
		var g1 = scn.find_child("gate", true, false) as Node3D
		var g2 = scn.find_child("gate2", true, false) as Node3D
		if g1:
			print("gate pos: ", g1.position, " rot: ", g1.rotation_degrees, " scale: ", g1.scale)
		if g2:
			print("gate2 pos: ", g2.position, " rot: ", g2.rotation_degrees, " scale: ", g2.scale)
	quit()
