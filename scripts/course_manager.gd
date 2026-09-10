class_name CourseManager
extends Node

static var instance: CourseManager

var timer_running: bool = false
var elapsed_time: float = 0.0
var best_time: float = -1.0
var start_point: Vector3 = Vector3(0, 1.0, 8.0)
var current_checkpoint: Vector3 = Vector3(0, 1.0, 8.0)
var player: CharacterBody3D

@onready var timer_label: Label = $TimerHUD/TimerLabel
@onready var record_label: Label = $TimerHUD/RecordLabel
@onready var checkpoint_label: Label = $TimerHUD/CheckpointNotice
@onready var victory_panel: PanelContainer = $TimerHUD/VictoryPanel
@onready var victory_time_label: Label = $TimerHUD/VictoryPanel/VBox/TimeLabel

func _ready():
	instance = self
	victory_panel.visible = false
	_update_hud()

func register_player(p: CharacterBody3D) -> void:
	player = p
	current_checkpoint = start_point

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta
		_update_hud()
	
	# Fall hazard check
	if player and player.global_position.y < -22.0:
		respawn_player()

func start_course() -> void:
	if not timer_running:
		timer_running = true
		elapsed_time = 0.0
		victory_panel.visible = false
		_show_notice("TRIAL STARTED! GO!", Color(0.2, 1.0, 0.4))
		if player and player.has_method("_play_tone_slide"):
			player._play_tone_slide(400.0, 800.0, 0.12)

func reach_checkpoint(pos: Vector3, checkpoint_num: int, total: int) -> void:
	current_checkpoint = pos
	_show_notice("CHECKPOINT %d/%d" % [checkpoint_num, total], Color(0.3, 0.8, 1.0))
	if player and player.has_method("_play_tone_slide"):
		player._play_tone_slide(500.0, 750.0, 0.08)

func finish_course() -> void:
	if not timer_running:
		return
	timer_running = false
	var is_new_record = false
	if best_time < 0.0 or elapsed_time < best_time:
		best_time = elapsed_time
		is_new_record = true

	victory_panel.visible = true
	var rec_text = " [NEW RECORD!]" if is_new_record else ""
	victory_time_label.text = "TIME: %s%s\nBEST: %s" % [_format_time(elapsed_time), rec_text, _format_time(best_time)]
	_show_notice("COURSE CLEARED!", Color(1.0, 0.85, 0.2))
	
	if player and player.has_method("_play_tone_slide"):
		# Fanfare tones
		player._play_tone_slide(440.0, 660.0, 0.15)
		get_tree().create_timer(0.16).timeout.connect(func(): if player: player._play_tone_slide(660.0, 880.0, 0.25))

func respawn_player() -> void:
	if player:
		player.global_position = current_checkpoint + Vector3(0, 0.5, 0)
		player.velocity = Vector3.ZERO
		if player.has_method("reset_for_respawn"):
			player.reset_for_respawn()
		if player.has_method("_play_tone_slide"):
			player._play_tone_slide(300.0, 150.0, 0.1, true)
		_show_notice("RESET TO CHECKPOINT", Color(1.0, 0.3, 0.3))

func restart_full_run() -> void:
	timer_running = false
	elapsed_time = 0.0
	current_checkpoint = start_point
	respawn_player()
	victory_panel.visible = false
	_show_notice("TRIAL RESET", Color(0.7, 0.7, 0.8))

func _update_hud() -> void:
	timer_label.text = "TIME: %s" % _format_time(elapsed_time)
	if best_time > 0.0:
		record_label.text = "BEST: %s" % _format_time(best_time)
	else:
		record_label.text = "BEST: --:--.--"

func _format_time(t: float) -> String:
	var mins = int(t) / 60
	var secs = int(t) % 60
	var msecs = int((t - int(t)) * 100)
	return "%02d:%02d.%02d" % [mins, secs, msecs]

func _show_notice(text: String, color: Color) -> void:
	checkpoint_label.text = text
	checkpoint_label.add_theme_color_override("font_color", color)
	checkpoint_label.visible = true
	var tween = create_tween()
	tween.tween_interval(1.6)
	tween.tween_callback(func(): checkpoint_label.visible = false)
