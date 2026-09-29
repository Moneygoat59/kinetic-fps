class_name PlayerCrawl
extends RefCounted
## The walker's low stance, for crawling through vent ducts (VentDuct): a short capsule, the eyes a hand's width under
## the duct roof (O73Kit.DUCT_H), slow, no jumping, sheet-metal knocks for steps. One state, STAND or CRAWL. Owned by the
## Player (player.crawl); set_stance(player, stance) swaps the capsule, head height, speed and step sounds, and puts the
## standing ones back afterwards. The head moves at once: a caller easing the camera tweens head.position.y itself.

enum Stance { STAND, CRAWL }

const CAPSULE_H := 0.8          # capsule height crawling (its standing radius stays, 0.4: fits O73Kit.DUCT_W x DUCT_H)
const EYE := 0.55               # head height over the feet crawling
const SPEED := 1.4
const STEP_L = preload("res://audio/impacts/Audio/impactPlate_light_000.ogg")
const STEP_R = preload("res://audio/impacts/Audio/impactPlate_light_002.ogg")

var stance := Stance.STAND
var _shape: CollisionShape3D
var _stand_shape: Shape3D
var _stand_shape_y := 0.9
var _stand_head_y := 1.4
var _stand_speed := 5.2
var _stand_jump := 6.8
var _stand_step_l: AudioStream
var _stand_step_r: AudioStream


## Puts `p` into `want`. False if it already is, or the player has no capsule / head.
func set_stance(p: Player, want: Stance) -> bool:
	if p == null or want == stance or p.head == null:
		return false
	if _shape == null:
		_shape = p.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _shape == null:
		return false
	stance = want
	if want == Stance.CRAWL:
		_crouch(p)
	else:
		_rise(p)
	return true


func _crouch(p: Player) -> void:
	_stand_shape = _shape.shape
	_stand_shape_y = _shape.position.y
	_stand_head_y = p.head.position.y
	_stand_speed = p.motor.ground_speed
	_stand_jump = p.motor.jump_velocity
	_stand_step_l = p.step_l
	_stand_step_r = p.step_r
	var capsule := CapsuleShape3D.new()
	var standing := _stand_shape as CapsuleShape3D
	capsule.radius = standing.radius if standing else 0.4
	capsule.height = maxf(CAPSULE_H, capsule.radius * 2.0)
	_shape.shape = capsule
	_shape.position.y = capsule.height * 0.5
	p.head.position.y = EYE
	p.motor.ground_speed = SPEED
	p.motor.jump_velocity = 0.0
	p.step_l = STEP_L
	p.step_r = STEP_R


func _rise(p: Player) -> void:
	_shape.shape = _stand_shape
	_shape.position.y = _stand_shape_y
	p.head.position.y = _stand_head_y
	p.motor.ground_speed = _stand_speed
	p.motor.jump_velocity = _stand_jump
	p.step_l = _stand_step_l
	p.step_r = _stand_step_r


## Head height standing (while crawling: the one to go back to).
func stand_eye() -> float:
	return _stand_head_y
