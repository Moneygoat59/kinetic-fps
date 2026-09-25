extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state)
	var scn = doc.generate_scene(state)
	var g = scn.find_child("gate", true, false) as MeshInstance3D
	if g and g.mesh:
		for i in range(g.mesh.get_surface_count()):
			var arrays = g.mesh.surface_get_arrays(i)
			var verts = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
			var min_v = Vector3(999, 999, 999)
			var max_v = Vector3(-999, -999, -999)
			for v in verts:
				min_v = min_v.min(v)
				max_v = max_v.max(v)
			print("surface ", i, " (", g.mesh.surface_get_material(i).resource_name, "): min=", min_v, " max=", max_v, " count=", verts.size())
	quit()
