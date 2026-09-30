extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): spawns Missile Silo 00 like spawn_silo.gd, then raycasts the walk
## from the apron over the bridge, down all nine flights to level 09, across the deck, through the door to the launch
## desk (floor under every step), on through the right-wall door and tunnel into the freight lift; rides the lift down
## with the real player on it (Engine.time_scale 6) and walks out round the generators; checks the landing gates block the
## shaft while the cage is away, the cages keep the player off the void, the fall reset waits below the hall, the hall zone
## (SiloGenerators.in_hall) and that the launch console engages once.
## Blender (x, y, z) positions, converted with G(). Look at failures with spawn_silo.gd.

const SPAWN := preload("res://tools/exec/spawn_silo.gd")
const X0 := -5.0            # silo_tower.py: tower centre x, lane centres, landing centre line
const LANE_A := -53.0
const LANE_B := -51.0
const YM := -52.0
const HALL_A0 := -114.5     # silo_hall.py / silo_lift.py: end-wall frame (x along the ray at A0), cage centre, floors
const CAB := Vector2(64.0, -2.0)
const GZ := -35.95
const FL := -119.95
const TRIP_TIMEOUT := 30.0  # s real time at time_scale 6


func run(scene: Node, tree: SceneTree) -> void:
	SPAWN.new().run(scene, tree)
	scene.set_meta("silo_check", self)             # capture.gd drops its reference to this hook; stay alive while awaiting
	tree.set_meta("capture_hold", true)            # the lift rides take longer than the shot's --wait
	for i in 3:
		await tree.physics_frame
	var ev = scene.get_node("DeadForestEvent")
	var silo: Node3D = ev.get_children().filter(func(n): return n is MissileSilo).back()
	var space := silo.get_world_3d().direct_space_state
	var terrain = scene.get_node("DeadForestTerrain")
	var c := silo.global_position
	var path: Array = [Vector3(0, -80, 0.05), Vector3(0, -70, 0.05), Vector3(0, -58, 0.05), Vector3(0, -55.9, 0.05),
		Vector3(0, -55.0, 0.05), Vector3(0, -53.5, 0.05), Vector3(0, YM, 0.05)]
	for n in range(1, 10):
		var zt := -(n - 1) * 4.0
		var y := LANE_A if n % 2 else LANE_B
		for f in [0.15, 0.5, 0.85]:
			var x: float = (X0 + 4 - 8 * f) if n % 2 else (X0 - 4 + 8 * f)
			path.append(Vector3(x, y, zt - 4 * f))
		path.append(Vector3(X0 - 5.0 if n % 2 else X0 + 5.0, YM, zt - 4))
	path.append(Vector3(-11.6, -53.0, -36.0))           # filler plate between the level 09 landing and the deck
	path.append(Vector3(-11.3, -50.5, -36.0))
	var fails := 0
	for p in path:
		fails += _floor(space, silo, p)
	for a in [-104.0, -108.0, -114.0]:
		fails += _floor(space, silo, _polar(51.0, a, -36.0))
	var room := Vector2(cos(deg_to_rad(-106.5)), sin(deg_to_rad(-106.5)))
	var e_u := Vector2(cos(deg_to_rad(-196.5)), sin(deg_to_rad(-196.5)))
	var q_room: Vector2 = room * 62.5 + e_u * 0.0
	for uv in [Vector2(-1.95, 0.5), Vector2(-1.95, 2.5), Vector2(0, 6.5), Vector2(3.0, 4.6)]:
		var q: Vector2 = room * (56.0 + uv.y) + e_u * uv.x
		fails += _floor(space, silo, Vector3(q.x, q.y, -36.0))
	_check("walk path has floor everywhere (%d samples)" % (path.size() + 7), fails == 0)
	var top_walk := _top_path(room, e_u)
	fails = 0
	for p in top_walk:
		fails += _floor(space, silo, p)
	_check("launch control -> door -> tunnel -> lift cage has floor everywhere (%d samples)" % top_walk.size(), fails == 0)
	_check("launch control -> door -> tunnel -> lift cage is clear", _clear(space, silo, top_walk) == 0)
	await _ride(silo, ev.player, tree)
	var hall := _hall_path()
	fails = 0
	for p in hall:
		fails += _floor(space, silo, p)
	_check("lift cage -> hall -> round the generators has floor everywhere (%d samples)" % hall.size(), fails == 0)
	_check("lift cage -> out into the hall is clear", _clear(space, silo, hall.slice(0, 4)) == 0)
	_check("level 09 landing gate blocks the shaft while the cage is down",
		_wall(space, silo, _frame(CAB.x, 1.2, GZ), Vector3(-sin(deg_to_rad(HALL_A0)), cos(deg_to_rad(HALL_A0)), 0) * -1.0))
	silo.lift.depart(SiloLift.State.UP)
	await _wait_lift(silo.lift, SiloLift.State.TOP, tree)
	_check("empty cage comes back up on call", silo.lift.state == SiloLift.State.TOP)
	_check("hall landing gate blocks the shaft while the cage is up",
		_wall(space, silo, _frame(CAB.x, -5.0, FL), Vector3(-sin(deg_to_rad(HALL_A0)), cos(deg_to_rad(HALL_A0)), 0)))
	_check("fall reset waits below the generator hall", terrain.get_kill_y(c.x, c.z, -30.0) < c.y + FL - 5.0)
	_check("hall zone: tunnel + hall in, launch control and bore out", SiloGenerators.in_hall(_local(top_walk[3]))
		and SiloGenerators.in_hall(_local(hall[-1])) and not SiloGenerators.in_hall(_local(Vector3(q_room.x, q_room.y, GZ)))
		and not SiloGenerators.in_hall(_local(_polar(40.0, -140.0, FL))))
	for probe in [[Vector3(X0, LANE_B, -2.0), Vector3(0, 1, 0)], [Vector3(X0, LANE_A, -2.0), Vector3(0, -1, 0)],
			[Vector3(-10.0, YM, -4.0), Vector3(-1, 0, 0)], [Vector3(0, YM, 0.05), Vector3(1, 0, 0)],
			[Vector3(X0, LANE_A, -2.0), Vector3(0, 1, 0)], [Vector3(-10.0, LANE_B, -36.0), Vector3(1, 0, 0)]]:
		_check("cage blocks %s at %s" % [probe[1], probe[0]], _wall(space, silo, probe[0], probe[1]))
	_check("fall reset waits below level 09 in the bore", terrain.get_kill_y(c.x, c.z, -30.0) < c.y - 45.0)
	_check("fall reset unchanged outside the bore", terrain.get_kill_y(c.x + 200.0, c.z, -30.0) == -30.0)
	var door_at := _polar(56.0, -106.5, -36.0) + Vector3(0, 0, 0)
	silo.check_interaction(G(silo, door_at))
	var door := _nearest_door(silo, G(silo, door_at))
	door._process(BunkerDoor.OPEN_TIME)             # one full travel; real time would outlast capture's --wait
	_check("launch control door opens on approach", door != null and door.state == BunkerDoor.State.OPEN)
	silo.check_interaction(silo.global_position + Vector3(0, 0, 60))
	door._process(BunkerDoor.OPEN_TIME)
	_check("launch control door closes behind", door.state == BunkerDoor.State.CLOSED)
	_check("console quiet from the rim", not silo.check_interaction(silo.global_position + Vector3(-20, 0, 60)))
	var fired := [0]
	silo.silo_activated.connect(func() -> void: fired[0] += 1)
	silo.check_interaction(silo.global_position, true)
	silo.check_interaction(silo.global_position, true)
	_check("override engages once", fired[0] == 1 and silo.console.state == SiloConsole.State.DONE)
	tree.set_meta("capture_hold", false)
	for i in 120:
		await tree.process_frame
	print("PERF fps=%d process=%.2fms draws=%d prims=%d lights_omni=%d" % [Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		silo.find_children("*", "OmniLight3D", true, false).size()])


