class_name PlayerLocomotion
extends RefCounted

static func update_state(current_state: int, is_on_floor: bool, is_grappling: bool, slide_held: bool, vel: Vector3, fwd_dir: Vector3, motor: PlayerMotor) -> int:
	if is_grappling:
		return PlayerState.State.GRAPPLE
	if is_on_floor:
		if slide_held and Vector2(vel.x, vel.z).length_squared() > 1.0:
			if current_state != PlayerState.State.SLIDE:
				motor.start_slide(vel, fwd_dir)
				SoundManager.play(AudioBank.SLIDE, -1.0, 0.05)
			return PlayerState.State.SLIDE
		return PlayerState.State.GROUND
	return PlayerState.State.AIR

static func step_movement(state: int, vel: Vector3, input: PlayerInput, motor: PlayerMotor, vine: PlayerVine, floor_normal: Vector3, fwd_dir: Vector3, cam_fwd: Vector3, player_pos: Vector3, is_on_floor: bool, delta: float) -> Vector3:
	match state:
		PlayerState.State.GROUND:
			if input.consume_jump():
				vel.y = motor.jump_velocity
				SoundManager.play(AudioBank.JUMP, -1.0, 0.04)
			elif input.consume_dash():
				vel = motor.execute_dash(vel, input.wish_dir, fwd_dir)
				SoundManager.play(AudioBank.DASH, 1.0, 0.05)
			else:
				vel = motor.apply_ground_physics(vel, input.wish_dir, delta)
				vel = motor.apply_gravity(vel, delta)
		PlayerState.State.AIR:
			if input.consume_dash():
				vel = motor.execute_dash(vel, input.wish_dir, fwd_dir)
				SoundManager.play(AudioBank.DASH, 1.0, 0.05)
			else:
				vel = motor.apply_air_physics(vel, input.wish_dir, delta)
				vel = motor.apply_gravity(vel, delta)
		PlayerState.State.SLIDE:
			vel = motor.apply_slide_physics(vel, floor_normal, delta)
			vel = motor.apply_gravity(vel, delta)
			if input.consume_jump():
				vel.y = motor.jump_velocity
				SoundManager.play(AudioBank.JUMP, -1.0, 0.04)
		PlayerState.State.GRAPPLE:
			if input.catapult_requested:
				vel = vine.release(vel, cam_fwd, true, motor.jump_velocity, motor.max_fall_speed)
				SoundManager.play(AudioBank.VINE_CATAPULT, 2.0, 0.05)
			else:
				vel = vine.apply_physics(player_pos, vel, input.wish_dir, is_on_floor, input.winch_held, motor.gravity, delta)
	return vel
