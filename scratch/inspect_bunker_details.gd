extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/bunker_small.glb", state) == OK:
		var scn = doc.generate_scene(state)
		print("--- bunker_small.glb hierarchy ---")
		_print_tree(scn, 0)
	quit()

func _print_tree(n: Node, depth: int) -> void:
	var indent = ""
	for i in range(depth): indent += "  "
	var extra = ""
	if n is Node3D:
		extra = " pos=" + str((n as Node3D).position) + " scale=" + str((n as Node3D).scale)
	if n is MeshInstance3D:
		var mi = n as MeshInstance3D
		if mi.mesh:
			extra += " aabb=" + str(mi.mesh.get_aabb())
	print(indent + n.name + " (" + n.get_class() + ")" + extra)
	for c in n.get_children():
		_print_tree(c, depth + 1)
