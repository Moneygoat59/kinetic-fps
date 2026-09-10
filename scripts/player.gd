class_name Player
extends CharacterBody3D

const CourseManager = preload("res://scripts/course_manager.gd")
const VineRenderer = preload("res://scripts/vine_renderer.gd")
const GrenadeScene = preload("res://scenes/props/grenade_projectile.tscn")

enum WeaponType { BLASTER, GRENADE }
enum GrenadeHoldState { READY, COOKING, THROWING }

@export_group("Movement")
@export var ground_speed: float = 14.0
@export var ground_accel: float = 14.0
@export var ground_decel: float = 9.0
@export var air_accel: float = 16.0
@export var air_wish_speed: float = 3.5
@export var jump_velocity: float = 8.5
@export var gravity: float = 24.0

@export_group("Slide & Dash")
@export var slide_friction: float = 0.6
@export var slide_boost: float = 6.0
@export var dash_speed: float = 26.0
@export var dash_cooldown: float = 0.75

@export_group("Vine Grapple (Shitty & Exaggerated)")
@export var vine_max_dist: float = 59.5
@export var vine_spring: float = 34.0
@export var vine_pump: float = 34.0
@export var vine_slingshot: float = 1.32

@export_group("Camera & Feel")
@export var mouse_sensitivity: float = 0.0024
@export var base_fov: float = 85.0
@export var max_fov: float = 112.0
@export var fov_speed_threshold: float = 14.0
@export var max_tilt_angle: float = deg_to_rad(3.5)

# Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun_mount: Node3D = $Head/Camera3D/GunMount
@onready var gun_mesh: Node3D = $Head/Camera3D/GunMount/Gun
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/GunMount/Gun/MuzzleFlash
@onready var grenade_mount: Node3D = $Head/Camera3D/GunMount/GrenadeHold
@onready var grenade_pin: MeshInstance3D = $Head/Camera3D/GunMount/GrenadeHold/PinRing
@onready var grenade_fuse_light: OmniLight3D = $Head/Camera3D/GunMount/GrenadeHold/FuseLight
@onready var aim_ray: RayCast3D = $Head/Camera3D/AimRay
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hud: CanvasLayer = $HUD
@onready var speed_label: Label = $HUD/SpeedLabel
@onready var weapon_label: Label = $HUD/WeaponLabel
@onready var interact_label: Label = $HUD/InteractPrompt
@onready var crosshair: Control = $HUD/Crosshair

var current_weapon: WeaponType = WeaponType.BLASTER
var grenade_hold_state: GrenadeHoldState = GrenadeHoldState.READY
var grenade_cook_timer: float = 0.0
const GRENADE_TOTAL_FUSE: float = 3.5

var mouse_captured: bool = true
var is_sliding: bool = false
var slide_vector: Vector3 = Vector3.ZERO
var dash_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var fire_cooldown_timer: float = 0.0
var weapon_sway_offset: Vector2 = Vector2.ZERO
var original_camera_pos: Vector3 = Vector3.ZERO

# Grapple vine state
var is_grappling: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var grapple_length: float = 0.0
var grapple_time: float = 0.0
var vine_strain: float = 0.0
var vine_snap_cooldown: float = 0.0
var strain_audio_timer: float = 0.0
const MAX_VINE_STRAIN: float = 1.0
var vine_renderer: VineRenderer

# Audio player
var sfx_player: AudioStreamPlayer

func _ready():
	original_camera_pos = head.position
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	vine_renderer = VineRenderer.new()
	vine_renderer.top_level = true
	add_child(vine_renderer)

	if gun_mesh:
		gun_mesh.visible = true
	if grenade_mount:
		grenade_mount.visible = false
	_reset_held_grenade()

	# Capture mouse once window is ready and on window focus
	_capture_mouse.call_deferred()
	get_window().focus_entered.connect(_capture_mouse)
	
	if CourseManager.instance:
		CourseManager.instance.register_player(self)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_capture_mouse.call_deferred()

func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true

func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false

