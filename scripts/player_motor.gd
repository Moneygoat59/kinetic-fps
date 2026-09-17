class_name PlayerMotor
extends RefCounted

var ground_speed: float = 14.0
var ground_accel: float = 14.0
var ground_decel: float = 9.0
var air_accel: float = 24.0
var air_control: float = 5.0
var air_brake: float = 18.0
var air_max_speed: float = 13.0
var jump_velocity: float = 8.5
var gravity: float = 24.0
var fall_gravity_mult: float = 1.25
var max_fall_speed: float = 45.0

var slide_friction: float = 0.6
var slide_boost: float = 6.0
var dash_speed: float = 26.0

func apply_gravity(vel: Vector3, delta: float) -> Vector3:
	if delta <= 0.0:
		return vel
	var mult = fall_gravity_mult if vel.y < 0.0 else 1.0
	vel.y = max(-max_fall_speed, vel.y - gravity * mult * delta)
	return vel

func apply_ground_physics(vel: Vector3, wish_dir: Vector3, delta: float) -> Vector3:
	if delta <= 0.0:
		return vel
	var hx = vel.x
	var hz = vel.z
	var speed = sqrt(hx * hx + hz * hz)

	if speed > 0.001:
		var drop = speed * ground_decel * delta
		var new_speed = max(0.0, speed - drop)
		var scale = new_speed / speed
		hx *= scale
		hz *= scale
	else:
		hx = 0.0
		hz = 0.0

	if wish_dir.length_squared() > 0.01:
		var target_x = wish_dir.x * ground_speed
		var target_z = wish_dir.z * ground_speed
		var step = ground_accel * ground_speed * delta
		hx = move_toward(hx, target_x, step)
		hz = move_toward(hz, target_z, step)

	vel.x = hx
	vel.z = hz
	return vel

func apply_air_physics(vel: Vector3, wish_dir: Vector3, delta: float) -> Vector3:
	if delta <= 0.0:
		return vel
	var hx = vel.x
	var hz = vel.z
	var speed = sqrt(hx * hx + hz * hz)

	if wish_dir.length_squared() > 0.01:
		var wx = wish_dir.x
		var wz = wish_dir.z
		if speed > 0.5:
			var cur_dx = hx / speed
			var cur_dz = hz / speed
			var dot_prod = cur_dx * wx + cur_dz * wz

			# Air steering
			var steer = clamp(air_control * delta, 0.0, 1.0)
			var nx = cur_dx + wx * steer * 2.2
			var nz = cur_dz + wz * steer * 2.2
			var nlen = sqrt(nx * nx + nz * nz)
			if nlen > 0.001:
				hx = (nx / nlen) * speed
				hz = (nz / nlen) * speed

			# Air braking when backpedaling
			if dot_prod < -0.15:
				var brake = -dot_prod * air_brake * delta
				speed = max(0.0, speed - brake)
				hx = (nx / max(0.001, nlen)) * speed
				hz = (nz / max(0.001, nlen)) * speed

			if speed < air_max_speed:
				hx = move_toward(hx, wx * air_max_speed, air_accel * delta)
				hz = move_toward(hz, wz * air_max_speed, air_accel * delta)
		else:
			hx = move_toward(hx, wx * air_max_speed, air_accel * delta)
			hz = move_toward(hz, wz * air_max_speed, air_accel * delta)

	# Aerodynamic drag taper above 26 m/s
	speed = sqrt(hx * hx + hz * hz)
	var drag_threshold = 26.0
	if speed > drag_threshold:
		var overspeed = speed - drag_threshold
		var drag = (1.6 + overspeed * 0.14) * delta
		var new_spd = max(drag_threshold, speed - overspeed * drag)
		if speed > 0.001:
			var scale = new_spd / speed
			hx *= scale
			hz *= scale

	vel.x = hx
	vel.z = hz
	return vel

func start_slide(vel: Vector3, fwd_dir: Vector3) -> Vector3:
	var h_dir = Vector3(vel.x, 0.0, vel.z).normalized()
	if h_dir.length_squared() < 0.01:
		h_dir = fwd_dir
	vel.x += h_dir.x * slide_boost
	vel.z += h_dir.z * slide_boost
	return vel

func apply_slide_physics(vel: Vector3, floor_norm: Vector3, delta: float) -> Vector3:
	if delta <= 0.0:
		return vel
	var slope_fwd = (Vector3.DOWN - floor_norm * Vector3.DOWN.dot(floor_norm)).normalized()
	if floor_norm.dot(Vector3.UP) < 0.98:
		vel += slope_fwd * (gravity * 1.5 * delta)
	else:
		var hx = vel.x
		var hz = vel.z
		var spd = sqrt(hx * hx + hz * hz)
		if spd > 0.001:
			var new_spd = max(0.0, spd - spd * slide_friction * delta)
			vel.x = hx * (new_spd / spd)
			vel.z = hz * (new_spd / spd)
	return vel

func execute_dash(vel: Vector3, wish_dir: Vector3, fwd_dir: Vector3) -> Vector3:
	var d_dir = wish_dir if wish_dir.length_squared() > 0.01 else fwd_dir
	return Vector3(d_dir.x * dash_speed, max(vel.y, 2.5), d_dir.z * dash_speed)
