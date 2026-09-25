extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/industrial/structure-doorway-wide.glb"), state)
	var scn = doc.generate_scene(state)
	var mi = scn.find_child("structure-doorway-wide", true, false) as MeshInstance3D
	if mi and mi.mesh:
		var arrays = mi.mesh.surface_get_arrays(0)
		var verts = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
		print("Total verts: ", verts.size())
		var ys = []
		for v in verts:
			if not ys.has(snappedf(v.y, 0.05)):
				ys.append(snappedf(v.y, 0.05))
		ys.sort()
		print("Unique Y levels: ", ys)
		# find vertices where abs(x) < 0.6
		for v in verts:
			if abs(v.x) < 0.6:
				print("x=", v.x, " y=", v.y, " z=", v.z)
	quit()
