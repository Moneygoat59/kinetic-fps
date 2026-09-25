class_name GalleryFlyCam
extends Camera3D

signal speed_changed(speed: float)

@export var move_speed: float = 18.0
@export var boost_mult: float = 3.0
@export var mouse_sensitivity: float = 0.0028

var cam_rot: Vector2 = Vector2.ZERO
var mouse_captured: bool = true
var _velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	current = true
	near = 0.05
	far = 1200.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cam_rot = Vector2(rotation.x, rotation.y)
	emit_signal("speed_changed", move_speed)

func teleport_to(target_pos: Vector3, look_target: Vector3) -> void:
	global_position = target_pos
	look_at(look_target, Vector3.UP)
	cam_rot = Vector2(rotation.x, rotation.y)
	_velocity = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not mouse_captured:
			mouse_captured = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = clampf(move_speed * 1.15, 3.0, 150.0)
			emit_signal("speed_changed", move_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = clampf(move_speed * 0.87, 3.0, 150.0)
			emit_signal("speed_changed", move_speed)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_captured = !mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE

	if mouse_captured and event is InputEventMouseMotion:
		cam_rot.y -= event.relative.x * mouse_sensitivity
		cam_rot.x = clampf(cam_rot.x - event.relative.y * mouse_sensitivity, -1.48, 1.48)
		rotation = Vector3(cam_rot.x, cam_rot.y, 0.0)

func _process(delta: float) -> void:
	if not mouse_captured: return

	var input_dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): input_dir -= global_transform.basis.z
	if Input.is_key_pressed(KEY_S): input_dir += global_transform.basis.z
	if Input.is_key_pressed(KEY_A): input_dir -= global_transform.basis.x
	if Input.is_key_pressed(KEY_D): input_dir += global_transform.basis.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E): input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_Q): input_dir += Vector3.DOWN

	var target_spd = move_speed * (boost_mult if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	var target_vel = input_dir.normalized() * target_spd if input_dir.length_squared() > 0.01 else Vector3.ZERO
	_velocity = _velocity.lerp(target_vel, 14.0 * delta)
	global_position += _velocity * delta
