extends SceneTree

func _init() -> void:
	var cam = Camera3D.new()
	root.add_child(cam)
	for pitch in [-90.0, -89.9, -85.0, -70.0, -45.0, 0.0]:
		cam.rotation_degrees = Vector3(pitch, 0, 0)
		var z = -cam.global_transform.basis.z
		var dir = Vector3(z.x, 0.0, z.z)
		print("pitch=", pitch, " z=", z, " dir.length=", dir.length(), " normalized=", dir.normalized())
	quit()
