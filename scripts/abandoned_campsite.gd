class_name AbandonedCampsite
extends Node3D

const STONE_TEX = preload("res://textures/mossy_stone_seamless.png")
const BARK_TEX = preload("res://textures/decayed_bark_seamless.png")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")

var lantern_light: OmniLight3D

func build_campsite(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var canvas_mat = StandardMaterial3D.new()
	canvas_mat.albedo_color = Color(0.28, 0.32, 0.24); canvas_mat.roughness = 0.95
	canvas_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_texture = BARK_TEX; wood_mat.albedo_color = Color(0.40, 0.34, 0.28); wood_mat.roughness = 0.95
	wood_mat.uv1_scale = Vector3(0.5, 0.5, 0.5)
	var char_mat = StandardMaterial3D.new()
	char_mat.albedo_color = Color(0.08, 0.07, 0.06); char_mat.roughness = 0.98
	var stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_texture = STONE_TEX; stone_mat.albedo_color = Color(0.52, 0.50, 0.46); stone_mat.roughness = 0.90
	stone_mat.uv1_scale = Vector3(0.4, 0.4, 0.4)
	var tarp_mat = StandardMaterial3D.new()
	tarp_mat.albedo_color = Color(0.16, 0.20, 0.18); tarp_mat.roughness = 0.92
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_texture = METAL_TEX; metal_mat.albedo_color = Color(0.38, 0.34, 0.30); metal_mat.roughness = 0.65
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.85, 0.5, 0.6); glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.72, 0.30); glass_mat.emission_energy_multiplier = 1.2

	_build_tent(canvas_mat)
	# Ridge pole along peak (Z-axis) & entrance frame poles
	_cyl(Vector3(0.0, 2.47, 0.0), 0.035, 4.2, wood_mat, false, Vector3(deg_to_rad(90), 0, 0))
	_cyl(Vector3(-0.80, 1.05, 1.9), 0.028, 2.15, wood_mat, false, Vector3(0, 0, deg_to_rad(8.0)))
	_cyl(Vector3(0.80, 1.05, 1.9), 0.028, 2.15, wood_mat, false, Vector3(0, 0, deg_to_rad(-8.0)))
	_cyl(Vector3(0.0, 2.10, 1.9), 0.028, 1.35, wood_mat, false, Vector3(0, 0, deg_to_rad(90.0)))
	for x in [-2.3, 2.3]:
		for z in [-1.9, 1.9]:
			_cyl(Vector3(x, 0.12, z), 0.025, 0.35, wood_mat, false, Vector3(0, 0, deg_to_rad(15 if x < 0 else -15)))

	# Interior: floor tarp, sleeping pad, rolled pillow, crate, camping lantern
	_box(Vector3(0.0, 0.01, 0.0), Vector3(3.3, 0.02, 3.6), tarp_mat, false)
	_box(Vector3(-0.85, 0.04, -0.2), Vector3(0.80, 0.06, 1.8), canvas_mat, false)
	_cyl(Vector3(-0.85, 0.13, -0.9), 0.12, 0.78, canvas_mat, false, Vector3(0, 0, deg_to_rad(90)))
	_box(Vector3(0.85, 0.22, -0.6), Vector3(0.55, 0.44, 0.55), wood_mat, true)
	_cyl(Vector3(0.85, 0.46, -0.6), 0.075, 0.04, metal_mat, false)
	_cyl(Vector3(0.85, 0.55, -0.6), 0.060, 0.14, glass_mat, false)
	_cyl(Vector3(0.85, 0.63, -0.6), 0.085, 0.03, metal_mat, false)
	lantern_light = OmniLight3D.new(); lantern_light.position = Vector3(0.85, 0.56, -0.6)
	lantern_light.light_color = Color(1.0, 0.72, 0.30); lantern_light.light_energy = 0.85; lantern_light.omni_range = 4.5
	add_child(lantern_light)

	# Dead campfire: ash bed, stone ring, criss-crossed charred logs, ember glow
	_cyl(Vector3(3.6, 0.02, 0.6), 0.80, 0.04, char_mat, false)
	for i in range(10):
		var a = float(i) * TAU / 10.0; var spos = Vector3(3.6 + cos(a) * 0.85, 0.10, 0.6 + sin(a) * 0.85)
		var sc = Vector3(1.1 + sin(float(i)) * 0.2, 0.75, 0.95 + cos(float(i)) * 0.2)
		_sphere(spos, 0.18, sc, stone_mat, true, Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3))
	_cyl(Vector3(3.6, 0.07, 0.6), 0.06, 0.85, char_mat, false, Vector3(deg_to_rad(8.0), deg_to_rad(35.0), deg_to_rad(85.0)))
	_cyl(Vector3(3.6, 0.09, 0.6), 0.055, 0.80, char_mat, false, Vector3(deg_to_rad(-6.0), deg_to_rad(-45.0), deg_to_rad(82.0)))
	_cyl(Vector3(3.6, 0.12, 0.6), 0.05, 0.75, char_mat, false, Vector3(deg_to_rad(4.0), deg_to_rad(80.0), deg_to_rad(86.0)))
	var ember = OmniLight3D.new(); ember.position = Vector3(3.6, 0.15, 0.6); ember.light_color = Color(1.0, 0.32, 0.05); ember.light_energy = 0.45; ember.omni_range = 1.8; add_child(ember)

	# Rounded sitting logs beside campfire
	_cyl(Vector3(3.6, 0.18, 2.0), 0.18, 1.85, wood_mat, true, Vector3(0.0, deg_to_rad(15.0), deg_to_rad(90.0)))
	_cyl(Vector3(2.1, 0.18, 0.6), 0.17, 1.70, wood_mat, true, Vector3(deg_to_rad(85.0), 0.0, 0.0))

