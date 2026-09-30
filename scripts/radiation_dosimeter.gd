class_name RadiationDosimeter
extends Node
## Field dosimeter logic: follows the active pylon chain of a channel, turns distance into a noisy signal, paces the Geiger
## clicks and advances as pylons are reached (track_completed when the chain ends). Everything the player sees is drawn by
## DosimeterView (needle, pixel display, LEDs); this node only decides what it shows and plays the sounds. With no track
## (not yet programmed at a route terminal) it rests silent. Reaching a relay: a soft two-pip lock in the device's own voice.

signal track_completed(channel: String)

const UPGRADE_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")
const NEAR_DIST := 7.0          # signal saturates inside this range (m)
const FAR_SPAN := 135.0         # ... and fades to nothing over this much further
const ARRIVED_BLINK_HZ := 1.5


var player: CharacterBody3D
var pylons: Array[Node3D] = []
var active_idx: int = 0
var view: DosimeterView
var held_tracker: Node3D        # the viewmodel root (the view), kept for callers that look it up
var beep_player: AudioStreamPlayer
var chime_player: AudioStreamPlayer
var upgrade_player: AudioStreamPlayer
var beep_timer: float = 0.0
var channel_name: String = "CHANNEL 01 // HUB"
var channel_color: Color = Color(1.0, 0.65, 0.12)
var destination_text: String = "CENTRAL HUB AHEAD"


func setup_dosimeter(target_player: CharacterBody3D, pylon_list: Array, ch_name: String = "CHANNEL 01 // HUB",
		col: Color = Color(1.0, 0.65, 0.12), dest_text: String = "CENTRAL HUB AHEAD") -> void:
	if target_player == null:
		return
	player = target_player
	beep_player = _player(DosimeterSounds.beep(), -10.0)
	chime_player = _player(DosimeterSounds.lock(), -12.0)
	upgrade_player = _player(UPGRADE_SOUND, -4.0)
	var cam := player.get_node_or_null("Head/Camera3D") as Camera3D
	if cam:
		view = DosimeterView.new()
		view.build(cam)
		held_tracker = view
	set_track(pylon_list, ch_name, col, dest_text, false)


func set_track(pylon_list: Array, ch_name: String, col: Color, dest_text: String, play_sfx: bool = true) -> void:
	for p in pylons:                              # release the old track's target (it would keep waiting otherwise)
		if is_instance_valid(p) and p.has_method("set_station_active"):
			p.set_station_active(false)
	pylons.clear()
	for p in pylon_list:
		if p is Node3D:
			pylons.append(p)
	active_idx = 0
	channel_name = ch_name
	channel_color = col
	destination_text = dest_text
	if view:
		view.set_channel(col)
	if play_sfx and upgrade_player:
		upgrade_player.play()
	_update_active_pylon()


func _player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume
	add_child(p)
	return p


func _update_active_pylon() -> void:
	for i in pylons.size():
		if is_instance_valid(pylons[i]) and pylons[i].has_method("set_station_active"):
			pylons[i].set_station_active(i == active_idx)


func _process(delta: float) -> void:
	if player == null or view == null:
		return
	if pylons.is_empty():
		view.show_reading(0.0, 0)                 # no route programmed: at rest, silent
		return
	var t := Time.get_ticks_msec() * 0.001
	if active_idx >= pylons.size():
		view.show_arrived(fmod(t * ARRIVED_BLINK_HZ, 1.0) < 0.6)
		return
	var target := pylons[active_idx]
	if not is_instance_valid(target):
		_on_pylon_reached()
		return
	var p_pos := player.global_position
	if target.has_method("check_player_proximity") and target.check_player_proximity(p_pos):
		_on_pylon_reached()
		return
	var to_t := target.global_position - p_pos
	to_t.y = 0.0
	var raw := clampf(1.0 - (to_t.length() - NEAR_DIST) / FAR_SPAN, 0.0, 1.0)
	var noise := sin(t * 3.8) * 0.045 + cos(t * 7.1) * 0.025 + randf_range(-0.02, 0.02)
	var level := clampf(raw + (noise if raw > 0.01 else 0.0), 0.0, 1.0)
	view.show_reading(level, clampi(int(level * 10.0), 0, 10))
	beep_timer -= delta
	if beep_timer <= 0.0:
		beep_timer = lerpf(2.2, 0.12, level * level) * randf_range(0.9, 1.1)
		beep_player.pitch_scale = lerpf(0.85, 1.45, level)
		beep_player.volume_db = lerpf(-14.0, -8.0, level)
		beep_player.play()
		view.click(level)


func _on_pylon_reached() -> void:
	chime_player.play()
	active_idx += 1
	_update_active_pylon()
	if active_idx >= pylons.size():
		track_completed.emit(channel_name)


func _exit_tree() -> void:
	if is_instance_valid(held_tracker):
		held_tracker.queue_free()
