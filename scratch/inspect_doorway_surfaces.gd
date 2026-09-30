extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/industrial/structure-doorway.glb", state) == OK:
		var scn = doc.generate_scene(state)
		var mi = scn.find_child("structure-doorway", true, false) as MeshInstance3D
		if mi and mi.mesh:
			print("Surfaces in structure-doorway: ", mi.mesh.get_surface_count())
			for s in range(mi.mesh.get_surface_count()):
				var m = mi.mesh.surface_get_material(s)
				print("  surface ", s, " name=", m.resource_name if m else "null")
	quit()
