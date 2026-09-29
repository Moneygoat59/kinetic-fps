class_name DevFlycam
extends Node
## Dev free flight (DevManager, F3): a detached camera flown with WASD, Space/E up, Ctrl/C/Q down, Shift boost, wheel speed.
## The walker's body is carried along under the camera with its physics off, so everything that follows the walker
## (the forest's terrain streaming, the stalkers) follows the flight; walking is not counted (ForestNightDirector).
## stop(true) sets the walker down where the camera is, stop(false) puts them back where the flight began.
## Fly speed is remembered per level (small rooms fly slow). Freezes with the tree while the dev menu is open.

signal changed(flying: bool, speed: float)

enum State { OFF, FLYING }

const LOOK_SENS := 0.0028
const PITCH_MAX := 1.48
const EYE := Vector3(0.0, 1.4, 0.0)          # the walker's Head over their feet
const SPEED_MIN := 1.0
const SPEED_MAX := 300.0
const BOOST := 3.0
const SMALL_LEVEL_SPEED := 3.0                # an ApartmentLevel
const OPEN_LEVEL_SPEED := 35.0

var state := State.OFF
var speed := OPEN_LEVEL_SPEED
var cam: Camera3D
var player: CharacterBody3D
var _player_cam: Camera3D
var _origin: Transform3D
var _rot := Vector2.ZERO
var _vel := Vector3.ZERO
var _speeds := {}                             # scene path -> fly speed last used there


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func start(body: CharacterBody3D) -> bool:
	if state == State.FLYING or body == null or not body.is_inside_tree():
		return false
	var eye := body.get_node_or_null("Head/Camera3D") as Camera3D
	if eye == null:
		return false
	player = body
	_player_cam = eye
	_origin = body.global_transform
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	speed = _speeds.get(path, SMALL_LEVEL_SPEED if get_tree().current_scene is ApartmentLevel else OPEN_LEVEL_SPEED)
	cam = Camera3D.new()
	cam.name = "DevFlyCam"
	cam.fov = eye.fov
	cam.near = 0.05
	cam.far = 4000.0
	get_tree().root.add_child(cam)
	cam.global_transform = eye.global_transform
	cam.current = true
	_rot = Vector2(cam.rotation.x, cam.rotation.y)
	_vel = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	state = State.FLYING
	changed.emit(true, speed)
	return true


## land: set the walker down under the camera, facing where it looks; else back where the flight began.
func stop(land: bool) -> void:
	if state != State.FLYING:
		return
	state = State.OFF
	if is_instance_valid(player):
		if land:
			player.global_position = cam.global_position - EYE
			player.rotation.y = _rot.y
			var head := player.get_node_or_null("Head") as Node3D
			if head: head.rotation.x = _rot.x
		else:
			player.global_transform = _origin
		player.velocity = Vector3.ZERO
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
	if is_instance_valid(_player_cam): _player_cam.current = true
	_free_cam()
	changed.emit(false, speed)


## The level went away under the flight (scene change): forget it all without touching the old walker.
func drop() -> void:
	state = State.OFF
	player = null
	_free_cam()


## Moves the flight to look at `look` from `from` (a dev teleport while flying).
func place(from: Vector3, look: Vector3) -> void:
	if state != State.FLYING:
		return
	cam.global_position = from
	if not from.is_equal_approx(look):
		cam.look_at(look, Vector3.UP)
	_rot = Vector2(cam.rotation.x, cam.rotation.y)
	_vel = Vector3.ZERO


func handle_input(event: InputEvent) -> bool:
	if state != State.FLYING:
		return false
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rot.y -= event.relative.x * LOOK_SENS
		_rot.x = clampf(_rot.x - event.relative.y * LOOK_SENS, -PITCH_MAX, PITCH_MAX)
		cam.rotation = Vector3(_rot.x, _rot.y, 0.0)
		return true
	if event is InputEventMouseButton and event.pressed:
		var mult := 1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else (0.8 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.0)
		if mult != 1.0:
			speed = clampf(speed * mult, SPEED_MIN, SPEED_MAX)
			if get_tree().current_scene: _speeds[get_tree().current_scene.scene_file_path] = speed
			changed.emit(true, speed)
			return true
	return false


func _process(delta: float) -> void:
	if state != State.FLYING or delta <= 0.0 or not is_instance_valid(cam) or not cam.is_inside_tree():
		return
	var dt := minf(delta, 0.1)
	var b := cam.global_basis
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= b.z
	if Input.is_key_pressed(KEY_S): dir += b.z
	if Input.is_key_pressed(KEY_A): dir -= b.x
	if Input.is_key_pressed(KEY_D): dir += b.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E): dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_Q): dir -= Vector3.UP
	var want := dir.normalized() * speed * (BOOST if Input.is_key_pressed(KEY_SHIFT) else 1.0) if dir.length_squared() > 0.01 else Vector3.ZERO
	_vel = _vel.lerp(want, minf(14.0 * dt, 1.0))
	cam.global_position += _vel * dt
	if is_instance_valid(player) and player.is_inside_tree():
		player.global_position = cam.global_position - EYE


func _free_cam() -> void:
	if is_instance_valid(cam): cam.queue_free()
	cam = null
	_player_cam = null
