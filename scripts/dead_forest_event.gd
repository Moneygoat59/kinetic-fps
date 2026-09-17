class_name DeadForestEvent
extends Node3D

const RUMBLE_BASS = preload("res://audio/sci-fi/Audio/lowFrequency_explosion_000.ogg")
const CRUNCH_SOUND = preload("res://audio/sci-fi/Audio/explosionCrunch_000.ogg")
const KLAXON_ALARM = preload("res://audio/sci-fi/Audio/forceField_000.ogg")
const ALERT_CHIME = preload("res://audio/digital/Audio/threeTone1.ogg")

const BUNKER_SCRIPT = preload("res://scripts/small_bunker.gd")
const PYLON_SCRIPT = preload("res://scripts/nuclear_pylon.gd")
const DOSIMETER_SCRIPT = preload("res://scripts/radiation_dosimeter.gd")

@export var player: CharacterBody3D
@export var terrain: Node3D

var wander_distance: float = 0.0
var wander_time: float = 0.0
var last_pos: Vector3 = Vector3.ZERO
var spawn_pos: Vector3 = Vector3.ZERO
var event_triggered: bool = false
var bunker_instance: Node3D
var pylons: Array[Node3D] = []
var dosimeter: Node

func _ready() -> void:
	if player:
		last_pos = player.global_position; spawn_pos = player.global_position

func _physics_process(delta: float) -> void:
	if not player: return
	var p_pos = player.global_position

	if not event_triggered:
		var d = p_pos.distance_to(last_pos)
		if d > 0.05 and d < 10.0: wander_distance += d
		last_pos = p_pos
		wander_time += delta

		if wander_time >= 25.0 and wander_distance >= 42.0 and p_pos.distance_to(spawn_pos) >= 18.0:
			_trigger_event()
	else:
		if bunker_instance and not bunker_instance.is_claimed:
			if bunker_instance.check_interaction(p_pos):
				_on_dosimeter_acquired()

func _trigger_event() -> void:
	event_triggered = true
	var p_pos = player.global_position
	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D

	# 3.2s violent sustained seismic camera shudder
	if cam:
		var tw = create_tween().set_loops(18)
		tw.tween_property(cam, "h_offset", randf_range(-0.28, 0.28), 0.08)
		tw.tween_property(cam, "v_offset", randf_range(-0.22, 0.22), 0.08)
		tw.finished.connect(func(): if is_instance_valid(cam): cam.h_offset = 0.0; cam.v_offset = 0.0)

	_play_sound(RUMBLE_BASS, 6.0, 0.65)
	_play_sound(CRUNCH_SOUND, 4.0, 0.8)
	_play_sound(KLAXON_ALARM, 2.0, 0.95)
	_show_alarm_flash()

	# Spawn Small Bunker 26m directly ahead in player view
	var fwd = -cam.global_transform.basis.z if cam else -player.global_transform.basis.z
	fwd.y = 0.0; fwd = fwd.normalized()
	var b_pos = p_pos + fwd * 26.0

	bunker_instance = BUNKER_SCRIPT.new()
	bunker_instance.build_bunker(terrain, b_pos.x, b_pos.z)
	add_child(bunker_instance)

	_show_broadcast_banner()

func _play_sound(stream: AudioStream, vol: float, pitch: float) -> void:
	var a = AudioStreamPlayer.new(); a.stream = stream; a.volume_db = vol
	a.pitch_scale = pitch; add_child(a); a.play()
	a.finished.connect(a.queue_free)

func _show_alarm_flash() -> void:
	var canvas = CanvasLayer.new(); canvas.layer = 15; add_child(canvas)
	var rect = ColorRect.new(); rect.color = Color(1.0, 0.55, 0.1, 0.45)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect)
	var tw = create_tween()
	tw.tween_property(rect, "color:a", 0.0, 3.2).set_trans(Tween.TRANS_SINE)
	tw.finished.connect(canvas.queue_free)

func _show_broadcast_banner() -> void:
	var canvas = CanvasLayer.new(); canvas.layer = 14; add_child(canvas)
	var panel = VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE); panel.position.y = 50; canvas.add_child(panel)

	var l1 = Label.new(); l1.text = "[ ⚠ EMERGENCY AIRDROP DETECTED ⚠ ]"
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l1.modulate = Color(1.0, 0.35, 0.2)
	panel.add_child(l1)

	var l2 = Label.new(); l2.text = ">>> ENTER SURVIVAL OUTPOST AHEAD TO RETRIEVE EQUIPMENT <<<"
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l2.modulate = Color(1.0, 0.85, 0.3)
	panel.add_child(l2)

	_play_sound(ALERT_CHIME, 4.0, 1.0)
	var tw = create_tween()
	tw.tween_interval(5.5); tw.tween_property(panel, "modulate:a", 0.0, 1.5)
	tw.finished.connect(canvas.queue_free)

func _on_dosimeter_acquired() -> void:
	var bx = bunker_instance.global_position.x
	var bz = bunker_instance.global_position.z
	_spawn_waypoints(bx, bz)

	dosimeter = DOSIMETER_SCRIPT.new(); add_child(dosimeter)
	dosimeter.setup_dosimeter(player, pylons)

func _spawn_waypoints(start_x: float, start_z: float) -> void:
	var count = 8
	for i in range(1, count + 1):
		var t = float(i) / float(count)
		var wx = lerpf(start_x, 0.0, t)
		var wz = lerpf(start_z, -174.0, t)
		if i < count:
			wx += sin(t * PI * 3.5) * 11.0
		var p = PYLON_SCRIPT.new()
		p.station_id = i; p.build_pylon(terrain, wx, wz)
		add_child(p); pylons.append(p)
