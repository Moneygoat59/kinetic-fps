class_name DroneEnemy
extends CharacterBody3D

signal enemy_died(enemy: DroneEnemy)

const ProjectileScene = preload("res://scenes/props/enemy_projectile.tscn")

enum State { PATROL, CHASE, ATTACK, DEAD }

@export var max_health: float = 60.0
@export var move_speed: float = 9.5
@export var detection_range: float = 38.0
@export var attack_range: float = 24.0
@export var fire_cooldown: float = 1.9

var current_health: float = 60.0
var state: State = State.PATROL
var target_player: Player = null
var spawn_pos: Vector3 = Vector3.ZERO
var patrol_time: float = 0.0
var strafe_dir: float = 1.0
var strafe_timer: float = 0.0
var fire_timer: float = 1.0
var sfx_player: AudioStreamPlayer

@onready var eye_light: OmniLight3D = $Core/EyeLight
@onready var core_mesh: MeshInstance3D = $Core
@onready var eye_mesh: MeshInstance3D = $Core/EyeMesh

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	current_health = max_health
	strafe_dir = 1.0 if randf() > 0.5 else -1.0
	fire_timer = randf_range(1.0, 2.0)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	_init_retro_visuals()
	_find_player()

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0] as Player
	else:
		for node in get_tree().root.get_children():
			var p = _search_for_player(node)
			if p:
				target_player = p
				break

func _search_for_player(node: Node) -> Player:
	if node is Player:
		return node
	for c in node.get_children():
		var res = _search_for_player(c)
		if res:
			return res
	return null

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if not target_player or not is_instance_valid(target_player):
		_find_player()
		if not target_player:
			return

	patrol_time += delta
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_dir = -strafe_dir
		strafe_timer = randf_range(1.8, 3.2)

	var to_player = target_player.global_position - global_position
	var dist_to_player = to_player.length()
	var has_los = _check_line_of_sight()

	# State transitions
	if dist_to_player < detection_range and has_los:
		if dist_to_player <= attack_range:
			state = State.ATTACK
		else:
			state = State.CHASE
	else:
		state = State.PATROL

	# Aim towards player
	if state != State.PATROL:
		var look_target = target_player.global_position + Vector3(0, 1.0, 0)
		var target_basis = Basis.looking_at(look_target - global_position, Vector3.UP)
		transform.basis = transform.basis.slerp(target_basis, delta * 6.0)

	# Movement execution
	match state:
		State.PATROL:
			var bob = sin(patrol_time * 2.2) * 0.45
			var patrol_target = spawn_pos + Vector3(sin(patrol_time * 0.5) * 3.0, bob, cos(patrol_time * 0.5) * 3.0)
			var move_dir = (patrol_target - global_position)
			if move_dir.length() > 0.2:
				velocity = velocity.move_toward(move_dir.normalized() * (move_speed * 0.4), delta * 14.0)
			else:
				velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0)

		State.CHASE:
			var desired_alt = target_player.global_position.y + 4.0
			var target_pos = target_player.global_position + (-to_player.normalized() * 14.0)
			target_pos.y = desired_alt
			var move_dir = (target_pos - global_position).normalized()
			velocity = velocity.move_toward(move_dir * move_speed, delta * 16.0)

		State.ATTACK:
			var desired_alt = target_player.global_position.y + 3.8
			var horiz_dist = Vector2(to_player.x, to_player.z).length()
			var desired_dist = 14.0
			
			var forward_comp = Vector3.ZERO
			if horiz_dist > desired_dist + 2.0:
				forward_comp = to_player.normalized() * (move_speed * 0.6)
			elif horiz_dist < desired_dist - 2.0:
				forward_comp = -to_player.normalized() * (move_speed * 0.7)
			
			var lateral_dir = to_player.cross(Vector3.UP).normalized() * strafe_dir
			var strafe_comp = lateral_dir * (move_speed * 0.8)
			var vert_comp = Vector3(0, (desired_alt - global_position.y) * 2.0, 0)
			
			var desired_vel = forward_comp + strafe_comp + vert_comp
			velocity = velocity.move_toward(desired_vel, delta * 18.0)
			
			_handle_shooting(delta)

	move_and_slide()

