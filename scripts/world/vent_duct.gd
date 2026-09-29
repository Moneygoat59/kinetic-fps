class_name VentDuct
extends Area3D
## The open mouth of a vent duct the walker can climb into (kit duct_mouth, O73Kit.DUCTS). The walker's aim finds it
## (get_interaction_prompt / interact, an Area3D so it never blocks the way): from the room, close up, CLIMB INTO DUCT;
## from inside, CLIMB OUT. Climbing in eases them up through the mouth onto the duct floor at the piece's marker_crawl,
## facing in, and puts them in the crawl stance (Player.crawl, PlayerCrawl); climbing out eases them back down onto the
## floor in front of the mouth, facing the room, and stands them up. One FSM: OUTSIDE, CLIMBING_IN, INSIDE, CLIMBING_OUT.
## mount(piece) on any duct_mouth piece (the silo's: SiloPit). Emits climbed(inside, player) once each climb has finished
## (DuctSound listens).

signal climbed(inside: bool, player: Player)

enum State { OUTSIDE, CLIMBING_IN, INSIDE, CLIMBING_OUT }

const GROUP := &"vent_duct"
const CLIMB_TIME := 1.2
const REACH := 2.2              # metres from the camera to the mouth: close enough to climb in (the aim ray reaches 4.2)
const OUT_REACH := 0.9          # metres in front of the mouth the walker stands after climbing out
const FLOOR_PROBE := 3.0        # metres down from the mouth to look for that floor
const TITLE_IN := "CLIMB INTO DUCT"
const TITLE_OUT := "CLIMB OUT"
const SUB_IN := "VENT DUCT  //  GRILLE OFF"
const SUB_OUT := "VENT DUCT  //  MOUTH"
const SND_KNOCK = preload("res://audio/impacts/Audio/impactPlate_medium_001.ogg")
const SND_CLOTH = preload("res://audio/rpg/Audio/cloth2.ogg")

var state := State.OUTSIDE
var _crawl_at: Node3D


## Adds the climb point to a duct_mouth piece (front +Z into the room, stub into the wall along -Z). Null without its
## marker_crawl.
static func mount(piece: Node3D) -> VentDuct:
	var at := piece.get_node_or_null("marker_crawl") as Node3D if piece else null
	if at == null:
		push_warning("VentDuct: no marker_crawl under %s" % (String(piece.name) if piece else "null"))
		return null
	var duct := VentDuct.new()
	duct.name = "VentDuct"
	duct._crawl_at = at
	duct.monitoring = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(O73Kit.DUCT_W, O73Kit.DUCT_H, 0.3)
	shape.shape = box
	shape.position = Vector3(0.0, O73Kit.DUCT_H * 0.5, -0.15)     # filling the opening, just inside the wall face
	duct.add_child(shape)
	piece.add_child(duct)
	duct.add_to_group(GROUP)
	return duct


func can_interact() -> bool:
	if state == State.INSIDE:
		return true
	if state != State.OUTSIDE:
		return false
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(global_position) < REACH


func get_interaction_prompt() -> String:
	return TITLE_OUT if state == State.INSIDE else TITLE_IN


func get_interaction_detail() -> String:
	return SUB_OUT if state == State.INSIDE else SUB_IN


func interact(p: Node) -> void:
	var player := p as Player
	if player == null or player.head == null or not can_interact():
		return
	if state == State.OUTSIDE:
		_climb(player, State.CLIMBING_IN, _crawl_at.global_position + Vector3.UP * 0.02, -global_basis.z)
	else:
		_climb(player, State.CLIMBING_OUT, _floor_in_front(), global_basis.z)


## The floor in front of the mouth (a ray down from OUT_REACH out); the mouth's own height if nothing is there.
func _floor_in_front() -> Vector3:
	var out := global_position + global_basis.z * OUT_REACH + Vector3.UP * 0.3
	var query := PhysicsRayQueryParameters3D.create(out, out + Vector3.DOWN * FLOOR_PROBE)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return (hit["position"] as Vector3) + Vector3.UP * 0.02 if hit else out


func _climb(player: Player, s: State, to: Vector3, facing: Vector3) -> void:
	state = s
	var inside := s == State.CLIMBING_IN
	var eye_from := player.head.position.y
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.crawl.set_stance(player, PlayerCrawl.Stance.CRAWL if inside else PlayerCrawl.Stance.STAND)
	var eye_to := player.head.position.y
	player.head.position.y = eye_from
	var yaw := player.rotation.y + wrapf(atan2(-facing.x, -facing.z) - player.rotation.y, -PI, PI)
	SoundManager.play(SND_CLOTH, -8.0, 0.05)
	SoundManager.play(SND_KNOCK, -10.0, 0.05)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(player, "global_position", to, CLIMB_TIME)
	tw.tween_property(player, "rotation:y", yaw, CLIMB_TIME * 0.6)
	tw.tween_property(player.head, "position:y", eye_to, CLIMB_TIME)
	tw.tween_property(player.head, "rotation:x", 0.0, CLIMB_TIME * 0.6)
	tw.chain().tween_callback(_settle.bind(player, State.INSIDE if inside else State.OUTSIDE))


func _settle(player: Player, s: State) -> void:
	state = s
	if not is_instance_valid(player):
		return
	if player.input_ctrl:
		player.input_ctrl.head_pitch = player.head.rotation.x      # mouse look carries on from here, no snap
	player.set_physics_process(true)
	climbed.emit(s == State.INSIDE, player)
