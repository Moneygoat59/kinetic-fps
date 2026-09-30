extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file("res://models/bunker_small.glb", state)
	var scn = doc.generate_scene(state)
	var hs = scn.find_child("hangar_smallA", true, false)
	if hs:
		for c in hs.get_children():
			print("Child of hangar_smallA:", c.name, "type:", c.get_class())
			if c is MeshInstance3D:
				print("  AABB:", (c as MeshInstance3D).get_aabb())
	quit()
