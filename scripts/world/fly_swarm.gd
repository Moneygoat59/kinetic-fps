class_name FlySwarm
extends RefCounted
## A few flies circling something rotten: tiny dark specks wandering on turbulence round a point (GPUParticles3D, no gravity),
## and now and then one of them buzzing (FlyBuzz: random takes, pitch, level and silences). Build-time only:
##   FlySwarm.make(parent, global_position, radius, count)

const LIFETIME := 6.0

static var _mesh: QuadMesh                  # shared speck mesh + material


## A swarm round `at` (global), `radius` metres across its wander, `count` flies. Returns its node (already in the tree).
static func make(parent: Node3D, at: Vector3, radius := 0.35, count := 7) -> Node3D:
	if parent == null:
		return null
	var root := Node3D.new()
	root.name = "FlySwarm"
	parent.add_child(root)
	root.global_position = at
	var p := GPUParticles3D.new()
	p.amount = count
	p.lifetime = LIFETIME
	p.preprocess = LIFETIME                  # already buzzing when the room fades in
	p.randomness = 0.5
	p.visibility_aabb = AABB(Vector3.ONE * -radius * 2.0, Vector3.ONE * radius * 4.0)
	p.draw_pass_1 = _speck()
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radius
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = 0.3
	m.initial_velocity_max = 0.9
	m.spread = 180.0
	m.turbulence_enabled = true
	m.turbulence_noise_strength = 6.0
	m.turbulence_noise_scale = 1.2
	m.turbulence_noise_speed_random = 0.8
	m.turbulence_influence_min = 0.4
	m.turbulence_influence_max = 0.9
	m.damping_min = 0.2
	m.damping_max = 0.6
	p.process_material = m
	root.add_child(p)
	var buzz := FlyBuzz.new()
	buzz.radius = radius
	root.add_child(buzz)
	return root


static func _speck() -> QuadMesh:
	if _mesh:
		return _mesh
	_mesh = QuadMesh.new()
	_mesh.size = Vector2(0.009, 0.007)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = Color(0.02, 0.018, 0.015)
	_mesh.material = mat
	return _mesh
