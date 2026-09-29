class_name PlayerFocus
extends RefCounted
## Takes the walker over for a close-up of something they use: freezes them (no walking, no mouse look), hides the
## crosshair and lowers whatever they hold (the camera's viewmodels), and eases their camera (it sits under Head, so
## mouse look is untouched) to a world view and field of view; ease_back() brings it home and release() hands control
## back. TerminalStation uses it; anything else the player handles up close can (AptCheck / AptJournal do it by hand).
##   var focus := PlayerFocus.grab(player)          # null if the player cannot be taken
##   focus.ease_to(self, view_xform, 50.0, 0.7).finished.connect(...)
##   focus.ease_back(self, 0.7).finished.connect(focus.release)

const EASE := Tween.EASE_IN_OUT
const TRANS := Tween.TRANS_SINE

var player: Player
var _fov := 75.0
var _lowered: Array[Node3D] = []     # viewmodels hidden for the close-up (shown again on release)


static func grab(p: Player) -> PlayerFocus:
	if p == null or not is_instance_valid(p) or p.camera == null or p.head == null:
		return null
	var focus := PlayerFocus.new()
	focus.player = p
	focus._fov = p.camera.fov
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.velocity = Vector3.ZERO
	FieldHud.show_crosshair(false)
	for child in p.camera.get_children():           # gun mount, held dosimeter: not lights, not the aim ray
		var held := child as Node3D
		if held and held.visible and not (held is Light3D or held is RayCast3D):
			held.visible = false
			focus._lowered.append(held)
	return focus


## Eases the camera to world transform `view` at `fov` degrees over `time` s. The tween belongs to `host` (it dies with it).
func ease_to(host: Node, view: Transform3D, fov: float, time: float) -> Tween:
	var tw := host.create_tween().set_parallel(true).set_trans(TRANS).set_ease(EASE)
	if not is_instance_valid(player):
		tw.tween_interval(0.0)
		return tw
	var lean := player.head.global_transform.affine_inverse() * view
	tw.tween_property(player.camera, "transform", lean, time)
	tw.tween_property(player.camera, "fov", fov, time)
	return tw


## Eases the camera back to the walker's eyes and their own field of view.
func ease_back(host: Node, time: float) -> Tween:
	var tw := host.create_tween().set_parallel(true).set_trans(TRANS).set_ease(EASE)
	if not is_instance_valid(player):
		tw.tween_interval(0.0)
		return tw
	tw.tween_property(player.camera, "transform", Transform3D.IDENTITY, time)
	tw.tween_property(player.camera, "fov", _fov, time)
	return tw


## Control back: camera home, walking and mouse look on, mouse captured, crosshair and held item shown. Safe twice.
func release() -> void:
	FieldHud.show_crosshair(true)
	for held in _lowered:
		if is_instance_valid(held):
			held.visible = true
	_lowered.clear()
	if not is_instance_valid(player):
		return
	player.camera.transform = Transform3D.IDENTITY
	player.camera.fov = _fov
	if player.presenter:
		player.presenter.reset_camera(player.camera)
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	if player.input_ctrl:
		player.input_ctrl.capture_mouse()
	player = null
