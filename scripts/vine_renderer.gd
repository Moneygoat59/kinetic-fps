class_name VineRenderer
extends MeshInstance3D

const SEGMENTS: int = 16
var imm_mesh: ImmediateMesh
var vine_mat: StandardMaterial3D
var _points: PackedVector3Array

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	imm_mesh = ImmediateMesh.new()
	mesh = imm_mesh
	_points.resize(SEGMENTS + 1)
	
	vine_mat = StandardMaterial3D.new()
	vine_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vine_mat.albedo_color = Color(1.0, 0.65, 0.12) # Golden Sodium Amber
	vine_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = vine_mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func clear_vine() -> void:
	if imm_mesh:
		imm_mesh.clear_surfaces()

func update_vine(start_pos: Vector3, end_pos: Vector3, time: float, strain: float = 0.0, tension: float = 1.0, cam_pos: Vector3 = Vector3.ZERO) -> void:
	if not imm_mesh:
		return
	global_transform = Transform3D.IDENTITY
	imm_mesh.clear_surfaces()
	
	if cam_pos.is_zero_approx():
		var cam = get_viewport().get_camera_3d() if is_inside_tree() else null
		cam_pos = cam.global_position if cam else (start_pos + Vector3.UP)

	var vine_width = 0.08 + (clamp(strain, 0.0, 1.0) * 0.04)
	
	# Color shifts from Golden Sodium Amber to strained incandescent red-orange
	var normal_color = Color(1.0, 0.65, 0.12)
	var strain_color = Color(1.0, 0.22, 0.08)
	vine_mat.albedo_color = normal_color.lerp(strain_color, clamp(strain, 0.0, 1.0))
	
	# Mutate pre-allocated points in-place (Zero hot-path allocation)
	for i in range(SEGMENTS + 1):
		var t = float(i) / float(SEGMENTS)
		var p = start_pos.lerp(end_pos, t)
		
		# Sag when slack, violent vibration when strained (pinned at endpoints)
		var envelope = sin(t * PI)
		var droop = (1.0 - clamp(tension, 0.0, 1.0)) * envelope * 2.0
		var wobble_intensity = ((clamp(tension, 0.0, 1.0) * 0.15) + (strain * 0.3)) * envelope
		var wobble_speed = 35.0 + (strain * 50.0)
		var wobble = sin(time * wobble_speed + t * 14.0) * wobble_intensity
		
		p.y -= droop
		p.x += wobble
		p.z += wobble * 0.6
		_points[i] = p
	
	imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, vine_mat)
	for i in range(SEGMENTS):
		var p0 = _points[i]
		var p1 = _points[i + 1]
		var dir = (p1 - p0).normalized()
		var to_cam = (cam_pos - p0).normalized()
		var side = dir.cross(to_cam)
		if side.length_squared() < 0.0001:
			side = dir.cross(Vector3.UP)
			if side.length_squared() < 0.0001:
				side = dir.cross(Vector3.RIGHT)
		side = side.normalized() * vine_width
		
		var v0 = p0 - side
		var v1 = p0 + side
		var v2 = p1 - side
		var v3 = p1 + side
		
		# Triangle 1
		imm_mesh.surface_add_vertex(v0)
		imm_mesh.surface_add_vertex(v1)
		imm_mesh.surface_add_vertex(v2)
		
		# Triangle 2
		imm_mesh.surface_add_vertex(v1)
		imm_mesh.surface_add_vertex(v3)
		imm_mesh.surface_add_vertex(v2)
	imm_mesh.surface_end()

func draw_vine(start_pos: Vector3, end_pos: Vector3, tension: float, time: float, cam_pos: Vector3, strain: float = 0.0) -> void:
	update_vine(start_pos, end_pos, time, strain, tension, cam_pos)
