class_name AmberToxicityEffect
extends Node

const DRINK_SOUND = preload("res://audio/sci-fi/Audio/slime_000.ogg")
const LUB_SOUND = preload("res://audio/impacts/Audio/impactSoft_heavy_000.ogg")
const DUB_SOUND = preload("res://audio/impacts/Audio/impactSoft_heavy_001.ogg")
const TOXIC_SHADER = preload("res://shaders/amber_toxicity.gdshader")
const FONT_LIB = preload("res://scripts/ui/font_library.gd")

const BOOST_DURATION: float = 15.0
const BOOST_MULT: float = 1.35
const TOXICITY_DURATION: float = 7.0

var player_ref: CharacterBody3D
var base_speed: float = 5.2
var is_boosted: bool = false
var boost_timer: float = 0.0

var toxicity_timer: float = 0.0
var heart_timer: float = 0.0
var heart_interval: float = 0.65
var dub_pending: bool = false
var dub_timer: float = 0.0
var heart_pulse: float = 0.0

var canvas_layer: CanvasLayer
var screen_overlay: ColorRect
var shader_mat: ShaderMaterial
var buff_label: Label
var lub_player: AudioStreamPlayer
var dub_player: AudioStreamPlayer
var drink_player: AudioStreamPlayer

static func apply_to_player(player: Node) -> void:
	if not player or not (player is CharacterBody3D): return
	var effect = player.get_node_or_null("AmberToxicityEffect")
	if not effect:
		var script = load("res://scripts/amber_toxicity_effect.gd")
		effect = script.new()
		effect.name = "AmberToxicityEffect"
		player.add_child(effect)
	effect.trigger()

func _ready() -> void:
	if not player_ref: player_ref = get_parent() as CharacterBody3D
	if not drink_player: _init_audio()
	if not screen_overlay: _init_visuals()

func _init_audio() -> void:
	drink_player = AudioStreamPlayer.new(); drink_player.stream = DRINK_SOUND; drink_player.volume_db = 2.0; add_child(drink_player)
	lub_player = AudioStreamPlayer.new(); lub_player.stream = LUB_SOUND; add_child(lub_player)
	dub_player = AudioStreamPlayer.new(); dub_player.stream = DUB_SOUND; add_child(dub_player)

func _init_visuals() -> void:
	canvas_layer = CanvasLayer.new(); canvas_layer.layer = 12; add_child(canvas_layer)
	shader_mat = ShaderMaterial.new(); shader_mat.shader = TOXIC_SHADER
	screen_overlay = ColorRect.new(); screen_overlay.material = shader_mat
	screen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; screen_overlay.visible = false
	canvas_layer.add_child(screen_overlay)

	buff_label = Label.new()
	buff_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	buff_label.offset_left = 10.0; buff_label.offset_top = -40.0; buff_label.offset_right = 240.0; buff_label.offset_bottom = -24.0
	buff_label.add_theme_font_size_override("font_size", 10)
	buff_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	var f = FONT_LIB.kinetic_font(); if f: buff_label.add_theme_font_override("font", f)
	buff_label.visible = false
	canvas_layer.add_child(buff_label)

func trigger() -> void:
	if not player_ref: player_ref = get_parent() as CharacterBody3D
	if not drink_player: _init_audio()
	if not screen_overlay: _init_visuals()
	if not player_ref: return
	if player_ref.has_method("take_hit"): player_ref.take_hit(20.0)
	if drink_player and is_inside_tree():
		drink_player.pitch_scale = randf_range(0.92, 1.08); drink_player.play()

	toxicity_timer = TOXICITY_DURATION; heart_timer = 0.05; heart_interval = 0.65
	dub_pending = false; heart_pulse = 1.0
	if screen_overlay: screen_overlay.visible = true

	if not is_boosted and player_ref.get("motor"):
		base_speed = player_ref.motor.ground_speed
		player_ref.motor.ground_speed = base_speed * BOOST_MULT
		is_boosted = true
	boost_timer = BOOST_DURATION
	if buff_label: buff_label.visible = true

func _process(delta: float) -> void:
	if delta <= 0.0: return
	if is_boosted:
		boost_timer -= delta
		if boost_timer <= 0.0:
			is_boosted = false
			if player_ref and player_ref.get("motor"): player_ref.motor.ground_speed = base_speed
			if buff_label: buff_label.visible = false
		elif buff_label: buff_label.text = "AMBER SURGE: %02.0fs" % ceilf(boost_timer)

	if toxicity_timer > 0.0:
		toxicity_timer -= delta
		if toxicity_timer <= 0.0:
			if screen_overlay: screen_overlay.visible = false
			if shader_mat:
				shader_mat.set_shader_parameter("intensity", 0.0); shader_mat.set_shader_parameter("pulse", 0.0)
		else:
			var intensity = clampf(toxicity_timer / TOXICITY_DURATION, 0.0, 1.0)
			heart_timer -= delta
			if heart_timer <= 0.0:
				_beat_lub(intensity)
				heart_interval = lerpf(1.05, 0.65, intensity); heart_timer = heart_interval
				dub_pending = true; dub_timer = 0.16
			if dub_pending:
				dub_timer -= delta
				if dub_timer <= 0.0:
					dub_pending = false; _beat_dub(intensity)

			heart_pulse = maxf(0.0, heart_pulse - delta * 3.5)
			if shader_mat:
				shader_mat.set_shader_parameter("intensity", intensity)
				shader_mat.set_shader_parameter("pulse", heart_pulse)

func _beat_lub(intensity: float) -> void:
	if lub_player and is_inside_tree():
		lub_player.volume_db = lerpf(-22.0, 1.5, intensity); lub_player.pitch_scale = randf_range(0.70, 0.74); lub_player.play()
	heart_pulse = 1.0

func _beat_dub(intensity: float) -> void:
	if dub_player and is_inside_tree():
		dub_player.volume_db = lerpf(-24.0, -1.5, intensity); dub_player.pitch_scale = randf_range(0.80, 0.84); dub_player.play()
	heart_pulse = 0.75

func _exit_tree() -> void:
	if is_boosted and player_ref and player_ref.get("motor"):
		player_ref.motor.ground_speed = base_speed
