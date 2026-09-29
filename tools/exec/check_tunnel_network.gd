extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the underground line in the silo depths (TunnelNetwork, joined to
## the silo's vent by SiloTunnels). Switches to scenes/levels/silo_depths.tscn and checks: the maze has every hall and all of
## them are reachable; the silo duct's cap is gone and the duct runs on, with floor, to the tunnel's duct mouth, whose CLIMB
## OUT lands on the walkway; there is floor along the track of every run and across every hall from each open mouth to the
## turntable; caved links are blocked at the rubble; every mouth with nothing behind it is plugged and every used one open;
## every pylon is lit; the tunnels' air turns black inside and gives the level its own back outside.

const LEVEL := "res://scenes/levels/silo_depths.tscn"
const EYE := 1.5


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("tunnel_network_check", self)
	tree.set_meta("capture_hold", true)
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	var net := level.tunnels if level else null
	if net == null or net.maze == null:
		_check("the silo depths built its tunnel network", false)
		tree.set_meta("capture_hold", false)
		return
	var space := net.get_world_3d().direct_space_state
	var halls := net.cols * net.rows
	_check("every hall built and reachable (%d / %d halls, %d reachable)" % [net.halls.size(), halls, net.maze.reachable()],
		net.halls.size() == halls and net.maze.reachable() == halls)
	_duct(level, net, space)
	var misses := 0
	var samples := 0
	for run in net.runs:
		for piece in run.get_children():
			if not String(piece.name).begins_with("tunnel_"):
				continue
			var end := 2.4 if String(piece.name).begins_with("tunnel_collapse") else _length(piece)
			if String(piece.name).begins_with("tunnel_vault"):
				end = 3.0                                   # then the buffer stop and the dock (check_tunnel_vault.gd)
			var s := 0.5
			while s < end:
				samples += 1
				misses += _floor_miss(space, piece, _along(piece, s) + Vector3(O73Kit.TRACK_X, 0.0, 0.0), 0.0)
				s += 1.0
	_check("floor along the track of every run (%d samples, %d misses)" % [samples, misses], misses == 0 and samples > 500)
	var open_mouths := 0
	var hall_misses := 0
	var plug_fails := 0
	var caved_fails := 0
	for p in net.halls:
		var hall: Node3D = net.halls[p]
		for k in 4:
			var at := Vector3i(p.x, p.y, k)
			var used: bool = net.maze.link(at) != TunnelMaze.Link.NONE or net.maze.spurs.has(at) or at == TunnelMaze.ENTRY \
				or (at == net.vault_mouth and net.vault != null)
			var dir := -(hall.get_node("marker_mouth_%d" % k) as Node3D).transform.basis.z
			var blocked := _hits(space, hall, dir * 6.0 + Vector3.UP * EYE, dir * (O73Kit.JUNC_R + 0.3) + Vector3.UP * EYE)
			plug_fails += 1 if blocked == used else 0
			if used:
				open_mouths += 1
				for r in [11.5, 9.0, 6.5, 3.0]:
					hall_misses += _hall_floor_miss(space, hall, dir * r)
			if net.maze.link(at) == TunnelMaze.Link.CAVED:
				var far := dir * (O73Kit.JUNC_R + float(net.slots) * O73Kit.TUN_LEN * 0.5 + 2.0)
				caved_fails += 0 if _hits(space, hall, dir * (O73Kit.JUNC_R + 1.0) + Vector3.UP * 2.2, far + Vector3.UP * 2.2) else 1
	_check("used mouths open, the rest plugged (%d open, %d wrong)" % [open_mouths, plug_fails], plug_fails == 0)
	_check("floor across every hall from each open mouth to the turntable (%d misses)" % hall_misses, hall_misses == 0)
	_check("every caved tunnel is blocked by its rubble (%d open)" % caved_fails, caved_fails == 0)
	var dark := net.pylons.filter(func(p: EmergencyPylon): return p.light == null or not p.light.visible)
	_check("every emergency pylon lights the way (%d pylons, %d dark)" % [net.pylons.size(), dark.size()],
		net.pylons.size() > halls * 4 and dark.is_empty())
	await _air(tree, level, net)
	tree.set_meta("capture_hold", false)


func _duct(level: SiloDepthsLevel, net: TunnelNetwork, space: PhysicsDirectSpaceState3D) -> void:
	var cap: Node3D = SiloTunnels._cap_marker(level.silo)
	_check("the silo duct's cap came off", cap != null and cap.get_children().all(func(c: Node): return c.is_queued_for_deletion()))
	var mouth := net.vent_mouth.global_transform
	var from := cap.global_position if cap else mouth.origin
	var steps := int(from.distance_to(mouth.origin) / 0.5)
	var misses := 0
	for i in range(1, steps):
		var p := from.lerp(mouth.origin, float(i) / steps) + Vector3.UP * 0.5
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p + Vector3.DOWN * 1.0))
		misses += 0 if hit and absf(hit.position.y - mouth.origin.y) < 0.1 else 1
	_check("the duct runs on with floor to the tunnel's mouth (%d samples, %d misses)" % [steps - 1, misses], misses == 0 and steps > 8)
	var out := net.vent._floor_in_front().y - (mouth.origin.y - SiloDepthsLevel.VENT_DROP)
	_check("CLIMB OUT of the duct lands on the tunnel walkway (%.2f m off)" % out, absf(out) < 0.1)


