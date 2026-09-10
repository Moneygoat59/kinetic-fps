class_name GrenadeProjectile
extends RigidBody3D

@export var blast_radius: float = 8.5
@export var blast_damage: float = 120.0
@export var blast_impulse: float = 24.0

var remaining_fuse: float = 3.5
var has_exploded: bool = false
var spark_light: OmniLight3D

var last_clank_time: float = 0.0

func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	spark_light = get_node_or_null("SparkLight")
	body_entered.connect(_on_bounce)

func initialize(fuse_time: float, throw_vel: Vector3) -> void:
	remaining_fuse = max(0.1, fuse_time)
	linear_velocity = throw_vel
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(12, 20))

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	remaining_fuse -= delta
	
	# Spark flicker
	if spark_light:
		spark_light.visible = fmod(remaining_fuse * 12.0, 1.0) > 0.4
	
	if remaining_fuse <= 0.0:
		explode()

func _on_bounce(_body: Node) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_clank_time > 0.12 and linear_velocity.length() > 1.2:
		last_clank_time = now
		_play_clank()

func explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	var blast_pos = global_position
	_spawn_blast_effects(blast_pos)
	_apply_blast_forces(blast_pos)
	
	queue_free()

func _apply_blast_forces(blast_pos: Vector3) -> void:
	var space = get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = blast_radius
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), blast_pos)
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	var results = space.intersect_shape(query, 32)
	for r in results:
		var col = r.collider
		if not col or col == self:
			continue
		
		var to_target = col.global_position - blast_pos
		var dist = max(0.2, to_target.length())
		if dist > blast_radius:
			continue
		
		var blast_dir = (to_target / dist).normalized()
		# Upward bias for cinematic launches
		blast_dir.y = max(blast_dir.y + 0.45, 0.4)
		blast_dir = blast_dir.normalized()
		var falloff = 1.0 - (dist / blast_radius)
		var force = blast_impulse * falloff
		
		# Deal damage
		if col.has_method("take_hit"):
			col.take_hit(blast_damage * falloff, -blast_dir, blast_pos)
		
		# Physics push
		if col is RigidBody3D:
			col.apply_impulse(blast_dir * force * 1.5, to_target * 0.2)
		elif col is CharacterBody3D:
			# Player rocket jump / explosion boost!
			col.velocity += blast_dir * (force * 1.6)

func _spawn_blast_effects(pos: Vector3) -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = pos
	
	# Blast flash light
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.2)
	light.light_energy = 8.0
	light.omni_range = 14.0
	effect.add_child(light)
	
	# Expanding fireball shockwave mesh
	var sphere_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.4, 0.1)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_inst.material_override = mat
	effect.add_child(sphere_inst)
	
	# Sound
	var sfx = AudioStreamPlayer3D.new()
	sfx.position = Vector3.ZERO
	effect.add_child(sfx)
	_play_synth_boom(sfx)
	
	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sphere_inst, "scale", Vector3(blast_radius, blast_radius, blast_radius) * 1.2, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_property(light, "light_energy", 0.0, 0.4)
	tween.chain().tween_callback(effect.queue_free)

func _play_synth_boom(player: AudioStreamPlayer3D) -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.65
	player.stream = gen
	player.play()
	var playback = player.get_stream_playback()
	if not playback:
		return
	var frames = int(gen.mix_rate * 0.6)
	for i in range(frames):
		var t = float(i) / float(frames)
		var decay = (1.0 - t) * (1.0 - t)
		var sample = (randf() * 2.0 - 1.0) * decay * 0.95
		playback.push_frame(Vector2(sample, sample))

func _play_clank() -> void:
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	var p = AudioStreamPlayer3D.new()
	add_child(p)
	p.stream = gen
	p.play()
	var pb = p.get_stream_playback()
	if not pb:
		return
	var frames = int(gen.mix_rate * 0.07)
	for i in range(frames):
		var t = float(i) / float(frames)
		var s = sin(t * 1200.0 * TAU) * (1.0 - t) * 0.3
		pb.push_frame(Vector2(s, s))
	get_tree().create_timer(0.15).timeout.connect(p.queue_free)
