class_name DeadForestManager
extends Node3D

@export var terrain: Node3D
@export var props: Node3D
@export var player: CharacterBody3D

const WIND_BASE = preload("res://audio/ambient/wind_long_loop.ogg")
const WIND_LAYER = preload("res://audio/ambient/wind_whoosh_loop.ogg")
const MUSIC_STREAM = preload("res://audio/ambient/forest_somber_ambient.ogg")
const LAND_SOUND = preload("res://audio/impacts/Audio/impactSoft_heavy_000.ogg")
const STEP_L = preload("res://audio/impacts/Audio/footstep_snow_000.ogg")
const BED_SCRIPT = preload("res://scripts/start_bed.gd")
const FONT_LIB = preload("res://scripts/ui/font_library.gd")

const GUSTS: Array[AudioStream] = [
	preload("res://audio/ambient/wind_gust_1.wav"),
	preload("res://audio/ambient/wind_gust_2.wav"),
	preload("res://audio/ambient/wind_gust_3.wav"),
	preload("res://audio/ambient/wind_gust_4.wav"),
	preload("res://audio/ambient/wind_gust_5.wav"),
]

var wind_player: AudioStreamPlayer
var wind_layer_player: AudioStreamPlayer
var gust_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var wake_overlay: ColorRect
var wake_label: Label
var spawn_point: Vector3 = Vector3.ZERO
var gust_timer: float = 5.0
var bed_instance: Node3D
var is_dropping: bool = false
var drop_timer: float = 0.0

func _ready() -> void:
	_init_audio()
	_init_world()
	_setup_wake_sequence()

func _init_audio() -> void:
	wind_player = AudioStreamPlayer.new(); wind_player.name = "WindBasePlayer"
	wind_player.stream = WIND_BASE; wind_player.volume_db = -9.0
	add_child(wind_player); wind_player.play()

	wind_layer_player = AudioStreamPlayer.new(); wind_layer_player.name = "WindLayerPlayer"
	wind_layer_player.stream = WIND_LAYER; wind_layer_player.volume_db = -15.0
	wind_layer_player.pitch_scale = 0.92; add_child(wind_layer_player); wind_layer_player.play()

	gust_player = AudioStreamPlayer.new(); gust_player.name = "WindGustPlayer"
	gust_player.volume_db = -32.0; add_child(gust_player)

	music_player = AudioStreamPlayer.new(); music_player.name = "MusicPlayer"
	music_player.stream = MUSIC_STREAM; music_player.volume_db = -14.0
	add_child(music_player); music_player.play()

func _process(delta: float) -> void:
	gust_timer -= delta
	if gust_timer <= 0.0:
		gust_timer = randf_range(10.0, 19.0)
		_trigger_wind_gust()

func _trigger_wind_gust() -> void:
	if not gust_player: return
	var stream = GUSTS[randi() % GUSTS.size()]
	gust_player.stream = stream
	gust_player.pitch_scale = randf_range(0.88, 1.12)
	gust_player.volume_db = -32.0
	var offset = randf_range(0.0, 25.0)
	gust_player.play(offset)
	var tw = create_tween()
	tw.tween_property(gust_player, "volume_db", randf_range(-11.0, -8.0), 2.8)
	tw.tween_interval(randf_range(3.5, 6.5))
	tw.tween_property(gust_player, "volume_db", -32.0, 3.2)

func _init_world() -> void:
	if not terrain: terrain = get_node_or_null("DeadForestTerrain")
	if not props: props = get_node_or_null("DeadForestProps")
	if not player: player = get_node_or_null("Player") as CharacterBody3D

	var ground_y = 0.0
	if terrain:
		ground_y = terrain.get_height(0.0, 0.0)
		if props and props.has_method("init_props"): props.init_props(terrain)

	if props and props.has_method("clear_area"):
		props.clear_area(Vector3(0.0, ground_y, 0.0), 3.5)

	bed_instance = BED_SCRIPT.new()
	bed_instance.name = "StartBed"
	bed_instance.build_bed(terrain, 0.0, 0.0)
	add_child(bed_instance)

	var side_x = 1.25
	spawn_point = Vector3(side_x, ground_y + 0.95, 0.0)
	var drop_pos = Vector3(side_x, ground_y + 2.3, 0.0)

	if player:
		if player.has_method("enable_walk_mode"): player.enable_walk_mode()
		player.global_position = drop_pos
		player.velocity = Vector3.ZERO
		player.rotation.y = deg_to_rad(15.0)
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		if player.health: player.health.spawn_position = spawn_point
		if terrain and terrain.has_method("update_player_pos"):
			terrain.update_player_pos(drop_pos)

func _setup_wake_sequence() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "WakeCanvas"
	canvas.layer = 20
	add_child(canvas)

	wake_overlay = ColorRect.new()
	wake_overlay.name = "WakeBlackout"
	wake_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
	wake_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wake_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(wake_overlay)

	wake_label = Label.new()
	wake_label.name = "WakeLabel"
	wake_label.text = "I must have had that dream again..."
	wake_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	wake_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wake_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wake_label.modulate = Color(0.88, 0.92, 0.98, 0.0)
	var df = FONT_LIB.dream_font()
	if df: wake_label.add_theme_font_override("font", df)
	wake_label.add_theme_font_size_override("font_size", 14)
	wake_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.add_child(wake_label)

	if player and player.camera: player.camera.rotation.x = deg_to_rad(-18.0)
	_run_wake_tween()

func _run_wake_tween() -> void:
	var seq = create_tween().set_parallel(false)
	seq.tween_interval(0.5)
	seq.tween_property(wake_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	seq.tween_interval(1.8)
	seq.tween_property(wake_label, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	seq.tween_interval(0.2)
	seq.tween_callback(Callable(self, "_trigger_drop_and_reveal"))

func _trigger_drop_and_reveal() -> void:
	is_dropping = true
	drop_timer = 2.0
	if player:
		player.set_physics_process(true)
		player.velocity = Vector3(0.0, -2.5, 0.0)

	var fade_tw = create_tween().set_parallel(true)
	fade_tw.tween_property(wake_overlay, "color:a", 0.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade_tw.finished.connect(func():
		if is_instance_valid(wake_overlay):
			var c = wake_overlay.get_parent()
			if is_instance_valid(c): c.queue_free()
	)

func _physics_process(delta: float) -> void:
	if player:
		if is_dropping:
			drop_timer -= delta
			if player.is_on_floor() or drop_timer <= 0.0:
				is_dropping = false
				player.set_process_unhandled_input(true)
				SoundManager.play(LAND_SOUND, -4.0, 0.04)
				SoundManager.play(STEP_L, -8.0, 0.04)
				if player.camera:
					var cam_tw = create_tween()
					cam_tw.tween_property(player.camera, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				spawn_point = player.global_position

		if terrain and terrain.has_method("update_player_pos"):
			terrain.update_player_pos(player.global_position)
		if player.global_position.y < -30.0:
			player.global_position = spawn_point
			player.velocity = Vector3.ZERO
			if player.has_method("reset_for_respawn"): player.reset_for_respawn()
