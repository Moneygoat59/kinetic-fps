class_name AbandonedCampsite
extends Node3D

const BARK_TEX = preload("res://textures/decayed_bark_seamless.png")
const STONE_TEX = preload("res://textures/mossy_stone_seamless.png")

static var canvas_tex: ImageTexture; static var tarp_tex: ImageTexture
static var crate_tex: ImageTexture; static var ash_tex: ImageTexture; static var lantern_tex: ImageTexture

var lantern_light: OmniLight3D

static func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

func build_campsite(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	if not canvas_tex: canvas_tex = _tex("res://textures/canvas_ragged.png")
	if not tarp_tex: tarp_tex = _tex("res://textures/tarp_worn.png")
	if not crate_tex: crate_tex = _tex("res://textures/crate_weathered.png")
	if not ash_tex: ash_tex = _tex("res://textures/campfire_ash.png")
	if not lantern_tex: lantern_tex = _tex("res://textures/rusted_lantern.png")

	var canvas_mat = _mat(canvas_tex, Color(0.95, 0.95, 0.92), 0.96, Vector3.ONE, true)
	var tarp_mat = _mat(tarp_tex, Color(0.90, 0.90, 0.88), 0.92, Vector3(1.2, 1.2, 1.2))
	var crate_mat = _mat(crate_tex, Color(0.92, 0.88, 0.82), 0.90)
	var wood_mat = _mat(BARK_TEX, Color(0.48, 0.40, 0.32), 0.95, Vector3(0.5, 1.0, 0.5))
	var stone_mat = _mat(STONE_TEX, Color(0.48, 0.46, 0.42), 0.92, Vector3(0.6, 0.6, 0.6))
	var metal_mat = _mat(lantern_tex, Color(0.85, 0.80, 0.75), 0.68)
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(1.0, 0.82, 0.40, 0.75); glass_mat.emission_enabled = true
	glass_mat.emission = Color(1.0, 0.70, 0.25); glass_mat.emission_energy_multiplier = 1.3
	var ash_mat = StandardMaterial3D.new()
	ash_mat.albedo_texture = ash_tex; ash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; ash_mat.roughness = 0.98

	_build_tent(canvas_mat)
	# Weathered wooden ridge pole & door poles
	_cyl(Vector3(0.0, 2.47, 0.0), 0.035, 4.2, wood_mat, false, Vector3(deg_to_rad(90), 0, 0))
	_cyl(Vector3(-0.80, 0.95, 1.9), 0.028, 2.35, wood_mat, false, Vector3(0, 0, deg_to_rad(8.0))); _cyl(Vector3(0.80, 0.95, 1.9), 0.028, 2.35, wood_mat, false, Vector3(0, 0, deg_to_rad(-8.0)))
	_cyl(Vector3(0.0, 2.10, 1.9), 0.028, 1.35, wood_mat, false, Vector3(0, 0, deg_to_rad(90.0)))
	for x in [-2.3, 2.3]:
		for z in [-1.9, 1.9]:
			_cyl(Vector3(x, 0.06, z), 0.025, 0.45, wood_mat, false, Vector3(0, 0, deg_to_rad(15 if x < 0 else -15)))

	# Interior: worn ground tarp, ragged bedroll, weathered crate, rusted lantern
	_box(Vector3(0.0, -0.01, 0.0), Vector3(3.3, 0.06, 3.6), tarp_mat, false); _box(Vector3(-0.85, 0.04, -0.2), Vector3(0.80, 0.06, 1.8), canvas_mat, false)
	_cyl(Vector3(-0.85, 0.13, -0.9), 0.12, 0.78, canvas_mat, false, Vector3(0, 0, deg_to_rad(90))); _box(Vector3(0.85, 0.22, -0.6), Vector3(0.55, 0.44, 0.55), crate_mat, true)
	_cyl(Vector3(0.85, 0.46, -0.6), 0.075, 0.04, metal_mat, false); _cyl(Vector3(0.85, 0.55, -0.6), 0.060, 0.14, glass_mat, false); _cyl(Vector3(0.85, 0.63, -0.6), 0.085, 0.03, metal_mat, false)
	lantern_light = OmniLight3D.new(); lantern_light.position = Vector3(0.85, 0.56, -0.6); lantern_light.light_color = Color(1.0, 0.70, 0.25); lantern_light.light_energy = 0.85; lantern_light.omni_range = 4.5; add_child(lantern_light)
	var note = load("res://scripts/paper_note.gd").new(); note.position = Vector3(0.72, 0.445, -0.48); note.rotation.y = deg_to_rad(-15.0); add_child(note)

	# Dead campfire: soot-dusted ash bed, 10 mossy/soot stones, criss-cross charred logs, ember glow
	_cyl(Vector3(3.6, 0.01, 0.6), 0.85, 0.06, ash_mat, false)
	for i in range(10):
		var a = float(i) * TAU / 10.0; var spos = Vector3(3.6 + cos(a) * 0.85, 0.10, 0.6 + sin(a) * 0.85)
		var sc = Vector3(1.1 + sin(float(i)) * 0.2, 0.75, 0.95 + cos(float(i)) * 0.2)
		_sphere(spos, 0.18, sc, stone_mat, false, Vector3(randf() * 0.3, randf() * TAU, randf() * 0.3))
	_cyl(Vector3(3.6, 0.07, 0.6), 0.06, 0.85, wood_mat, false, Vector3(deg_to_rad(8.0), deg_to_rad(35.0), deg_to_rad(85.0)))
	_cyl(Vector3(3.6, 0.09, 0.6), 0.055, 0.80, wood_mat, false, Vector3(deg_to_rad(-6.0), deg_to_rad(-45.0), deg_to_rad(82.0)))
	_cyl(Vector3(3.6, 0.12, 0.6), 0.05, 0.75, wood_mat, false, Vector3(deg_to_rad(4.0), deg_to_rad(80.0), deg_to_rad(86.0)))
	var ember = OmniLight3D.new(); ember.position = Vector3(3.6, 0.45, 0.6); ember.light_color = Color(1.0, 0.40, 0.08); ember.light_energy = 3.2; ember.omni_range = 34.0; add_child(ember)

	# Weathered cut sitting logs arranged with open clearance around campfire
	_sitting_log(Vector3(3.6, 0.15, 2.25), 0.18, 1.85, wood_mat, deg_to_rad(12.0))
	_sitting_log(Vector3(5.15, 0.15, 0.6), 0.17, 1.70, wood_mat, deg_to_rad(85.0))

func _build_tent(canvas_mat: Material) -> void:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw = 1.75; var hd = 1.9; var ey = 0.75; var py = 2.45; var ew = 1.65
	var p_rf_r = Vector3(0.0, py, -hd); var p_rf_f = Vector3(0.0, py, hd)
	var p_el_f = Vector3(-ew, ey, hd); var p_el_r = Vector3(-ew, ey, -hd)
	var p_er_f = Vector3(ew, ey, hd); var p_er_r = Vector3(ew, ey, -hd)
	var p_bl_f = Vector3(-hw, -0.35, hd); var p_bl_r = Vector3(-hw, -0.35, -hd)
	var p_br_f = Vector3(hw, -0.35, hd); var p_br_r = Vector3(hw, -0.35, -hd)

	_quad_uv(st, p_el_r, Vector2(0, 1), p_el_f, Vector2(2, 1), p_rf_f, Vector2(2, 0), p_rf_r, Vector2(0, 0))
	_quad_uv(st, p_er_f, Vector2(2, 1), p_er_r, Vector2(0, 1), p_rf_r, Vector2(0, 0), p_rf_f, Vector2(2, 0))
	_quad_uv(st, p_bl_r, Vector2(0, 1), p_bl_f, Vector2(2, 1), p_el_f, Vector2(2, 0), p_el_r, Vector2(0, 0))
	_quad_uv(st, p_br_f, Vector2(2, 1), p_br_r, Vector2(0, 1), p_er_r, Vector2(0, 0), p_er_f, Vector2(2, 0))
	_quad_uv(st, p_br_r, Vector2(1, 1), p_bl_r, Vector2(0, 1), p_el_r, Vector2(0, 0.4), p_er_r, Vector2(1, 0.4))
	_tri_uv(st, p_er_r, Vector2(1, 0.4), p_el_r, Vector2(0, 0.4), p_rf_r, Vector2(0.5, 0.0))

	var dtl = Vector3(-0.65, 2.10, hd); var dtr = Vector3(0.65, 2.10, hd)
	var dbl = Vector3(-0.95, -0.35, hd); var dbr = Vector3(0.95, -0.35, hd)
	_tri_uv(st, p_bl_f, _uv_f(p_bl_f), p_el_f, _uv_f(p_el_f), p_rf_f, _uv_f(p_rf_f)); _tri_uv(st, p_bl_f, _uv_f(p_bl_f), p_rf_f, _uv_f(p_rf_f), dtl, _uv_f(dtl))
	_tri_uv(st, p_bl_f, _uv_f(p_bl_f), dtl, _uv_f(dtl), dbl, _uv_f(dbl)); _tri_uv(st, p_br_f, _uv_f(p_br_f), p_rf_f, _uv_f(p_rf_f), p_er_f, _uv_f(p_er_f))
	_tri_uv(st, p_br_f, _uv_f(p_br_f), dtr, _uv_f(dtr), p_rf_f, _uv_f(p_rf_f)); _tri_uv(st, p_br_f, _uv_f(p_br_f), dbr, _uv_f(dbr), dtr, _uv_f(dtr))
	_tri_uv(st, dtl, _uv_f(dtl), p_rf_f, _uv_f(p_rf_f), dtr, _uv_f(dtr))

	st.generate_normals(); var mesh = st.commit()
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = canvas_mat; add_child(mi)
	var sb = StaticBody3D.new()
	# Sloped roof colliders: 54.9° wall normal prevents standing/sticking outside and stops head clipping inside
	_add_col_box(sb, Vector3(0.86, 1.225, 0.0), Vector3(0.12, 3.0, 3.8), Vector3(0, 0, deg_to_rad(35.07)))
	_add_col_box(sb, Vector3(-0.86, 1.225, 0.0), Vector3(0.12, 3.0, 3.8), Vector3(0, 0, deg_to_rad(-35.07)))
	_add_col_box(sb, Vector3(0.0, 1.05, -1.90), Vector3(3.20, 2.50, 0.12))
	_add_col_box(sb, Vector3(-1.15, 0.90, 1.90), Vector3(0.90, 2.20, 0.10))
	_add_col_box(sb, Vector3(1.15, 0.90, 1.90), Vector3(0.90, 2.20, 0.10))
	_add_col_box(sb, Vector3(0.0, 2.25, 1.90), Vector3(1.40, 0.40, 0.10))
	add_child(sb)

func _uv_f(p: Vector3) -> Vector2:
	return Vector2((p.x + 1.75) / 3.5, 1.0 - (p.y / 2.45))

func _tri_uv(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2) -> void:
	st.set_uv(ua); st.add_vertex(a); st.set_uv(ub); st.add_vertex(b); st.set_uv(uc); st.add_vertex(c)

func _quad_uv(st: SurfaceTool, a: Vector3, ua: Vector2, b: Vector3, ub: Vector2, c: Vector3, uc: Vector2, d: Vector3, ud: Vector2) -> void:
	_tri_uv(st, a, ua, b, ub, c, uc); _tri_uv(st, a, ua, c, uc, d, ud)

func _mat(tex: Texture2D, tint: Color, rough: float, uv_sc: Vector3 = Vector3.ONE, dbl: bool = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = tint; m.roughness = rough
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; m.uv1_scale = uv_sc
	if dbl: m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _sitting_log(pos: Vector3, r: float, h: float, mat: Material, rot_y: float = 0.0) -> void:
	var mi = MeshInstance3D.new(); var cyl = CylinderMesh.new(); cyl.top_radius = r; cyl.bottom_radius = r; cyl.height = h; cyl.radial_segments = 10
	mi.mesh = cyl; mi.material_override = mat; mi.position = pos
	mi.rotation = Vector3(0.0, rot_y, deg_to_rad(90.0)); add_child(mi)
	var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shp = BoxShape3D.new()
	shp.size = Vector3(h * 0.96, r * 1.75, r * 1.75)
	col.shape = shp; sb.position = pos; sb.rotation = Vector3(0.0, rot_y, 0.0); sb.add_child(col); add_child(sb)

func _cyl(pos: Vector3, r: float, h: float, mat: Material, _add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var cyl = CylinderMesh.new(); cyl.top_radius = r; cyl.bottom_radius = r; cyl.height = h; cyl.radial_segments = 10
	mi.mesh = cyl; mi.material_override = mat; mi.position = pos; mi.rotation = rot; add_child(mi)
	return mi

func _sphere(pos: Vector3, r: float, sc: Vector3, mat: Material, _add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var sp = SphereMesh.new(); sp.radius = r; sp.height = r * 2.0; sp.radial_segments = 8; sp.rings = 5
	mi.mesh = sp; mi.material_override = mat; mi.position = pos; mi.scale = sc; mi.rotation = rot; add_child(mi)
	return mi

func _box(pos: Vector3, sz: Vector3, mat: Material, add_col: bool = false, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var bx = BoxMesh.new(); bx.size = sz
	mi.mesh = bx; mi.material_override = mat; mi.position = pos; mi.rotation = rot; add_child(mi)
	if add_col:
		var sb = StaticBody3D.new(); var col = CollisionShape3D.new(); var shp = BoxShape3D.new()
		shp.size = sz; col.shape = shp; sb.position = pos; sb.rotation = rot; sb.add_child(col); add_child(sb)
	return mi

func _add_col_box(sb: StaticBody3D, pos: Vector3, sz: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var col = CollisionShape3D.new(); var shp = BoxShape3D.new()
	shp.size = sz; col.shape = shp; col.position = pos; col.rotation = rot; sb.add_child(col)
