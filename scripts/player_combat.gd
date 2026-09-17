class_name PlayerCombat
extends RefCounted

signal weapon_fired(type: int, is_hit: bool, hit_pos: Vector3, hit_norm: Vector3)
signal grenade_pin_pulled
signal grenade_thrown
signal grenade_exploded_in_hand
signal weapon_switched(new_type: int)

enum WeaponType { BLASTER, GRENADE }
enum GrenadeHoldState { READY, COOKING, THROWING }

const GrenadeScene = preload("res://scenes/props/grenade_projectile.tscn")
const TOTAL_FUSE: float = 3.5

var current_weapon: WeaponType = WeaponType.BLASTER
var grenade_hold_state: GrenadeHoldState = GrenadeHoldState.READY
var grenade_cook_timer: float = 0.0
var fire_cooldown_timer: float = 0.0

var gun_mesh: Node3D
var grenade_mount: Node3D
var grenade_pin: MeshInstance3D
var grenade_fuse_light: OmniLight3D

func setup_visuals(mesh: Node3D, mount: Node3D, pin: MeshInstance3D, light: OmniLight3D, tree: SceneTree) -> void:
	gun_mesh = mesh
	grenade_mount = mount
	grenade_pin = pin
	grenade_fuse_light = light
	weapon_switched.connect(func(type):
		if gun_mesh: gun_mesh.visible = (type == 0)
		if grenade_mount:
			grenade_mount.visible = (type == 1)
			if grenade_pin: grenade_pin.visible = true
			if grenade_fuse_light: grenade_fuse_light.visible = false
	)
	grenade_pin_pulled.connect(func():
		if grenade_pin: grenade_pin.visible = false
		if grenade_fuse_light: grenade_fuse_light.visible = true
	)
	grenade_thrown.connect(func():
		if grenade_mount: grenade_mount.visible = false
		tree.create_timer(0.4).timeout.connect(func():
			if current_weapon == WeaponType.GRENADE and grenade_mount:
				grenade_mount.visible = true
				if grenade_pin: grenade_pin.visible = true
				if grenade_fuse_light: grenade_fuse_light.visible = false
		)
	)

func update_timers(delta: float) -> void:
	if delta <= 0.0: return
	fire_cooldown_timer = max(0.0, fire_cooldown_timer - delta)
	if current_weapon == WeaponType.GRENADE and grenade_hold_state == GrenadeHoldState.COOKING:
		grenade_cook_timer -= delta
		if grenade_cook_timer <= 0.0:
			grenade_exploded_in_hand.emit()
			reset_grenade()

func switch_to(new_type: WeaponType) -> void:
	if current_weapon == new_type: return
	current_weapon = new_type
	reset_grenade()
	weapon_switched.emit(int(new_type))

func shoot_blaster(space_state: PhysicsDirectSpaceState3D, cam_origin: Vector3, cam_fwd: Vector3, exclude_rid: RID) -> bool:
	if fire_cooldown_timer > 0.0 or not space_state: return false
	fire_cooldown_timer = 0.14
	var query = PhysicsRayQueryParameters3D.create(cam_origin, cam_origin + cam_fwd * 120.0)
	query.exclude = [exclude_rid]
	var res = space_state.intersect_ray(query)
	if res:
		var col = res.collider
		if col and col.has_method("take_hit"):
			col.take_hit(24.0, res.normal, res.position)
		weapon_fired.emit(int(WeaponType.BLASTER), true, res.position, res.normal)
		return true
	weapon_fired.emit(int(WeaponType.BLASTER), false, cam_origin + cam_fwd * 120.0, Vector3.UP)
	return true

func handle_grenade_trigger(cam_trans: Transform3D, player_vel: Vector3, world_root: Node) -> void:
	if current_weapon != WeaponType.GRENADE: return
	match grenade_hold_state:
		GrenadeHoldState.READY:
			grenade_hold_state = GrenadeHoldState.COOKING
			grenade_cook_timer = TOTAL_FUSE
			grenade_pin_pulled.emit()
		GrenadeHoldState.COOKING:
			grenade_hold_state = GrenadeHoldState.THROWING
			_throw_grenade(cam_trans, player_vel, world_root)
			grenade_thrown.emit()

func _throw_grenade(cam_trans: Transform3D, player_vel: Vector3, world_root: Node) -> void:
	if not world_root: return
	var grenade = GrenadeScene.instantiate()
	var spawn_pos = cam_trans.origin + (-cam_trans.basis.z * 0.8) + (cam_trans.basis.y * -0.1)
	world_root.add_child(grenade)
	grenade.global_position = spawn_pos
	var throw_dir = -cam_trans.basis.z
	var throw_vel = (throw_dir * 24.0) + (cam_trans.basis.y * 2.2) + (player_vel * 0.5)
	grenade.initialize(grenade_cook_timer, throw_vel)

func explode_in_hand(world_root: Node, pos: Vector3) -> void:
	if not world_root: return
	var grenade_inst = GrenadeScene.instantiate()
	world_root.add_child(grenade_inst)
	grenade_inst.global_position = pos
	grenade_inst.explode()
	reset_grenade()

func reset_grenade() -> void:
	grenade_hold_state = GrenadeHoldState.READY
	grenade_cook_timer = 0.0
