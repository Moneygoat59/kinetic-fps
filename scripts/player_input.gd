class_name PlayerInput
extends Node

const CourseManager = preload("res://scripts/course_manager.gd")
const MegaLevelManager = preload("res://scripts/megalevel_manager.gd")

var mouse_captured: bool = true
var mouse_sensitivity: float = 0.0024
var head_pitch: float = 0.0

var input_vec: Vector2 = Vector2.ZERO
var wish_dir: Vector3 = Vector3.ZERO

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.75

var dash_requested: bool = false
var slide_held: bool = false
var winch_held: bool = false
var catapult_requested: bool = false

func update_timers(delta: float, is_on_floor: bool) -> void:
	if delta <= 0.0:
		return
	if is_on_floor:
		coyote_timer = 0.12
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)

func poll_inputs(player_basis: Basis, is_grappling: bool) -> void:
	input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_vec.length_squared() > 0.001:
		wish_dir = (player_basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	else:
		wish_dir = Vector3.ZERO

	catapult_requested = false
	dash_requested = false
	winch_held = false

	if is_grappling:
		if Input.is_action_just_pressed("dash"):
			catapult_requested = true
		winch_held = Input.is_action_pressed("jump")
		slide_held = false
	else:
		if Input.is_action_just_pressed("jump"):
			jump_buffer_timer = 0.15
		if Input.is_action_just_pressed("dash") and dash_timer <= 0.0:
			dash_requested = true
		slide_held = Input.is_action_pressed("slide")

func consume_jump() -> bool:
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		return true
	return false

func consume_dash() -> bool:
	if dash_requested and dash_timer <= 0.0:
		dash_requested = false
		dash_timer = dash_cooldown
		return true
	dash_requested = false
	return false

func handle_mouse_input(event: InputEvent, body: CharacterBody3D, head: Node3D) -> void:
	if not (event is InputEventMouseMotion and mouse_captured):
		return
	if not body or not head:
		return
	var mm = event as InputEventMouseMotion
	body.rotate_y(-mm.relative.x * mouse_sensitivity)
	head_pitch = clamp(head_pitch - mm.relative.y * mouse_sensitivity, deg_to_rad(-89.0), deg_to_rad(89.0))
	head.rotation.x = head_pitch

func handle_system_shortcuts(event: InputEvent, hud: PlayerHudView) -> bool:
	if event.is_action_pressed("reset"):
		if CourseManager.instance:
			if event.is_shift_pressed(): CourseManager.instance.restart_full_run()
			else: CourseManager.instance.respawn_player()
		elif MegaLevelManager.instance:
			if event.is_shift_pressed(): MegaLevelManager.instance.teleport_to_hub()
			else: MegaLevelManager.instance.respawn_wave()
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_H and hud:
			hud.toggle_help()
			return true
		if event.keycode == KEY_F10:
			var vp = get_viewport()
			if vp:
				var s = vp.scaling_3d_scale
				if s < 0.9: vp.scaling_3d_scale = 1.0
				elif s < 1.2: vp.scaling_3d_scale = 1.25
				elif s < 1.4: vp.scaling_3d_scale = 1.5
				elif s < 1.9: vp.scaling_3d_scale = 2.0
				else: vp.scaling_3d_scale = 0.65
			return true
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var m = DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if (m == DisplayServer.WINDOW_MODE_FULLSCREEN or m == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) else DisplayServer.WINDOW_MODE_FULLSCREEN)
			return true
	return false

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func toggle_mouse() -> void:
	if mouse_captured: release_mouse()
	else: capture_mouse()
