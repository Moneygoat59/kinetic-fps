extends SceneTree

func _init() -> void:
	var models = [
		"res://models/bunker_small.glb",
		"res://models/bunker_structure_module.glb",
		"res://models/industrial/structure-doorway.glb",
		"res://models/industrial/structure-wall.glb",
		"res://models/industrial/machine-fortified.glb",
		"res://models/industrial/screen-panel-flat.glb",
		"res://models/industrial/machine-bed.glb",
		"res://models/industrial/box-large.glb",
		"res://models/prop_containment_vat.glb"
	]
	for path in models:
		print("\n=== MODEL: ", path, " ===")
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path), state) != OK:
			print("FAILED TO LOAD")
			continue
		var scn = doc.generate_scene(state)
		_dump_node(scn, 0)
	quit()

func _dump_node(n: Node, indent: int) -> void:
	var pad = "  ".repeat(indent)
	var extra = ""
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		var aabb = mi.mesh.get_aabb() if mi.mesh else AABB()
		var sc = mi.mesh.get_surface_count() if mi.mesh else 0
		extra = " [Mesh AABB: %s, surfaces: %d]" % [str(aabb), sc]
		for s in range(sc):
			var mat = mi.get_surface_override_material(s)
			if not mat and mi.mesh:
				mat = mi.mesh.surface_get_material(s)
			var mat_name = mat.resource_name if mat else "none"
			extra += " (s%d: %s)" % [s, mat_name]
	print(pad, n.name, " (", n.get_class(), ")", extra)
	for c in n.get_children():
		_dump_node(c, indent + 1)
