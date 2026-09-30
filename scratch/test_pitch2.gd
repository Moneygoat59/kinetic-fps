extends SceneTree

func _init() -> void:
	var cam = Camera3D.new()
	root.add_child(cam)
	for pitch in [-90.0, -89.9, -85.0, -70.0, -45.0, 0.0]:
		cam.rotation = Vector3(deg_to_rad(pitch), 0, 0)
		var basis_z = cam.global_transform.basis.z
		var fwd = -basis_z
		var dir = Vector3(fwd.x, 0.0, fwd.z)
		print("pitch=", pitch, " basis.z=", basis_z, " dir.len=", dir.length())
	quit()
