class_name Sparks
extends RefCounted
## A spray of hot metal sparks (grinding, shorting, brakes on a rail): a CPUParticles3D of tiny unshaded orange-white
## streaks thrown out and falling under gravity. World-space particles, so they stay behind a moving emitter (a falling
## lift cage leaves them streaming upward). Build once with make(); toggle `emitting` after.

const AMOUNT := 180
const LIFETIME := 0.7
const COLOR := Color(1.0, 0.62, 0.22)

static var _mesh: QuadMesh                  # shared by every emitter


static func make(parent: Node3D, at: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Sparks"
	p.position = at
	p.emitting = false
	p.amount = AMOUNT
	p.lifetime = LIFETIME
	p.explosiveness = 0.1
	p.randomness = 0.6
	p.local_coords = false
	p.mesh = _shared_mesh()
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.5
	p.gravity = Vector3(0.0, -9.8, 0.0)
	p.damping_min = 0.5
	p.damping_max = 2.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.particle_flag_align_y = true          # streaks along their flight
	p.color = COLOR
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	return p


static func _shared_mesh() -> QuadMesh:
	if _mesh:
		return _mesh
	_mesh = QuadMesh.new()
	_mesh.size = Vector2(0.018, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.6, 1.3, 1.0)
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mesh.material = mat
	return _mesh
