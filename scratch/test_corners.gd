extends SceneTree

func _init() -> void:
	for p in ["res://models/industrial/structure-corner-outer.glb", "res://models/industrial/structure-corner-inner.glb", "res://models/industrial/floor.glb", "res://models/industrial/floor-large.glb", "res://models/industrial/door-wide-open.glb"]:
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		doc.append_from_file(ProjectSettings.globalize_path(p), state)
		var scn = doc.generate_scene(state)
		var mi = scn.find_child(p.get_file().get_basename(), true, false) as MeshInstance3D
		if mi:
			print(p, " AABB: ", mi.mesh.get_aabb(), " pos: ", mi.position)
		else:
			print(p, " no mesh child matching basename, children:")
			for c in scn.get_children():
				if c is MeshInstance3D: print("  mesh: ", c.name, " ", c.mesh.get_aabb())
				for c2 in c.get_children():
					if c2 is MeshInstance3D: print("    mesh: ", c2.name, " ", c2.mesh.get_aabb())
	quit()
