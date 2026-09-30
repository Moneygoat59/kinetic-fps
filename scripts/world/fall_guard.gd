class_name FallGuard
extends Node
## A fall nobody walks away from: watches the walker's speed while airborne and, on the frame they land, emits
## hard_landing(speed) if they hit the ground faster than LETHAL (a drop of ~21 m under the walker's fall gravity). The
## level decides what that means: the forest resets the walker as it does for a fall out of the world, but only inside a
## pit (the silo bore's floor is walkable now, SiloPit, so jumping in from the rim must not land them on it).
## One state: GROUNDED or FALLING. setup(player), then add it as a child. Idle while the walker is carried (physics off).

signal hard_landing(speed: float)

enum State { GROUNDED, FALLING }

const LETHAL := 36.0                # m/s at impact

var state := State.GROUNDED
var player: CharacterBody3D
var _peak := 0.0                    # fastest downward speed of this fall


func setup(p: CharacterBody3D) -> void:
	player = p


func _physics_process(_delta: float) -> void:
	if player == null or not player.is_physics_processing():
		state = State.GROUNDED
		_peak = 0.0
		return
	if not player.is_on_floor():
		state = State.FALLING
		_peak = maxf(_peak, -player.velocity.y)
		return
	var landed := state == State.FALLING and _peak >= LETHAL
	var speed := _peak
	state = State.GROUNDED
	_peak = 0.0
	if landed:
		hard_landing.emit(speed)
