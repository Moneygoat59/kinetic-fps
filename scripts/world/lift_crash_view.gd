class_name LiftCrashView
extends Node
## The walker's side of the freight lift crash (SiloLiftCrash): from the seize on they are frozen (mouse look stays, as in
## DreamTrip) and carried with the cage; the camera takes the hits. Trauma-style shake (h/v offset + roll, squared so
## small knocks stay small), a dip on every jolt, the field of view widening as the cage falls. ForestNightDirector adds
## it when it dooms a lift; it does nothing until the crash's first phase and only carries a walker who is in the cage.

## phase -> [trauma kick, sustained trauma floor while in it, camera dip (m)]
const HITS := {
	SiloLiftCrash.Phase.SEIZE: [0.95, 0.12, 0.28],
	SiloLiftCrash.Phase.JOLT: [0.6, 0.12, 0.16],
	SiloLiftCrash.Phase.FALL: [0.8, 0.45, 0.0],
	SiloLiftCrash.Phase.BRAKE: [1.0, 0.8, 0.35],
	SiloLiftCrash.Phase.HOLD: [0.7, 0.15, 0.1],
	SiloLiftCrash.Phase.SLIP: [0.9, 0.55, 0.12],
}
const SHAKE := Vector2(0.09, 0.07)          # m of h / v offset at full trauma
const ROLL := 5.0                            # degrees at full trauma
const DECAY := 1.6                           # trauma per second
const DIP_RETURN := 5.0
const FALL_FOV := 14.0                       # degrees wider at the bottom of the fall

var player: Player
var lift: SiloLift
var _crash: SiloLiftCrash
var _cam: Camera3D
var _carry := false
var _last_y := 0.0
var _trauma := 0.0
var _floor := 0.0
var _dip := 0.0
var _fov := 0.0
var _time := 0.0
var _noise := FastNoiseLite.new()


func setup(p: Player, l: SiloLift, crash: SiloLiftCrash) -> void:
	player = p
	lift = l
	_crash = crash
	_cam = p.camera if p else null
	if crash:
		crash.phase_changed.connect(_on_phase)


func _ready() -> void:
	process_physics_priority = 100           # after the crash has moved the cage this frame: carry without lag
	_noise.frequency = 2.2
	set_physics_process(false)


func _on_phase(phase: SiloLiftCrash.Phase) -> void:
	if player == null or _cam == null or _crash == null:
		return
	if phase == SiloLiftCrash.Phase.SEIZE:
		_carry = lift != null and lift.in_cage(player.global_position)
		_last_y = _crash.height
		_fov = _cam.fov
		if _carry:
			player.set_physics_process(false)
			player.velocity = Vector3.ZERO
		set_physics_process(true)
	if HITS.has(phase):
		var hit: Array = HITS[phase]
		_trauma = maxf(_trauma, hit[0])
		_floor = hit[1]
		_dip -= hit[2]
	elif phase == SiloLiftCrash.Phase.WRECK:
		_trauma = 1.0
		_dip -= 0.6


func _physics_process(delta: float) -> void:
	if player == null or _cam == null or _crash == null:
		return
	var dt := clampf(delta, 0.0, 0.1)
	_time += dt
	if _carry:
		player.global_position.y += _crash.height - _last_y              # the lift model is never tilted or scaled
		_last_y = _crash.height
	var ramp := 1.0 + 0.8 * _crash.slip_progress()
	_trauma = maxf(_trauma - DECAY * dt, _floor * ramp)
	_dip = move_toward(_dip, 0.0, DIP_RETURN * dt * maxf(absf(_dip), 0.05))
	var k := minf(_trauma * _trauma, 1.2)
	_cam.h_offset = SHAKE.x * k * _noise.get_noise_2d(_time * 60.0, 0.0)
	_cam.v_offset = SHAKE.y * k * _noise.get_noise_2d(0.0, _time * 60.0) + _dip
	_cam.rotation.z = deg_to_rad(ROLL) * k * _noise.get_noise_2d(_time * 40.0, 50.0)
	var falling := _crash.phase == SiloLiftCrash.Phase.FALL or _crash.phase == SiloLiftCrash.Phase.SLIP
	_cam.fov = move_toward(_cam.fov, _fov + (FALL_FOV * (ramp - 0.5) if falling else 0.0), 30.0 * dt)
