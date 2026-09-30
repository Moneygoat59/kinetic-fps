class_name MechEnemy
extends CharacterBody3D

signal enemy_died(enemy: MechEnemy)

const ProjectileScene = preload("res://scenes/props/enemy_projectile.tscn")

enum State { PATROL, CHASE, BURST_FIRE, STOMP, DEAD }

@export var max_health: float = 120.0
@export var move_speed: float = 6.5
@export var detection_range: float = 34.0
@export var attack_range: float = 22.0
@export var burst_interval: float = 2.6
@export var gravity: float = 24.0

var current_health: float = 120.0
var state: State = State.PATROL
var target_player: Player = null
var spawn_pos: Vector3 = Vector3.ZERO
var patrol_dir: Vector3 = Vector3.FORWARD
var patrol_timer: float = 3.0
var burst_cooldown_timer: float = 1.5
var is_firing_burst: bool = false
var stomp_timer: float = 0.0
var walk_cycle: float = 0.0
var sfx_player: AudioStreamPlayer

@onready var visor_light: OmniLight3D = $Torso/VisorLight
@onready var muzzle_flash: OmniLight3D = $Torso/ShoulderCannon/MuzzleLight
@onready var torso_mesh: MeshInstance3D = $Torso
@onready var cannon_node: Node3D = $Torso/ShoulderCannon

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	current_health = max_health
	patrol_dir = transform.basis.z.normalized()
	burst_cooldown_timer = randf_range(1.0, 2.2)
	
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

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	if not target_player or not is_instance_valid(target_player):
		_find_player()
		if not target_player:
			move_and_slide()
			return

	burst_cooldown_timer -= delta
	stomp_timer -= delta

	var to_player = target_player.global_position - global_position
	var dist_horiz = Vector2(to_player.x, to_player.z).length()
	var has_los = _check_line_of_sight()

	# State selection
	if not is_firing_burst and state != State.STOMP:
		if dist_horiz < 4.8 and stomp_timer <= 0.0:
			_start_stomp()
		elif dist_horiz < detection_range and has_los:
			if dist_horiz <= attack_range and burst_cooldown_timer <= 0.0:
				_start_burst_fire()
			else:
				state = State.CHASE
		else:
			state = State.PATROL

	# Handle movement & orientation based on state
	match state:
		State.PATROL:
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				patrol_dir = -patrol_dir
				patrol_timer = randf_range(3.0, 5.5)

			var look_target = global_position + patrol_dir
			_smooth_turn_y(look_target, delta * 4.0)

			velocity.x = patrol_dir.x * (move_speed * 0.45)
			velocity.z = patrol_dir.z * (move_speed * 0.45)
			_animate_walk(delta, 0.45)

		State.CHASE:
			_smooth_turn_y(target_player.global_position, delta * 7.0)
			
			var move_dir = Vector3(to_player.x, 0, to_player.z).normalized()
			if dist_horiz > 5.5:
				velocity.x = move_dir.x * move_speed
				velocity.z = move_dir.z * move_speed
				_animate_walk(delta, 1.0)
			else:
				velocity.x = move_toward(velocity.x, 0.0, delta * 15.0)
				velocity.z = move_toward(velocity.z, 0.0, delta * 15.0)

		State.BURST_FIRE:
			_smooth_turn_y(target_player.global_position, delta * 9.0)
			velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)

		State.STOMP:
			velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)

	move_and_slide()

func _smooth_turn_y(target_pos: Vector3, turn_rate: float) -> void:
	var dir = Vector3(target_pos.x - global_position.x, 0, target_pos.z - global_position.z)
	if dir.length_squared() > 0.01:
		var target_basis = Basis.looking_at(dir, Vector3.UP)
		transform.basis = transform.basis.slerp(target_basis, turn_rate)

func _animate_walk(delta: float, speed_mult: float) -> void:
	walk_cycle += delta * 6.5 * speed_mult
	torso_mesh.position.y = 1.3 + sin(walk_cycle * 2.0) * 0.06
	torso_mesh.rotation.z = sin(walk_cycle) * deg_to_rad(2.5)

func _check_line_of_sight() -> bool:
	if not target_player:
		return false
	var space = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1.8, 0)
	var to = target_player.global_position + Vector3(0, 1.2, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var res = space.intersect_ray(query)
	if res:
		return res.collider == target_player or res.collider.has_method("take_hit")
	return true

func _start_burst_fire() -> void:
	state = State.BURST_FIRE
	is_firing_burst = true
	burst_cooldown_timer = burst_interval + randf_range(-0.3, 0.4)
	
	# Pre-fire charge whine
	SoundManager.play_spatial(AudioBank.VINE_LATCH, global_position)
	await get_tree().create_timer(0.24).timeout
	
	if state == State.DEAD:
		return

	# Fire 3 round burst
	for i in range(3):
		if state == State.DEAD:
			return
		_fire_single_shot()
		await get_tree().create_timer(0.18).timeout

	is_firing_burst = false
	if state != State.DEAD:
		state = State.CHASE

func _fire_single_shot() -> void:
	if not target_player:
		return
	
	SoundManager.play_spatial(AudioBank.MECH_FIRE, global_position, 1.0)
	
	if muzzle_flash:
		muzzle_flash.visible = true
		get_tree().create_timer(0.05).timeout.connect(func(): if muzzle_flash: muzzle_flash.visible = false)

	var proj = ProjectileScene.instantiate()
	get_parent().add_child(proj)
	
	var muzzle_pos = cannon_node.global_position + (-cannon_node.global_transform.basis.z * 1.1)
	var lead_offset = target_player.velocity * 0.3
	var spread = Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.4), randf_range(-0.4, 0.4))
	var aim_target = target_player.global_position + Vector3(0, 0.9, 0) + lead_offset + spread
	var shoot_dir = (aim_target - muzzle_pos).normalized()
	
	proj.initialize(muzzle_pos, shoot_dir)

