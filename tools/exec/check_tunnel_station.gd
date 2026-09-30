extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the station (tunnel_station) on the run out to the records vault in
## the silo depths' tunnel network. Switches to scenes/levels/silo_depths.tscn and checks: the station was laid and the
## vault starts where it ends; there is floor and a clear way (knee to head) from the bore's walkway onto the platform,
## down its length past the benches and the pylon, off its far end and along the vault's approach to the dock; the platform
## edge drops to the track with a recess under the nosing; the vault overhead closes it in; the benches and the wall
## terminal are furnished; an emergency pylon stands on the platform; the indicator lights; it is inside the network's bounds.

const LEVEL := "res://scenes/levels/silo_depths.tscn"
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const F := 0.7                                          # O73Kit.WALK_Z: walkway, platform and dock
const LEN := 24.0                                       # kit_dims.py STA_LEN
## the walk, station space (Godot: -Z = on down the line): walkway, platform, its far end, the vault's approach to its dock
const PATH: Array[Vector3] = [Vector3(2.4, F, -0.3), Vector3(2.4, F, -2.5), Vector3(4.5, F, -4.0), Vector3(4.5, F, -21.0),
	Vector3(2.4, F, -22.8), Vector3(2.4, F, -LEN - 2.0), Vector3(2.4, F, -LEN - 8.2)]


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("tunnel_station_check", self)
	tree.set_meta("capture_hold", true)
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	var net := level.tunnels if level else null
	var station := net.station if net else null
	_check("the station is laid on the vault run", station != null and String(station.name).begins_with("tunnel_station"))
	if station == null:
		tree.set_meta("capture_hold", false)
		return
	var joined := net.vault != null and TunnelLine.exit([station]).origin.distance_to(net.vault.position) < 0.01
	_check("the records vault starts where the station ends", joined)
	var space := station.get_world_3d().direct_space_state
	_walk(space, station)
	_edge(space, station)
	var up := _ray(space, station, Vector3(3.0, 2.0, -12.0), Vector3(3.0, 8.0, -12.0))
	_check("the vault closes the cavern in overhead (%s)" % (up.get("position", "open")), not up.is_empty())
	var furnished := 0
	for child in station.get_children():
		if String(child.name).begins_with(KitScript.PREFIX) and child.get_child_count() > 0:
			furnished += 1
	_check("benches and the wall terminal are furnished (%d)" % furnished, furnished == 4)
	var pylons := net.pylons.filter(func(p: EmergencyPylon): return p.get_parent() == station)
	_check("an emergency pylon stands on the platform (%d)" % pylons.size(), pylons.size() == 1)
	var ind := station.find_child("marker_light_indicator", true, false)
	_check("the indicator lights the platform", ind != null and not ind.find_children("*", "OmniLight3D", true, false).is_empty())
	_check("the station is inside the network's bounds", net.bounds.has_point(net.to_local(station.to_global(Vector3(3, 2, -12)))))
	tree.set_meta("capture_hold", false)


## Floor at walkway height under every 0.5 m of the path, nothing across it at knee, chest and head height.
func _walk(space: PhysicsDirectSpaceState3D, station: Node3D) -> void:
	var misses := 0
	var blocks := 0
	for i in PATH.size() - 1:
		var a := PATH[i]
		var b := PATH[i + 1]
		var steps := maxi(int(a.distance_to(b) / 0.5), 1)
		for j in steps + 1:
			var p := a.lerp(b, float(j) / steps)
			var hit := _ray(space, station, p + Vector3.UP, p + Vector3.DOWN * 0.6)
			if hit.is_empty() or absf(station.to_local(hit.position).y - F) > 0.06:
				misses += 1
				print("CHECK FAIL no floor at %s (%s)" % [p, station.to_local(hit.position) if hit else "nothing"])
		for h in [0.4, 1.0, 1.7]:
			var hit := _ray(space, station, a + Vector3.UP * h, b + Vector3.UP * h)
			if not hit.is_empty():
				blocks += 1
				print("CHECK FAIL blocked %s -> %s at %.1f m by %s" % [a, b, h, hit.collider.get_parent().name if hit.collider else "?"])
	_check("walkway, platform, far end, the vault's dock: floor all the way and clear (%d misses, %d blocks)" % [misses, blocks],
		misses == 0 and blocks == 0)


## The platform stops at its nosing: the track bed below, a recess under the edge.
func _edge(space: PhysicsDirectSpaceState3D, station: Node3D) -> void:
	var on := _ray(space, station, Vector3(1.05, 2.0, -12.0), Vector3(1.05, -1.0, -12.0))
	var off := _ray(space, station, Vector3(0.6, 2.0, -12.0), Vector3(0.6, -1.0, -12.0))
	var on_y: float = station.to_local(on.position).y if on else -9.0
	var off_y: float = station.to_local(off.position).y if off else -9.0
	_check("the platform edge drops to the track (%.2f m -> %.2f m)" % [on_y, off_y], absf(on_y - F) < 0.03 and off_y < 0.1)
	var under := _ray(space, station, Vector3(0.6, 0.3, -12.0), Vector3(2.0, 0.3, -12.0))
	var face: float = station.to_local(under.position).x if under else 9.0
	_check("a recess runs in under the nosing (face at x %.2f)" % face, face > 1.15 and face < 1.4)


func _ray(space: PhysicsDirectSpaceState3D, station: Node3D, a: Vector3, b: Vector3) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(station.to_global(a), station.to_global(b)))


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
