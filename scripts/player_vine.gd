class_name PlayerVine
extends RefCounted

signal vine_latched
signal vine_released(was_catapult: bool)
signal vine_winch_tick
signal vine_snapped

var vine_max_dist: float = 42.0
var vine_spring: float = 20.0
var vine_pump: float = 26.0
var vine_latch_boost: float = 3.2
var vine_release_boost: float = 6.0
var vine_max_launch_speed: float = 34.0
var vine_max_vertical_speed: float = 24.5
var vine_winch_speed: float = 7.5
var vine_floor_friction: float = 6.0
var vine_can_snap: bool = false

var is_active: bool = false
var grapple_point: Vector3 = Vector3.ZERO
var grapple_length: float = 0.0
var grapple_time: float = 0.0
var vine_strain: float = 0.0
var vine_tension: float = 1.0
var snap_cooldown: float = 0.0
var winch_audio_timer: float = 0.0
const MAX_VINE_STRAIN: float = 1.0

func update_cooldowns(delta: float) -> void:
	if delta > 0.0: snap_cooldown = max(0.0, snap_cooldown - delta)

func try_start(space_state: PhysicsDirectSpaceState3D, origin: Vector3, dir: Vector3, exclude_rid: RID, player_pos: Vector3) -> bool:
	if not space_state or snap_cooldown > 0.0: return false
	var query = PhysicsRayQueryParameters3D.create(origin, origin + dir * vine_max_dist)
	query.exclude = [exclude_rid]
	var res = space_state.intersect_ray(query)
	if res:
		is_active = true
		grapple_point = res.position
		grapple_length = (player_pos - grapple_point).length()
		grapple_time = 0.0; vine_strain = 0.0; vine_tension = 1.0; winch_audio_timer = 0.0
		vine_latched.emit()
		return true
	return false

func apply_physics(player_pos: Vector3, vel: Vector3, wish_dir: Vector3, is_on_floor: bool, winch_held: bool, gravity: float, delta: float) -> Vector3:
	if delta <= 0.0 or not is_active: return vel
	grapple_time += delta
	var to_anchor = grapple_point - player_pos
	var dist = to_anchor.length()
	var rope_dir = to_anchor.normalized() if dist > 0.001 else Vector3.UP

	if grapple_length > 0.01:
		vine_tension = clamp(dist / grapple_length, 0.0, 1.0)
		vine_strain = clamp((dist - grapple_length) / 3.5, 0.0, 1.0) if dist > grapple_length else 0.0

	# Winch in slowly with Space
	if winch_held:
		grapple_length = max(2.5, grapple_length - vine_winch_speed * delta)
		vel += rope_dir * (8.5 * delta)
		if is_on_floor and rope_dir.y > 0.05: vel.y = max(vel.y, 4.8)
		winch_audio_timer -= delta
		if winch_audio_timer <= 0.0:
			winch_audio_timer = 0.13
			vine_winch_tick.emit()

	# Floor surface contact drag
	if is_on_floor:
		var h_speed = sqrt(vel.x * vel.x + vel.z * vel.z)
		if h_speed > 0.001:
			var surface_drag = (vine_floor_friction + h_speed * 0.10) * delta
			var scale = max(0.0, h_speed - surface_drag) / h_speed
			vel.x *= scale; vel.z *= scale

	# Elastic spring force
	if dist > grapple_length:
		var stretch = dist - grapple_length
		var spring_accel = rope_dir * (stretch * vine_spring)
		if spring_accel.y > 0.0: spring_accel.y = min(spring_accel.y, 44.0)
		if is_on_floor:
			spring_accel.x *= 0.70; spring_accel.z *= 0.70
		vel += spring_accel * delta

		var outward_speed = vel.dot(-rope_dir)
		if outward_speed > 0.0: vel += rope_dir * outward_speed * 0.94

	# High ceiling clamp during swing
	if vel.y > 27.0: vel.y = lerp(vel.y, 27.0, delta * 8.0)
	vel.y -= gravity * (1.15 if vel.y < 0.0 else 0.95) * delta

	# Tangential swing pump (WASD)
	if wish_dir.length_squared() > 0.01:
		var tangent = wish_dir - rope_dir * wish_dir.dot(rope_dir)
		if tangent.length_squared() > 0.01:
			var pump_mult = 0.55 if is_on_floor else 1.0
			vel += tangent.normalized() * (vine_pump * pump_mult * delta)

	return vel

func release(vel: Vector3, fwd_dir: Vector3, was_catapult: bool, jump_vel: float, max_fall_spd: float) -> Vector3:
	if not is_active: return vel
	is_active = false; vine_strain = 0.0; vine_tension = 1.0
	var speed = vel.length()
	var fwd_2d = Vector3(fwd_dir.x, 0.0, fwd_dir.z).normalized()

	if speed > 3.0:
		if vel.y > vine_max_vertical_speed:
			var excess_up = vel.y - vine_max_vertical_speed
			if fwd_2d.length_squared() > 0.01: vel += fwd_2d * (excess_up * 0.75)
			vel.y = vine_max_vertical_speed

		if fwd_2d.length_squared() > 0.01: vel += fwd_2d * vine_release_boost
		if was_catapult:
			vel.y = clamp(max(vel.y, jump_vel * 0.9) + 4.5, jump_vel, vine_max_vertical_speed)
		else:
			vel.y = clamp(vel.y, -max_fall_spd, vine_max_vertical_speed)

		var h_speed = sqrt(vel.x * vel.x + vel.z * vel.z)
		if h_speed > vine_max_launch_speed:
			var scale = vine_max_launch_speed / h_speed
			vel.x *= scale; vel.z *= scale
	else:
		if was_catapult:
			vel.y = jump_vel
			if fwd_2d.length_squared() > 0.01: vel += fwd_2d * (vine_release_boost * 1.5)

	vine_released.emit(was_catapult)
	return vel
