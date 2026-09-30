extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the silo depths, the section after the lift crash. Checks the story
## data (night 4's sleep leads to the silo level), then switches to scenes/levels/silo_depths.tscn and drives it: the lift is
## wrecked at the foot of the shaft with the walker in it, the walker comes to and stands, the cage gate holds until forced
## and then both hall-side gates open; there is floor under the whole walk (cage -> hall -> pit door -> tunnel -> bridge
## -> the four flights -> the bore floor, and the hall to the vent), the pit door opens on approach, the moon is hidden
## down there; the vent takes the walker in (crawl stance, eyes low), has floor all the way to its cap, and lets them out
## standing on the hall floor; a long fall trips FallGuard and a short one does not. Sound: the wake mutes the world through
## a Dazed bus and puts every bus back when it ends; the duct's breathing starts inside and fades out after.
## Blender (x, y, z) silo-space positions, converted with G().

const LEVEL := "res://scenes/levels/silo_depths.tscn"
const FL := -119.95          # generator hall floor (silo_hall.py), bore floor (silo_pit.py: 16 m under it)
const FLOOR := -135.95
const PIT_A := -128.0        # silo_pit.py: stair frame
const TIMEOUT := 20.0        # s real time for each wait below (Engine.time_scale 4)


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("depths_check", self)              # the scene is swapped below: stay alive on the tree
	tree.set_meta("capture_hold", true)
	_check("night 4's sleep leads to the silo depths", ForestNights.spec(4).get("sleep", &"") == &"silo"
		and tree.root.get_node("LevelFlow").LEVELS.has(&"silo"))
	_check("night 5 still goes back to the forest", not ForestNights.spec(5).has("sleep"))
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	if level == null or level.silo == null or level.silo.lift == null:
		_check("the silo depths level built its silo and lift", false)
		_finish(tree)
		return
	var silo := level.silo
	var lift := silo.lift
	var player := level.player
	var space := silo.get_world_3d().direct_space_state
	_check("the lift is wrecked at the foot (CRASH, cage down, debris shown)", lift.state == SiloLift.State.CRASH
		and lift.wrecked != null and is_equal_approx(lift._body.position.y, -lift.drop)
		and silo.model.get_node("silo_lift_wreck").visible)
	_check("the walker comes to in the cage, frozen", lift.in_cage(player.global_position) and not player.is_physics_processing())
	var ears := level.find_children("*", "HearingReturn", true, false)
	var dazed := AudioServer.get_bus_index(HearingReturn.DAZED)
	var hall_bus := silo.generators._sound.muffle
	_check("ears ringing: the world is muffled (a Dazed bus the machines' own bus sends into)", ears.size() == 1 and dazed > 0
		and hall_bus.send == HearingReturn.DAZED and AudioServer.get_bus_index(SiloGeneratorSound.BUS) > dazed
		and silo.generators._sound._drones[0].bus == SiloGeneratorSound.BUS)
	Engine.time_scale = 4.0
	await _until(tree, func() -> bool: return player.is_physics_processing())
	_check("the walker gets up (camera home, control back)", player.is_physics_processing()
		and player.camera.position.length() < 0.01)
	if not ears.is_empty() and is_instance_valid(ears[0]):
		ears[0].queue_free()                             # hearing comes back early: the buses must come back too
	await tree.process_frame
	_check("hearing back: the Dazed bus is gone and the machines' bus sends to Master again",
		AudioServer.get_bus_index(HearingReturn.DAZED) == -1 and hall_bus.send == MuffleBus.MASTER)
	var cab := silo.model.get_node("marker_lift_bottom") as Node3D
	var out_dir := cab.global_basis.z
	var skip: Array[RID] = [player.get_rid()]
	_check("the cage gate holds before it is forced", _ray(space, cab.global_position + Vector3.UP, out_dir, 4.0, skip))
	lift.wrecked.force()
	var gates_up := func() -> bool: return lift._gates["out"].state == LiftGate.State.OPEN and lift._gates["bottom"].state == LiftGate.State.OPEN
	await _until(tree, gates_up)
	_check("forcing it opens both hall-side gates", lift.wrecked.state == SiloLiftWreck.State.OPEN
		and not _ray(space, cab.global_position + Vector3.UP, out_dir, 4.0, skip))
	Engine.time_scale = 1.0
	var fails := 0
	for p in _pit_walk():
		fails += _floor(space, silo, p)
	for m in ["marker_lift_bottom", "marker_lift_call_bottom", "marker_pit_door", "marker_vent_mouth", "marker_pit_floor"]:
		fails += _floor_at(space, (silo.model.get_node(m) as Node3D).global_position)
	_check("floor under the walk: cage, hall, tunnel, bridge, four flights, bore floor", fails == 0)
	_door_opens(silo)
	var bottom := G(silo, _pit(-3.0, 51.0, FLOOR))
	_check("the pit counts as underground (moon hidden there)", SiloPit.in_pit(silo.to_local(bottom)))
	await _vent(tree, silo, player, space)
	await _falls(tree, player, G(silo, Vector3(40.0 * cos(deg_to_rad(-60.0)), 40.0 * sin(deg_to_rad(-60.0)), FLOOR)))
	_finish(tree)


