extends SceneTree

const DEV_MANAGER = preload("res://scripts/dev/dev_tools.gd")

func _init() -> void:
	print("[TEST] Starting Dev Teleport & Auto-Spawn Test...")

	var terrain = DeadForestTerrain.new()
	terrain.name = "DeadForestTerrain"
	root.add_child(terrain)
	terrain._ready()

	var player = CharacterBody3D.new()
	player.name = "Player"
	var col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.height = 1.8; cap.radius = 0.4
	col.shape = cap; col.position = Vector3(0.0, 0.9, 0.0)
	player.add_child(col)
	var head = Node3D.new(); head.name = "Head"
	var cam = Camera3D.new(); cam.name = "Camera3D"
	head.add_child(cam); player.add_child(head)
	root.add_child(player)

	var event = DeadForestEvent.new()
	event.name = "DeadForestEvent"
	event.player = player
	event.terrain = terrain
	root.add_child(event)

	var dev = DEV_MANAGER.new()
	dev.name = "DevManager"
	root.add_child(dev)

	# 1. Teleport to Bunker 1 (F5 / id=1) when not spawned
	print("[TEST] Testing Teleport to Bunker 1 (unspawned)...")
	dev.teleport_to_poi(1)
	assert(event.bunker_instance != null, "Bunker 1 should have auto-spawned!")
	var b_pos = event.bunker_instance.position
	var p_pos1 = player.position
	var dist_b1 = p_pos1.distance_to(b_pos)
	print("  Player distance to Bunker 1: %.2fm (expected ~6.8m)" % dist_b1)
	assert(dist_b1 > 5.0 and dist_b1 < 10.0, "Player should be right outside bunker entrance!")
	var chunk_dist1 = player.position.distance_to(Vector3(terrain.last_player_chunk.x * 48.0, 0, terrain.last_player_chunk.y * 48.0))
	assert(chunk_dist1 < 50.0, "Terrain chunks should be centered on player!")
	print("[TEST] Bunker 1 auto-spawn & teleport VERIFIED!")

	# 2. Teleport to Central Hub (F6 / id=2) when not spawned
	print("[TEST] Testing Teleport to Central Hub (unspawned)...")
	dev.teleport_to_poi(2)
	assert(event.hub_instance != null, "Central Hub should have auto-spawned!")
	var h_pos = event.hub_instance.position
	var p_pos2 = player.position
	var dist_h = p_pos2.distance_to(h_pos)
	print("  Player distance to Hub: %.2fm (expected ~7.5m)" % dist_h)
	assert(dist_h > 5.0 and dist_h < 12.0, "Player should be right outside hub entrance!")
	print("[TEST] Central Hub auto-spawn & teleport VERIFIED!")

	# 3. Teleport to Outpost 2 (F7 / id=3)
	print("[TEST] Testing Teleport to Outpost 2 (unspawned)...")
	dev.teleport_to_poi(3)
	assert(event.outpost_2_instance != null, "Outpost 2 should have auto-spawned!")
	var op2_pos = event.outpost_2_instance.position
	var dist_op2 = player.position.distance_to(op2_pos)
	print("  Player distance to Outpost 2: %.2fm (expected ~5.5m)" % dist_op2)
	assert(dist_op2 > 4.0 and dist_op2 < 10.0, "Player should be right outside Outpost 2 entrance!")
	print("[TEST] Outpost 2 auto-spawn & teleport VERIFIED!")

	# 4. Teleport to Outpost 3 (F8 / id=4)
	print("[TEST] Testing Teleport to Outpost 3 (unspawned)...")
	dev.teleport_to_poi(4)
	assert(event.outpost_3_instance != null, "Outpost 3 should have auto-spawned!")
	var op3_pos = event.outpost_3_instance.position
	var dist_op3 = player.position.distance_to(op3_pos)
	print("  Player distance to Outpost 3: %.2fm (expected ~5.5m)" % dist_op3)
	assert(dist_op3 > 4.0 and dist_op3 < 10.0, "Player should be right outside Outpost 3 entrance!")
	print("[TEST] Outpost 3 auto-spawn & teleport VERIFIED!")

	# 5. Teleport to Missile Silo (F9 / id=5)
	print("[TEST] Testing Teleport to Missile Silo (unspawned)...")
	dev.teleport_to_poi(5)
	assert(event.silo_instance != null, "Missile Silo should have auto-spawned!")
	var s_pos = event.silo_instance.position
	var dist_s = player.position.distance_to(s_pos)
	print("  Player distance to Silo center: %.2fm (expected ~24m at catwalk)" % dist_s)
	assert(dist_s > 18.0 and dist_s < 32.0, "Player should be at the observation catwalk!")
	print("[TEST] Missile Silo auto-spawn & teleport VERIFIED!")

	print("[TEST] ALL TELEPORT TESTS PASSED SUCCESSFULLY!")
	quit()