func _build_tent(canvas_mat: Material) -> void:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = 1.75; var hd = 1.9; var ey = 0.75; var py = 2.45; var ew = 1.65
	var p_rf_r = Vector3(0.0, py, -hd); var p_rf_f = Vector3(0.0, py, hd)
	var p_el_f = Vector3(-ew, ey, hd); var p_el_r = Vector3(-ew, ey, -hd)
	var p_er_f = Vector3(ew, ey, hd); var p_er_r = Vector3(ew, ey, -hd)
	var p_bl_f = Vector3(-hw, 0.0, hd); var p_bl_r = Vector3(-hw, 0.0, -hd)
	var p_br_f = Vector3(hw, 0.0, hd); var p_br_r = Vector3(hw, 0.0, -hd)

	_quad(st, p_el_r, p_el_f, p_rf_f, p_rf_r); _quad(st, p_er_f, p_er_r, p_rf_r, p_rf_f)
	_quad(st, p_bl_r, p_bl_f, p_el_f, p_el_r); _quad(st, p_br_f, p_br_r, p_er_r, p_er_f)
	_quad(st, p_br_r, p_bl_r, p_el_r, p_er_r); _tri(st, p_er_r, p_el_r, p_rf_r)

	var dtl = Vector3(-0.65, 2.10, hd); var dtr = Vector3(0.65, 2.10, hd)
	var dbl = Vector3(-0.95, 0.0, hd); var dbr = Vector3(0.95, 0.0, hd)
	_tri(st, p_bl_f, p_el_f, p_rf_f); _tri(st, p_bl_f, p_rf_f, dtl); _tri(st, p_bl_f, dtl, dbl)
	_tri(st, p_br_f, p_rf_f, p_er_f); _tri(st, p_br_f, dtr, p_rf_f); _tri(st, p_br_f, dbr, dtr)
	_tri(st, dtl, p_rf_f, dtr)

	st.generate_normals(); var mesh = st.commit()
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = canvas_mat; add_child(mi)
	var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); col.shape = mesh.create_trimesh_shape()
	sb.add_child(col); add_child(sb)

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.set_uv(Vector2(a.x, a.y)); st.add_vertex(a); st.set_uv(Vector2(b.x, b.y)); st.add_vertex(b); st.set_uv(Vector2(c.x, c.y)); st.add_vertex(c)

func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c); _tri(st, a, c, d)

func _cyl(pos: Vector3, r: float, h: float, mat: Material, add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var cyl = CylinderMesh.new(); cyl.top_radius = r; cyl.bottom_radius = r; cyl.height = h; cyl.radial_segments = 10
	mi.mesh = cyl; mi.material_override = mat; mi.position = pos; mi.rotation = rot; add_child(mi)
	if add_col:
		var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shp = CylinderShape3D.new()
		shp.radius = r; shp.height = h; col.shape = shp; sb.position = pos; sb.rotation = rot; sb.add_child(col); add_child(sb)
	return mi

func _sphere(pos: Vector3, r: float, sc: Vector3, mat: Material, add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var sp = SphereMesh.new(); sp.radius = r; sp.height = r * 2.0; sp.radial_segments = 8; sp.rings = 5
	mi.mesh = sp; mi.material_override = mat; mi.position = pos; mi.scale = sc; mi.rotation = rot; add_child(mi)
	if add_col:
		var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shp = SphereShape3D.new()
		shp.radius = r * maxf(sc.x, maxf(sc.y, sc.z)) * 0.85; col.shape = shp; sb.position = pos; sb.add_child(col); add_child(sb)
	return mi

func _box(pos: Vector3, sz: Vector3, mat: Material, add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var bx = BoxMesh.new(); bx.size = sz
	mi.mesh = bx; mi.material_override = mat; mi.position = pos; mi.rotation = rot; add_child(mi)
	if add_col:
		var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shp = BoxShape3D.new()
		shp.size = sz; col.shape = shp; sb.position = pos; sb.rotation = rot; sb.add_child(col); add_child(sb)
	return mi
