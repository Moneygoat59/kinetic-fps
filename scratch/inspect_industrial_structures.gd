extends SceneTree

func _init() -> void:
	for name in ["structure-doorway.glb", "structure-doorway-wide.glb", "structure-wall.glb", "structure-corner-outer.glb", "door.glb", "door-wide-open.glb"]:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/industrial/" + name, state) == OK:
			var scn = doc.generate_scene(state)
			var aabb_str = ""
			for c in scn.get_children():
				if c is MeshInstance3D and c.mesh:
					aabb_str += str(c.mesh.get_aabb()) + " "
			print(name, ": ", aabb_str)
	quit()
