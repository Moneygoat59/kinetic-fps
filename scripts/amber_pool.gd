class_name AmberPool
extends Area3D

const SIZZLE_SOUND = preload("res://audio/sci-fi/Audio/slime_000.ogg")
const BUBBLE_SOUND = preload("res://audio/sci-fi/Audio/slime_001.ogg")

static var sludge_tex: ImageTexture; static var emit_tex: ImageTexture

var pool_radius: float = 3.0
var damage_timer: float = 0.0
var player_in_pool: CharacterBody3D
var pool_light: OmniLight3D
var bubble_audio: AudioStreamPlayer3D
var sizzle_audio: AudioStreamPlayer3D
var time_offset: float = 0.0
var liquid_mat: StandardMaterial3D
var stain_mat: StandardMaterial3D
var vapor_mi: MeshInstance3D

static func _load_tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

func build_pool(terrain: Node3D, pos_x: float, pos_z: float, radius: float, depth: float = 0.8, p_seed: int = 0) -> void:
	pool_radius = radius; time_offset = randf() * 10.0
	if not sludge_tex: sludge_tex = _load_tex("res://textures/amber_sludge_pixel.png")
	if not emit_tex: emit_tex = _load_tex("res://textures/amber_sludge_pixel_emit.png")

	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy + depth * 0.55, pos_z)

	stain_mat = StandardMaterial3D.new()
	stain_mat.albedo_texture = sludge_tex; stain_mat.albedo_color = Color(0.42, 0.36, 0.30, 0.90)
	stain_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stain_mat.vertex_color_use_as_albedo = true; stain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stain_mat.proximity_fade_enabled = true; stain_mat.proximity_fade_distance = 0.35
	stain_mat.roughness = 0.95; stain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var stain_mi = MeshInstance3D.new(); stain_mi.mesh = _create_seep_mesh(radius * 1.25, p_seed + 19, true)
	stain_mi.material_override = stain_mat; stain_mi.position.y = -0.02; add_child(stain_mi)

	liquid_mat = StandardMaterial3D.new()
	liquid_mat.albedo_texture = sludge_tex; liquid_mat.emission_enabled = true; liquid_mat.emission_texture = emit_tex
	liquid_mat.emission_energy_multiplier = 2.6; liquid_mat.vertex_color_use_as_albedo = true
	liquid_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	liquid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_mat.proximity_fade_enabled = true; liquid_mat.proximity_fade_distance = 0.30
	liquid_mat.roughness = 0.12; liquid_mat.metallic = 0.15
	liquid_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED; liquid_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mi = MeshInstance3D.new(); mi.mesh = _create_seep_mesh(radius, p_seed, true)
	mi.material_override = liquid_mat; add_child(mi)

	var vapor_mat = StandardMaterial3D.new()
	vapor_mat.albedo_texture = sludge_tex; vapor_mat.albedo_color = Color(0.95, 0.65, 0.18, 0.24)
	vapor_mat.emission_enabled = true; vapor_mat.emission = Color(0.95, 0.55, 0.10); vapor_mat.emission_energy_multiplier = 0.6
	vapor_mat.vertex_color_use_as_albedo = true; vapor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vapor_mat.proximity_fade_enabled = true; vapor_mat.proximity_fade_distance = 0.40
	vapor_mat.cull_mode = BaseMaterial3D.CULL_DISABLED; vapor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vapor_mi = MeshInstance3D.new(); vapor_mi.mesh = _create_seep_mesh(radius * 1.15, p_seed + 37, true)
	vapor_mi.material_override = vapor_mat; vapor_mi.position.y = 0.04; add_child(vapor_mi)

	pool_light = OmniLight3D.new(); pool_light.position = Vector3(0.0, 0.35, 0.0)
	pool_light.light_color = Color(1.0, 0.58, 0.10); pool_light.light_energy = 2.0
	pool_light.omni_range = radius * 2.8; add_child(pool_light)

	var col = CollisionShape3D.new(); var shape = CylinderShape3D.new()
	shape.radius = radius * 0.75; shape.height = 0.40; col.shape = shape; col.position.y = 0.10; add_child(col)

	bubble_audio = AudioStreamPlayer3D.new(); bubble_audio.stream = BUBBLE_SOUND
	bubble_audio.unit_size = 6.0; bubble_audio.max_distance = 22.0; bubble_audio.volume_db = -11.0
	bubble_audio.finished.connect(_loop_bubbles); add_child(bubble_audio)

	sizzle_audio = AudioStreamPlayer3D.new(); sizzle_audio.stream = SIZZLE_SOUND
	sizzle_audio.unit_size = 9.0; sizzle_audio.volume_db = 2.5; add_child(sizzle_audio)

	body_entered.connect(_on_body_entered); body_exited.connect(_on_body_exited)

