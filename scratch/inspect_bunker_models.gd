extends SceneTree

func _init() -> void:
	for p in ["res://models/bunker_hangar_large.glb", "res://models/bunker_structure_module.glb"]:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(p), state) == OK:
			var scn = doc.generate_scene(state)
			print("--- ", p, " ---")
			_dump(scn, 0)
	quit()

func _dump(n: Node, d: int) -> void:
	var prefix = "  ".repeat(d)
	var extra = ""
	if n is MeshInstance3D:
		extra = " aabb: " + str((n as MeshInstance3D).get_aabb())
	print(prefix, n.name, " (", n.get_class(), ")", extra)
	for c in n.get_children():
		_dump(c, d + 1)
