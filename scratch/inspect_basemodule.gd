extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/kaykit_space_base/basemodule_A.gltf", state) == OK:
		var scn = doc.generate_scene(state)
		print("--- basemodule_A ---")
		for c in scn.get_children():
			print(c.name, " (", c.get_class(), ")")
			for c2 in c.get_children():
				print("  ", c2.name, " (", c2.get_class(), ")")
				if c2 is MeshInstance3D and c2.mesh:
					print("    aabb=", c2.mesh.get_aabb())
	quit()
