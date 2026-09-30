extends SceneTree
## Print the node tree of a scene/model as Godot imported it (class, transform, mesh tris, collision shapes).
## godot --headless --path . --script tools/tree_dump.gd -- res://models/generated/outpost73_bunker.glb

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		printerr("usage: -- <res://scene-or-glb>"); quit(2); return
	var res = load(a[0])
	if not (res is PackedScene):
		printerr("TREE FAIL: cannot load ", a[0], " (glb needs a prior import: godot --headless --path . --import)")
		quit(1); return
	var n: Node = res.instantiate()
	root.add_child(n)
	_dump(n, 0)
	quit(0)

func _dump(n: Node, depth: int) -> void:
	var s := "  ".repeat(depth) + "%s [%s]" % [n.name, n.get_class()]
	if n is Node3D and depth > 0:
		s += " pos=" + str((n as Node3D).position.snapped(Vector3(0.01, 0.01, 0.01)))
	if n is MeshInstance3D and n.mesh:
		var tris := 0
		for i in n.mesh.get_surface_count():
			var arr: Array = n.mesh.surface_get_arrays(i)
			var count: int = arr[Mesh.ARRAY_INDEX].size() if arr[Mesh.ARRAY_INDEX] != null else arr[Mesh.ARRAY_VERTEX].size()
			tris += count / 3
		s += " surfaces=%d tris=%d aabb=%s" % [n.mesh.get_surface_count(), tris, str(n.mesh.get_aabb().size.snapped(Vector3(0.01, 0.01, 0.01)))]
	if n is CollisionShape3D and n.shape:
		s += " shape=" + n.shape.get_class()
	print(s)
	for c in n.get_children():
		_dump(c, depth + 1)
