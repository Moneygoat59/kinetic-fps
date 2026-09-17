class_name Player
extends CharacterBody3D

const CourseManager = preload("res://scripts/course_manager.gd")
const MegaLevelManager = preload("res://scripts/megalevel_manager.gd")
const VineRenderer = preload("res://scripts/vine_renderer.gd")

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun_mount: Node3D = $Head/Camera3D/GunMount
@onready var gun_mesh: Node3D = $Head/Camera3D/GunMount/Gun
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/GunMount/Gun/MuzzleFlash
@onready var grenade_mount: Node3D = $Head/Camera3D/GunMount/GrenadeHold
@onready var grenade_pin: MeshInstance3D = $Head/Camera3D/GunMount/GrenadeHold/PinRing
@onready var grenade_fuse_light: OmniLight3D = $Head/Camera3D/GunMount/GrenadeHold/FuseLight
@onready var aim_ray: RayCast3D = $Head/Camera3D/AimRay
@onready var hud: CanvasLayer = $HUD

var current_state: int = PlayerState.State.GROUND
var is_grappling: bool:
	get: return vine != null and vine.is_active
var current_health: float:
	get: return health.current_health if health else 100.0
var is_dead: bool:
	get: return health.is_dead if health else false
var mouse_captured: bool:
	get: return input_ctrl.mouse_captured if input_ctrl else true

var input_ctrl: PlayerInput; var presenter: PlayerPresenter
var motor: PlayerMotor = PlayerMotor.new(); var vine: PlayerVine = PlayerVine.new()
var combat: PlayerCombat = PlayerCombat.new(); var health: PlayerHealth = PlayerHealth.new()
var hud_view: PlayerHudView; var vine_renderer: VineRenderer; var sound_manager: SoundManager

func _ready() -> void:
	sound_manager = SoundManager.new(); input_ctrl = PlayerInput.new()
	presenter = PlayerPresenter.new(); hud_view = PlayerHudView.new()
	vine_renderer = VineRenderer.new()
	for child in [sound_manager, input_ctrl, presenter, hud_view, vine_renderer]: add_child(child)
	hud_view.setup_ui(hud)

	health.init(100.0, global_position)
	health.health_changed.connect(func(cur, _m): hud_view.update_health(cur))
	health.player_died.connect(_on_player_died)

	presenter.setup(combat, vine, get_parent(), get_tree(), muzzle_flash, gun_mount, camera, hud_view)
	combat.setup_visuals(gun_mesh, grenade_mount, grenade_pin, grenade_fuse_light, get_tree())
	combat.grenade_exploded_in_hand.connect(func(): combat.explode_in_hand(get_parent(), camera.global_position))
	combat.weapon_switched.connect(func(_t): SoundManager.play(AudioBank.WEAPON_SWITCH, -2.0))

	PlayerPs1View.apply_ps1_visuals(self, gun_mesh, grenade_mount)
	input_ctrl.capture_mouse.call_deferred()
	get_window().focus_entered.connect(func(): input_ctrl.capture_mouse.call_deferred())
	if CourseManager.instance: CourseManager.instance.register_player(self)

func _unhandled_input(event: InputEvent) -> void:
	if input_ctrl.handle_system_shortcuts(event, hud_view): return
	if event.is_action_pressed("toggle_mouse"): input_ctrl.toggle_mouse(); return
	if event is InputEventMouseButton and event.pressed and not input_ctrl.mouse_captured: input_ctrl.capture_mouse()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("equip_grenade") or event.keycode in [KEY_G, KEY_2]:
			combat.switch_to(PlayerCombat.WeaponType.BLASTER if combat.current_weapon == PlayerCombat.WeaponType.GRENADE else PlayerCombat.WeaponType.GRENADE)
		elif event.keycode == KEY_1: combat.switch_to(PlayerCombat.WeaponType.BLASTER)
		return
	input_ctrl.handle_mouse_input(event, self, head)
	_handle_clicks(event)

