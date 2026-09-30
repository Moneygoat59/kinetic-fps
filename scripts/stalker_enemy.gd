class_name StalkerEnemy
extends CharacterBody3D

signal struck_player   # an attack landed (ForestNightDirector wakes the walker on it)

enum Phase { OBSERVER, STALKER, HUNTING }
enum State { IDLE, PROWL, CHASE, ATTACK, REPULSED, RETREAT }

const MODEL_SCENE = preload("res://models/stalker_monster.glb")
const ROAR_SND = preload("res://audio/stalker/roar.mp3"); const BREATH_SND = preload("res://audio/stalker/breathing.mp3")
const SLASH_SND = preload("res://audio/rpg/Audio/knifeSlice.ogg"); const CRUNCH_SND = preload("res://audio/sci-fi/Audio/explosionCrunch_000.ogg")
const ZAP_SND = preload("res://audio/sci-fi/Audio/forceField_000.ogg"); const STEP_SND = preload("res://audio/impacts/Audio/impactWood_heavy_000.ogg")

@export var current_phase: Phase = Phase.OBSERVER
var current_state: State = State.IDLE
var player: CharacterBody3D; var terrain: Node3D; var pylons: Array[Node3D] = []
var anim: AnimationPlayer; var audio: AudioStreamPlayer3D; var audio_crunch: AudioStreamPlayer3D
var audio_step: AudioStreamPlayer3D; var audio_breath: AudioStreamPlayer3D
var eye_light: OmniLight3D; var chest_light: OmniLight3D; var model_root: Node3D
var attack_cd: float = 0.0; var repulse_cd: float = 0.0; var step_timer: float = 0.0
var hunt_delay: float = 0.0; var repulse_dir: Vector3 = Vector3.FORWARD; var target_facing: Vector3 = Vector3.FORWARD
var unstuck_timer: float = 0.0; var unstuck_dir: Vector3 = Vector3.FORWARD; var unstuck_sign: float = 1.0
var wall_avoid_timer: float = 0.0; var wall_avoid_dir: Vector3 = Vector3.ZERO
var last_check_pos: Vector3 = Vector3.ZERO; var progress_check_timer: float = 0.0

func _ready() -> void: _setup_visuals(); _setup_body()

func _setup_visuals() -> void:
	if find_child("AnimationPlayer", true, false): return
	model_root = MODEL_SCENE.instantiate() as Node3D; model_root.scale = Vector3(0.55, 0.55, 0.55); add_child(model_root)
	anim = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim:
		for an in ["Idle1_Action", "Idle2_Action", "Walk1_Action", "Walk2_Action", "Sniff_Action"]:
			if anim.has_animation(an): anim.get_animation(an).loop_mode = Animation.LOOP_LINEAR
	for m in model_root.find_children("*", "MeshInstance3D"):
		var mat = (m as MeshInstance3D).get_active_material(0)
		if mat is StandardMaterial3D:
			mat = mat.duplicate(); mat.emission_enabled = true; mat.emission = Color(0.85, 0.32, 0.06); mat.emission_energy_multiplier = 0.5
			(m as MeshInstance3D).set_surface_override_material(0, mat)
	eye_light = OmniLight3D.new(); eye_light.position = Vector3(0.0, 2.76, 0.65); eye_light.light_color = Color(1.0, 0.45, 0.08); eye_light.light_energy = 5.0; eye_light.omni_range = 10.0; add_child(eye_light)
	chest_light = OmniLight3D.new(); chest_light.position = Vector3(0.0, 2.18, 0.05); chest_light.light_color = Color(0.9, 0.28, 0.04); chest_light.light_energy = 3.0; chest_light.omni_range = 7.0; add_child(chest_light)

func _setup_body() -> void:
	var cs = CollisionShape3D.new(); var cap = CapsuleShape3D.new()
	cap.radius = 0.45; cap.height = 2.5; cs.shape = cap; cs.position = Vector3(0.0, 1.25, 0.0); add_child(cs)
	floor_snap_length = 0.4; floor_max_angle = deg_to_rad(50.0); wall_min_slide_angle = deg_to_rad(15.0)
	audio = AudioStreamPlayer3D.new(); audio.max_distance = 110.0; audio.unit_size = 18.0; audio.volume_db = 4.0; add_child(audio)
	audio_crunch = AudioStreamPlayer3D.new(); audio_crunch.max_distance = 60.0; audio_crunch.unit_size = 12.0; audio_crunch.volume_db = 5.0; add_child(audio_crunch)
	audio_step = AudioStreamPlayer3D.new(); audio_step.max_distance = 65.0; audio_step.unit_size = 14.0; audio_step.volume_db = 5.0; add_child(audio_step)
	audio_breath = AudioStreamPlayer3D.new(); audio_breath.max_distance = 65.0; audio_breath.unit_size = 12.0; audio_breath.volume_db = 2.0; audio_breath.stream = BREATH_SND; add_child(audio_breath)

