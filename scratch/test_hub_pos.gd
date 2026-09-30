extends SceneTree

func _init() -> void:
	var event = DeadForestEvent.new()
	var player = CharacterBody3D.new()
	var cam = Camera3D.new(); cam.name = "Camera3D"
	var head = Node3D.new(); head.name = "Head"; head.add_child(cam); player.add_child(head)
	root.add_child(player); root.add_child(event)
	event.player = player

	event.wander_distance = 650.0; event._physics_process(0.016)
	print("bunker_1 pos: ", event.bunker_instance.position)

	# Simulate player looking straight down at desk
	cam.rotation.x = deg_to_rad(-90.0)
	event._start_path_to_hub()
	print("hub_pos: ", event.hub_pos)
	print("Distance between bunker_1 and hub: ", event.bunker_instance.position.distance_to(event.hub_pos))
	print("pylons count: ", event.pylons.size())
	for i in range(event.pylons.size()):
		print("  pylon ", i+1, " pos: ", event.pylons[i].position, " dist to bunker_1: ", event.bunker_instance.position.distance_to(event.pylons[i].position))
	quit()
