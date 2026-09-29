class_name LiftGate
extends RefCounted
## A barred gate that rises to open (lift cages, landing gates): its mesh node slides up `rise` metres and its collision
## shape blocks the opening until it is fully up. One FSM: CLOSED, OPENING, OPEN, CLOSING. Owner calls set_open(want)
## and step(delta) every physics frame; step returns true on the frame the gate stops (for a clank). snap_open() puts
## it open with no travel (the lift's starting end), snap_shut() shut (a wrecked lift).

enum State { CLOSED, OPENING, OPEN, CLOSING }

const SPEED := 1.6                  # m/s

var state := State.CLOSED
var rise := 2.3
var _mesh: Node3D
var _shape: CollisionShape3D
var _rest := Vector3.ZERO
var _up := 0.0                      # metres raised


static func make(mesh: Node3D, shape: CollisionShape3D, rise_m: float) -> LiftGate:
	var g := LiftGate.new()
	g._mesh = mesh
	g._shape = shape
	g.rise = maxf(rise_m, 0.01)
	if mesh:
		g._rest = mesh.position
	return g


func set_open(want: bool) -> void:
	if want and (state == State.CLOSED or state == State.CLOSING):
		state = State.OPENING
	elif not want and (state == State.OPEN or state == State.OPENING):
		state = State.CLOSING
		if _shape:
			_shape.disabled = false


func snap_open() -> void:
	state = State.OPEN
	_up = rise
	if _mesh:
		_mesh.position = _rest + Vector3(0.0, _up, 0.0)
	if _shape:
		_shape.disabled = true


## Shut with no travel (a wrecked lift's gates).
func snap_shut() -> void:
	state = State.CLOSED
	_up = 0.0
	if _mesh:
		_mesh.position = _rest
	if _shape:
		_shape.disabled = false


func is_shut() -> bool:
	return state == State.CLOSED


func step(delta: float) -> bool:
	if state == State.CLOSED or state == State.OPEN:
		return false
	var dir := 1.0 if state == State.OPENING else -1.0
	_up = clampf(_up + dir * SPEED * delta, 0.0, rise)
	if _mesh:
		_mesh.position = _rest + Vector3(0.0, _up, 0.0)
	if state == State.OPENING and _up >= rise:
		state = State.OPEN
		if _shape:
			_shape.disabled = true
		return true
	if state == State.CLOSING and _up <= 0.0:
		state = State.CLOSED
		return true
	return false
