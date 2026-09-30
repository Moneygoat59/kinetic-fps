extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_small.glb", state) == OK:
		var scn = doc.generate_scene(state)
		var h = scn.find_child("hangar_smallA", true, false) as MeshInstance3D
		if h and h.mesh:
			var m = h.mesh
			print("hangar_smallA AABB: ", m.get_aabb())
			for s in range(m.get_surface_count()):
				var arrays = m.surface_get_arrays(s)
				var verts = arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
				print("surface ", s, " verts count=", verts.size())
				var min_v = Vector3(999,999,999); var max_v = Vector3(-999,-999,-999)
				for v in verts:
					min_v.x = minf(min_v.x, v.x); min_v.y = minf(min_v.y, v.y); min_v.z = minf(min_v.z, v.z)
					max_v.x = maxf(max_v.x, v.x); max_v.y = maxf(max_v.y, v.y); max_v.z = maxf(max_v.z, v.z)
				print("  bounds: min=", min_v, " max=", max_v)
	quit()
