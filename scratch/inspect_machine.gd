extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/industrial/machine-fortified.glb", state) == OK:
		var scn = doc.generate_scene(state)
		for c in scn.get_children():
			if c is MeshInstance3D and c.mesh:
				print("machine-fortified AABB: ", c.mesh.get_aabb())
	quit()
