class_name VineRenderer
extends MeshInstance3D

var imm_mesh: ImmediateMesh
var vine_mat: StandardMaterial3D

func _ready():
	imm_mesh = ImmediateMesh.new()
	mesh = imm_mesh
	
	vine_mat = StandardMaterial3D.new()
	vine_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vine_mat.albedo_color = Color(0.15, 0.95, 0.25) # Toxic neon vine green
	vine_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = vine_mat

func clear_vine() -> void:
	if imm_mesh:
		imm_mesh.clear_surfaces()

func draw_vine(start_pos: Vector3, end_pos: Vector3, tension: float, time: float, cam_pos: Vector3, strain: float = 0.0) -> void:
	imm_mesh.clear_surfaces()
	
	var segments = 16
	var vine_width = 0.09 + (strain * 0.04)
	
	# Color shifts from toxic green to straining bright orange and neon red
	var normal_color = Color(0.15, 0.95, 0.25)
	var strain_color = Color(1.0, 0.15, 0.08)
	vine_mat.albedo_color = normal_color.lerp(strain_color, clamp(strain, 0.0, 1.0))
	
	# Generate points along the vine curve
	var points: Array[Vector3] = []
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var p = start_pos.lerp(end_pos, t)
		
		# Sag when slack, violent rubber vibration when strained
		var droop = (1.0 - clamp(tension, 0.0, 1.0)) * sin(t * PI) * 2.2
		var wobble_intensity = (clamp(tension, 0.0, 1.0) * 0.18) + (strain * 0.35)
		var wobble_speed = 35.0 + (strain * 50.0)
		var wobble = sin(time * wobble_speed + t * 14.0) * wobble_intensity
		
		p.y -= droop
		p.x += wobble
		p.z += wobble * 0.6
		points.append(p)
	
	imm_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(segments):
		var p0 = points[i]
		var p1 = points[i + 1]
		var dir = (p1 - p0).normalized()
		var to_cam = (cam_pos - p0).normalized()
		var side = dir.cross(to_cam).normalized() * vine_width
		
		var v0 = p0 - side
		var v1 = p0 + side
		var v2 = p1 - side
		var v3 = p1 + side
		
		# Quad triangle 1
		imm_mesh.surface_add_vertex(v0)
		imm_mesh.surface_add_vertex(v1)
		imm_mesh.surface_add_vertex(v2)
		
		# Quad triangle 2
		imm_mesh.surface_add_vertex(v1)
		imm_mesh.surface_add_vertex(v3)
		imm_mesh.surface_add_vertex(v2)
		
	imm_mesh.surface_end()
