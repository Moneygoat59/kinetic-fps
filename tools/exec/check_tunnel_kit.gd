extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the rail tunnel kit. Lays the showcase line (scenes/dev/
## tunnel_showcase.tscn: every tunnel piece, pylons in the refuges, a duct mouth in the vent piece) far under the forest and
## checks: TunnelLine chains the pieces head to tail and the curves turn the right way; floor under the track and the
## walkway the whole way, the walls and the crown hold; the refuge's steps lead up to the walkway and its niche is open;
## the cave-in blocks the line; every refuge got a lit EmergencyPylon whose states switch its light; the duct mouth's
## CLIMB OUT lands on the walkway.

const SHOWCASE := preload("res://scenes/dev/tunnel_showcase.tscn")
const AT := Vector3(0.0, -600.0, 0.0)          # under everything in the forest
const EYE := 1.5


func run(scene: Node, tree: SceneTree) -> void:
	scene.set_meta("tunnel_kit_check", self)
	tree.set_meta("capture_hold", true)
	var show := SHOWCASE.instantiate() as Node3D
	show.position = AT
	tree.root.add_child(show)
	for i in 3:
		await tree.physics_frame
	var pieces: Array[Node3D] = show.get("pieces")
	var line: Array = show.get_script().get_script_constant_map()["LINE"]
	var space := show.get_world_3d().direct_space_state
	_check("the whole line was laid (%d / %d pieces)" % [pieces.size(), line.size()], pieces.size() == line.size())
	var gaps := 0
	for i in range(1, pieces.size()):
		gaps += 0 if pieces[i].transform.origin.distance_to(TunnelLine.exit([pieces[i - 1]]).origin) < 0.01 else 1
	_check("every piece starts where the one before ends", gaps == 0)
	_check("three right curves turn 45 deg right", absf(_yaw(pieces[7]) + 45.0) < 0.1)
	_check("two left curves turn back to 15 deg", absf(_yaw(pieces[11]) + 15.0) < 0.1)
	var bad := {"track": 0, "walk": 0, "left wall": 0, "right wall": 0, "crown": 0}
	for piece in pieces:
		var open_end := 1.2 if String(piece.name).begins_with("tunnel_collapse") else _length(piece)   # showcase buffer at 1.6
		var s := 0.5
		while s < open_end:
			var p := _along(piece, s)
			bad["track"] += _floor_miss(space, show, piece, p, O73Kit.TRACK_X, 0.0)
			bad["walk"] += _floor_miss(space, show, piece, p, 2.4, O73Kit.WALK_Z)
			bad["left wall"] += 0 if _hit_within(space, show, piece, p, Vector3(O73Kit.TRACK_X, EYE, 0), Vector3.LEFT, 3.3) else 1
			bad["crown"] += 0 if _hit_within(space, show, piece, p, Vector3(0.0, EYE, 0), Vector3.UP, 4.5) else 1
			if not _is_opening(piece, s):
				bad["right wall"] += 0 if _hit_within(space, show, piece, p, Vector3(2.4, O73Kit.WALK_Z + 1.2, 0), Vector3.RIGHT, 1.0) else 1
			s += 1.0
	for what in bad:
		_check("%s holds the whole way (%d misses)" % [what, bad[what]], bad[what] == 0)
	var refuge := pieces[2]
	var step := _ray_down(space, show, refuge, Vector3(1.3, 2.0, -4.0))
	_check("the refuge's steps rise from the track to the walkway (%.2f m at x 1.3)" % step, step > 0.25 and step < 0.6)
	_check("the refuge niche is open at walkway level",
		not _hit_within(space, show, refuge, _along(refuge, 4.0), Vector3(2.4, O73Kit.WALK_Z + 1.0, 0), Vector3.RIGHT, 1.05))   # past the wall face, short of the pylon
	var cave := pieces.back() as Node3D
	_check("the cave-in closes the line", String(cave.name).begins_with("tunnel_collapse")
		and _hit_within(space, show, cave, _along(cave, 2.4), Vector3(O73Kit.TRACK_X, EYE + 0.6, 0), Vector3.FORWARD, 5.0)
		and cave.get_node_or_null(TunnelLine.NEXT) == null)
	var pylons: Array[EmergencyPylon] = show.get("pylons")
	pylons = pylons.filter(func(p: EmergencyPylon): return String(p.get_parent().name).begins_with("tunnel_refuge"))   # not the vault's dock
	var lit := pylons.filter(func(p: EmergencyPylon): return p.light and p.light.visible and p.light.light_energy > 0.5)
	_check("an emergency pylon stands lit in every refuge (%d / 2)" % lit.size(), pylons.size() == 2 and lit.size() == 2)
	if pylons.size() > 0:
		var p0 := pylons[0]
		p0.set_state(EmergencyPylon.State.ALERT)
		var alert_range := p0.light.omni_range
		p0.set_state(EmergencyPylon.State.DARK)
		_check("pylon states switch its light (alert reaches %.0f m, dark is off)" % alert_range,
			alert_range > EmergencyPylon.STANDBY_RANGE and not p0.light.visible and not p0.is_processing())
	var duct := show.find_children("VentDuct", "", true, false).filter(func(n: Node): return n is VentDuct)
	var out_y := (duct[0] as VentDuct)._floor_in_front().y - show.global_position.y if duct.size() == 1 else -99.0
	_check("the vent's CLIMB OUT lands on the walkway (%.2f m)" % out_y, absf(out_y - O73Kit.WALK_Z) < 0.1)
	show.queue_free()
	tree.set_meta("capture_hold", false)


func _length(piece: Node3D) -> float:
	var next := piece.get_node_or_null(TunnelLine.NEXT) as Node3D
	return next.position.length() if next else O73Kit.TUN_LEN


func _yaw(piece: Node3D) -> float:
	return rad_to_deg(piece.transform.basis.get_euler().y)


## Piece-local point on the chord at s metres (a curve's chord strays ~0.26 m from its arc: well inside the bore).
func _along(piece: Node3D, s: float) -> Vector3:
	var next := piece.get_node_or_null(TunnelLine.NEXT) as Node3D
	var end := next.position if next else Vector3(0, 0, -O73Kit.TUN_LEN)
	return end.normalized() * s


func _is_opening(piece: Node3D, s: float) -> bool:
	var n := String(piece.name)
	return (n.begins_with("tunnel_refuge") and s > 2.8 and s < 5.2) or (n.begins_with("tunnel_vent") and s > 3.0 and s < 5.0)


func _world(show: Node3D, piece: Node3D, local: Vector3) -> Vector3:
	return show.to_global(piece.transform * local)


func _floor_miss(space: PhysicsDirectSpaceState3D, show: Node3D, piece: Node3D, p: Vector3, x: float, want: float) -> int:
	var h := _ray_down(space, show, piece, p + Vector3(x, 2.0, 0))
	if absf(h - want) < 0.12:
		return 0
	print("CHECK FAIL floor at %s s %.1f x %.1f: %.2f (want %.2f)" % [piece.name, -p.z, x, h, want])
	return 1


func _ray_down(space: PhysicsDirectSpaceState3D, show: Node3D, piece: Node3D, local: Vector3) -> float:
	var from := _world(show, piece, local)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 3.0))
	return (hit.position.y - show.global_position.y) if hit else -99.0


func _hit_within(space: PhysicsDirectSpaceState3D, show: Node3D, piece: Node3D, p: Vector3, off: Vector3, dir: Vector3,
		reach: float) -> bool:
	var from := _world(show, piece, p + Vector3(off.x, off.y, 0))
	var to := _world(show, piece, p + Vector3(off.x, off.y, 0) + dir * reach)
	return not space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to)).is_empty()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
