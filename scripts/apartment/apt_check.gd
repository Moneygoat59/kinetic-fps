class_name AptCheck
extends Node
## The walker doing a check (an AptUse with a row in apt_check_moves.gd): they lean in to look (the camera eases toward the
## spot under Head, so mouse look is untouched), their hand works the piece (its pivot nodes turn / lift and come back, the
## use's sound on each move), then they straighten up. The player is frozen and the use blocked meanwhile; the use reports
## `used` when it is over (so LEAVE's thought comes after the knob will not give). AptUse.mount adds it.

enum State { IDLE, LEAN, ACT, BACK }

const Moves = preload("res://scripts/apartment/apt_check_moves.gd")
const LEAN := 0.9                    # seconds leaning in / straightening up
const SETTLE := 0.35                 # seconds looking before the hand moves
const LINGER := 0.5                  # seconds still looking after the last move, before straightening up
const NEAR := 0.6                    # metres from the eye to what is checked, leaning in (a row's "near" overrides)
const REACH := 0.35                  # the most the eye moves: a lean of the head, along the aim line (the use's ray found it clear)
const FOCUS_FOV := 75.0              # the view narrows a little onto the thing while checking it (restored after)

var state := State.IDLE
var use: AptUse
var spec: Dictionary
var player: Player
var _piece: Node3D
var _fov := 75.0
var _nodes: Array[Node3D] = []
var _rest: Array[Transform3D] = []


static func mount(u: AptUse) -> AptCheck:
	var s := Moves.spec(u.id) if u else {}
	if s.is_empty():
		return null
	var check := AptCheck.new()
	check.name = "check"
	check.use = u
	check.spec = s
	u.add_child(check)
	return check


func _ready() -> void:
	_piece = use.get_parent().get_parent() as Node3D if use.get_parent() else null   # use <- marker_use_<id> <- piece
	for m in spec["moves"]:
		var node := _piece.find_child(String(m[0]), true, false) as Node3D if _piece else null
		if node == null:
			push_warning("AptCheck '%s': no pivot '%s' in %s" % [use.id, m[0], _piece.name if _piece else "?"])
		_nodes.append(node)
		_rest.append(node.transform if node else Transform3D.IDENTITY)


## Starts the check for `p`. False if it cannot run (busy, no camera): the use then acts at once.
func perform(p: Player) -> bool:
	if state != State.IDLE or p == null or p.camera == null or p.head == null or _piece == null:
		return false
	state = State.LEAN
	player = p
	use.enabled = false
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.velocity = Vector3.ZERO
	var look: Vector3 = _piece.global_transform * spec.get("look", _piece.to_local(use.global_position))
	var eye := p.camera.global_position
	var to := look - eye
	var eye_to := eye + to.normalized() * clampf(to.length() - float(spec.get("near", NEAR)), 0.0, REACH)
	var lean := p.head.global_transform.affine_inverse() * Transform3D(Basis.looking_at(look - eye_to, Vector3.UP), eye_to)
	_fov = p.camera.fov
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p.camera, "transform", lean, LEAN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(p.camera, "fov", FOCUS_FOV, LEAN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(_act)
	return true


func _act() -> void:
	state = State.ACT
	var tw := create_tween()
	tw.tween_interval(SETTLE)
	for i in _nodes.size():
		var node := _nodes[i]
		if node == null:
			continue
		var m: Array = spec["moves"][i]
		var out := Transform3D(_rest[i].basis * Basis.from_euler(m[2] * (PI / 180.0)), _rest[i].origin + m[1])
		var half: float = m[4] * 0.5
		for n in int(m[3]):
			tw.tween_callback(use.play_sound)
			tw.tween_property(node, "transform", out, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_interval(m[5])
			tw.tween_property(node, "transform", _rest[i], half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(LINGER)
	tw.tween_callback(_back)


func _back() -> void:
	state = State.BACK
	if not is_instance_valid(player):
		_end()
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player.camera, "transform", Transform3D.IDENTITY, LEAN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player.camera, "fov", _fov, LEAN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(_end)


func _end() -> void:
	state = State.IDLE
	for i in _nodes.size():
		if _nodes[i]:
			_nodes[i].transform = _rest[i]
	if is_instance_valid(player):
		player.camera.transform = Transform3D.IDENTITY
		player.camera.fov = _fov
		if player.presenter:
			player.presenter.reset_camera(player.camera)
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
	use.enabled = true
	use.report()
