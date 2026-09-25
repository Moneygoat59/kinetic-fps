extends SceneTree

func _init() -> void:
	var event = DeadForestEvent.new()
	root.add_child(event)
	event._spawn_bunker_1(Vector3(150.0, 0.0, 150.0))
	var b = event.bunker_instance
	print("b inside tree: ", b.is_inside_tree())
	print("b transform.basis.z: ", b.transform.basis.z)
	print("b global_transform.basis.z: ", b.global_transform.basis.z)
	quit()
