extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_structure_module.glb", state) == OK:
		var scn = doc.generate_scene(state)
		print("--- bunker_structure_module.glb ---")
		for c in scn.get_children():
			print("child: ", c.name, " (", c.get_class(), ")")
			for c2 in c.get_children():
				print("  child2: ", c2.name, " (", c2.get_class(), ")")
				if c2 is MeshInstance3D and c2.mesh:
					print("    aabb=", c2.mesh.get_aabb())
	quit()
