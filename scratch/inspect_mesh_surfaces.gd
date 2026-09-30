extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_small.glb", state) == OK:
		var scn = doc.generate_scene(state)
		var m = scn.find_child("hangar_smallA", true, false) as MeshInstance3D
		if m and m.mesh:
			print("hangar_smallA surface count: ", m.mesh.get_surface_count())
			for s in range(m.mesh.get_surface_count()):
				print("  surface ", s, " mat=", m.mesh.surface_get_material(s))
		var g = scn.find_child("gate", true, false) as MeshInstance3D
		if g and g.mesh:
			print("gate surface count: ", g.mesh.get_surface_count())
	quit()
