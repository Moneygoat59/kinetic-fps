extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state) == OK:
		var scn = doc.generate_scene(state)
		var mi = scn.find_child("hangar_smallA", true, false) as MeshInstance3D
		if mi and mi.mesh:
			for i in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(i) as StandardMaterial3D
				print("surface ", i, ": ", mat)
				if mat:
					print("  albedo_color: ", mat.albedo_color)
					print("  albedo_texture: ", mat.albedo_texture)
	quit()
