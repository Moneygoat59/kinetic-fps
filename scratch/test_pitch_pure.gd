extends SceneTree

func _init() -> void:
	for pitch in [-90.0, -89.0, -85.0, -70.0, -45.0, 0.0]:
		var t = Transform3D().rotated(Vector3(1, 0, 0), deg_to_rad(pitch))
		var fwd = -t.basis.z
		var dir = Vector3(fwd.x, 0.0, fwd.z)
		print("pitch=", pitch, " fwd=", fwd, " dir.len=", dir.length(), " norm=", dir.normalized())
	quit()
