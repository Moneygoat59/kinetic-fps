class_name SiloLiftCrash
extends Node
## The freight lift failing with the walker in it (night 4's ending). SiloLift.doom() makes it; the lift hands over the
## cage STALL_AT s into the trip down (begin) and from then on this drives the cage's height on a fixed timeline that
## audio/silo/lift_crash.wav is rendered to (tools/audio/lift_crash.py: keep the times equal):
##   SEIZE  a huge clank, the cage drops a hand's width and bounces, the motor dies, the lamp stutters
##   JOLT   it lurches down again          FALL   the cable snaps: free fall, sparks off the rails, the lamp strobing
##   BRAKE  the safety brakes bite: a shrieking stop in a shower of sparks
##   HOLD   it hangs on the brakes, groaning  SLIP   they let go: it falls the rest of the shaft, faster and faster
##   WRECK  the hall floor (emits phase_changed(WRECK): ForestNightDirector cuts to black there)
## LiftCrashView listens to phase_changed for the walker's side (frozen, carried, shaken).

signal phase_changed(phase: Phase)

enum Phase { IDLE, SEIZE, JOLT, FALL, BRAKE, HOLD, SLIP, WRECK }

## seconds from the seize (lift_crash.py: JOLT, SNAP, BRAKE, HOLD, SLIP, WRECK)
const AT := {Phase.JOLT: 1.3, Phase.FALL: 2.4, Phase.BRAKE: 3.6, Phase.HOLD: 4.05, Phase.SLIP: 4.9, Phase.WRECK: 7.1}
const G := 9.8
const SEIZE_DIP := 0.35                     # m the cage drops on the seize, then bounces BOUNCE back
const BOUNCE := 0.1
const JOLT_DIP := 0.2
const CREEP := 0.05                         # m it slides on the brakes while it hangs
const MAX_DELTA := 0.1
const SOUND := preload("res://audio/silo/lift_crash.wav")

var phase := Phase.IDLE
var height := 0.0                           # the cage's height now (body position.y); read the body back and it lags a tick
var _t := 0.0
var _body: Node3D
var _lamp: OmniLight3D
var _lamp_energy := 0.0
var _motor: AudioStreamPlayer3D
var _drop := 0.0
var _y0 := 0.0                              # cage height (body position.y) at the seize
var _sparks: Array[CPUParticles3D] = []


func _ready() -> void:
	set_physics_process(false)


## Takes over the cage (the lift is CRASH now). frame = the cage frame at the top (SiloLift._top), for the spark points.
func begin(body: Node3D, lamp: OmniLight3D, motor: AudioStreamPlayer3D, drop: float, frame: Transform3D) -> void:
	if phase != Phase.IDLE or body == null:
		return
	_body = body
	_lamp = lamp
	_lamp_energy = lamp.light_energy if lamp else 0.0
	_motor = motor
	_drop = drop
	_y0 = body.position.y
	height = _y0
	for side in [-1.0, 1.0]:
		_sparks.append(Sparks.make(body, frame * Vector3(side * 1.7, 0.3, 0.0)))   # brake shoes, outside the side rails
	if _motor:
		create_tween().tween_property(_motor, "pitch_scale", 0.15, 0.7).set_ease(Tween.EASE_IN)
		create_tween().tween_callback(_motor.stop).set_delay(0.7)
	SoundManager.play(SOUND, 0.0, 0.0)
	_enter(Phase.SEIZE)
	set_physics_process(true)


## 0..1 through the last fall (SLIP), 0 before it: LiftCrashView builds the shake with it.
func slip_progress() -> float:
	return clampf((_t - AT[Phase.SLIP]) / (AT[Phase.WRECK] - AT[Phase.SLIP]), 0.0, 1.0)


## Where the timeline has the cage (body position.y) at t seconds from the seize.
func cage_y(t: float) -> float:
	var y_fall: float = _y0 - SEIZE_DIP + BOUNCE - JOLT_DIP
	var fall_t: float = AT[Phase.BRAKE] - AT[Phase.FALL]
	var v: float = G * fall_t
	var y_brake := y_fall - 0.5 * G * fall_t * fall_t
	var brake_t: float = AT[Phase.HOLD] - AT[Phase.BRAKE]
	var y_hold := y_brake - v * brake_t * 0.5
	var y_slip := y_hold - CREEP
	var y := _y0
	if t < AT[Phase.JOLT]:
		y = _y0 - SEIZE_DIP * clampf(t / 0.1, 0.0, 1.0) + BOUNCE * clampf((t - 0.1) / 0.3, 0.0, 1.0)
	elif t < AT[Phase.FALL]:
		y = y_fall + JOLT_DIP * (1.0 - clampf((t - AT[Phase.JOLT]) / 0.08, 0.0, 1.0))
	elif t < AT[Phase.BRAKE]:
		var s: float = t - AT[Phase.FALL]
		y = y_fall - 0.5 * G * s * s
	elif t < AT[Phase.HOLD]:
		var s: float = t - AT[Phase.BRAKE]
		y = y_brake - v * s + 0.5 * (v / brake_t) * s * s
	elif t < AT[Phase.SLIP]:
		y = y_hold - CREEP * (t - AT[Phase.HOLD]) / (AT[Phase.SLIP] - AT[Phase.HOLD])
	else:
		var u := clampf((t - AT[Phase.SLIP]) / (AT[Phase.WRECK] - AT[Phase.SLIP]), 0.0, 1.0)
		y = y_slip - (y_slip + _drop) * u * u
	return maxf(y, -_drop)


func _physics_process(delta: float) -> void:
	if phase == Phase.IDLE or phase == Phase.WRECK or _body == null:
		return
	_t += clampf(delta, 0.0, MAX_DELTA)
	var next: int = phase + 1
	if AT.has(next) and _t >= AT[next]:
		_enter(next as Phase)
	height = cage_y(_t)
	_body.position.y = height
	_flicker()


func _enter(next: Phase) -> void:
	phase = next
	var sparking := next == Phase.SEIZE or next == Phase.FALL or next == Phase.BRAKE or next == Phase.SLIP
	for s in _sparks:
		s.emitting = sparking
	if next == Phase.WRECK:
		height = -_drop
		_body.position.y = height
		set_physics_process(false)
		if _lamp:
			_lamp.visible = false
	phase_changed.emit(next)


## The cage lamp: stutters on the seize, strobes while falling, burns steady-dim on the brakes.
func _flicker() -> void:
	if _lamp == null:
		return
	var on := true
	match phase:
		Phase.SEIZE, Phase.JOLT:
			on = randf() > 0.25
		Phase.FALL, Phase.SLIP:
			on = fmod(_t * 11.0, 1.0) < 0.5 and randf() > 0.15
		Phase.BRAKE:
			on = randf() > 0.4
	_lamp.light_energy = _lamp_energy * (0.55 if phase == Phase.HOLD else 1.0) if on else 0.0
