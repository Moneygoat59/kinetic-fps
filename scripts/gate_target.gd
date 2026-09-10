class_name GateTarget
extends StaticBody3D

const ShootGate = preload("res://scripts/shoot_gate.gd")

@export var gate_parent: Node3D
var is_active: bool = true

func take_hit(_damage: float, _normal: Vector3, _point: Vector3) -> void:
	if not is_active:
		return
	is_active = false
	
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3.ZERO, 0.18)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	if gate_parent and gate_parent.has_method("register_target_hit"):
		gate_parent.register_target_hit()
