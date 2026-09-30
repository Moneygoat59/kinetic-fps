extends SceneTree

func _init() -> void:
	var event = DeadForestEvent.new()
	root.add_child(event)
	event._spawn_bunker_1(Vector3(150.0, 0.0, 150.0))
	var b = event.bunker_instance
	print("bunker pos: ", b.position)
	print("bunker rot.y: ", b.rotation.y, " deg=", rad_to_deg(b.rotation.y))
	print("bunker basis.z: ", b.global_transform.basis.z)
	event._start_path_to_hub()
	print("pylon 1 pos: ", event.pylons[0].position)
	print("hub pos: ", event.hub_pos)
	var diff = event.pylons[0].position - b.position
	print("diff pylon 1 - bunker: ", diff)
	print("dot with basis.z: ", b.global_transform.basis.z.dot(diff.normalized()))
	quit()
