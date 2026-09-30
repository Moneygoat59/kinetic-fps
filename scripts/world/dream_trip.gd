class_name DreamTrip
extends Node
## The first night's ending: the walker's foot catches, they lurch, pitch forward and hit the ground. Emits `landed` on the
## impact (ForestNightDirector cuts to black there: the hit is the jolt awake). Animates the player's camera under Head, so
## mouse look (Head pitch) is untouched; the player is frozen from the first frame.

signal landed

enum State { IDLE, STUMBLE, FALL, DOWN }

const STUMBLE := 0.34                # seconds: the catch and lurch
const FALL := 0.4                    # seconds: going down (accelerating)
const EYE_DROP := -1.22              # camera ends ~0.2 m above the ground
const LURCH := 0.8                   # metres carried forward
const SND_SCUFF = preload("res://audio/impacts/Audio/footstep_snow_003.ogg")
const SND_CLOTH = preload("res://audio/rpg/Audio/cloth3.ogg")
const SND_HIT = preload("res://audio/impacts/Audio/impactPunch_heavy_001.ogg")
const SND_THUD = preload("res://audio/impacts/Audio/impactSoft_heavy_002.ogg")

var state := State.IDLE


func start(player: Player) -> void:
	if state != State.IDLE or player == null or player.camera == null:
		return
	state = State.STUMBLE
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.velocity = Vector3.ZERO
	var cam := player.camera
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length_squared() > 0.01 else Vector3.FORWARD
	SoundManager.play(SND_SCUFF, -2.0, 0.05)
	SoundManager.play(SND_CLOTH, -8.0, 0.05)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(cam, "rotation:x", deg_to_rad(-26.0), STUMBLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "rotation:z", deg_to_rad(8.0), STUMBLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "position:y", -0.25, STUMBLE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(player, "global_position", player.global_position + fwd * LURCH * 0.55, STUMBLE)
	tw.chain().tween_callback(_set_state.bind(State.FALL))
	tw.tween_property(player, "global_position", player.global_position + fwd * LURCH, FALL)
	tw.tween_property(cam, "position:y", EYE_DROP, FALL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(cam, "rotation:x", deg_to_rad(-78.0), FALL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(cam, "rotation:z", deg_to_rad(22.0), FALL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(_impact)


func _set_state(next: State) -> void:
	state = next


func _impact() -> void:
	if state == State.DOWN:
		return
	state = State.DOWN
	SoundManager.play(SND_HIT, 2.0, 0.03)
	SoundManager.play(SND_THUD, 0.0, 0.03)
	landed.emit()
