extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): night 4's ending. Spawns Missile Silo 00 like spawn_silo.gd, adds a
## ForestNightDirector for night 4 (it dooms the silo's lift and adds a LiftCrashView), stands the real player in the cage
## at level 09 and sends it down (Engine.time_scale 6): checks the crash runs every phase in order, the cage ends on the
## hall floor with the player carried inside it, the camera shook, the lift answers nothing after, and the director
## would wake the walker on the impact (its wake is disconnected here so the test run stays in the forest).

const SPAWN := preload("res://tools/exec/spawn_silo.gd")
const SILO_CHECK := preload("res://tools/exec/check_silo.gd")
const TIMEOUT := 30.0       # s real time at time_scale 6

var _phases: Array[int] = []
var _shook := 0.0


func run(scene: Node, tree: SceneTree) -> void:
	SPAWN.new().run(scene, tree)
	scene.set_meta("lift_crash_check", self)       # capture.gd drops its reference to this hook; stay alive while awaiting
	tree.set_meta("capture_hold", true)
	for i in 3:
		await tree.physics_frame
	var ev = scene.get_node("DeadForestEvent")
	var silo: MissileSilo = ev.get_children().filter(func(n): return n is MissileSilo).back()
	var player: Player = ev.player
	var director := ForestNightDirector.new()
	director.setup(player, scene.get_node("DeadForestTerrain"), ForestNights.spec(4))
	scene.add_child(director)
	var lift := silo.lift
	_check("night 4 ends in the lift crash, night 5 on is the open forest", ForestNights.spec(4)["ending"]
		== ForestNights.Ending.CRASH and ForestNights.spec(9)["ending"] == ForestNights.Ending.NONE)
	_check("the director dooms a lift already standing", lift.crash != null
		and director.get_node_or_null("LiftCrashView") != null)
	var crash := lift.crash
	_check("the director wakes the walker on the impact", crash.phase_changed.is_connected(director._on_crash_phase))
	crash.phase_changed.disconnect(director._on_crash_phase)
	crash.phase_changed.connect(func(p: int) -> void: _phases.append(p))
	var later := SiloLift.new()                     # a lift built after the night began (the walk reaching the silo)
	scene.add_child(later)
	_check("the director dooms a lift built later", later.crash != null)
	later.queue_free()
	var h := SILO_CHECK.new()
	player.global_position = h.G(silo, h._frame(h.CAB.x, h.CAB.y, h.GZ + 1.0))
	player.velocity = Vector3.ZERO
	for i in 10:
		await tree.physics_frame
	lift.depart(SiloLift.State.DOWN)
	Engine.time_scale = 6.0
	var start := Time.get_ticks_msec()
	while crash.phase != SiloLiftCrash.Phase.WRECK and Time.get_ticks_msec() - start < TIMEOUT * 1000.0:
		await tree.physics_frame
		_shook = maxf(_shook, absf(player.camera.h_offset) + absf(player.camera.v_offset))
	Engine.time_scale = 1.0
	var want: Array[int] = [SiloLiftCrash.Phase.SEIZE, SiloLiftCrash.Phase.JOLT, SiloLiftCrash.Phase.FALL,
		SiloLiftCrash.Phase.BRAKE, SiloLiftCrash.Phase.HOLD, SiloLiftCrash.Phase.SLIP, SiloLiftCrash.Phase.WRECK]
	_check("the crash runs seize, jolt, fall, brake, hold, slip, wreck (%s)" % [_phases], _phases == want)
	var floor_y := h.G(silo, h._frame(h.CAB.x, h.CAB.y, h.FL)).y
	_check("the cage hits the hall floor (%.1f m down)" % lift.drop, absf(lift._body.position.y + lift.drop) < 0.01)
	_check("the walker was carried, not left to physics", not player.is_physics_processing())
	_check("the walker rode it down inside the cage (%.1f m over the floor)" % (player.global_position.y - floor_y),
		lift.in_cage(player.global_position) and absf(player.global_position.y - floor_y) < 1.5)
	_check("the camera took the hits (%.3f m peak offset)" % _shook, _shook > 0.02)
	_check("the wrecked lift answers nothing", lift.state == SiloLift.State.CRASH and not lift.is_moving())
	var mono := true
	for i in 70:
		mono = mono and crash.cage_y(i * 0.1 + 0.5) <= crash.cage_y(i * 0.1 + 0.4) + 0.001
	_check("the cage only ever goes down after the seize bounce", mono)
	director.queue_free()
	tree.set_meta("capture_hold", false)


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