func _check_line_of_sight() -> bool:
	if not target_player:
		return false
	var space = get_world_3d().direct_space_state
	var from = global_position
	var to = target_player.global_position + Vector3(0, 1.2, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var res = space.intersect_ray(query)
	if res:
		return res.collider == target_player or res.collider.has_method("take_hit")
	return true

func _handle_shooting(delta: float) -> void:
	fire_timer -= delta
	
	# Visual/Audio Tell before firing
	if fire_timer <= 0.35 and fire_timer > 0.0:
		if eye_light:
			eye_light.light_energy = lerp(eye_light.light_energy, 6.0, delta * 14.0)
			eye_light.light_color = Color(1.0, 0.9, 0.2)
	else:
		if eye_light:
			eye_light.light_energy = lerp(eye_light.light_energy, 2.0, delta * 8.0)
			eye_light.light_color = Color(1.0, 0.2, 0.1)

	if fire_timer <= 0.0:
		_shoot_projectile()
		fire_timer = fire_cooldown + randf_range(-0.25, 0.25)

func _shoot_projectile() -> void:
	if not target_player:
		return
	
	SoundManager.play_spatial(AudioBank.ENEMY_ATTACK, global_position)
	
	var proj = ProjectileScene.instantiate()
	get_parent().add_child(proj)
	
	var muzzle_pos = global_position + (-transform.basis.z * 0.9)
	var lead_offset = target_player.velocity * 0.35
	var target_point = (target_player.global_position + Vector3(0, 1.0, 0) + lead_offset)
	var shoot_dir = (target_point - muzzle_pos).normalized()
	
	proj.initialize(muzzle_pos, shoot_dir)
	
	# Slight recoil push
	velocity += transform.basis.z * 3.0

func take_hit(damage: float, normal: Vector3 = Vector3.ZERO, _point: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	
	current_health -= damage
	velocity += -normal * (damage * 0.25)
	
	# Hit flash
	if core_mesh:
		var mat = core_mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var orig = mat.albedo_color
			mat.albedo_color = Color(1.0, 1.0, 1.0)
			get_tree().create_timer(0.08).timeout.connect(func(): if mat: mat.albedo_color = orig)
	
	SoundManager.play_spatial(AudioBank.ENEMY_HURT, global_position)
	
	# Aggro immediately onto player
	state = State.ATTACK
	
	if current_health <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	enemy_died.emit(self)
	SoundManager.play_spatial(AudioBank.ENEMY_DESTROY, global_position, 2.0)
	
	# Spawn wreckage explosion
	_spawn_death_effects()
	queue_free()

func _spawn_death_effects() -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = global_position
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.4, 0.1)
	light.light_energy = 4.0
	light.omni_range = 6.0
	effect.add_child(light)

	# Debris pieces
	for i in range(4):
		var piece = RigidBody3D.new()
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.2, 0.15, 0.3)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.25, 0.28)
		mat.metallic = 0.8
		mesh_inst.mesh = box
		mesh_inst.material_override = mat
		piece.add_child(mesh_inst)
		
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		piece.add_child(col)
		
		effect.add_child(piece)
		piece.global_position = global_position + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
		piece.apply_impulse(Vector3(randf_range(-5, 5), randf_range(3, 8), randf_range(-5, 5)))

	var tween = effect.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.35)
	tween.tween_interval(2.5)
	tween.tween_callback(effect.queue_free)

func _init_retro_visuals() -> void:
	var model_shader = load("res://shaders/ps1_triplanar_model.gdshader") as Shader
	var metal_tex: Texture2D = _load_texture("res://textures/gun_metal_scratched.png")
	if model_shader and metal_tex:
		var drone_mat = ShaderMaterial.new()
		drone_mat.shader = model_shader
		drone_mat.set_shader_parameter("albedo_texture", metal_tex)
		drone_mat.set_shader_parameter("uv_scale", Vector3(3.0, 3.0, 3.0))
		drone_mat.set_shader_parameter("jitter_resolution", 160.0)
		drone_mat.set_shader_parameter("metallic", 0.3)
		drone_mat.set_shader_parameter("roughness", 0.8)
		drone_mat.set_shader_parameter("tint_color", Color(0.7, 0.75, 0.8, 1.0))
		if core_mesh:
			core_mesh.material_override = drone_mat
		var wing_l = get_node_or_null("Core/WingL") as MeshInstance3D
		if wing_l: wing_l.material_override = drone_mat
		var wing_r = get_node_or_null("Core/WingR") as MeshInstance3D
		if wing_r: wing_r.material_override = drone_mat
		var cannon = get_node_or_null("Core/Cannon") as MeshInstance3D
		if cannon: cannon.material_override = drone_mat

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null
