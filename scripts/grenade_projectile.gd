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
	linear_damp = 1.2
	angular_damp = 2.0
	spark_light = get_node_or_null("SparkLight")
	body_entered.connect(_on_bounce)
	var g_model = get_node_or_null("GrenadeModel")
	if g_model:
		var model_shader = load("res://shaders/ps1_triplanar_model.gdshader") as Shader
		var haz_img = Image.new()
		if haz_img.load("res://textures/hazard_stripes.png") == OK and model_shader:
			var haz_mat = ShaderMaterial.new()
			haz_mat.shader = model_shader
			haz_mat.set_shader_parameter("albedo_texture", ImageTexture.create_from_image(haz_img))
			haz_mat.set_shader_parameter("uv_scale", Vector3(10.0, 10.0, 10.0))
			haz_mat.set_shader_parameter("jitter_resolution", 180.0)
			haz_mat.set_shader_parameter("metallic", 0.2)
			haz_mat.set_shader_parameter("roughness", 0.85)
			haz_mat.set_shader_parameter("tint_color", Color(0.9, 0.85, 0.8))
			_apply_mat_recursive(g_model, haz_mat)

func _apply_mat_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D: node.material_override = mat
	for child in node.get_children(): _apply_mat_recursive(child, mat)

func initialize(fuse_time: float, throw_vel: Vector3) -> void:
	remaining_fuse = max(0.1, fuse_time)
	linear_velocity = throw_vel
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(12, 20))

func _physics_process(delta: float) -> void:
	if has_exploded: return
	remaining_fuse -= delta
	if spark_light: spark_light.visible = fmod(remaining_fuse * 12.0, 1.0) > 0.4
	if remaining_fuse <= 0.0: explode()

func _on_bounce(body: Node) -> void:
	if has_exploded: return
	if body and body != self and (body.is_in_group("enemies") or body.has_method("take_hit")):
		explode()
		return
	linear_velocity.x *= 0.55
	linear_velocity.z *= 0.55
	linear_velocity.y *= 0.35
	angular_velocity *= 0.45
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_clank_time > 0.12 and linear_velocity.length() > 0.8:
		last_clank_time = now
		SoundManager.play_spatial(AudioBank.GRENADE_BOUNCE, global_position, -2.0)

func explode() -> void:
	if has_exploded: return
	has_exploded = true
	var blast_pos = global_position
	_spawn_blast_effects(blast_pos)
	_apply_blast_forces(blast_pos)
	SoundManager.play_spatial(AudioBank.EXPLOSION, blast_pos, 4.0)
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
		if not col or col == self: continue
		var to_target = col.global_position - blast_pos
		var dist = max(0.2, to_target.length())
		if dist > blast_radius: continue
		var blast_dir = (to_target / dist).normalized()
		blast_dir.y = max(blast_dir.y + 0.45, 0.4)
		blast_dir = blast_dir.normalized()
		var falloff = 1.0 - (dist / blast_radius)
		var force = blast_impulse * falloff
		if col.has_method("take_hit"):
			col.take_hit(blast_damage * falloff, -blast_dir, blast_pos)
		if col is RigidBody3D:
			col.apply_impulse(blast_dir * force * 1.5, to_target * 0.2)
		elif col is CharacterBody3D:
			col.velocity += blast_dir * (force * 1.6)

func _spawn_blast_effects(pos: Vector3) -> void:
	var effect = Node3D.new()
	get_parent().add_child(effect)
	effect.global_position = pos
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.2)
	light.light_energy = 8.0
	light.omni_range = 14.0
	effect.add_child(light)
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
	var tween = effect.create_tween()
	tween.set_parallel(true)
	tween.tween_property(sphere_inst, "scale", Vector3.ONE * (blast_radius * 1.2), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tween.tween_property(light, "light_energy", 0.0, 0.4)
	tween.chain().tween_callback(effect.queue_free)