func _play_anim(a_name: String, speed: float = 1.0) -> void:
	if anim and anim.has_animation(a_name) and anim.current_animation != a_name: anim.play(a_name, 0.2, speed)

func _pos(n: Node3D = null) -> Vector3:
	var t = n if n else self; return t.global_position if t.is_inside_tree() else t.position

func _is_in_safe_zone(pos: Vector3, margin: float = 0.0) -> bool:
	for p in pylons:
		if not is_instance_valid(p): continue
		var active = p.is_barrier_active() if p.has_method("is_barrier_active") else p.is_active
		if active and Vector2(pos.x - _pos(p).x, pos.z - _pos(p).z).length() < (p.BARRIER_RADIUS if "BARRIER_RADIUS" in p else 20.0) + margin: return true
	return false

func _physics_process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta); repulse_cd = maxf(0.0, repulse_cd - delta); hunt_delay = maxf(0.0, hunt_delay - delta)
	if audio_breath and not audio_breath.playing and is_inside_tree(): audio_breath.play()
	if not is_on_floor(): velocity.y -= 24.0 * delta
	else: velocity.y = -0.1
	if _check_pylon_repulsion(): _process_repulsion(delta)
	elif unstuck_timer > 0.0: _process_unstuck(delta)
	else:
		match current_phase:
			Phase.OBSERVER: _process_observer(delta)
			Phase.STALKER: _process_stalker(delta)
			Phase.HUNTING: _process_hunting(delta)
		_avoid_obstacles(delta)
	if is_inside_tree() and get_world_3d(): move_and_slide()
	_detect_stuck(delta); _update_rotation(delta); _update_footsteps(delta)

func _check_pylon_repulsion() -> bool:
	if repulse_cd > 0.0: return true
	var my_p = _pos()
	for p in pylons:
		if not is_instance_valid(p): continue
		var p_active = p.is_barrier_active() if p.has_method("is_barrier_active") else p.is_active
		if not p_active: continue
		var p_pos = _pos(p); var d = Vector2(my_p.x - p_pos.x, my_p.z - p_pos.z).length()
		var rad = p.BARRIER_RADIUS if "BARRIER_RADIUS" in p else 20.0
		if d < rad:
			repulse_dir = Vector3(my_p.x - p_pos.x, 0.0, my_p.z - p_pos.z).normalized()
			if repulse_dir.length_squared() < 0.01: repulse_dir = Vector3.FORWARD
			_trigger_repulse(); return true
	return false

func _trigger_repulse() -> void:
	current_state = State.REPULSED; repulse_cd = 1.6; velocity = repulse_dir * 14.0
	if audio and is_inside_tree(): audio.stream = ZAP_SND; audio.pitch_scale = randf_range(0.9, 1.1); audio.play()
	_play_anim("Damage_Action", 1.5)

func _process_repulsion(_delta: float) -> void:
	velocity.x = lerpf(velocity.x, repulse_dir.x * 4.0, 0.08); velocity.z = lerpf(velocity.z, repulse_dir.z * 4.0, 0.08); target_facing = -repulse_dir

func _process_unstuck(delta: float) -> void:
	unstuck_timer -= delta; velocity.x = unstuck_dir.x * 8.5; velocity.z = unstuck_dir.z * 8.5; target_facing = unstuck_dir
	if is_on_floor() and unstuck_timer > 0.4: velocity.y = 5.0
	_play_anim("Walk1_Action", 3.2)

func _avoid_obstacles(delta: float) -> void:
	wall_avoid_timer = maxf(0.0, wall_avoid_timer - delta)
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if col.get_normal().y < 0.65:
			if wall_avoid_timer <= 0.0:
				var n = Vector3(col.get_normal().x, 0.0, col.get_normal().z).normalized(); var t = Vector3(-n.z, 0.0, n.x)
				if t.dot(target_facing) < -0.05: t = -t
				elif abs(t.dot(target_facing)) <= 0.05: t = t * unstuck_sign
				wall_avoid_dir = t; wall_avoid_timer = 0.45
			velocity.x = (velocity.x + wall_avoid_dir.x * 8.0) * 0.7; velocity.z = (velocity.z + wall_avoid_dir.z * 8.0) * 0.7; break

func _detect_stuck(delta: float) -> void:
	var req_spd = Vector2(velocity.x, velocity.z).length(); progress_check_timer += delta
	if progress_check_timer >= 0.25:
		var moved = Vector2(_pos().x - last_check_pos.x, _pos().z - last_check_pos.z).length()
		last_check_pos = _pos(); progress_check_timer = 0.0
		if req_spd > 2.5 and moved < 0.45 and unstuck_timer <= 0.0 and repulse_cd <= 0.0:
			unstuck_timer = 0.65; unstuck_sign = -unstuck_sign
			var perp = Vector3(-target_facing.z, 0.0, target_facing.x) * unstuck_sign
			unstuck_dir = (target_facing * 0.3 + perp * 0.95).normalized()
			if is_on_floor(): velocity.y = 5.2