func _input(event: InputEvent) -> void:
	# R key: reset to checkpoint, Shift+R full run restart
	if event.is_action_pressed("reset"):
		if CourseManager.instance:
			if event.is_shift_pressed():
				CourseManager.instance.restart_full_run()
			else:
				CourseManager.instance.respawn_player()
		get_viewport().set_input_as_handled()
		return

	# F11 or Alt+Enter to toggle fullscreen
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var cur_mode = DisplayServer.window_get_mode()
			if cur_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or cur_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
			return

	# ESC toggles cursor capture
	if event.is_action_pressed("toggle_mouse"):
		if mouse_captured:
			_release_mouse()
		else:
			_capture_mouse()
		get_viewport().set_input_as_handled()
		return

	# Any click inside the window immediately recaptures mouse if not captured
	if event is InputEventMouseButton and event.pressed:
		if not mouse_captured or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			_capture_mouse()

	# Mouse look: always active whenever mouse_captured is true
	if event is InputEventMouseMotion:
		if mouse_captured:
			rotate_y(-event.relative.x * mouse_sensitivity)
			if camera:
				camera.rotate_x(-event.relative.y * mouse_sensitivity)
				camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
			
			weapon_sway_offset.x = clamp(weapon_sway_offset.x - event.relative.x * 0.001, -0.05, 0.05)
			weapon_sway_offset.y = clamp(weapon_sway_offset.y - event.relative.y * 0.001, -0.05, 0.05)

	# Right click for vine grapple start & release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_start_vine_grapple()
		else:
			if is_grappling:
				_release_vine(false)

	# Weapon switching: G or 2 toggles/equips Grenade, 1 equips Blaster
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("equip_grenade") or event.keycode == KEY_G or event.keycode == KEY_2:
			if current_weapon == WeaponType.BLASTER:
				_set_weapon(WeaponType.GRENADE)
			elif current_weapon == WeaponType.GRENADE:
				if grenade_hold_state == GrenadeHoldState.COOKING:
					_play_tone_slide(200.0, 150.0, 0.05, true)
				else:
					_set_weapon(WeaponType.BLASTER)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_1:
			if current_weapon == WeaponType.GRENADE and grenade_hold_state == GrenadeHoldState.COOKING:
				_play_tone_slide(200.0, 150.0, 0.05, true)
			else:
				_set_weapon(WeaponType.BLASTER)
			get_viewport().set_input_as_handled()
			return

	# Left click trigger
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if current_weapon == WeaponType.GRENADE:
				_handle_grenade_click()
			elif current_weapon == WeaponType.BLASTER and fire_cooldown_timer <= 0.0:
				_shoot()

