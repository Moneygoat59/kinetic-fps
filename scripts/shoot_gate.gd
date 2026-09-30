class_name ShootGate
extends Node3D

@export var door_node: Node3D
@export var targets_needed: int = 2

var targets_hit: int = 0
var is_open: bool = false

func register_target_hit() -> void:
	targets_hit += 1
	if targets_hit >= targets_needed and not is_open:
		open_gate()

func open_gate() -> void:
	is_open = true
	SoundManager.play_spatial(AudioBank.GATE_OPEN, global_position, 2.0)
	if door_node:
		var tween = create_tween()
		tween.tween_property(door_node, "position:y", door_node.position.y + 7.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
