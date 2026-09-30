extends SceneTree

func _init() -> void:
	var n = Node3D.new()
	root.add_child(n)
	var dx = 10.0
	var dz = 0.0
	var ang = atan2(dx, dz)
	n.rotation.y = ang
	print("dx=", dx, " dz=", dz, " ang=", ang, " deg=", rad_to_deg(ang))
	print("basis.z=", n.global_transform.basis.z)
	print("basis.x=", n.global_transform.basis.x)
	quit()