func _process_observer(_delta: float) -> void:
	if not player: return
	var to_p = Vector3(_pos(player).x - _pos().x, 0.0, _pos(player).z - _pos().z); var d = to_p.length()
	target_facing = to_p.normalized() if d > 0.1 else Vector3.FORWARD
	if d < 18.0:
		current_state = State.RETREAT; var away = -target_facing; velocity.x = away.x * 10.0; velocity.z = away.z * 10.0; target_facing = away
		_play_anim("Walk1_Action", 3.0)
	else:
		velocity.x = 0.0; velocity.z = 0.0; current_state = State.IDLE; _play_anim("Idle1_Action", 1.0)

func _process_stalker(_delta: float) -> void:
	if not player: return
	var to_p = Vector3(_pos(player).x - _pos().x, 0.0, _pos(player).z - _pos().z); var d = to_p.length(); var dir = to_p.normalized()
	if d > 32.0:
		velocity.x = dir.x * 5.2; velocity.z = dir.z * 5.2; target_facing = dir; _play_anim("Walk1_Action", 2.6)
	elif d < 14.0:
		var away = -dir; velocity.x = away.x * 6.8; velocity.z = away.z * 6.8; target_facing = away; _play_anim("Walk1_Action", 2.8)
	else:
		var tangent = Vector3(-dir.z, 0.0, dir.x); velocity.x = tangent.x * 3.6; velocity.z = tangent.z * 3.6; target_facing = dir
		_play_anim("Sniff_Action", 1.6)

func _process_hunting(_delta: float) -> void:
	if not player: return
	var p_pos = _pos(player); var my_p = _pos(); var to_p = Vector3(p_pos.x - my_p.x, 0.0, p_pos.z - my_p.z); var d = to_p.length(); var dir = to_p.normalized()
	target_facing = dir
	if hunt_delay > 0.0:
		velocity.x = 0.0; velocity.z = 0.0; _play_anim("Roar_Action", 1.15); return
	if _is_in_safe_zone(p_pos):
		current_state = State.PROWL; var tangent = Vector3(-dir.z, 0.0, dir.x); velocity.x = tangent.x * 4.8; velocity.z = tangent.z * 4.8
		_play_anim("Walk1_Action", 2.8); return
	if d <= 2.6:
		velocity.x = 0.0; velocity.z = 0.0; if attack_cd <= 0.0 and not _is_in_safe_zone(my_p): _perform_attack()
	else:
		current_state = State.CHASE; velocity.x = dir.x * 9.5; velocity.z = dir.z * 9.5; _play_anim("Walk2_Action", 4.0)

func _perform_attack() -> void:
	if not player or _is_in_safe_zone(_pos(player)) or _is_in_safe_zone(_pos()): return
	if _pos().distance_to(_pos(player)) > 3.2: return
	current_state = State.ATTACK; attack_cd = 1.75; _play_anim("Punch_Action", 2.6)
	if audio and is_inside_tree(): audio.stream = SLASH_SND; audio.pitch_scale = randf_range(0.85, 1.1); audio.play()
	if audio_crunch and is_inside_tree(): audio_crunch.stream = CRUNCH_SND; audio_crunch.pitch_scale = randf_range(1.1, 1.3); audio_crunch.play()
	if player.has_method("take_hit"): player.take_hit(20.0, target_facing, _pos(player))
	struck_player.emit()

func _update_rotation(delta: float) -> void:
	if target_facing.length_squared() > 0.01: rotation.y = lerp_angle(rotation.y, atan2(target_facing.x, target_facing.z), delta * 7.5)

func _update_footsteps(delta: float) -> void:
	var spd = Vector2(velocity.x, velocity.z).length()
	if spd > 2.5 and is_on_floor():
		step_timer -= delta
		if step_timer <= 0.0:
			step_timer = 0.28 if spd > 7.0 else 0.48
			if audio_step and is_inside_tree(): audio_step.stream = STEP_SND; audio_step.pitch_scale = randf_range(0.65, 0.85); audio_step.play()

func set_phase(new_phase: Phase) -> void:
	current_phase = new_phase; current_state = State.IDLE
	if new_phase == Phase.HUNTING:
		hunt_delay = 4.2; if audio and is_inside_tree(): audio.stream = ROAR_SND; audio.pitch_scale = randf_range(0.9, 1.0); audio.play()
		if eye_light: eye_light.light_color = Color(1.0, 0.08, 0.02); eye_light.light_energy = 8.5; eye_light.omni_range = 16.0
		if chest_light: chest_light.light_color = Color(0.9, 0.12, 0.02); chest_light.light_energy = 5.0
		if model_root:
			for m in model_root.find_children("*", "MeshInstance3D"):
				var mat = (m as MeshInstance3D).get_surface_override_material(0)
				if mat is StandardMaterial3D: (mat as StandardMaterial3D).emission = Color(1.0, 0.1, 0.02); (mat as StandardMaterial3D).emission_energy_multiplier = 0.8