## Blender points: launch control -> right-wall door -> tunnel -> the cage at level 09.
func _top_path(room: Vector2, e_u: Vector2) -> Array:
	var pts: Array = []
	for u in [4.5, 6.0, 6.5, 7.5, 8.5]:                     # room floor, the door, the tunnel (room frame v 7.4)
		var q: Vector2 = room * (56.0 + 7.4) + e_u * u
		pts.append(Vector3(q.x, q.y, GZ))
	for y in [-0.25, -1.0, CAB.y]:
		pts.append(_frame(CAB.x, y, GZ))
	return pts


## Blender points: the cage at the hall floor -> out through the gates -> the channel -> round each generator.
func _hall_path() -> Array:
	var pts: Array = [_frame(CAB.x, CAB.y, FL), _frame(CAB.x, -3.4, FL), _frame(CAB.x, -4.6, FL), _frame(CAB.x, -6.5, FL)]
	for a in [-121.0, -126.0, -138.0, -152.0, -166.0]:
		pts.append(_polar(68.5, a, FL))
	for a in [-131.0, -145.0, -159.0]:
		pts.append(_polar(76.0, a, FL))
		pts.append(_polar(61.2, a, FL))
	return pts


## Stands the real player in the cage, sends it down at time_scale 6 and checks it arrives with the player still on it.
func _ride(silo: Node3D, player: Node3D, tree: SceneTree) -> void:
	player.global_position = G(silo, _frame(CAB.x, CAB.y, GZ + 1.0))
	player.velocity = Vector3.ZERO
	for i in 10:
		await tree.physics_frame
	silo.lift.depart(SiloLift.State.DOWN)
	await _wait_lift(silo.lift, SiloLift.State.BOTTOM, tree)
	var floor_y := G(silo, _frame(CAB.x, CAB.y, FL)).y
	_check("lift takes the player down to the hall (%.1f m)" % silo.lift.drop, silo.lift.state == SiloLift.State.BOTTOM
		and silo.lift.in_cage(player.global_position) and absf(player.global_position.y - floor_y) < 1.5)


