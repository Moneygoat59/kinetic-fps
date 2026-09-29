extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): apartment remnants in the forest levels.
## Buildings: Outpost 73 and the relay hub get RemnantSmalls sets on free kit surfaces, clean, inert (no AptUse), never
## on top of another prop, the same set each build. Forest: BuriedRemnants turns up in about CHANCE of chunks, never in the
## start clearing, and every piece in every pose sinks into the ground with part of it showing, soiled by the grime overlay.

func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	var bunker = ev.BUNKER_SCRIPT.new()
	bunker.build_bunker(terrain, 0.0, -40.0)
	ev.add_child(bunker)
	_check_building("outpost 73", bunker.model)
	var again = ev.BUNKER_SCRIPT.new()
	again.build_bunker(terrain, 0.0, -80.0)
	ev.add_child(again)
	_check("outpost 73 same sets each build", _names(bunker.model) == _names(again.model))
	var hub = ev.HUB_SCRIPT.new()
	ev.add_child(hub)
	hub.build_hub(terrain, 120.0, -40.0, Vector3(0.0, 0.0, -40.0))
	_check_building("relay hub", hub.model)
	_check_scatter(terrain)
	_check_poses(scene, terrain)


func _check_building(what: String, model: Node3D) -> void:
	var smalls := _remnants(model)
	_check("%s has remnants (%d)" % [what, smalls.size()], smalls.size() > 0)
	var inert := true
	var clean := true
	for s in smalls:
		inert = inert and s.get_tree().get_nodes_in_group(AptUse.GROUP).filter(func(u): return s.is_ancestor_of(u)).is_empty()
		for mi in s.find_children("*", "MeshInstance3D", true, false):
			clean = clean and (mi as MeshInstance3D).material_overlay == null
	_check("%s remnants inert" % what, inert)
	_check("%s remnants clean" % what, clean)
	var clear := true
	for s in smalls:
		for child in model.get_children():
			var n := String(child.name)
			if n.begins_with("marker_kit_") and not n.contains("table_steel") and not n.contains("shelf_rack") \
					and not n.contains("crate_large"):
				var d: Vector3 = (child as Node3D).position - s.position
				clear = clear and not (absf(d.y) < 0.1 and Vector2(d.x, d.z).length() < 0.15)
	_check("%s remnants on free spots" % what, clear)


func _check_scatter(terrain: Node3D) -> void:
	var root := Node3D.new()
	terrain.add_child(root)
	var hits := 0
	var near_start := 0
	for cx in range(-15, 15):
		for cz in range(-15, 15):
			var got := BuriedRemnants.scatter(root, terrain, cx, cz, Callable())
			hits += got.size()
			for g in got:
				near_start += 1 if Vector2(g.x, g.y).length() < BuriedRemnants.CLEAR_ORIGIN else 0
	var rate := hits / 900.0
	_check("scatter is rare (%.3f of chunks)" % rate, rate > 0.03 and rate < 0.12)
	_check("scatter keeps the start clearing", near_start == 0)
	var blocked := BuriedRemnants.scatter(root, terrain, 7, 3, func(_x: float, _z: float) -> bool: return true)
	_check("scatter respects blocked", blocked.is_empty())
	root.queue_free()


func _check_poses(scene: Node, terrain: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ok := true
	var root := Node3D.new()
	scene.add_child(root)
	for kind in BuriedRemnants.PIECES:
		for pose in BuriedRemnants.PIECES[kind]:
			var at := Vector3(200.0, 0.0, 200.0)
			var piece := BuriedRemnants.place(kind, root, terrain, at, rng.randf() * TAU, pose, rng)
			var box := piece.transform * Remnant.bounds(piece)
			var ground: float = terrain.get_height(at.x, at.z)
			var sunk := box.position.y < ground - 0.1 and box.end.y > ground + 0.15
			var soiled := (piece.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).material_overlay != null
			var inert := piece.find_children("marker_use_*", "", true, false).is_empty()
			if not (sunk and soiled and inert):
				print("  %s pose %d: sunk %s soiled %s inert %s" % [kind, pose, sunk, soiled, inert])
			ok = ok and sunk and soiled and inert
			piece.free()
	_check("every piece and pose sunk, soiled, inert", ok)
	root.queue_free()


func _remnants(model: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in model.get_children():
		if String(c.name).begins_with("remnant_"):
			out.append(c)
	return out


func _names(model: Node3D) -> Array[String]:
	var out: Array[String] = []
	for r in _remnants(model):
		out.append("%s %s" % [r.name, r.position.snappedf(0.01)])
	return out


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
