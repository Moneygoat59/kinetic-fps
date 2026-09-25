extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path("res://models/bunker_small.glb"), state) == OK:
		var scn = doc.generate_scene(state)
		var h = scn.find_child("hangar_smallA", true, false) as MeshInstance3D
		var g = scn.find_child("gate", true, false) as MeshInstance3D
		var g2 = scn.find_child("gate2", true, false) as MeshInstance3D
		print("hangar pos: ", h.position, " aabb: ", h.mesh.get_aabb() if h.mesh else "no mesh")
		if g: print("gate pos: ", g.position, " aabb: ", g.mesh.get_aabb() if g.mesh else "no mesh")
		if g2: print("gate2 pos: ", g2.position, " aabb: ", g2.mesh.get_aabb() if g2.mesh else "no mesh")
	quit()