func _wait_lift(lift: SiloLift, want: SiloLift.State, tree: SceneTree) -> void:
	Engine.time_scale = 6.0
	var start := Time.get_ticks_msec()
	while lift.state != want and Time.get_ticks_msec() - start < TRIP_TIMEOUT * 1000.0:
		await tree.physics_frame
	for i in 40:                                             # the arrival gates finish opening
		await tree.physics_frame
	Engine.time_scale = 1.0


func _clear(space: PhysicsDirectSpaceState3D, silo: Node3D, pts: Array) -> int:
	var blocked := 0
	for i in pts.size() - 1:                                 # nothing in the way, chest high
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(G(silo, pts[i] + Vector3(0, 0, 1.0)),
			G(silo, pts[i + 1] + Vector3(0, 0, 1.0))))
		if not hit.is_empty():
			blocked += 1
			print("CHECK FAIL blocked between blender %s and %s at %s" % [pts[i], pts[i + 1], hit.position])
	return blocked


func _frame(x: float, y: float, z: float) -> Vector3:
	var a := deg_to_rad(HALL_A0)
	return Vector3(x * cos(a) - y * sin(a), x * sin(a) + y * cos(a), z)


func _polar(r: float, deg: float, z: float) -> Vector3:
	return Vector3(r * cos(deg_to_rad(deg)), r * sin(deg_to_rad(deg)), z)


func _local(b: Vector3) -> Vector3:                        # Blender -> silo space (Godot local)
	return Vector3(b.x, b.z, -b.y)


func G(silo: Node3D, b: Vector3) -> Vector3:
	return silo.to_global(Vector3(b.x, b.z, -b.y))


func _floor(space: PhysicsDirectSpaceState3D, silo: Node3D, b: Vector3) -> int:
	var at := G(silo, b)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.0, at + Vector3.DOWN * 1.5))
	var ok := not hit.is_empty() and absf(hit.position.y - at.y) < 0.4
	if not ok:
		print("CHECK FAIL no floor at blender %s (hit %s)" % [b, hit.get("position", "none")])
	return 0 if ok else 1


func _wall(space: PhysicsDirectSpaceState3D, silo: Node3D, b: Vector3, dir_b: Vector3) -> bool:
	var at := G(silo, b + Vector3(0, 0, 0.9))
	var d := silo.global_transform.basis * Vector3(dir_b.x, dir_b.z, -dir_b.y)
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(at, at + d * 2.5)).is_empty()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])


## The silo's kit blast door whose centre is nearest `at` (launch control's, the pit's).
static func _nearest_door(silo: MissileSilo, at: Vector3) -> BunkerDoor:
	var best: BunkerDoor = null
	var best_d := INF
	for i in silo._doors.size():
		var d: float = silo._door_centers[i].global_position.distance_to(at)
		if d < best_d:
			best_d = d
			best = silo._doors[i]
	return best
