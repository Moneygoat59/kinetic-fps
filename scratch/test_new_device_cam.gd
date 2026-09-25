extends SceneTree

func _init() -> void:
	# Let's test a position where the screen is in lower-right, but bigger and closer to camera:
	# Previous screen position in cam: (0.20, -0.15, -0.32)
	# New screen position in cam: (0.16, -0.12, -0.26) -> closer to eyes!
	var screen_cam_pos = Vector3(0.16, -0.12, -0.26)

	var screen_normal_desired = (-screen_cam_pos).normalized()
	# Up vector in camera space: tilted inward slightly (~12 deg)
	var screen_up_desired = Vector3(-0.12, 0.99, 0.0).normalized()

	var b_z = screen_normal_desired
	var b_x = screen_up_desired.cross(b_z).normalized()
	var b_y = b_z.cross(b_x).normalized()

	var screen_basis = Basis(b_x, b_y, b_z)
	var model_basis = Basis(screen_basis.z, screen_basis.y, -screen_basis.x)

	var dev_scale = 0.35 # 30% larger!
	var model_center = Vector3(0.0586, 0.730, 0.0) * dev_scale
	var dev_pos = screen_cam_pos - model_basis * model_center

	print("dev_pos in camera:", dev_pos)
	print("dev_rotation in camera (deg):", model_basis.get_euler() * (180.0 / PI))
	print("dev_scale:", dev_scale)
	quit()