func _air(tree: SceneTree, level: SiloDepthsLevel, net: TunnelNetwork) -> void:
	var env := net.get_viewport().world_3d.environment
	var pale := env.fog_light_color
	var player := level.player
	player.set_physics_process(false)
	player.global_position = net.vent_mouth.global_position + net.vent_mouth.global_basis.z * 2.0 + Vector3.DOWN * 1.4
	await tree.create_timer(TunnelAir.FADE + 0.4).timeout
	_check("in the tunnels the air is black (fog %s)" % env.fog_light_color, env.fog_light_color.v < 0.02 and net.air.state == TunnelAir.State.INSIDE)
	player.global_position = level.silo.model.get_node("marker_vent_mouth").global_position
	await tree.create_timer(TunnelAir.FADE + 0.4).timeout
	_check("back in the hall the level's own air returns", env.fog_light_color.is_equal_approx(pale) and net.air.state == TunnelAir.State.OUTSIDE)


func _length(piece: Node3D) -> float:
	var next := piece.get_node_or_null(TunnelLine.NEXT) as Node3D
	return next.position.length() if next else O73Kit.TUN_LEN


func _along(piece: Node3D, s: float) -> Vector3:
	var next := piece.get_node_or_null(TunnelLine.NEXT) as Node3D
	var end := next.position if next else Vector3(0, 0, -O73Kit.TUN_LEN)
	return end.normalized() * s


func _floor_miss(space: PhysicsDirectSpaceState3D, piece: Node3D, local: Vector3, want: float) -> int:
	var from := piece.to_global(local + Vector3.UP * 2.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0))
	var h: float = piece.to_local(hit.position).y if hit else -99.0
	if absf(h - want) < 0.12:
		return 0
	print("CHECK FAIL no floor in %s/%s at %s (%.2f)" % [piece.get_parent().name, piece.name, local, h])
	return 1


func _hall_floor_miss(space: PhysicsDirectSpaceState3D, hall: Node3D, local: Vector3) -> int:
	var from := hall.to_global(local + Vector3.UP * 2.0)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0))
	var h: float = hall.to_local(hit.position).y if hit else -99.0
	if h > -0.4 and h < 0.15:
		return 0
	print("CHECK FAIL no floor in %s at %s (%.2f)" % [hall.name, local, h])
	return 1


func _hits(space: PhysicsDirectSpaceState3D, hall: Node3D, a: Vector3, b: Vector3) -> bool:
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(hall.to_global(a), hall.to_global(b))).is_empty()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
