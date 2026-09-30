extends SceneTree

func _init() -> void:
	for name in ["basemodule_A.gltf", "basemodule_B.gltf", "basemodule_C.gltf"]:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/kaykit_space_base/" + name, state) == OK:
			var scn = doc.generate_scene(state)
			print("--- ", name, " ---")
			for c in scn.get_children():
				print(" ", c.name, " (", c.get_class(), ")")
				if c is MeshInstance3D and c.mesh:
					print("   surfaces: ", c.mesh.get_surface_count())
					for s in range(c.mesh.get_surface_count()):
						print("     s", s, " mat=", c.mesh.surface_get_material(s).resource_name if c.mesh.surface_get_material(s) else "null")
	quit()
