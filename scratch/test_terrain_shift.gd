extends SceneTree

func _init() -> void:
	var terrain = DeadForestTerrain.new()
	root.add_child(terrain)
	terrain._ready()
	terrain.update_player_pos(Vector3(100, 0, 100))
	
	for bx in [50.0, 120.0, 200.0, 350.0]:
		var bz = bx * 0.7
		var bunker_y = terrain.get_height(bx, bz)
		var p1_x = bx + 12.0
		var p1_z = bz + 4.5
		var p1_gy = terrain.get_height(p1_x, p1_z)
		terrain.add_flat_zone(p1_x, p1_z, 22.0, p1_gy, 8.0)
		var bunker_y_after = terrain.get_height(bx, bz)
		print("bx=", bx, " diff=", bunker_y_after - bunker_y, " init_bunker_y=", bunker_y, " after_y=", bunker_y_after)
	quit()
