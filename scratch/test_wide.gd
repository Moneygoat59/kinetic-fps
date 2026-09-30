extends SceneTree

func _init() -> void:
	var doc = GLTFDocument.new()
	var state = GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://models/industrial/structure-doorway-wide.glb"), state)
	var scn = doc.generate_scene(state)
	var mi = scn.find_child("structure-doorway-wide", true, false) as MeshInstance3D
	if mi:
		print("doorway-wide AABB: ", mi.mesh.get_aabb())
	quit()
