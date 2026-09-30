class_name SiloLiftControls
extends RefCounted
## The freight lift's controls (SiloLift): the prompt and [E] in the cage (to the other end) and at the two call spots
## (bring it to you). Stateless; SiloLift.update calls update(lift, player position) every physics frame.

const REACH := 1.4                  # m from a call spot: prompt + [E]
const FADE := 0.5
const CLICK := preload("res://audio/ui/Audio/click_002.ogg")


static func update(lift: SiloLift, p_pos: Vector3) -> void:
	if lift.state == SiloLift.State.CRASH:
		return
	if lift.in_cage(p_pos):
		if lift.is_moving():
			InteractPrompt.offer(lift, "LIFT MOVING", "FREIGHT LIFT  //  HOLD ON", 1.0)
		elif lift.state == SiloLift.State.TOP:
			_offer(lift, 1.0, "LOWER LIFT", "GENERATOR HALL  //  %d M DOWN" % roundi(lift.drop), SiloLift.State.DOWN)
		else:
			_offer(lift, 1.0, "RAISE LIFT", "LAUNCH CONTROL  //  LEVEL 09", SiloLift.State.UP)
		return
	_call(lift, p_pos, lift.call_top, SiloLift.State.BOTTOM, SiloLift.State.UP, "LIFT  //  AT GENERATOR HALL")
	_call(lift, p_pos, lift.call_bottom, SiloLift.State.TOP, SiloLift.State.DOWN, "LIFT  //  AT LEVEL 09")


static func _call(lift: SiloLift, p_pos: Vector3, spot: Node3D, away: SiloLift.State, trip: SiloLift.State, sub: String) -> void:
	if spot == null:
		return
	var at := spot.global_position
	var dist := Vector2(p_pos.x - at.x, p_pos.z - at.z).length()
	if dist > REACH or absf(p_pos.y - at.y) > 2.0:
		return
	if lift.state == away:
		_offer(lift, (REACH - dist) / FADE, "CALL LIFT", sub, trip)
	elif lift.is_moving():
		InteractPrompt.offer(lift, "LIFT MOVING", "FREIGHT LIFT  //  ON ITS WAY", (REACH - dist) / FADE)


static func _offer(lift: SiloLift, strength: float, title: String, sub: String, trip: SiloLift.State) -> void:
	InteractPrompt.offer(lift, title, sub, strength)
	if Input.is_action_just_pressed("interact"):
		SoundManager.play(CLICK, -6.0, 0.02)
		lift.depart(trip)
