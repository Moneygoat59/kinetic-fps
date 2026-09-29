extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): builds Outposts 02 and 03 in the forest the way DeadForestEvent
## does and verifies the variant wiring: model, door, route-key station (channel-tinted lamp, key node, claim -> key_acquired
## with the right id, key freed), channel-coloured beacon, pump running on 02 and stalled on 03.

func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	for id in [2, 3]:
		var col: Color = HubRoutes.COLORS[HubRoutes.Route.W02 if id == 2 else HubRoutes.Route.W03]
		var o = ev.OUTPOST_SCRIPT.new()
		o.build_outpost(terrain, 60.0 * id, -40.0, id, col)
		ev.add_child(o)
		var got: Array[int] = []
		o.key_acquired.connect(func(k: int) -> void: got.append(k))
		var lamp: BaseMaterial3D = o.pickup._lamp if o.pickup else null
		_check("%d model" % id, o.model != null and String(o.model.scene_file_path).contains("outpost0%d" % id))
		_check("%d door" % id, o.door != null)
		_check("%d key station" % id, o.pickup != null and o.pickup._key != null)
		_check("%d lamp tinted" % id, lamp != null and lamp.emission.is_equal_approx(col))
		_check("%d beacon tinted" % id, o._beacon != null and o._beacon.emission.is_equal_approx(col))
		_check("%d pump %s" % [id, "stalled" if id == 3 else "running"], (o.pump == null) == (id == 3))
		_check("%d no claim from afar" % id, not o.check_interaction(o.global_position + Vector3(0, 0, 30)) and got.is_empty())
		var key: Node3D = o.pickup._key
		_check("%d claim" % id, o.check_interaction(o.global_position, true) and got == [id])
		_check("%d key freed" % id, key.is_queued_for_deletion())
		_check("%d claims once" % id, not o.check_interaction(o.global_position, true) and got.size() == 1)


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
