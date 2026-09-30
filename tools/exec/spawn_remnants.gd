extends RefCounted
## capture.ps1 -Exec hook: apartment remnants to look at.
##   REMNANTS=buried (default): every BuriedRemnants piece in each of its poses, a line along x at z = -24 (4 m apart,
##     starting x = -24), on a flat pad; e.g. -Cam 0,3,-12 -Look 0,0.5,-24.
##   REMNANTS=bunker: Outpost 73 at (0, 0, -40) as DeadForestEvent builds it; prints where its remnants stand.

func run(scene: Node, _tree: SceneTree) -> void:
	var terrain = scene.get_node("DeadForestTerrain")
	var props = scene.get_node("DeadForestProps")
	if OS.get_environment("REMNANTS") == "bunker":
		var ev = scene.get_node("DeadForestEvent")
		props.clear_area(Vector3(0.0, 0.0, -40.0), 16.0)
		terrain.add_flat_zone(0.0, -40.0, 20.0, 0.0, 9.0)
		terrain.update_player_pos(Vector3(0.0, 0.0, -40.0))
		var bunker = ev.BUNKER_SCRIPT.new()
		bunker.build_bunker(terrain, 0.0, -40.0)
		ev.add_child(bunker)
		for c in bunker.model.get_children():
			if String(c.name).begins_with("remnant_"):
				print("REMNANT %s at %s" % [c.name, (bunker.model.transform * (c as Node3D).position + bunker.position).snappedf(0.01)])
		return
	props.clear_area(Vector3(0.0, 0.0, -24.0), 30.0)
	terrain.add_flat_zone(0.0, -24.0, 34.0, 0.0, 30.0)
	terrain.update_player_pos(Vector3(0.0, 0.0, -24.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var root := Node3D.new()
	scene.add_child(root)
	var x := -24.0
	for kind in BuriedRemnants.PIECES:
		for pose in BuriedRemnants.PIECES[kind]:
			BuriedRemnants.place(kind, root, terrain, Vector3(x, 0.0, -24.0), rng.randf_range(-0.6, 0.6), pose, rng)
			x += 4.0
