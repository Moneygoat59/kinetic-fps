extends SceneTree

func _init() -> void:
	print("[TEST] Starting Multi-Stage Pylon & Silo Progression Test...")

	var event = DeadForestEvent.new()
	var player = CharacterBody3D.new()
	var cam = Camera3D.new()
	var head = Node3D.new(); head.name = "Head"; head.add_child(cam); player.add_child(head)
	root.add_child(player)
	root.add_child(event)
	event.player = player

	# 1. Test Wandering -> Bunker 1
	event.wander_distance = 650.0
	event._physics_process(0.016)
	assert(event.current_state == DeadForestEvent.State.BUNKER_1, "Expected State.BUNKER_1")
	assert(event.bunker_instance != null, "Bunker 1 should exist")
	print("[TEST] Stage 1 PASSED: Bunker 1 spawned")

	# 2. Test Claiming Dosimeter -> Path to Hub
	event._start_path_to_hub()
	assert(event.hub_instance != null, "Hub instance should exist")
	assert(event.dosimeter != null, "Dosimeter should exist")
	assert(event.pylons.size() == 4, "Path 1 should have 4 pylons")
	assert(event.pylons[0].pylon_color == Color(1.0, 0.65, 0.12), "Path 1 should be Amber")
	# Test Hub Interaction at terminal position
	player.global_position = event.hub_instance.to_global(Vector3(0.0, 1.0, -2.0))
	var hub_can_interact = event.hub_instance.check_interaction(player.global_position)
	assert(hub_can_interact, "Player at Hub terminal must be able to interact!")
	print("[TEST] Stage 2 PASSED: Amber Pylons & Central Hub spawned (Hub Terminal Interaction VERIFIED)")

	# 3. Test Hub Stage 0 -> Cyan Pylons & Outpost 2
	event._on_hub_interacted(0)
	assert(event.current_state == DeadForestEvent.State.OUTPOST_2_ACTIVE, "Expected OUTPOST_2_ACTIVE")
	assert(event.outpost_2_instance != null, "Outpost 2 should exist")
	assert(event.pylons.size() == 4, "Path 2 should have 4 pylons")
	assert(event.pylons[0].pylon_color == Color(0.15, 0.8, 1.0), "Path 2 should be Cyan")
	print("[TEST] Stage 3 PASSED: Cyan Pylons & Outpost 2 spawned")

	# 4. Test Key Extraction Outpost 2 -> Return to Hub
	event._on_outpost_key_acquired(2)
	assert(event.hub_instance.current_stage == 2, "Hub should be at stage 2")
	print("[TEST] Stage 4 PASSED: Outpost 2 Key acquired, return track set")

	# 5. Test Hub Stage 2 -> Green Pylons & Outpost 3
	event._on_hub_interacted(2)
	assert(event.current_state == DeadForestEvent.State.OUTPOST_3_ACTIVE, "Expected OUTPOST_3_ACTIVE")
	assert(event.outpost_3_instance != null, "Outpost 3 should exist")
	assert(event.pylons.size() == 4, "Path 3 should have 4 pylons")
	assert(event.pylons[0].pylon_color == Color(0.2, 0.95, 0.35), "Path 3 should be Emerald Green")
	print("[TEST] Stage 5 PASSED: Green Pylons & Outpost 3 spawned")

	# 6. Test Key Extraction Outpost 3 -> Return to Hub
	event._on_outpost_key_acquired(3)
	assert(event.hub_instance.current_stage == 4, "Hub should be at stage 4")
	print("[TEST] Stage 6 PASSED: Outpost 3 Key acquired, return track set")

	# 7. Test Hub Stage 4 -> Crimson Pylons & Missile Silo
	event._on_hub_interacted(4)
	assert(event.current_state == DeadForestEvent.State.SILO_ACTIVE, "Expected SILO_ACTIVE")
	assert(event.silo_instance != null, "Missile Silo should exist")
	assert(event.pylons.size() == 5, "Path 4 should have 5 pylons")
	assert(event.pylons[0].pylon_color == Color(1.0, 0.15, 0.1), "Path 4 should be Crimson")
	print("[TEST] Stage 7 PASSED: Crimson Pylons & Missile Silo spawned")

	# 8. Test Silo Activation -> Climax / Completion
	event.silo_instance._activate_silo()
	assert(event.current_state == DeadForestEvent.State.COMPLETED, "Expected COMPLETED")
	print("[TEST] Stage 8 PASSED: Missile Silo activated and level completed!")

	print("[TEST] ALL PROGRESSION TESTS COMPLETED SUCCESSFULLY!")
	quit()
