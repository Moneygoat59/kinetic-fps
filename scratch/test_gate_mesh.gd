extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state)
	var scn = doc.generate_scene(state)
	var g = scn.find_child("gate", true, false) as MeshInstance3D
	if g and g.mesh:
		print("gate surface count: ", g.mesh.get_surface_count())
		for i in range(g.mesh.get_surface_count()):
			print("  surface ", i, ": ", g.mesh.surface_get_material(i).resource_name)
	quit()
