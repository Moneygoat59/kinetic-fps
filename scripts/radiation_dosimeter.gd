class_name RadiationDosimeter
extends Node

const CLICKS: Array[AudioStream] = [
	preload("res://audio/ui/Audio/click_001.ogg"),
	preload("res://audio/ui/Audio/click_002.ogg"),
	preload("res://audio/ui/Audio/click_003.ogg"),
	preload("res://audio/ui/Audio/click_004.ogg"),
]
const CHIME_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")

var player: CharacterBody3D
var pylons: Array[Node3D] = []
var active_idx: int = 0
var click_player: AudioStreamPlayer
var chime_player: AudioStreamPlayer

var click_timer: float = 0.0
var hud_canvas: CanvasLayer
var hud_title: Label
var hud_bearing: Label
var hud_signal: Label

func setup_dosimeter(target_player: CharacterBody3D, pylon_list: Array) -> void:
	player = target_player
	for p in pylon_list: if p is Node3D: pylons.append(p)
	active_idx = 0

	click_player = AudioStreamPlayer.new()
	click_player.volume_db = -11.0; add_child(click_player)

	chime_player = AudioStreamPlayer.new()
	chime_player.stream = CHIME_SOUND
	chime_player.volume_db = -5.0; add_child(chime_player)

	_setup_hud()
	_update_active_pylon()

func _setup_hud() -> void:
	hud_canvas = CanvasLayer.new(); hud_canvas.layer = 12; add_child(hud_canvas)
	var panel = VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-280, 24)
	hud_canvas.add_child(panel)

	hud_title = Label.new()
	hud_title.text = "[ ☢ RAD-DOSIMETER MK-IV ☢ ]"
	hud_title.modulate = Color(1.0, 0.85, 0.25); panel.add_child(hud_title)

	hud_bearing = Label.new()
	hud_bearing.text = "BEARING: SEARCHING..."; hud_bearing.modulate = Color(1.0, 0.95, 0.4)
	panel.add_child(hud_bearing)

	hud_signal = Label.new()
	hud_signal.modulate = Color(1.0, 0.70, 0.15); panel.add_child(hud_signal)

func _update_active_pylon() -> void:
	for i in range(pylons.size()): pylons[i].set_station_active(i == active_idx)

func _process(delta: float) -> void:
	if not player or active_idx >= pylons.size():
		if active_idx >= pylons.size() and hud_bearing:
			hud_bearing.text = "BEARING: ▲ BLAST DOOR AHEAD"
			hud_signal.text = "STATUS: BUNKER AIRLOCK [100%]"
		return

	var target = pylons[active_idx]
	var p_pos = player.global_position
	if target.check_player_proximity(p_pos):
		_on_pylon_reached()
		return

	var to_t = target.global_position - p_pos; to_t.y = 0.0
	var dist = to_t.length(); var to_dir = to_t.normalized()

	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	var look = -cam.global_transform.basis.z if cam else -player.global_transform.basis.z
	look.y = 0.0; look = look.normalized()

	var dot = look.dot(to_dir)
	var cross_y = look.cross(to_dir).y

	var bearing = "▲ STRAIGHT AHEAD"
	if dot < -0.45: bearing = "▼ BEHIND YOU"
	elif cross_y > 0.35: bearing = "▶ HARD RIGHT"
	elif cross_y < -0.35: bearing = "◀ HARD LEFT"
	elif cross_y > 0.1: bearing = "↗ SLIGHT RIGHT"
	elif cross_y < -0.1: bearing = "↖ SLIGHT LEFT"

	var sig = clampf(1.0 - (dist / 85.0), 0.08, 1.0) * (0.35 + 0.65 * maxf(0.0, dot))

	click_timer -= delta
	var click_rate = lerpf(1.6, 0.06, sig)
	if click_timer <= 0.0:
		click_timer = click_rate * randf_range(0.85, 1.15)
		click_player.stream = CLICKS[randi() % CLICKS.size()]
		click_player.pitch_scale = randf_range(0.9, 1.25); click_player.play()

	hud_title.text = "[ ☢ RAD-DOSIMETER ] WAYPOINT %02d/%02d (%dm)" % [target.station_id, pylons.size(), int(dist)]
	hud_bearing.text = "BEARING: %s" % bearing
	var pips = int(sig * 10.0); var bar = "SIGNAL: ["
	for i in range(10): bar += "|" if i < pips else "."
	bar += "] %d%%" % int(sig * 100.0); hud_signal.text = bar

func _on_pylon_reached() -> void:
	chime_player.play()
	active_idx += 1
	_update_active_pylon()