func _physics_process(delta: float) -> void:
	if delta <= 0.0: return
	input_ctrl.update_timers(delta, is_on_floor())
	vine.update_cooldowns(delta)
	combat.update_timers(delta)
	hud_view.decay_damage_flash(delta)
	_check_interaction()

	if health.is_dead:
		velocity = motor.apply_gravity(velocity, delta)
		move_and_slide()
		return

	input_ctrl.poll_inputs(global_transform.basis, vine.is_active)
	current_state = PlayerLocomotion.update_state(current_state, is_on_floor(), vine.is_active, input_ctrl.slide_held, velocity, -global_transform.basis.z, motor)
	velocity = PlayerLocomotion.step_movement(current_state, velocity, input_ctrl, motor, vine, get_floor_normal(), -global_transform.basis.z, -camera.global_transform.basis.z, global_position, is_on_floor(), delta)
	move_and_slide()

	var swing_tilt = 0.0
	if vine.is_active:
		var rope_dir = (vine.grapple_point - global_position).normalized()
		swing_tilt = clamp(velocity.cross(rope_dir).y * 0.02, -deg_to_rad(9.0), deg_to_rad(9.0))
	presenter.update_camera_and_weapon(camera, gun_mount, velocity, input_ctrl.input_vec, current_state == PlayerState.State.SLIDE, swing_tilt, delta)
	hud_view.update_speed(Vector2(velocity.x, velocity.z).length(), vine.is_active, vine.vine_strain, (global_position - vine.grapple_point).length(), input_ctrl.winch_held, PlayerState.to_string_name(current_state))
	hud_view.update_weapon(int(combat.current_weapon), int(combat.grenade_hold_state), combat.grenade_cook_timer)

	if vine.is_active and vine_renderer:
		var hand_pos = camera.global_position + (-camera.global_transform.basis.z * 0.3) + (camera.global_transform.basis.x * -0.15) + (camera.global_transform.basis.y * -0.1)
		vine_renderer.update_vine(hand_pos, vine.grapple_point, vine.grapple_time, vine.vine_strain, vine.vine_tension, camera.global_position)
	elif vine_renderer:
		vine_renderer.clear_vine()

func _handle_clicks(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if vine.try_start(get_world_3d().direct_space_state, camera.global_position, -camera.global_transform.basis.z, get_rid(), global_position):
					SoundManager.play(AudioBank.VINE_LATCH, 0.0)
					velocity += (-camera.global_transform.basis.z * 3.2) + (Vector3.UP * 1.5)
			elif vine.is_active:
				velocity = vine.release(velocity, -camera.global_transform.basis.z, false, motor.jump_velocity, motor.max_fall_speed)
				SoundManager.play(AudioBank.VINE_RELEASE, 0.0)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if combat.current_weapon == PlayerCombat.WeaponType.BLASTER:
				combat.shoot_blaster(get_world_3d().direct_space_state, camera.global_position, -camera.global_transform.basis.z, get_rid())
			else:
				combat.handle_grenade_trigger(camera.global_transform, velocity, get_parent())

func _check_interaction() -> void:
	var col = aim_ray.get_collider() if aim_ray and aim_ray.is_colliding() else null
	if col and col.has_method("interact"):
		hud_view.show_prompt(col.get_interaction_prompt() if col.has_method("get_interaction_prompt") else "[E] Interact")
		if Input.is_action_just_pressed("interact"): col.interact(self)
	else: hud_view.hide_prompt()

func take_hit(damage: float, _normal: Vector3 = Vector3.ZERO, _point: Vector3 = Vector3.ZERO) -> void:
	if health.is_dead: return
	hud_view.flash_damage()
	presenter.add_recoil(1.8, 6.0)
	SoundManager.play(AudioBank.HURT, 1.0)
	SoundManager.play(AudioBank.GLITCH, -3.0)
	health.take_damage(damage)

func reset_for_respawn() -> void:
	if vine.is_active: velocity = vine.release(velocity, -camera.global_transform.basis.z, false, motor.jump_velocity, motor.max_fall_speed)
	combat.reset_grenade(); combat.switch_to(combat.current_weapon); health.reset()
	current_state = PlayerState.State.GROUND; velocity = Vector3.ZERO
	presenter.reset_camera(camera)

func _on_player_died() -> void:
	current_state = PlayerState.State.DEAD; SoundManager.play(AudioBank.DEATH, 2.0); hud_view.set_death_overlay(true)
	await get_tree().create_timer(0.8).timeout
	if CourseManager.instance: CourseManager.instance.respawn_at_checkpoint()
	elif MegaLevelManager.instance: MegaLevelManager.instance.respawn_player()
	else: global_position = health.spawn_position; velocity = Vector3.ZERO
	reset_for_respawn(); hud_view.set_death_overlay(false)

func _play_tone_slide(start_freq: float, end_freq: float, duration: float, add_noise: bool = false) -> void:
	if presenter: presenter.play_tone_slide(start_freq, end_freq, duration, add_noise)
