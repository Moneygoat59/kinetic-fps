class_name WraithGrab
extends Node
## Night 2's ending (WraithStalk starts it): the walker freezes (HUSH), a hand closes on a shoulder (GRIP, LOOK), they are
## wrenched round into its face (TURN), its eyes kindle (GLARE) and it screams (SCREAM); NightmareFx tears the picture up
## throughout. `finished` at the end, every sound cut dead (the director cuts to black).

signal finished

enum State { IDLE, HUSH, GRIP, LOOK, TURN, GLARE, SCREAM, DONE }

const LENGTH := {State.HUSH: 1.8, State.GRIP: 0.12, State.LOOK: 1.05, State.TURN: 0.3, State.GLARE: 0.9, State.SCREAM: 1.9}
const BEHIND := 1.05               # metres behind the walker while it grips (its wrist then rests on their shoulder)
const STOOP := 0.62                # and that much lower than it hovers: looming right over their head
const GRIP_REACH := 0.52           # WraithView.reach of the gripping arm (the forearm over the shoulder)
const FACE := 0.26                 # metres from the walker's eyes to its eyes at the end
const ZOOM := 16.0                 # degrees of fov lost while it screams
const SWISH = preload("res://audio/swishes/swish-10.wav")
const MAX_DELTA := 0.1

var state := State.IDLE
var _player: Player
var _wraith: Wraith
var _cam: Camera3D
var _t := 0.0
var _side := 1.0                   # +1 the walker's right shoulder, -1 the left
var _fwd := Vector3.FORWARD
var _right := Vector3.RIGHT
var _eye := Vector3.ZERO
var _look := Quaternion.IDENTITY   # where the camera points, before shake
var _from := Quaternion.IDENTITY
var _to := Quaternion.IDENTITY
var _w_from := Vector3.ZERO
var _w_to := Vector3.ZERO
var _stare := Vector3.ZERO         # where its eyes are held: FACE in front of the walker's
var _fov := 75.0
var _shoulder: WalkerShoulder


## `forward` = the walker's flat facing.
func start(player: Player, wraith: Wraith, forward: Vector3) -> void:
	if state != State.IDLE or player == null or player.camera == null or wraith == null:
		return
	_player = player
	_wraith = wraith
	_cam = player.camera
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.velocity = Vector3.ZERO
	_fwd = forward
	_right = _fwd.cross(Vector3.UP)
	_side = -1.0 if randf() < 0.5 else 1.0
	_eye = _cam.global_position
	_fov = _cam.fov
	_look = _cam.global_basis.get_rotation_quaternion()
	var at := player.global_position - _fwd * BEHIND                    # its arm, raised, comes in over their shoulder
	wraith.appear(at, at + _fwd * 10.0, 0.3)                              # behind them, facing their back
	wraith.global_position.y -= STOOP
	wraith.view.set_flicker(0.0)                                          # it is wholly there now
	wraith.view.reach_arm = 1 if _side > 0.0 else 0                    # its arm_l (local +X) is the walker's left
	wraith.audio.dread = 1.0
	wraith.audio.breathing = true
	wraith.audio.set_mix(WraithAudio.Mix.HUSH)
	wraith.audio.whisper(player, _right * _side, true, 0.35)
	add_child(NightmareFx.new(self, player))                              # what it does to the picture
	_enter(State.HUSH)


func _process(delta: float) -> void:
	if state == State.IDLE or state == State.DONE:
		return
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_t += dt
	var k := clampf(_t / LENGTH[state], 0.0, 1.0)
	var shake := 0.0
	match state:
		State.HUSH:
			shake = 0.004 * k
		State.GRIP:
			_wraith.view.reach = GRIP_REACH * k
			_wraith.view.grip = k
			shake = 0.07
		State.LOOK:
			_look = _from.slerp(_to, 1.0 - pow(1.0 - minf(k * 2.2, 1.0), 3.0))   # jerks round, then stares
			shake = 0.07 * (1.0 - k) * (1.0 - k) + 0.004
		State.TURN:
			_look = _from.slerp(_to, k * k * (3.0 - 2.0 * k))
			_hold_eyes(0.0, dt)
			_wraith.global_position = _w_from.lerp(_w_to, k)
			shake = 0.012
		State.GLARE:
			_wraith.view.eyes.set_glow(0.0 if k < 0.2 else (1.0 if k > 0.55 or randf() < 0.55 else 0.15))
			_hold_eyes(0.0, dt)
			_wraith.global_position = _w_to
			shake = 0.006
		State.SCREAM:
			_wraith.view.rage = minf(k * 3.0, 1.0)
			_wraith.view.gape = minf(k * 6.0, 1.0) * randf_range(0.85, 1.0)
			_wraith.view.eyes.set_glow(randf_range(0.8, 1.0))
			_hold_eyes(0.08 * k, dt)
			_wraith.global_position = _w_to
			_cam.fov = _fov - ZOOM * k * (2.0 - k)
			shake = lerpf(0.025, 0.06, k)
	var jolt := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.5, 1.5)) * shake
	_cam.global_basis = Basis(_look) * Basis.from_euler(jolt)
	if k >= 1.0:
		_enter((state + 1) as State)


func _enter(next: State) -> void:
	state = next
	_t = 0.0
	_from = _look
	match next:
		State.GRIP:
			_shoulder = WalkerShoulder.make(_player.get_parent(), _eye, _right, _fwd, _side)
			_wraith.audio.set_mix(WraithAudio.Mix.SILENT)
			_wraith.audio.grip()
		State.LOOK:
			_to = _aim(_wraith.view.rig.hand_point(_wraith.view.reach_arm))            # the hand, wherever it closed
		State.TURN:
			_shoulder.queue_free()
			_w_from = _wraith.global_position
			_stare = _eye - _fwd * FACE                                     # its eyes end up here, level with theirs
			_w_to = _stare - (_wraith.view.eyes.center() - _w_from)
			_to = _aim(_stare)
			SoundManager.play(SWISH, 0.0, 0.0)
		State.GLARE:
			_wraith.view.reach_arm = -1
			_wraith.view.reach = 0.3
			_wraith.audio.inhale()
		State.SCREAM:
			_wraith.audio.scream()
		State.DONE:
			_wraith.audio.cut()
			set_process(false)
			finished.emit()


## Its hover bob and twitching head carry its eyes about: ease the body so they stay on `_stare` (`closer` metres nearer).
func _hold_eyes(closer: float, dt: float) -> void:
	var eyes_off := _wraith.view.eyes.center() - _wraith.global_position
	_w_to = _w_to.lerp(_stare + _fwd * closer - eyes_off, 1.0 - exp(-dt * 10.0))


func progress() -> float: return clampf(_t / LENGTH.get(state, 1.0), 0.0, 1.0)


func _aim(point: Vector3) -> Quaternion:
	return Basis.looking_at(point - _eye, Vector3.UP).get_rotation_quaternion()
