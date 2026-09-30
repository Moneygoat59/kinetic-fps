class_name AptWake
extends Node
## Coming to on the couch (ForestNights "wake" = couch): the walker is slumped on the sofa's end seat, head down, facing the
## TV; they lift their head, then get up and have control. Like DreamTrip it animates the camera under Head (mouse look is
## untouched): the body already stands at a clear spot in front of the sofa and the camera is offset back onto the seat,
## then eased home. The player is frozen until standing; given a `face` node they then turn to look down at it (the journal).
## come_to() is the same wake anywhere: eyes at a world point, the head turned any way (SiloDepthsLevel: flat on the
## wrecked lift cage's floor, staring up at its lamp).

enum State { SLUMPED, RISING, DONE }

const SEAT := Vector3(-0.55, 1.08, -0.05)   # sofa-local eye point, slumped on the end seat (sofa front +Z, floor y 0)
const STAND := Vector3(-1.0, 0.0, 0.9)      # sofa-local clear floor spot beside the coffee table, where they stand up
const BODY_UP := 0.02                       # the player's origin is at the feet: stand on the floor, no drop on release
const HOLD := 4.2                           # seconds slumped (the fade in from black runs through the first 2.8)
const LIFT := 2.6                           # seconds of that spent lifting the head to the screen
const RISE := 1.4
const TURN := 0.8                           # seconds turning to the `face` node once up
const SND_CLOTH = preload("res://audio/rpg/Audio/cloth3.ogg")

var state := State.SLUMPED
var player: Player
var face: Node3D
var hold := HOLD                            # seconds before rising (lifting the head to lift_rot takes the last LIFT)
var lift_rot := Vector3(deg_to_rad(-6.0), 0.0, deg_to_rad(3.0))   # camera rotation the head comes up to before rising


## Sits `p` on `sofa` (a sofa kit piece or its marker); once up they turn to `look_at` if given. Returns the running wake
## (add it to the tree), or null.
static func couch(p: Player, sofa: Node3D, look_at: Node3D = null) -> AptWake:
	if sofa == null:
		return null
	var xf := sofa.global_transform
	var fwd := xf.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.01 else Vector3.BACK
	var cam_rot := Vector3(deg_to_rad(-30.0), 0.0, deg_to_rad(7.0))
	return come_to(p, xf * STAND, atan2(-fwd.x, -fwd.z), xf * SEAT, cam_rot, look_at)    # facing out of the sofa, at the TV


## Stands `p` at `stand` (feet, world) facing `yaw` and puts the camera at `eye` (world) turned `cam_rot` (head space):
## they come to there, then rise into their own eyes. Set hold / lift_rot on the result before adding it to the tree.
static func come_to(p: Player, stand: Vector3, yaw: float, eye: Vector3, cam_rot: Vector3, look_at: Node3D = null) -> AptWake:
	if p == null or p.camera == null or p.head == null:
		return null
	p.global_position = stand + Vector3.UP * BODY_UP
	p.rotation.y = yaw
	p.head.rotation.x = 0.0
	p.velocity = Vector3.ZERO
	if p.health:
		p.health.spawn_position = p.global_position
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	var cam := p.camera
	cam.position = p.head.global_transform.affine_inverse() * eye
	cam.rotation = cam_rot
	var wake := AptWake.new()
	wake.name = "AptWake"
	wake.player = p
	wake.face = look_at
	return wake


func _ready() -> void:
	if player == null:
		state = State.DONE
		return
	var cam := player.camera
	var tw := create_tween()
	tw.tween_interval(maxf(hold - LIFT, 0.01))
	tw.tween_property(cam, "rotation", lift_rot, LIFT) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_rise)


func _rise() -> void:
	if state != State.SLUMPED or not is_instance_valid(player):
		return
	state = State.RISING
	SoundManager.play(SND_CLOTH, -8.0, 0.05)
	var cam := player.camera
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam, "position", Vector3.ZERO, RISE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(cam, "rotation", Vector3.ZERO, RISE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(_turn)


func _turn() -> void:
	if state != State.RISING or not is_instance_valid(player):
		return
	if not is_instance_valid(face):
		_stand()
		return
	var to := face.global_position - player.head.global_position
	var yaw := player.rotation.y + wrapf(atan2(-to.x, -to.z) - player.rotation.y, -PI, PI)
	var pitch := atan2(to.y, Vector2(to.x, to.z).length())
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player, "rotation:y", yaw, TURN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player.head, "rotation:x", pitch, TURN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(_stand)


func _stand() -> void:
	if state != State.RISING or not is_instance_valid(player):
		return
	state = State.DONE
	player.camera.position = Vector3.ZERO
	if player.presenter:
		player.presenter.reset_camera(player.camera)
	if player.input_ctrl:
		player.input_ctrl.head_pitch = player.head.rotation.x      # mouse look carries on from here, no snap
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	queue_free()
