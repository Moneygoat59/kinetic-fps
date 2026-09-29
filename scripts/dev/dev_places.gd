class_name DevPlaces
extends RefCounted
## The dev menu's GO TO list: places in the running level, read from the level itself so new ones appear on their own.
##   apartment  the bedside spawn, then every live interaction point (AptUse group: bed, locks, stove...), stood in front of
##   forest     the wake spot, and on nights with buildings (ForestNights "event") the five POIs, built on demand
##   others     whatever the level's dev_places() lists: [label, feet position, point to face] (SiloDepthsLevel)
## list() -> [{label, key}]; resolve(key) -> {pos: feet position, look: point to face} or {}; stand() puts the walker there.

const POI_NAMES := ["Bunker 1", "Central Hub", "Outpost 02", "Outpost 03", "Missile Silo"]
const POI_REACH := [6.8, 7.5, 5.5, 5.5, 70.0]    # metres out in front of each POI's door
const USE_REACH := 0.7                           # metres between an apartment use's trigger box and the walker
const SPAWN := &"spawn"


static func list(tree: SceneTree) -> Array:
	var out := []
	var scene := tree.current_scene if tree else null
	if scene is ApartmentLevel:
		out.append({"label": "Bedside (spawn)", "key": SPAWN})
		var uses := tree.get_nodes_in_group(AptUse.GROUP)
		uses.sort_custom(func(a, b): return _use_rank(a) < _use_rank(b))
		for use in uses:
			if (use as AptUse).enabled:
				out.append({"label": (use as AptUse).get_interaction_prompt().capitalize(), "key": use})
	elif scene is DeadForestManager:
		if ForestNights.spec(ForestNights.current(tree))["event"]:
			for i in POI_NAMES.size():
				out.append({"label": POI_NAMES[i], "key": i + 1})
		out.append({"label": "Wake spot", "key": SPAWN})
	elif scene and scene.has_method("dev_places"):             # any other level lists its own ([label, pos, look] rows)
		for row in scene.call("dev_places"):
			out.append({"label": row[0], "key": row})
	return out


static func resolve(tree: SceneTree, key: Variant) -> Dictionary:
	var scene := tree.current_scene if tree else null
	if scene == null:
		return {}
	if scene is ApartmentLevel:
		return _apartment(scene as ApartmentLevel, key)
	if key is Array:
		return {"pos": key[1], "look": key[2]}
	if key is int:
		return _poi(scene, key)
	if not scene is DeadForestManager:
		return {}
	var at: Vector3 = (scene as DeadForestManager).spawn_point
	return {"pos": _on_ground(scene, at), "look": at + Vector3(0.0, 1.5, -10.0)}


## Stands the walker at `pos` facing `look` (in the forest it also becomes the fall-reset point and ends the wake-up).
static func stand(scene: Node, pos: Vector3, look: Vector3) -> bool:
	var player := scene.find_child("Player", true, false) as CharacterBody3D if scene else null
	if player == null:
		return false
	if scene is DeadForestManager:
		(scene as DeadForestManager).spawn_point = pos
		var wake := scene.find_child("WakeCanvas", true, false)
		if wake: wake.queue_free()
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.global_position = pos
	player.rotation.y = atan2(pos.x - look.x, pos.z - look.z)
	player.velocity = Vector3.ZERO
	var head := player.get_node_or_null("Head") as Node3D
	if head: head.rotation.x = 0.0
	return true


static func _use_rank(use: Node) -> int:
	var id: StringName = (use as AptUse).id
	return 0 if id == &"sleep" else AptUse.Uses.SPECS.keys().find(id) + 1


static func _apartment(level: ApartmentLevel, key: Variant) -> Dictionary:
	var spawn := level.model.get_node_or_null("marker_spawn") as Node3D if level.model else null
	if spawn == null:
		return {}
	var floor_y := spawn.global_position.y
	if key is StringName and key == SPAWN:
		var ahead := -spawn.global_basis.z
		return {"pos": Vector3(spawn.global_position.x, floor_y, spawn.global_position.z), "look": spawn.global_position + ahead}
	var use := key as AptUse
	if use == null or not is_instance_valid(use) or not use.is_inside_tree():
		return {}
	var front := Vector3(use.global_basis.z.x, 0.0, use.global_basis.z.z)
	front = front.normalized() if front.length_squared() > 0.001 else Vector3.BACK
	var depth := 0.3
	var shape := use.get_child(0) as CollisionShape3D
	if shape and shape.shape is BoxShape3D:
		depth = (shape.shape as BoxShape3D).size.z * 0.5
	var at := use.global_position + front * (depth + USE_REACH)
	return {"pos": Vector3(at.x, floor_y, at.z), "look": use.global_position}


## Builds the POI (and the ones before it, as the story would) if it is not up yet; stands in front of its door.
static func _poi(scene: Node, id: int) -> Dictionary:
	var ev := scene.find_child("DeadForestEvent", true, false)
	if ev == null or id < 1 or id > POI_NAMES.size():
		return {}
	var target := _ensure_poi(ev, id)
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return {}
	var t_pos := target.global_position
	var fwd := target.global_basis.z
	return {"pos": _on_ground(scene, t_pos + fwd * POI_REACH[id - 1]), "look": t_pos + Vector3(0.0, 1.5, 0.0)}


static func _ensure_poi(ev: Node, id: int) -> Node3D:
	if id >= 1 and not ev.get("bunker_instance"):
		var player := ev.get("player") as Node3D
		ev.call("_spawn_bunker_1", player.global_position if player else Vector3.ZERO)
	if id >= 2 and not ev.get("hub_instance"): ev.call("_on_terminal_programmed", HubRoutes.Route.W73)
	if id >= 3 and not ev.get("outpost_2_instance"): ev.call("_on_hub_interacted", 0)
	if id >= 4 and not ev.get("outpost_3_instance"):
		ev.call("_on_outpost_key_acquired", 2); ev.call("_on_hub_interacted", 2)
	if id >= 5 and not ev.get("silo_instance"):
		ev.call("_on_outpost_key_acquired", 3); ev.call("_on_hub_interacted", 4)
	var names := ["bunker_instance", "hub_instance", "outpost_2_instance", "outpost_3_instance", "silo_instance"]
	return ev.get(names[id - 1]) as Node3D


## The point dropped onto the forest floor (the terrain streams its chunks there first so the height is real).
static func _on_ground(scene: Node, at: Vector3) -> Vector3:
	var terrain := scene.find_child("DeadForestTerrain", true, false)
	if terrain == null or not terrain.has_method("get_height"):
		return at
	if terrain.has_method("update_player_pos"):
		terrain.update_player_pos(at)
	return Vector3(at.x, terrain.get_height(at.x, at.z) + 0.15, at.z)
