extends SceneTree

func _init() -> void:
	var b1 = SmallBunker.new()
	root.add_child(b1)
	b1.build_bunker(null, 0, 0)
	print("Bunker 1 children count: ", b1.get_child_count())
	for c in b1.get_children():
		var p = c.position if c is Node3D else "non-3d"
		var s = c.scale if c is Node3D else "non-3d"
		print("  ", c.name, " (", c.get_class(), ") pos=", p, " scale=", s)
	quit()
