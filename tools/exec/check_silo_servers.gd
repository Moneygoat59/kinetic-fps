extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): spawns Missile Silo 00 like spawn_silo.gd and checks the level 09
## data room (tools/blender/props/silo_servers.py): floor under the walk from launch control through the left-wall doorway
## down the rack aisle to the operator console, nothing in the way chest high, the side walls hold, every kit piece
## spawned, the racks and trays batched, the room's lamps lit. Blender points in the room frame (silo_room.py: u along the
## wall, v out from the bore face), converted like check_silo.gd.

const SPAWN := preload("res://tools/exec/spawn_silo.gd")
const ROOM_A := -106.5      # silo_room.ROOM_A
const R := 56.0             # bore radius: room frame v is measured from it
const GZ := -35.95          # level 09 floor
const AISLE := 7.6          # silo_servers.AISLE (= the doorway's centre line)
const WALK_U: Array[float] = [-3.0, -5.5, -6.5, -7.2, -9.0, -11.0, -13.0, -15.1]
const KIT_PIECES := 33      # silo_servers.KIT rows: 7 furniture, 18 racks, 8 trays


func run(scene: Node, tree: SceneTree) -> void:
	SPAWN.new().run(scene, tree)
	scene.set_meta("silo_servers_check", self)     # capture.gd drops its reference to this hook; stay alive while awaiting
	tree.set_meta("capture_hold", true)
	for i in 3:
		await tree.physics_frame
	var ev = scene.get_node("DeadForestEvent")
	var silo: Node3D = ev.get_children().filter(func(n): return n is MissileSilo).back()
	var space := silo.get_world_3d().direct_space_state
	var walk: Array[Vector3] = []
	for u in WALK_U:
		walk.append(_room(u, AISLE))
	var fails := 0
	for p in walk:
		fails += _floor(space, silo, p)
	_check("launch control -> doorway -> rack aisle -> console has floor everywhere (%d samples)" % walk.size(), fails == 0)
	var blocked := 0
	for i in walk.size() - 1:
		blocked += _blocked(space, silo, walk[i], walk[i + 1])
	_check("the walk to the console is clear", blocked == 0)
	_check("the data room's side walls hold (rows of racks, then wall)", _hits(space, silo, _room(-11.8, AISLE), _room(-11.8, 3.0))
		and _hits(space, silo, _room(-11.8, AISLE), _room(-11.8, 12.0)))
	_check("the far end wall holds", _hits(space, silo, _room(-15.1, AISLE - 1.5), _room(-19.0, AISLE - 1.5)))
	var pieces := 0
	var console: Node = null
	for child in silo.model.get_children():
		if String(child.name).begins_with("marker_kit_") and String(child.name).contains("__srv") and child.get_child_count() > 0:
			pieces += 1
			if String(child.name).begins_with("marker_kit_terminal_server"):
				console = child.get_child(0)
	_check("every data room kit piece spawned (%d / %d)" % [pieces, KIT_PIECES], pieces == KIT_PIECES)
	_check("operator console is live (screen + light)", console != null and console.get_node_or_null("screens") != null
		and not console.find_children("*", "OmniLight3D", true, false).is_empty())
	var batches := silo.find_children("kit_batch_*", "MultiMeshInstance3D", false, false)
	var rack_faces := 0
	for node in silo.find_children("screens", "MeshInstance3D", true, false):
		rack_faces += 1 if String(node.get_parent().get_parent().name).begins_with("marker_kit_server_rack") else 0
	_check("racks and trays batched, each rack keeps its face (%d batches, %d faces)" % [batches.size(), rack_faces],
		batches.size() > 0 and rack_faces == 18)
	var lamps := 0
	for n in ["light_srv_0", "light_srv_1"]:
		lamps += 1 if silo.model.find_child(n, true, false) != null else 0
	_check("data room lamps lit (%d / 2)" % lamps, lamps == 2)
	tree.set_meta("capture_hold", false)


func _room(u: float, v: float) -> Vector3:
	var r := Vector2(cos(deg_to_rad(ROOM_A)), sin(deg_to_rad(ROOM_A)))
	var e_u := Vector2(cos(deg_to_rad(ROOM_A - 90.0)), sin(deg_to_rad(ROOM_A - 90.0)))
	var q: Vector2 = r * (R + v) + e_u * u
	return Vector3(q.x, q.y, GZ)


func G(silo: Node3D, b: Vector3) -> Vector3:
	return silo.to_global(Vector3(b.x, b.z, -b.y))


func _floor(space: PhysicsDirectSpaceState3D, silo: Node3D, b: Vector3) -> int:
	var at := G(silo, b)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.0, at + Vector3.DOWN * 1.5))
	var ok := not hit.is_empty() and absf(hit.position.y - at.y) < 0.4
	if not ok:
		print("CHECK FAIL no floor at blender %s (hit %s)" % [b, hit.get("position", "none")])
	return 0 if ok else 1


func _blocked(space: PhysicsDirectSpaceState3D, silo: Node3D, a: Vector3, b: Vector3) -> int:
	var up := Vector3(0, 0, 1.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(G(silo, a + up), G(silo, b + up)))
	if hit.is_empty():
		return 0
	print("CHECK FAIL blocked between blender %s and %s at %s" % [a, b, hit.position])
	return 1


func _hits(space: PhysicsDirectSpaceState3D, silo: Node3D, a: Vector3, b: Vector3) -> bool:
	var up := Vector3(0, 0, 1.0)
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(G(silo, a + up), G(silo, b + up))).is_empty()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
