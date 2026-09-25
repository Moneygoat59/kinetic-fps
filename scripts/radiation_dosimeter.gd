class_name RadiationDosimeter
extends Node

signal track_completed(channel: String)

const CHIME_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg"); const UPGRADE_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
static var dev_meter_tex: ImageTexture; static var metal_norm_tex: ImageTexture; static var beep_wav: AudioStreamWAV

static func _tex(path: String) -> ImageTexture:
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if (img and not img.is_empty()) else null

static func _load_glb(res_path: String) -> Node3D:
	var doc = GLTFDocument.new(); var state = GLTFState.new()
	return doc.generate_scene(state) as Node3D if doc.append_from_file(ProjectSettings.globalize_path(res_path), state) == OK else null

static func _get_beep() -> AudioStreamWAV:
	if beep_wav: return beep_wav
	beep_wav = AudioStreamWAV.new(); beep_wav.format = AudioStreamWAV.FORMAT_8_BITS; beep_wav.mix_rate = 22050
	var samples = 1100; var data = PackedByteArray(); data.resize(samples)
	for i in range(samples):
		var env = sin(float(i) / float(samples) * PI)
		data[i] = clampi(int(128.0 + 100.0 * sin(float(i) * 0.26) * env), 0, 255)
	beep_wav.data = data; return beep_wav

var player: CharacterBody3D; var pylons: Array[Node3D] = []; var active_idx: int = 0
var beep_player: AudioStreamPlayer; var chime_player: AudioStreamPlayer; var upgrade_player: AudioStreamPlayer
var beep_timer: float = 0.0; var held_tracker: Node3D; var tracker_light: OmniLight3D; var meter_mat: StandardMaterial3D; var led_mat: StandardMaterial3D
var lbl_header: Label3D; var lbl_bar: Label3D; var lbl_status: Label3D
var led_segs: Array[MeshInstance3D] = []; var seg_mats: Array[StandardMaterial3D] = []
var channel_name: String = "104.2 MHz // AMBER"; var channel_color: Color = Color(1.0, 0.65, 0.12); var destination_text: String = "CENTRAL HUB"

func setup_dosimeter(target_player: CharacterBody3D, pylon_list: Array, ch_name: String = "104.2 MHz // AMBER", col: Color = Color(1.0, 0.65, 0.12), dest_text: String = "CENTRAL HUB") -> void:
	player = target_player
	beep_player = AudioStreamPlayer.new(); beep_player.stream = _get_beep(); beep_player.volume_db = -10.0; add_child(beep_player)
	chime_player = AudioStreamPlayer.new(); chime_player.stream = CHIME_SOUND; chime_player.volume_db = -5.0; add_child(chime_player)
	upgrade_player = AudioStreamPlayer.new(); upgrade_player.stream = UPGRADE_SOUND; upgrade_player.volume_db = -4.0; add_child(upgrade_player)
	_setup_held_viewmodel(); set_track(pylon_list, ch_name, col, dest_text, false)

func set_track(pylon_list: Array, ch_name: String, col: Color, dest_text: String, play_sfx: bool = true) -> void:
	pylons.clear()
	for p in pylon_list: if p is Node3D: pylons.append(p)
	active_idx = 0; channel_name = ch_name; channel_color = col; destination_text = dest_text
	if tracker_light: tracker_light.light_color = col
	if meter_mat: meter_mat.emission = col
	if led_mat: led_mat.emission = col
	for lbl in [lbl_header, lbl_bar, lbl_status]: if lbl: lbl.modulate = col
	for m in seg_mats: m.albedo_color = col; m.emission = col
	if play_sfx and upgrade_player: upgrade_player.play()
	_update_active_pylon()

func _setup_held_viewmodel() -> void:
	if not player: return
	var cam = player.get_node_or_null("Head/Camera3D"); if not cam: return
	if not dev_meter_tex: dev_meter_tex = _tex("res://textures/device_meter_analog.png"); metal_norm_tex = _tex("res://textures/worn_metal_normal.png")
	held_tracker = Node3D.new(); held_tracker.name = "HeldFieldTracker"
	held_tracker.position = Vector3(0.146, -0.364, -0.182); held_tracker.rotation_degrees = Vector3(6.0, -119.2, 21.6); cam.add_child(held_tracker)
	var dev = _load_glb("res://models/finder_device.glb")
	if dev:
		dev.scale = Vector3(0.35, 0.35, 0.35)
		var mi = dev.find_child("Multmeter_Cube", true, false) as MeshInstance3D
		if mi:
			meter_mat = StandardMaterial3D.new(); meter_mat.albedo_texture = dev_meter_tex; meter_mat.emission_enabled = true; meter_mat.emission_texture = dev_meter_tex; meter_mat.emission = channel_color; meter_mat.emission_energy_multiplier = 1.4; meter_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mi.set_surface_override_material(2, meter_mat)
			var b_mat = _mat(METAL_TEX, Color(0.24, 0.26, 0.30), 0.7, 0.8)
			mi.set_surface_override_material(0, b_mat); mi.set_surface_override_material(1, b_mat); mi.set_surface_override_material(4, b_mat)
			mi.set_surface_override_material(3, _mat(METAL_TEX, Color(0.14, 0.15, 0.16), 0.5, 0.9))
		held_tracker.add_child(dev); _setup_screen_ui(dev)
	tracker_light = OmniLight3D.new(); tracker_light.position = Vector3(0.06, 0.75, 0.0); tracker_light.light_color = channel_color; tracker_light.light_energy = 0.7; tracker_light.omni_range = 1.0; held_tracker.add_child(tracker_light)