## The walk from the tunnel down the pit stair to the floor (Blender coordinates).
func _pit_walk() -> Array:
	var pts: Array = [_pit(0, 58.5, FL), _pit(0, 56.5, FL), _pit(0, 55.0, FL), _pit(0, 52.5, FL)]
	for n in range(1, 5):
		var top := FL - (n - 1) * 4.0
		var odd := n % 2 == 1
		for f in [0.15, 0.5, 0.85]:
			pts.append(_pit(1.0 + 8.0 * f if odd else 9.0 - 8.0 * f, 53.0 if odd else 51.0, top - 4.0 * f))
		if n < 4:
			pts.append(_pit(10.0 if odd else 0.0, 52.0, top - 4.0))
	pts.append(_pit(-3.0, 51.0, FLOOR))
	for ra in [[30.0, -60.0], [45.0, 20.0], [50.0, 170.0], [36.0, -120.0], [50.0, -70.0], [26.0, 90.0]]:
		var a := deg_to_rad(ra[1])
		pts.append(Vector3(ra[0] * cos(a), ra[0] * sin(a), FLOOR))
	return pts


func _door_opens(silo: MissileSilo) -> void:
	var at := (silo.model.get_node("marker_pit_door") as Node3D).global_position
	silo.check_interaction(at)
	var door: BunkerDoor = null
	for i in silo._doors.size():
		if silo._door_centers[i].global_position.distance_to(at) < 4.0:
			door = silo._doors[i]
	if door == null:
		_check("the pit has a blast door", false)
		return
	door._process(BunkerDoor.OPEN_TIME)
	_check("the pit door opens on approach", door.state == BunkerDoor.State.OPEN)


