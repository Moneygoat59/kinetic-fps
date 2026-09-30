class_name EnemyProjectile
extends Area3D

@export var speed: float = 28.0
@export var damage: float = 14.0
@export var lifetime: float = 4.0

var velocity: Vector3 = Vector3.ZERO
var age: float = 0.0

func initialize(start_pos: Vector3, dir: Vector3) -> void:
	global_position = start_pos
	velocity = dir.normalized() * speed
	look_at(global_position + dir, Vector3.UP)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	
	global_position += velocity * delta

func _on_body_entered(body: Node3D) -> void:
	if body is EnemyProjectile:
		return
	if body.has_method("take_hit"):
		body.take_hit(damage, -velocity.normalized(), global_position)
	_spawn_impact()
	queue_free()

func _on_area_entered(area: Area3D) -> void:
	if area is EnemyProjectile:
		return
	if area.has_method("take_hit"):
		area.take_hit(damage, -velocity.normalized(), global_position)
		_spawn_impact()
		queue_free()

func _spawn_impact() -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.3, 0.1)
	light.light_energy = 2.5
	light.omni_range = 3.0
	effect.add_child(light)

	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.1)
	mat.emission_energy_multiplier = 3.0
	mesh_inst.mesh = sphere
	mesh_inst.material_override = mat
	effect.add_child(mesh_inst)

	var tween = effect.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.15)
	tween.parallel().tween_property(mesh_inst, "scale", Vector3.ZERO, 0.15)
	tween.tween_callback(effect.queue_free)
