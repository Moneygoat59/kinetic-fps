extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://models/finder_device.glb"), state) == OK:
		var scn = doc.generate_scene(state)
		print("Scene nodes in finder_device.glb:")
		_print_tree(scn, 0)
	quit()

func _print_tree(n: Node, depth: int) -> void:
	var prefix = "  ".repeat(depth)
	print(prefix, n.name, " (", n.get_class(), ")")
	for c in n.get_children():
		_print_tree(c, depth + 1)