func _vent(tree: SceneTree, silo: MissileSilo, player: Player, space: PhysicsDirectSpaceState3D) -> void:
	_check("the hall has one open vent", silo.vents.size() == 1)
	if silo.vents.is_empty():
		return
	var vent: VentDuct = silo.vents[0]
	var mouth := (silo.model.get_node("marker_vent_mouth") as Node3D).global_position
	player.global_position = mouth + Vector3.UP * 0.05
	player.velocity = Vector3.ZERO
	await tree.physics_frame
	_eye(vent, player)
	_check("CLIMB INTO DUCT offered at the mouth", vent.can_interact() and vent.get_interaction_prompt() == VentDuct.TITLE_IN)
	vent.interact(player)
	await _until(tree, func() -> bool: return vent.state == VentDuct.State.INSIDE)
	_check("climbing in: inside, crawling, eyes low, moving again", vent.state == VentDuct.State.INSIDE
		and player.crawl.stance == PlayerCrawl.Stance.CRAWL and player.head.position.y < O73Kit.DUCT_H
		and player.is_physics_processing())
	var sound := silo.model.get_node("DuctSound") as DuctSound
	_check("crawling: the duct's sound is on (breathing)", sound != null and sound.state == DuctSound.State.CRAWLING
		and sound._calm.playing)
	var fails := 0
	for m in silo.model.get_children():
		if String(m.name).begins_with("marker_kit_duct_") and not String(m.name).contains("grille") \
				and not String(m.name).contains("cap"):
			var at := (m as Node3D).global_position + (m as Node3D).global_basis.z * -0.3
			fails += _floor_at(space, at)
	var end := (silo.model.get_node("marker_vent_end") as Node3D).global_position
	fails += _floor_at(space, end)
	_check("floor all along the duct to its cap", fails == 0)
	_check("the duct counts as underground", SiloGenerators.in_vent(silo.to_local(end)))
	player.global_position = vent._crawl_at.global_position + Vector3.UP * 0.05
	await tree.physics_frame
	_eye(vent, player)
	_check("CLIMB OUT offered from inside", vent.can_interact() and vent.get_interaction_prompt() == VentDuct.TITLE_OUT)
	vent.interact(player)
	await _until(tree, func() -> bool: return vent.state == VentDuct.State.OUTSIDE)
	await tree.physics_frame
	_check("climbing out: standing on the hall floor", player.crawl.stance == PlayerCrawl.Stance.STAND
		and absf(player.global_position.y - (FL + silo.global_position.y)) < 0.3 and player.head.position.y > 1.0)
	await _until(tree, func() -> bool: return sound == null or sound.state == DuctSound.State.IDLE)
	_check("out of the duct: the breathing fades and stops", sound != null and sound.state == DuctSound.State.IDLE
		and not sound._calm.playing)


func _falls(tree: SceneTree, player: Player, spot: Vector3) -> void:
	var guard := FallGuard.new()
	guard.setup(player)
	tree.current_scene.add_child(guard)
	var hits := [0]
	guard.hard_landing.connect(func(_s: float) -> void: hits[0] += 1)
	for drop in [6.0, 60.0]:
		player.global_position = spot + Vector3(0.0, drop, 0.0)
		player.velocity = Vector3.ZERO
		await tree.physics_frame
		await _until(tree, func() -> bool: return player.is_on_floor())
		for i in 3:
			await tree.physics_frame
	_check("FallGuard: a 60 m drop is a hard landing, a 6 m one is not (%d)" % hits[0], hits[0] == 1)


## The prompt's reach is measured from the viewport's camera: in a capture run that is the capture tool's, so put it at
## the walker's eye.
func _eye(vent: VentDuct, player: Player) -> void:
	var cam := vent.get_viewport().get_camera_3d()
	if cam:
		cam.global_transform = player.camera.global_transform


func _until(tree: SceneTree, done: Callable) -> void:
	var t0 := Time.get_ticks_msec()
	while not done.call() and Time.get_ticks_msec() - t0 < TIMEOUT * 1000.0:
		await tree.physics_frame


func _finish(tree: SceneTree) -> void:
	Engine.time_scale = 1.0
	tree.set_meta("capture_hold", false)


func _pit(u: float, v: float, z: float) -> Vector3:
	var a := deg_to_rad(PIT_A)
	return Vector3(v * cos(a) - u * sin(a), v * sin(a) + u * cos(a), z)


static func G(silo: Node3D, b: Vector3) -> Vector3:
	return silo.to_global(Vector3(b.x, b.z, -b.y))


func _floor(space: PhysicsDirectSpaceState3D, silo: Node3D, b: Vector3) -> int:
	return _floor_at(space, G(silo, b), b)


func _floor_at(space: PhysicsDirectSpaceState3D, at: Vector3, label: Variant = null) -> int:
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.6, at + Vector3.DOWN * 1.5))
	var ok := not hit.is_empty() and absf(hit.position.y - at.y) < 0.45
	if not ok:
		print("CHECK FAIL no floor at %s (hit %s)" % [label if label != null else at, hit.get("position", "none")])
	return 0 if ok else 1


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, dir: Vector3, length: float, skip: Array[RID]) -> bool:
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + dir * length, 0xFFFFFFFF, skip)).is_empty()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
