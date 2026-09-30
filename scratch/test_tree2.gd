extends SceneTree

func _init() -> void:
	var event = DeadForestEvent.new()
	root.add_child(event)
	event._spawn_bunker_1(Vector3(150.0, 0.0, 150.0))
	var b = event.bunker_instance
	var b_fwd = b.transform.basis.z
	print("b transform.basis.z: ", b_fwd)
	var pts_dir = b_fwd.normalized()
	print("pts_dir: ", pts_dir)
	quit()
