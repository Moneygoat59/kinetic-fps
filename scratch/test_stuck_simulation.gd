extends SceneTree

func _init() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var terrain = DeadForestTerrain.new()
	root_node.add_child(terrain)
	terrain._ready()
	
	var event = DeadForestEvent.new()
	event.terrain = terrain
	root_node.add_child(event)
	
	# Spawn bunker 1
	event._spawn_bunker_1(Vector3(100, 0, 100))
	var b_pos = event.bunker_instance.global_position
	print("Bunker 1 pos: ", b_pos)
	
	# Create real player
	var player_scene = load("res://scenes/player/player.tscn")
	var player = player_scene.instantiate() as CharacterBody3D
	root_node.add_child(player)
	event.player = player
	
	# Place player inside Bunker 1 in front of desk
	# Bunker desk is at local (0, 0.45, -1.5)
	player.global_position = event.bunker_instance.to_global(Vector3(0, 0.5, -0.5))
	print("Player initial pos: ", player.global_position)
	
	# Tick physics a few times to let player settle on the bunker floor
	for frame in range(10):
		player._physics_process(0.016)
	print("Player pos after settling: ", player.global_position, " is_on_floor: ", player.is_on_floor())
	
	# Now trigger _start_path_to_hub()
	print("--- TRIGGERING _start_path_to_hub() ---")
	event._start_path_to_hub()
	print("Hub pos: ", event.hub_pos)
	print("Pylon 1 pos: ", event.pylons[0].global_position)
	print("Player pos right after start_path: ", player.global_position)
	
	# Tick physics 60 times (1 second of gameplay)
	for frame in range(60):
		# Simulate trying to walk forward
		player.input_ctrl.input_vec = Vector2(0, -1)
		player.input_ctrl.wish_dir = -player.global_transform.basis.z
		player._physics_process(0.016)
		if frame % 15 == 0:
			print("Frame ", frame, " player pos: ", player.global_position, " vel: ", player.velocity, " on_floor: ", player.is_on_floor())
			
	quit()
