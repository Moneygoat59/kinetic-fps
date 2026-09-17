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
var blisters: Array[MeshInstance3D] = []
var blister_offsets: Array[float] = []

static func _load_tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(path)
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

func build_pool(terrain: Node3D, pos_x: float, pos_z: float, radius: float, depth: float = 0.8, p_seed: int = 0) -> void:
	pool_radius = radius; time_offset = randf() * 10.0
	if not sludge_tex: sludge_tex = _load_tex("res://textures/amber_sludge_pixel.png")
	if not emit_tex: emit_tex = _load_tex("res://textures/amber_sludge_pixel_emit.png")

	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy + depth * 0.55, pos_z)

	var stain_mat = StandardMaterial3D.new()
	stain_mat.albedo_texture = sludge_tex; stain_mat.albedo_color = Color(0.20, 0.14, 0.07, 0.88)
	stain_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; stain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	stain_mat.roughness = 0.95; stain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var stain_mi = MeshInstance3D.new(); stain_mi.mesh = _create_seep_mesh(radius * 1.25, p_seed + 19)
	stain_mi.material_override = stain_mat; stain_mi.position.y = -0.04; add_child(stain_mi)

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = sludge_tex; mat.emission_enabled = true; mat.emission_texture = emit_tex
	mat.emission_energy_multiplier = 3.0; mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.roughness = 0.08; mat.metallic = 0.2
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED; mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mi = MeshInstance3D.new(); mi.mesh = _create_seep_mesh(radius, p_seed)
	mi.material_override = mat; add_child(mi)

	for i in range(4):
		var bmi = MeshInstance3D.new(); var sph = SphereMesh.new(); var brad = randf_range(0.10, 0.22)
		sph.radius = brad; sph.height = brad * 0.8; bmi.mesh = sph; bmi.material_override = mat
		var ang = randf() * TAU; var dist = randf_range(0.15, radius * 0.60)
		bmi.position = Vector3(cos(ang) * dist, 0.01, sin(ang) * dist)
		add_child(bmi); blisters.append(bmi); blister_offsets.append(randf() * 10.0)

	pool_light = OmniLight3D.new(); pool_light.position = Vector3(0.0, 0.35, 0.0)
	pool_light.light_color = Color(1.0, 0.58, 0.10); pool_light.light_energy = 2.4
	pool_light.omni_range = radius * 2.8; add_child(pool_light)

	var col = CollisionShape3D.new(); var shape = CylinderShape3D.new()
	shape.radius = radius * 0.75; shape.height = 0.40; col.shape = shape; col.position.y = 0.10; add_child(col)

	bubble_audio = AudioStreamPlayer3D.new(); bubble_audio.stream = BUBBLE_SOUND
	bubble_audio.unit_size = 6.0; bubble_audio.max_distance = 22.0; bubble_audio.volume_db = -9.0
	bubble_audio.finished.connect(_loop_bubbles); add_child(bubble_audio)

	sizzle_audio = AudioStreamPlayer3D.new(); sizzle_audio.stream = SIZZLE_SOUND
	sizzle_audio.unit_size = 9.0; sizzle_audio.volume_db = 2.5; add_child(sizzle_audio)

	body_entered.connect(_on_body_entered); body_exited.connect(_on_body_exited)

func _create_seep_mesh(rad: float, p_seed: int) -> ArrayMesh:
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); var segs = 28
	var center = Vector3.ZERO
	for i in range(segs):
		var a0 = float(i) * TAU / float(segs); var a1 = float(i + 1) * TAU / float(segs)
		var r0 = rad * (0.92 + 0.14 * sin(a0 * 3.0 + float(p_seed % 100)) + 0.10 * cos(a0 * 5.0 + float(p_seed % 67)))
		var r1 = rad * (0.92 + 0.14 * sin(a1 * 3.0 + float(p_seed % 100)) + 0.10 * cos(a1 * 5.0 + float(p_seed % 67)))
		var p0 = Vector3(cos(a0) * r0, 0.0, sin(a0) * r0); var p1 = Vector3(cos(a1) * r1, 0.0, sin(a1) * r1)
		var uv0 = Vector2(clampf(0.5 + p0.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p0.z / (rad * 2.1), 0.0, 1.0))
		var uv1 = Vector2(clampf(0.5 + p1.x / (rad * 2.1), 0.0, 1.0), clampf(0.5 + p1.z / (rad * 2.1), 0.0, 1.0))
		st.set_normal(Vector3.UP); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(center)
		st.set_normal(Vector3.UP); st.set_uv(uv0); st.add_vertex(p0)
		st.set_normal(Vector3.UP); st.set_uv(uv1); st.add_vertex(p1)
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

func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	if pool_light:
		var pulse = (sin(t * 4.0 + time_offset) + 1.0) * 0.5
		pool_light.light_energy = lerpf(1.6, 2.8, pulse)
	for i in range(blisters.size()):
		var b = blisters[i]
		if is_instance_valid(b): b.position.y = 0.02 + sin(t * 3.0 + blister_offsets[i]) * 0.02

func _physics_process(delta: float) -> void:
	if not player_in_pool: return
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = 0.38
		if is_instance_valid(player_in_pool):
			player_in_pool.take_hit(9.0)
			if sizzle_audio and is_inside_tree():
				sizzle_audio.pitch_scale = randf_range(0.92, 1.15); sizzle_audio.play()
