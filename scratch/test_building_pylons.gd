extends SceneTree

func _init() -> void:
	print("--- Testing Pylon Placement Next to Buildings ---")
	var event = DeadForestEvent.new()
	var player = CharacterBody3D.new()
	var cam = Camera3D.new(); cam.name = "Camera3D"
	var head = Node3D.new(); head.name = "Head"; head.add_child(cam); player.add_child(head)
	root.add_child(player); root.add_child(event)
	event.player = player

	# 1. Bunker 1 -> Hub
	event.wander_distance = 650.0; event._physics_process(0.016)
	event._start_path_to_hub()

	var b1_pos = event.bunker_instance.position
	var p1_pos = event.pylons[0].position
	var d_b1_p1 = Vector2(b1_pos.x - p1_pos.x, b1_pos.z - p1_pos.z).length()
	print("Distance from Bunker 1 to Pylon 1: ", d_b1_p1, " m")
	assert(d_b1_p1 < 16.0, "Pylon 1 must be right next to Bunker 1")

	var hub_pos = event.hub_instance.position
	var p4_hub = event.pylons[3].position
	var d_hub_p4 = Vector2(hub_pos.x - p4_hub.x, hub_pos.z - p4_hub.z).length()
	print("Distance from Central Hub to Pylon 4: ", d_hub_p4, " m")
	assert(d_hub_p4 < 15.0, "Pylon 4 must be right next to Central Hub")

	# 2. Hub -> Outpost 2
	event._on_hub_interacted(0)
	var op2_pos = event.outpost_2_instance.position
	var p4_op2 = event.pylons[3].position
	var d_op2_p4 = Vector2(op2_pos.x - p4_op2.x, op2_pos.z - p4_op2.z).length()
	print("Distance from Outpost 2 to Pylon 4: ", d_op2_p4, " m")
	assert(d_op2_p4 < 15.0, "Pylon 4 must be right next to Outpost 2")

	# 3. Hub -> Outpost 3
	event._on_outpost_key_acquired(2)
	event._on_hub_interacted(2)
	var op3_pos = event.outpost_3_instance.position
	var p4_op3 = event.pylons[3].position
	var d_op3_p4 = Vector2(op3_pos.x - p4_op3.x, op3_pos.z - p4_op3.z).length()
	print("Distance from Outpost 3 to Pylon 4: ", d_op3_p4, " m")
	assert(d_op3_p4 < 15.0, "Pylon 4 must be right next to Outpost 3")

	# 4. Hub -> Missile Silo
	event._on_outpost_key_acquired(3)
	event._on_hub_interacted(4)
	var silo_pos = event.silo_instance.position
	var p5_silo = event.pylons[4].position
	var d_silo_p5 = Vector2(silo_pos.x - p5_silo.x, silo_pos.z - p5_silo.z).length()
	print("Distance from Missile Silo center to Pylon 5: ", d_silo_p5, " m")
	# Silo radius is 30m, catwalk starts at 33m, so pylon at ~34m is right at catwalk entrance!
	assert(d_silo_p5 > 30.0 and d_silo_p5 < 38.0, "Pylon 5 must be right at Silo catwalk entrance")

	print("--- ALL BUILDING PYLON PROXIMITY TESTS PASSED SUCCESSFULLY! ---")
	quit()