func _physics_process(delta: float) -> void:
	dash_timer -= delta
	jump_buffer_timer -= delta
	fire_cooldown_timer -= delta
	vine_snap_cooldown -= delta
	
	# Grenade cooking in hand
	if current_weapon == WeaponType.GRENADE and grenade_hold_state == GrenadeHoldState.COOKING:
		grenade_cook_timer -= delta
		if grenade_fuse_light:
			grenade_fuse_light.visible = fmod(grenade_cook_timer * 14.0, 1.0) > 0.35
			if randf() < 0.08:
				_play_tone_slide(900.0, 1400.0, 0.02, true)
		if grenade_cook_timer <= 0.0:
			_explode_in_hand()
	
	if is_on_floor():
		coyote_timer = 0.15
	else:
		coyote_timer -= delta
		velocity.y -= gravity * delta

	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.15

	var wish_jump = (jump_buffer_timer > 0.0) and (is_on_floor() or coyote_timer > 0.0)

	# Get input vector
	var input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir = (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()

	# Dash mechanic
	if Input.is_action_just_pressed("dash") and dash_timer <= 0.0:
		var d_dir = wish_dir if wish_dir.length_squared() > 0.01 else -transform.basis.z
		velocity.x = d_dir.x * dash_speed
		velocity.z = d_dir.z * dash_speed
		dash_timer = dash_cooldown
		_play_tone_slide(450.0, 750.0, 0.08)

	# Slide mechanic
	var slide_pressed = Input.is_action_pressed("slide")
	if slide_pressed and is_on_floor() and not is_sliding:
		var horiz_vel = Vector3(velocity.x, 0, velocity.z)
		if horiz_vel.length() > 3.0:
			is_sliding = true
			slide_vector = horiz_vel.normalized()
			velocity += slide_vector * slide_boost
	elif not slide_pressed and is_sliding:
		is_sliding = false

	var target_head_y = 0.6 if is_sliding else 1.4
	head.position.y = lerp(head.position.y, target_head_y, delta * 14.0)

	# Vine grapple: check if right mouse button is released
	if is_grappling and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and not Input.is_action_pressed("alt_fire"):
		_release_vine(false)

	# Jump execution (also detaches vine with catapult boost if in mid-swing!)
	if Input.is_action_just_pressed("jump") and is_grappling:
		_release_vine(true)
		wish_jump = false
	elif wish_jump:
		velocity.y = jump_velocity
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		if is_sliding:
			is_sliding = false
		_play_tone_slide(240.0, 360.0, 0.05)

	# Movement physics
	if is_grappling:
		_apply_vine_physics(delta, wish_dir)
	elif is_on_floor():
		if is_sliding:
			_apply_slide_physics(delta)
		else:
			_apply_ground_physics(wish_dir, delta)
	else:
		_apply_air_physics(wish_dir, delta)

	move_and_slide()

	# Auto-fire while holding Left Click (Blaster only)
	if current_weapon == WeaponType.BLASTER:
		var holding_fire = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("shoot")
		if holding_fire and fire_cooldown_timer <= 0.0:
			_shoot()

	# Interaction check
	_check_interaction()

	# Camera & Weapon feel
	_update_juice(input_vec, delta)
	_update_hud()

func _start_vine_grapple() -> void:
	if vine_snap_cooldown > 0.0:
		_play_tone_slide(180.0, 100.0, 0.05, true)
		return

	var space_state = get_world_3d().direct_space_state
	var origin = camera.global_position
	var dir = -camera.global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * vine_max_dist)
	query.exclude = [get_rid()]
	var res = space_state.intersect_ray(query)
	if res:
		is_grappling = true
		grapple_point = res.position
		grapple_length = (global_position - grapple_point).length()
		grapple_time = 0.0
		vine_strain = 0.0
		strain_audio_timer = 0.0
		var to_anc = (grapple_point - global_position).normalized()
		velocity += to_anc * 6.5
		_play_tone_slide(140.0, 380.0, 0.15)
	else:
		_play_tone_slide(420.0, 180.0, 0.08, true)

func _apply_vine_physics(delta: float, wish_dir: Vector3) -> void:
	grapple_time += delta
	var to_anchor = grapple_point - global_position
	var dist = to_anchor.length()
	var rope_dir = to_anchor.normalized()

	if dist > grapple_length:
		var stretch = dist - grapple_length
		var spring_accel = rope_dir * (stretch * vine_spring)
		velocity += spring_accel * delta

		var outward_speed = velocity.dot(-rope_dir)
		if outward_speed > 0.0:
			velocity += rope_dir * outward_speed * 0.94

	velocity.y -= gravity * 0.45 * delta

	if wish_dir.length_squared() > 0.01:
		var tangent = wish_dir - rope_dir * wish_dir.dot(rope_dir)
		if tangent.length_squared() > 0.01:
			velocity += tangent.normalized() * (vine_pump * delta)

	if Input.is_action_pressed("move_forward"):
		grapple_length = max(3.5, grapple_length - 14.0 * delta)
	elif Input.is_action_pressed("move_back"):
		grapple_length = min(vine_max_dist, grapple_length + 12.0 * delta)

	# Option 3: Strain accumulation under intense centrifugal speed or heavy stretch
	var horiz_spd = Vector2(velocity.x, velocity.z).length()
	if horiz_spd > 33.0 or dist > grapple_length * 1.25:
		var over = max((horiz_spd - 33.0) / 10.0, (dist - grapple_length) / 3.0)
		vine_strain += delta * (0.42 + over * 0.65)
		strain_audio_timer -= delta
		if strain_audio_timer <= 0.0:
			_play_tone_slide(220.0 + vine_strain * 480.0, 280.0 + vine_strain * 560.0, 0.07)
			strain_audio_timer = 0.12
	else:
		vine_strain = max(0.0, vine_strain - delta * 1.5)

	# Vine snaps if strained past threshold!
	if vine_strain >= MAX_VINE_STRAIN:
		_snap_vine()
		return

	var vine_source = camera.global_position + (-camera.global_transform.basis.x * 0.28) + (-camera.global_transform.basis.y * 0.22)
	var tension = clamp(dist / max(0.1, grapple_length), 0.0, 2.0)
	vine_renderer.draw_vine(vine_source, grapple_point, tension, grapple_time, camera.global_position, vine_strain)