func _start_stomp() -> void:
	state = State.STOMP
	stomp_timer = 4.0
	
	# Mech rears back
	var tween = create_tween()
	tween.tween_property(torso_mesh, "position:y", 1.7, 0.25)
	SoundManager.play_spatial(AudioBank.VINE_CATAPULT, global_position, 0.0)
	
	await tween.finished
	if state == State.DEAD:
		return

	# Slam down!
	torso_mesh.position.y = 1.2
	SoundManager.play_spatial(AudioBank.MECH_STOMP, global_position, 4.0)
	_spawn_shockwave()
	
	# Knock player back if close
	if target_player:
		var to_p = target_player.global_position - global_position
		if to_p.length() < 6.5:
			var knock_dir = to_p.normalized()
			knock_dir.y = 0.9
			knock_dir = knock_dir.normalized()
			target_player.velocity += knock_dir * 20.0
			target_player.take_hit(24.0, -knock_dir, global_position)
	
	await get_tree().create_timer(0.3).timeout
	if state != State.DEAD:
		state = State.CHASE

func _spawn_shockwave() -> void:
	var ring = Node3D.new()
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector3(0, 0.1, 0)
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.25, 0.1)
	light.light_energy = 5.0
	light.omni_range = 8.0
	ring.add_child(light)

	var mesh_inst = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 0.15
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.2, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 3.0
	mesh_inst.mesh = cylinder
	mesh_inst.material_override = mat
	ring.add_child(mesh_inst)

	var tw = ring.create_tween()
	tw.tween_property(mesh_inst, "scale", Vector3(12.0, 1.0, 12.0), 0.3)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.3)
	tw.tween_callback(ring.queue_free)

func take_hit(damage: float, normal: Vector3 = Vector3.ZERO, _point: Vector3 = Vector3.ZERO) -> void:
	if state == State.DEAD:
		return
	
	current_health -= damage
	velocity += -normal * (damage * 0.18)
	
	# Armor flash
	if torso_mesh:
		var mat = torso_mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			var orig = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.9, 0.4)
			get_tree().create_timer(0.08).timeout.connect(func(): if mat: mat.albedo_color = orig)
	
	SoundManager.play_spatial(AudioBank.ENEMY_HURT, global_position, 1.0)
	
	if state == State.PATROL:
		state = State.CHASE

	if current_health <= 0.0:
		_die()

func _die() -> void:
	state = State.DEAD
	enemy_died.emit(self)
	SoundManager.play_spatial(AudioBank.EXPLOSION, global_position, 5.0)
	
	# Dramatic explosion and mech destruction
	_spawn_mech_death_explosion()
	queue_free()

func _spawn_mech_death_explosion() -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = global_position + Vector3(0, 1.2, 0)
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.5, 0.1)
	light.light_energy = 6.0
	light.omni_range = 10.0
	effect.add_child(light)

	for i in range(6):
		var piece = RigidBody3D.new()
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(randf_range(0.3, 0.6), randf_range(0.3, 0.6), randf_range(0.3, 0.6))
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.22, 0.25)
		mat.metallic = 0.9
		mat.roughness = 0.4
		mesh_inst.mesh = box
		mesh_inst.material_override = mat
		piece.add_child(mesh_inst)
		
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		piece.add_child(col)
		
		effect.add_child(piece)
		piece.global_position = effect.global_position + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		piece.apply_impulse(Vector3(randf_range(-8, 8), randf_range(6, 14), randf_range(-8, 8)))

	var tw = effect.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.4)
	tw.tween_interval(3.0)
	tw.tween_callback(effect.queue_free)

func _init_retro_visuals() -> void:
	var model_shader = load("res://shaders/ps1_triplanar_model.gdshader") as Shader
	var wall_tex: Texture2D = _load_texture("res://textures/alien_blast_wall.png")
	var metal_tex: Texture2D = _load_texture("res://textures/gun_metal_scratched.png")
	if model_shader and wall_tex:
		var torso_mat = ShaderMaterial.new()
		torso_mat.shader = model_shader
		torso_mat.set_shader_parameter("albedo_texture", wall_tex)
		torso_mat.set_shader_parameter("uv_scale", Vector3(2.5, 2.5, 2.5))
		torso_mat.set_shader_parameter("jitter_resolution", 160.0)
		torso_mat.set_shader_parameter("metallic", 0.4)
		torso_mat.set_shader_parameter("roughness", 0.8)
		if torso_mesh:
			torso_mesh.material_override = torso_mat
			
		var limb_mat = ShaderMaterial.new()
		limb_mat.shader = model_shader
		limb_mat.set_shader_parameter("albedo_texture", metal_tex)
		limb_mat.set_shader_parameter("uv_scale", Vector3(3.0, 3.0, 3.0))
		limb_mat.set_shader_parameter("jitter_resolution", 160.0)
		
		var leg_l = get_node_or_null("LegL") as MeshInstance3D
		if leg_l: leg_l.material_override = limb_mat
		var leg_r = get_node_or_null("LegR") as MeshInstance3D
		if leg_r: leg_r.material_override = limb_mat
		var cannon = get_node_or_null("Torso/ShoulderCannon") as MeshInstance3D
		if cannon: cannon.material_override = limb_mat

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