func _create_seep_mesh(rad: float, p_seed: int, fade_edge: bool) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); var segs = 24
	var center = Vector3.ZERO
	for i in range(segs):
		var a0 = float(i) * TAU / float(segs); var a1 = float(i + 1) * TAU / float(segs)
		var lob0 = (0.92 + 0.14 * sin(a0 * 3.0 + float(p_seed % 100)) + 0.10 * cos(a0 * 5.0 + float(p_seed % 67)))
		var lob1 = (0.92 + 0.14 * sin(a1 * 3.0 + float(p_seed % 100)) + 0.10 * cos(a1 * 5.0 + float(p_seed % 67)))
		var p0_in = Vector3(cos(a0) * rad * 0.55, 0.0, sin(a0) * rad * 0.55)
		var p1_in = Vector3(cos(a1) * rad * 0.55, 0.0, sin(a1) * rad * 0.55)
		var p0_out = Vector3(cos(a0) * rad * lob0, 0.0, sin(a0) * rad * lob0)
		var p1_out = Vector3(cos(a1) * rad * lob1, 0.0, sin(a1) * rad * lob1)
		var uv0_in = Vector2(clampf(0.5 + p0_in.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p0_in.z / (rad * 2.1), 0.0, 1.0))
		var uv1_in = Vector2(clampf(0.5 + p1_in.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p1_in.z / (rad * 2.1), 0.0, 1.0))
		var uv0_out = Vector2(clampf(0.5 + p0_out.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p0_out.z / (rad * 2.1), 0.0, 1.0))
		var uv1_out = Vector2(clampf(0.5 + p1_out.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p1_out.z / (rad * 2.1), 0.0, 1.0))
		var c_in = Color(1, 1, 1, 1); var c_out = Color(1, 1, 1, 0.0 if fade_edge else 1.0)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(center)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(uv0_in); st.add_vertex(p0_in)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(uv1_in); st.add_vertex(p1_in)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(uv0_in); st.add_vertex(p0_in)
		st.set_normal(Vector3.UP); st.set_color(c_out); st.set_uv(uv0_out); st.add_vertex(p0_out)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(uv1_in); st.add_vertex(p1_in)
		st.set_normal(Vector3.UP); st.set_color(c_in); st.set_uv(uv1_in); st.add_vertex(p1_in)
		st.set_normal(Vector3.UP); st.set_color(c_out); st.set_uv(uv0_out); st.add_vertex(p0_out)
		st.set_normal(Vector3.UP); st.set_color(c_out); st.set_uv(uv1_out); st.add_vertex(p1_out)
	st.generate_normals(); return st.commit()

func _ready() -> void:
	if bubble_audio and not bubble_audio.playing: bubble_audio.play()

func _loop_bubbles() -> void:
	if is_instance_valid(bubble_audio) and is_inside_tree():
		bubble_audio.pitch_scale = randf_range(0.88, 1.12); bubble_audio.play()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("take_hit"):
		player_in_pool = body; damage_timer = 0.0

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_pool: player_in_pool = null

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.0006
	if liquid_mat:
		liquid_mat.uv1_offset = Vector3(sin(t + time_offset) * 0.025, cos(t * 0.85 + time_offset * 1.3) * 0.025, 0.0)
	if stain_mat:
		stain_mat.uv1_offset = Vector3(cos(t * 0.6 + time_offset) * 0.02, sin(t * 0.7 + time_offset * 1.1) * 0.02, 0.0)
	if vapor_mi:
		vapor_mi.rotation.y += delta * 0.08
		var br = 1.0 + sin(t * 1.8 + time_offset) * 0.035
		vapor_mi.scale = Vector3(br, 1.0, br)

func _physics_process(delta: float) -> void:
	if not player_in_pool: return
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = 0.38
		if is_instance_valid(player_in_pool):
			player_in_pool.take_hit(9.0)
			if sizzle_audio and is_inside_tree():
				sizzle_audio.pitch_scale = randf_range(0.92, 1.15); sizzle_audio.play()