func _snap_vine() -> void:
	is_grappling = false
	vine_renderer.clear_vine()
	vine_strain = 0.0
	vine_snap_cooldown = 0.45

	# Over-strain snap punishment: shed 40% horizontal speed and drop downward
	velocity.x *= 0.6
	velocity.z *= 0.6
	velocity.y = min(velocity.y, -4.0)

	# Comedic rubber-band snap twang sound
	_play_tone_slide(950.0, 80.0, 0.18, true)

	# Jarring camera shock
	camera.rotation.z += (randf() - 0.5) * deg_to_rad(12.0)
	camera.rotation.x += deg_to_rad(4.5)

func _release_vine(was_jump: bool) -> void:
	if not is_grappling:
		return
	is_grappling = false
	vine_renderer.clear_vine()
	vine_strain = 0.0

	var speed = velocity.length()
	if speed > 6.0:
		# Option 1: Physics-True release + punchy forward catapult impulse
		var forward_dir = -transform.basis.z
		velocity += forward_dir * 7.0
		
		# Soft cap launch speed so you don't fly off into the distance
		var horiz_vel = Vector2(velocity.x, velocity.z)
		if horiz_vel.length() > 36.0:
			horiz_vel = horiz_vel.normalized() * 36.0
			velocity.x = horiz_vel.x
			velocity.z = horiz_vel.y
		
		if was_jump:
			velocity.y = max(velocity.y + 6.8, jump_velocity * 1.25)
		_play_tone_slide(560.0, 340.0, 0.1)
	else:
		if was_jump:
			velocity.y = jump_velocity

	camera.fov = min(camera.fov + 10.0, max_fov)

func _apply_ground_physics(wish_dir: Vector3, delta: float) -> void:
	var horiz_vel = Vector2(velocity.x, velocity.z)
	var speed = horiz_vel.length()
	
	if speed > 0.001:
		var drop = speed * ground_decel * delta
		var new_speed = max(0.0, speed - drop)
		horiz_vel = horiz_vel * (new_speed / speed)
	else:
		horiz_vel = Vector2.ZERO

	if wish_dir.length_squared() > 0.01:
		var target_vel = Vector2(wish_dir.x, wish_dir.z) * ground_speed
		horiz_vel = horiz_vel.move_toward(target_vel, ground_accel * ground_speed * delta)

	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.y

func _apply_slide_physics(delta: float) -> void:
	var horiz_vel = Vector2(velocity.x, velocity.z)
	var speed = horiz_vel.length()
	
	if speed > 0.1:
		var drop = speed * slide_friction * delta
		var new_speed = max(0.0, speed - drop)
		horiz_vel = horiz_vel * (new_speed / speed)
	
	velocity.x = horiz_vel.x
	velocity.z = horiz_vel.y

func _apply_air_physics(wish_dir: Vector3, delta: float) -> void:
	if wish_dir.length_squared() > 0.01:
		var current_speed = velocity.dot(wish_dir)
		var add_speed = air_wish_speed - current_speed
		if add_speed > 0.0:
			var accel_speed = air_accel * air_wish_speed * delta
			accel_speed = min(accel_speed, add_speed)
			velocity += wish_dir * accel_speed

	# Option 1: Aerodynamic drag taper above 28 m/s
	var horiz_vel = Vector2(velocity.x, velocity.z)
	var horiz_speed = horiz_vel.length()
	var drag_threshold = 28.0
	if horiz_speed > drag_threshold:
		var overspeed = horiz_speed - drag_threshold
		var drag = (1.6 + overspeed * 0.14) * delta
		var new_speed = max(drag_threshold, horiz_speed - overspeed * drag)
		horiz_vel = horiz_vel * (new_speed / horiz_speed)
		velocity.x = horiz_vel.x
		velocity.z = horiz_vel.y

