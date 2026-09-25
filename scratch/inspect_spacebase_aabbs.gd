extends SceneTree

func _init() -> void:
	for name in ["basemodule_A.gltf", "basemodule_B.gltf", "basemodule_C.gltf", "basemodule_D.gltf", "basemodule_garage.gltf", "cargodepot_A.gltf"]:
		var doc = GLTFDocument.new(); var state = GLTFState.new()
		if doc.append_from_file("C:/Users/Isaac/kinetic-fps/models/kaykit_space_base/" + name, state) == OK:
			var scn = doc.generate_scene(state)
			var h = scn.find_child("*", true, false) as MeshInstance3D
			if h and h.mesh:
				print(name, ": aabb=", h.mesh.get_aabb())
	quit()
