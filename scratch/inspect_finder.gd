extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	if doc.append_from_file("res://models/bunker_small.glb", state) == OK:
		var scn = doc.generate_scene(state)
		var g1 = scn.find_child("gate", true, false)
		var g2 = scn.find_child("gate2", true, false)
		print("gate1: ", g1.position, " vis: ", g1.visible if g1 else "none")
		print("gate2: ", g2.position, " vis: ", g2.visible if g2 else "none")
	quit()

func _dump(n: Node, indent: String) -> void:
	print(indent, n.name, " (", n.get_class(), ")")
	for c in n.get_children():
		_dump(c, indent + "  ")
