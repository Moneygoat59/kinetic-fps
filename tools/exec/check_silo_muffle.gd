extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the generator hall's sound respects walls (MuffleBus, SiloHallEar).
## Switches to scenes/levels/silo_depths.tscn, waits for the walker to get up, then stands them in places and reads the hall
## bus the machines play through: full in the hall; far down behind the pit door much quieter and muffled (a low-pass); a
## door that is open lets more through than one that is shut; in the tunnels it is sealed; back in the hall it is full again.

const LEVEL := "res://scenes/levels/silo_depths.tscn"
const TIMEOUT := 30.0            # s real time for each wait (Engine.time_scale 4)


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("muffle_check", self)
	tree.set_meta("capture_hold", true)
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	if level == null or level.silo == null or level.tunnels == null:
		_check("the silo depths built its silo and tunnels", false)
		tree.set_meta("capture_hold", false)
		return
	var silo := level.silo
	var player := level.player
	var bus := silo.generators._sound.muffle
	Engine.time_scale = 4.0
	await _until(tree, func() -> bool: return player.is_physics_processing())
	var ears := level.find_children("*", "HearingReturn", true, false)
	if not ears.is_empty():
		ears[0].queue_free()
	var hall := silo.model.get_node("marker_lift_bottom") as Node3D
	var pit := silo.model.get_node("marker_pit_floor") as Node3D
	var door := silo.model.get_node("marker_pit_door") as Node3D
	_stand(player, hall.global_position)
	await _settle(tree, bus)
	_check("in the hall the machines are heard in full (%.1f dB, %.0f Hz)" % [_db(), _hz(bus)], _db() > -1.0 and _hz(bus) > 15000.0)
	_stand(player, pit.global_position)
	await _settle(tree, bus)
	_check("down on the bore floor behind the shut door they are far quieter and muffled (%.1f dB, %.0f Hz)" % [_db(), _hz(bus)],
		_db() < -30.0 and _hz(bus) < 400.0)
	var local := silo.to_local(door.global_position)
	var behind := Vector3(local.x, local.y, local.z) * Vector3(0.96, 1.0, 0.96)     # r 62 -> 59.5: just inside the door, toward the bore
	var shut := SiloHallEar.openness(behind, 0.0, false)
	var open := SiloHallEar.openness(behind, 1.0, false)
	_check("just inside the pit door, opening it lets the hall through (%.2f shut, %.2f open)" % [shut, open],
		SiloPit.in_pit(behind) and open > shut + 0.3)
	var mouth := level.tunnels.vent_mouth.global_transform
	_stand(player, mouth.origin + mouth.basis.z * 1.0 + Vector3.DOWN * SiloDepthsLevel.VENT_DROP)
	await _settle(tree, bus)
	_check("in the tunnels they are sealed off (%.1f dB, %.0f Hz, sealed %s)" % [_db(), _hz(bus), silo.generators.sealed],
		silo.generators.sealed and _db() < -38.0 and _hz(bus) < 250.0)
	_stand(player, hall.global_position)
	await _settle(tree, bus)
	_check("back in the hall they are full again (%.1f dB)" % _db(), not silo.generators.sealed and _db() > -1.0)
	Engine.time_scale = 1.0
	tree.set_meta("capture_hold", false)


func _stand(player: Player, at: Vector3) -> void:
	player.global_position = at + Vector3.UP * 0.2
	player.velocity = Vector3.ZERO


## Long enough for the bus to finish easing (a full swing is 1 / RATE seconds of game time).
func _settle(tree: SceneTree, bus: MuffleBus) -> void:
	await tree.create_timer(2.5 / MuffleBus.RATE / Engine.time_scale).timeout
	var waited := 0.0
	while bus.is_processing() and waited < TIMEOUT:
		await tree.create_timer(0.1).timeout
		waited += 0.1


func _until(tree: SceneTree, cond: Callable) -> void:
	var waited := 0.0
	while not cond.call() and waited < TIMEOUT:
		await tree.create_timer(0.1).timeout
		waited += 0.1


func _db() -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(SiloGeneratorSound.BUS))


func _hz(bus: MuffleBus) -> float:
	return bus._lpf.cutoff_hz


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
