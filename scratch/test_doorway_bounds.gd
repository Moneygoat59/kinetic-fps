extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/industrial/structure-doorway.glb"), state)
	var scn = doc.generate_scene(state)
	var mi = scn.find_child("structure-doorway", true, false) as MeshInstance3D
	var aabb = mi.mesh.get_aabb()
	print("doorway AABB: ", aabb)
	print("doorway pos: ", mi.position, " rot: ", mi.rotation_degrees)
	
	doc = GLTFDocument.new()
	state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/industrial/structure-wall.glb"), state)
	scn = doc.generate_scene(state)
	mi = scn.find_child("structure-wall", true, false) as MeshInstance3D
	aabb = mi.mesh.get_aabb()
	print("wall AABB: ", aabb)
	print("wall pos: ", mi.position, " rot: ", mi.rotation_degrees)
	quit()
