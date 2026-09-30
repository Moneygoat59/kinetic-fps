extends SceneTree

func _init() -> void:
	for p in ["res://models/bunker_hangar_large.glb", "res://models/bunker_structure_module.glb", "res://models/industrial/door.glb", "res://models/industrial/door-wide-half.glb"]:
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(p), state) == OK:
			var scn = doc.generate_scene(state)
			print(p, ":")
			_p(scn, 1)
	quit()

func _p(n: Node, d: int) -> void:
	var extra = ""
	if n is MeshInstance3D:
		extra = " mesh: %s AABB: %s" % [n.mesh.resource_name, str(n.mesh.get_aabb())]
	print("  ".repeat(d), n.name, extra)
	for c in n.get_children():
		_p(c, d + 1)
