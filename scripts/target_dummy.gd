class_name TargetDummy
extends RigidBody3D

@export var max_health: float = 100.0
var current_health: float = 100.0
var initial_pos: Vector3
var initial_rot: Vector3
var mesh: MeshInstance3D

func _ready():
	initial_pos = global_position
	initial_rot = global_rotation
	mesh = get_node_or_null("MeshInstance3D")

func take_hit(damage: float, normal: Vector3, point: Vector3) -> void:
	current_health -= damage
	apply_impulse(-normal * (damage * 0.4), point - global_position)
	
	# Flash material
	if mesh:
		var mat = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var orig_color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.2, 0.2)
			get_tree().create_timer(0.08).timeout.connect(func(): mat.albedo_color = orig_color)

	if current_health <= 0.0:
		_die()

func _die() -> void:
	# Dramatic launch upwards and reset after 2.5s
	apply_impulse(Vector3.UP * 15.0 + Vector3(randf_range(-5,5), 0, randf_range(-5,5)))
	await get_tree().create_timer(2.5).timeout
	global_position = initial_pos
	global_rotation = initial_rot
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	current_health = max_health
