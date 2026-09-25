extends SceneTree

func _init() -> void:
	for name in ["machine-bed.glb", "machine.glb", "box-wide.glb", "box-large.glb"]:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/industrial/" + name, state) == OK:
			var scn = doc.generate_scene(state)
			var h = scn.find_child("*", true, false) as MeshInstance3D
			if h and h.mesh:
				print(name, ": aabb=", h.mesh.get_aabb())
	quit()