func _shoot() -> void:
	fire_cooldown_timer = 0.14
	camera.rotation.x += deg_to_rad(1.4)
	gun_mount.position.z += 0.08
	
	if muzzle_flash:
		muzzle_flash.visible = true
		get_tree().create_timer(0.04).timeout.connect(func(): muzzle_flash.visible = false)

	_play_tone_slide(880.0, 200.0, 0.05, true)

	if aim_ray.is_colliding():
		var hit_collider = aim_ray.get_collider()
		var hit_point = aim_ray.get_collision_point()
		var hit_normal = aim_ray.get_collision_normal()

		if hit_collider.has_method("take_hit"):
			hit_collider.take_hit(25.0, hit_normal, hit_point)
		elif hit_collider is RigidBody3D:
			var push_dir = -aim_ray.global_transform.basis.z
			hit_collider.apply_impulse(push_dir * 14.0, hit_point - hit_collider.global_position)

		_spawn_impact(hit_point, hit_normal)

func _spawn_impact(point: Vector3, _normal: Vector3) -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = point
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.3)
	light.light_energy = 2.5
	light.omni_range = 3.0
	effect.add_child(light)

	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	mesh_inst.mesh = box
	effect.add_child(mesh_inst)

	var tween = effect.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.15)
	tween.tween_callback(effect.queue_free)

func _check_interaction() -> void:
	interact_label.visible = false
	if aim_ray.is_colliding():
		var collider = aim_ray.get_collider()
		if collider and collider.has_method("interact"):
			var prompt = "[E] Interact"
			if collider.has_method("get_interaction_prompt"):
				prompt = collider.get_interaction_prompt()
			interact_label.text = prompt
			interact_label.visible = true
			if Input.is_action_just_pressed("interact"):
				collider.interact(self)

func _update_juice(input_vec: Vector2, delta: float) -> void:
	var target_tilt = -input_vec.x * max_tilt_angle
	if is_sliding:
		target_tilt *= 1.8
	elif is_grappling:
		var to_anchor = grapple_point - global_position
		var rope_dir = to_anchor.normalized()
		var swing_cross = velocity.cross(rope_dir)
		target_tilt += clamp(swing_cross.y * 0.02, -deg_to_rad(9.0), deg_to_rad(9.0))
		
	camera.rotation.z = lerp_angle(camera.rotation.z, target_tilt, delta * 10.0)

	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	var target_fov = base_fov
	if horiz_speed > fov_speed_threshold:
		var t = clamp((horiz_speed - fov_speed_threshold) / 22.0, 0.0, 1.0)
		target_fov = lerp(base_fov, max_fov, t)
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	weapon_sway_offset = weapon_sway_offset.lerp(Vector2.ZERO, delta * 12.0)
	gun_mount.position.x = lerp(gun_mount.position.x, weapon_sway_offset.x + 0.28, delta * 10.0)
	gun_mount.position.y = lerp(gun_mount.position.y, weapon_sway_offset.y - 0.22, delta * 10.0)
	gun_mount.position.z = lerp(gun_mount.position.z, -0.45, delta * 10.0)

func _update_hud() -> void:
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	speed_label.text = "VEL: %4.1f m/s" % horiz_speed
	
	if is_grappling:
		var dist = (global_position - grapple_point).length()
		if vine_strain > 0.25:
			speed_label.text += " [STRAIN: %d%%!]" % int(vine_strain * 100.0)
		else:
			speed_label.text += " [VINE: %2.0fm]" % dist
	elif vine_snap_cooldown > 0.0:
		speed_label.text += " [VINE SNAPPED!]"
	elif is_sliding:
		speed_label.text += " [SLIDING]"
	elif dash_timer > 0.0:
		speed_label.text += " [DASH]"
	elif not is_on_floor():
		speed_label.text += " [AIR]"

	if weapon_label:
		if current_weapon == WeaponType.BLASTER:
			weapon_label.text = "[1] BLASTER   [G] GRENADE"
			weapon_label.add_theme_color_override("font_color", Color(0.2, 0.9, 1.0, 1.0))
		elif current_weapon == WeaponType.GRENADE:
			match grenade_hold_state:
				GrenadeHoldState.READY:
					weapon_label.text = "[G] GRENADE [PIN IN - LMB TO PULL]"
					weapon_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3, 1.0))
				GrenadeHoldState.COOKING:
					weapon_label.text = "[G] FUSE: %1.1fs! [LMB TO THROW!]" % max(0.0, grenade_cook_timer)
					weapon_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15, 1.0))
				GrenadeHoldState.THROWING:
					weapon_label.text = "[G] THROWING..."
					weapon_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))

