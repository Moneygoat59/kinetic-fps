extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/prop_alien_floating_artifact.glb", state) == OK:
		var scn = doc.generate_scene(state)
		print("--- prop_alien_floating_artifact.glb ---")
		for c in scn.get_children():
			if c is MeshInstance3D and c.mesh:
				print("child: ", c.name, " aabb=", c.mesh.get_aabb())
			for c2 in c.get_children():
				if c2 is MeshInstance3D and c2.mesh:
					print("  child2: ", c2.name, " aabb=", c2.mesh.get_aabb())
	quit()