func _setup_screen_ui(dev: Node3D) -> void:
	var font = FontLibrary.tech_font(); var scr = Node3D.new()
	scr.position = Vector3(0.064, 0.730, 0.0); scr.rotation.y = deg_to_rad(90.0); dev.add_child(scr)
	lbl_header = _label(scr, Vector3(0.0, 0.038, 0.003), 16, 0.00115, font); lbl_bar = _label(scr, Vector3(0.0, 0.010, 0.003), 22, 0.0014, font); lbl_status = _label(scr, Vector3(0.0, -0.018, 0.003), 15, 0.0011, font)
	led_segs.clear(); seg_mats.clear()
	for i in range(10):
		var sm = StandardMaterial3D.new(); sm.albedo_color = channel_color; sm.emission_enabled = true; sm.emission = channel_color; sm.emission_energy_multiplier = 0.05
		var m_box = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = Vector3(0.0065, 0.011, 0.002); m_box.mesh = bm; m_box.material_override = sm; m_box.position = Vector3(-0.045 + float(i) * 0.010, -0.038, 0.003); scr.add_child(m_box); led_segs.append(m_box); seg_mats.append(sm)
	var led = MeshInstance3D.new(); var cm = CylinderMesh.new(); cm.top_radius = 0.010; cm.bottom_radius = 0.010; cm.height = 0.010; led.mesh = cm
	led_mat = StandardMaterial3D.new(); led_mat.albedo_color = channel_color; led_mat.emission_enabled = true; led_mat.emission = channel_color; led_mat.emission_energy_multiplier = 0.8
	led.position = Vector3(0.075, 0.60, 0.11); led.rotation.z = deg_to_rad(90.0); led.material_override = led_mat; dev.add_child(led)

func _label(parent: Node3D, pos: Vector3, sz: int, px_sz: float, f: Font) -> Label3D:
	var l = Label3D.new(); l.position = pos; l.font = f; l.font_size = sz; l.pixel_size = px_sz; l.modulate = channel_color; l.no_depth_test = true; l.render_priority = 2; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; parent.add_child(l); return l

func _mat(tex: Texture2D, col: Color, rough: float, met: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = col; m.roughness = rough; m.metallic = met; m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if metal_norm_tex: m.normal_enabled = true; m.normal_texture = metal_norm_tex; m.normal_scale = 1.0
	return m

func _update_active_pylon() -> void:
	for i in range(pylons.size()):
		if is_instance_valid(pylons[i]) and pylons[i].has_method("set_station_active"): pylons[i].set_station_active(i == active_idx)

func _process(delta: float) -> void:
	if not player: return
	if active_idx >= pylons.size():
		if lbl_header: lbl_header.text = "[ %s ]" % channel_name
		if lbl_bar: lbl_bar.text = "[||||||||||]"
		if lbl_status: lbl_status.text = "★ %s REACHED ★" % destination_text
		for m in seg_mats: m.emission_energy_multiplier = 3.0
		return

	var target = pylons[active_idx]
	var p_pos = player.global_position if player.is_inside_tree() else player.position
	var t_pos = target.global_position if target.is_inside_tree() else target.position
	if target.has_method("check_player_proximity") and target.check_player_proximity(p_pos):
		_on_pylon_reached(); return

	var to_t = t_pos - p_pos; to_t.y = 0.0
	var dist = to_t.length()
	var raw_prox = clampf(1.0 - ((dist - 7.0) / 135.0), 0.0, 1.0)
	var t = Time.get_ticks_msec() * 0.001
	var noise = sin(t * 3.8) * 0.045 + cos(t * 7.1) * 0.025 + randf_range(-0.02, 0.02)
	var prox = clampf(raw_prox + (noise if raw_prox > 0.01 else 0.0), 0.0, 1.0)
	var pips = clampi(int(prox * 10.0), 0, 10)

	var bar_str = "[" + "|".repeat(pips) + ".".repeat(10 - pips) + "]"
	var status_str = "PROXIMITY: CRITICAL" if prox > 0.85 else ("PROXIMITY: STRONG" if prox > 0.60 else ("PROXIMITY: ELEVATED" if prox > 0.35 else ("PROXIMITY: MODERATE" if prox > 0.12 else "PROXIMITY: WEAK")))
	if lbl_header: lbl_header.text = "[ %s ]" % channel_name
	if lbl_bar: lbl_bar.text = bar_str
	if lbl_status: lbl_status.text = status_str

	for i in range(seg_mats.size()):
		if i < pips:
			var flicker = lerpf(1.8, 3.8, (sin(t * 18.0) + 1.0) * 0.5) if i == pips - 1 else 2.6
			seg_mats[i].emission_energy_multiplier = flicker
		else: seg_mats[i].emission_energy_multiplier = 0.05

	if led_mat: led_mat.emission_energy_multiplier = lerpf(led_mat.emission_energy_multiplier, 0.4, delta * 6.0)
	if held_tracker: held_tracker.position.y = -0.364 + sin(Time.get_ticks_msec() * 0.003) * 0.004

	beep_timer -= delta
	if beep_timer <= 0.0:
		beep_timer = lerpf(2.2, 0.12, prox * prox) * randf_range(0.90, 1.10)
		beep_player.pitch_scale = lerpf(0.85, 1.45, prox); beep_player.volume_db = lerpf(-14.0, -8.0, prox); beep_player.play()
		if led_mat: led_mat.emission_energy_multiplier = 4.5
		if tracker_light: tracker_light.light_energy = lerpf(0.5, 1.8, prox)

func _on_pylon_reached() -> void:
	chime_player.play(); active_idx += 1; _update_active_pylon()
	if active_idx >= pylons.size(): track_completed.emit(channel_name)

func _exit_tree() -> void:
	if is_instance_valid(held_tracker): held_tracker.queue_free()