func reset_for_respawn() -> void:
	_release_vine(false)
	is_sliding = false
	_reset_held_grenade()

func _set_weapon(new_weapon: WeaponType) -> void:
	if current_weapon == new_weapon:
		return
	current_weapon = new_weapon
	if current_weapon == WeaponType.BLASTER:
		if gun_mesh:
			gun_mesh.visible = true
		if grenade_mount:
			grenade_mount.visible = false
		_play_tone_slide(400.0, 700.0, 0.04)
	elif current_weapon == WeaponType.GRENADE:
		if gun_mesh:
			gun_mesh.visible = false
		if grenade_mount:
			grenade_mount.visible = true
		_reset_held_grenade()
		_play_tone_slide(500.0, 300.0, 0.04)

func _reset_held_grenade() -> void:
	grenade_hold_state = GrenadeHoldState.READY
	grenade_cook_timer = 0.0
	if grenade_mount:
		grenade_mount.visible = (current_weapon == WeaponType.GRENADE)
	if grenade_pin:
		grenade_pin.visible = true
	if grenade_fuse_light:
		grenade_fuse_light.visible = false

func _handle_grenade_click() -> void:
	if grenade_hold_state == GrenadeHoldState.READY:
		# First LMB click: pull pin, start cooking fuse
		grenade_hold_state = GrenadeHoldState.COOKING
		grenade_cook_timer = GRENADE_TOTAL_FUSE
		if grenade_pin:
			grenade_pin.visible = false
		if grenade_fuse_light:
			grenade_fuse_light.visible = true
		# Metallic clink / pin pull audio
		_play_tone_slide(1200.0, 2200.0, 0.07)
		gun_mount.position.z += 0.06
	elif grenade_hold_state == GrenadeHoldState.COOKING:
		# Second LMB click: throw grenade!
		_throw_grenade()

func _throw_grenade() -> void:
	if grenade_hold_state != GrenadeHoldState.COOKING:
		return
	grenade_hold_state = GrenadeHoldState.THROWING
	
	_play_tone_slide(280.0, 520.0, 0.09, true)
	
	var grenade = GrenadeScene.instantiate()
	get_parent().add_child(grenade)
	
	var cam_trans = camera.global_transform
	var spawn_pos = cam_trans.origin + (-cam_trans.basis.z * 0.8) + (cam_trans.basis.y * -0.1)
	grenade.global_position = spawn_pos
	
	var throw_dir = -cam_trans.basis.z
	var throw_vel = (throw_dir * 25.0) + (cam_trans.basis.y * 3.5) + (velocity * 0.6)
	grenade.initialize(grenade_cook_timer, throw_vel)
	
	# Visual throw recoil & hide held grenade during toss
	camera.rotation.x += deg_to_rad(2.0)
	gun_mount.position.z += 0.12
	if grenade_mount:
		grenade_mount.visible = false
	
	# After short delay, equip new grenade
	get_tree().create_timer(0.4).timeout.connect(func():
		if current_weapon == WeaponType.GRENADE:
			_reset_held_grenade()
	)

func _explode_in_hand() -> void:
	if grenade_hold_state != GrenadeHoldState.COOKING:
		return
	var blast_pos = camera.global_position
	var grenade_inst = GrenadeScene.instantiate()
	get_parent().add_child(grenade_inst)
	grenade_inst.global_position = blast_pos
	grenade_inst.explode()
	
	_reset_held_grenade()

func _play_tone_slide(start_freq: float, end_freq: float, duration: float, add_noise: bool = false) -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = duration + 0.05
	sfx_player.stream = gen
	sfx_player.play()
	var playback = sfx_player.get_stream_playback()
	if not playback:
		return
	var frames = int(gen.mix_rate * duration)
	var phase = 0.0
	for i in range(frames):
		var t = float(i) / float(frames)
		var freq = lerp(start_freq, end_freq, t)
		phase += freq / gen.mix_rate
		var decay = 1.0 - t
		var sample = sin(phase * TAU) * decay * 0.45
		if add_noise:
			sample += (randf() * 2.0 - 1.0) * 0.22 * decay
		playback.push_frame(Vector2(sample, sample))
