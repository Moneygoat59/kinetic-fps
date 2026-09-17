class_name AmberPool
extends Area3D

const SIZZLE_SOUND = preload("res://audio/sci-fi/Audio/slime_000.ogg")
const BUBBLE_SOUND = preload("res://audio/sci-fi/Audio/slime_001.ogg")

var pool_radius: float = 3.0
var damage_timer: float = 0.0
var player_in_pool: CharacterBody3D
var pool_light: OmniLight3D
var bubble_audio: AudioStreamPlayer3D
var sizzle_audio: AudioStreamPlayer3D
var time_offset: float = 0.0
var blisters: Array[MeshInstance3D] = []
var blister_offsets: Array[float] = []

func build_pool(terrain: Node3D, pos_x: float, pos_z: float, radius: float) -> void:
	pool_radius = radius; time_offset = randf() * 10.0
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy + 0.05, pos_z)

	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.15, 0.13, 0.11); rim_mat.roughness = 0.95
	var rim_mi = MeshInstance3D.new(); var rim_cyl = CylinderMesh.new()
	rim_cyl.top_radius = radius * 1.08; rim_cyl.bottom_radius = radius * 1.15; rim_cyl.height = 0.22
	rim_mi.mesh = rim_cyl; rim_mi.material_override = rim_mat; rim_mi.position.y = -0.06
	add_child(rim_mi)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.54, 0.06, 0.94)
	mat.emission_enabled = true; mat.emission = Color(1.0, 0.48, 0.04)
	mat.emission_energy_multiplier = 3.2; mat.roughness = 0.08; mat.metallic = 0.2
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var mi = MeshInstance3D.new()
	var cyl = CylinderMesh.new(); cyl.top_radius = radius; cyl.bottom_radius = radius * 0.92; cyl.height = 0.16
	mi.mesh = cyl; mi.material_override = mat; add_child(mi)

	for i in range(3):
		var bmi = MeshInstance3D.new(); var sph = SphereMesh.new()
		var brad = radius * randf_range(0.12, 0.22)
		sph.radius = brad; sph.height = brad * 1.3
		bmi.mesh = sph; bmi.material_override = mat
		var ang = randf() * TAU; var dist = randf_range(0.2, radius * 0.65)
		bmi.position = Vector3(cos(ang) * dist, 0.04, sin(ang) * dist)
		add_child(bmi); blisters.append(bmi); blister_offsets.append(randf() * 10.0)

	pool_light = OmniLight3D.new(); pool_light.position = Vector3(0.0, 0.4, 0.0)
	pool_light.light_color = Color(1.0, 0.58, 0.10); pool_light.light_energy = 2.4
	pool_light.omni_range = radius * 3.0; add_child(pool_light)

	var col = CollisionShape3D.new(); var shape = CylinderShape3D.new()
	shape.radius = radius * 0.96; shape.height = 1.6
	col.shape = shape; col.position.y = 0.7; add_child(col)

	bubble_audio = AudioStreamPlayer3D.new(); bubble_audio.stream = BUBBLE_SOUND
	bubble_audio.unit_size = 6.0; bubble_audio.max_distance = 22.0; bubble_audio.volume_db = -9.0
	bubble_audio.finished.connect(_loop_bubbles)
	add_child(bubble_audio)

	sizzle_audio = AudioStreamPlayer3D.new(); sizzle_audio.stream = SIZZLE_SOUND
	sizzle_audio.unit_size = 9.0; sizzle_audio.volume_db = 2.5; add_child(sizzle_audio)

	body_entered.connect(_on_body_entered); body_exited.connect(_on_body_exited)

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
		if is_instance_valid(b): b.position.y = 0.04 + sin(t * 3.0 + blister_offsets[i]) * 0.03

func _physics_process(delta: float) -> void:
	if not player_in_pool: return
	damage_timer -= delta
	if damage_timer <= 0.0:
		damage_timer = 0.38
		if is_instance_valid(player_in_pool):
			player_in_pool.take_hit(9.0)
			if sizzle_audio and is_inside_tree():
				sizzle_audio.pitch_scale = randf_range(0.92, 1.15); sizzle_audio.play()
