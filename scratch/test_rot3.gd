extends SceneTree

func _init() -> void:
	var dx = 10.0
	var dz = 0.0
	var ang = atan2(dx, dz)
	var t = Transform3D().rotated(Vector3.UP, ang)
	print("dx=", dx, " dz=", dz, " ang=", ang, " deg=", rad_to_deg(ang))
	print("basis.z=", t.basis.z)
	print("basis.x=", t.basis.x)
	quit()
