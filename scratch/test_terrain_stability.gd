extends SceneTree

func _init() -> void:
	var terrain = DeadForestTerrain.new()
	root.add_child(terrain)
	terrain._ready()
	
	var event = DeadForestEvent.new()
	event.terrain = terrain
	root.add_child(event)
	
	# Spawn Bunker 1
	event._spawn_bunker_1(Vector3(150.0, 0.0, 150.0))
	var b_pos = event.bunker_instance.position
	var height_before = terrain.get_height(b_pos.x, b_pos.z)
	print("Height under Bunker 1 BEFORE grabbing dosimeter: ", height_before)
	
	# Start path to hub (claims dosimeter)
	event._start_path_to_hub()
	var height_after = terrain.get_height(b_pos.x, b_pos.z)
	print("Height under Bunker 1 AFTER grabbing dosimeter: ", height_after)
	
	var diff = abs(height_after - height_before)
	print("Terrain height shift under Bunker 1: ", diff)
	assert(diff < 0.001, "Terrain under Bunker 1 must NOT shift when dosimeter is grabbed!")
	
	var p1 = event.pylons[0]
	var p1_pos = p1.position
	print("Pylon 1 position: ", p1_pos)
	print("Bunker 1 to Pylon 1 distance: ", b_pos.distance_to(p1_pos))
	
	# Check forward direction: Pylon 1 should be in front of Bunker 1's doorway
	var b_fwd = event.bunker_instance.transform.basis.z
	var to_p1 = (p1_pos - b_pos).normalized()
	var dot = b_fwd.dot(to_p1)
	print("Dot product of Bunker entrance forward and Pylon 1: ", dot)
	assert(dot > 0.5, "Pylon 1 must be in front of the bunker doorway!")
	
	print("[SUCCESS] Terrain stability and doorway orientation verified!")
	quit()
