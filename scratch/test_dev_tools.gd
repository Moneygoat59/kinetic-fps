extends SceneTree

const DEV_TOOLS_SCRIPT = preload("res://scripts/dev/dev_tools.gd")

func _init() -> void:
	print("--- Testing Dev Tools (Fog Toggle & Flycam) ---")

	var world = Node3D.new()
	root.add_child(world)

	# 1. Setup Environment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.fog_enabled = true
	env_node.environment = env
	world.add_child(env_node)

	# 2. Setup Dummy Player
	var player = CharacterBody3D.new()
	player.name = "Player"
	var head = Node3D.new(); head.name = "Head"
	var cam = Camera3D.new(); cam.name = "Camera3D"
	head.add_child(cam); player.add_child(head)
	player.position = Vector3(10.0, 1.0, 10.0)
	world.add_child(player)

	# 3. Instantiate DevTools
	var dev = DEV_TOOLS_SCRIPT.new()
	world.add_child(dev)
	dev._find_env()

	# Test 1: Fog Toggle
	print("Initial fog_enabled: ", env.fog_enabled)
	assert(env.fog_enabled == true, "Fog should initially be enabled")

	dev.toggle_fog()
	print("After toggle 1 fog_enabled: ", env.fog_enabled)
	assert(env.fog_enabled == false, "Fog should be disabled after toggle")
	assert(dev.fog_disabled == true, "dev.fog_disabled should be true")

	dev.toggle_fog()
	print("After toggle 2 fog_enabled: ", env.fog_enabled)
	assert(env.fog_enabled == true, "Fog should be re-enabled after second toggle")
	assert(dev.fog_disabled == false, "dev.fog_disabled should be false")
	print("[PASS] Fog toggle verified successfully!")

	# Test 2: Flycam Activation & Deactivation
	dev._find_player()
	assert(dev.cached_player == player, "Player should be cached")

	dev.toggle_flycam()
	assert(dev.flycam_active == true, "Flycam should be active")
	assert(dev.flycam != null, "Flycam node should exist")
	assert(dev.flycam.current == true, "Flycam should be the current camera")
	assert(player.is_physics_processing() == false, "Player physics should be paused during flycam")

	# Move flycam
	dev.flycam.position = Vector3(100.0, 50.0, 100.0)

	# Deactivate flycam (with teleport)
	dev.toggle_flycam(false)
	assert(dev.flycam_active == false, "Flycam should be inactive")
	assert(dev.flycam == null, "Flycam node should be freed")
	assert(player.is_physics_processing() == true, "Player physics should be resumed")
	print("Player position after flycam landing: ", player.position)
	assert(player.position.distance_to(Vector3(100.0, 48.6, 100.0)) < 0.1, "Player should be teleported to flycam position")
	print("[PASS] Flycam activation, movement, and landing teleport verified successfully!")

	# Test 3: Flycam Deactivation with Cancel (Shift held)
	var orig_pos = player.position
	dev.toggle_flycam()
	dev.flycam.position = Vector3(500.0, 100.0, 500.0)
	dev.toggle_flycam(true) # cancel teleport
	assert(player.position == orig_pos, "Player position should not change on cancel")
	print("[PASS] Flycam cancel-teleport verified successfully!")

	print("--- ALL DEV TOOLS TESTS COMPLETED SUCCESSFULLY! ---")
	quit()
