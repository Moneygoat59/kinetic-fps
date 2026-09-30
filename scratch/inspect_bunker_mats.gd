extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_small.glb", state) == OK:
		var scn = doc.generate_scene(state)
		var h = scn.find_child("hangar_smallA", true, false) as MeshInstance3D
		if h and h.mesh:
			for s in range(h.mesh.get_surface_count()):
				var mat = h.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					print("surface ", s, " col=", mat.albedo_color, " tex=", mat.albedo_texture)
	quit()
