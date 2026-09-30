class_name PlayerPresenter
extends Node

var base_fov: float = 85.0
var max_fov: float = 112.0
var fov_speed_threshold: float = 14.0

var recoil_pitch: float = 0.0
var recoil_roll: float = 0.0
var weapon_sway_offset: Vector2 = Vector2.ZERO

func setup(combat: PlayerCombat, vine: PlayerVine, world_root: Node, tree: SceneTree, muzzle: OmniLight3D, mount: Node3D, cam: Camera3D, hud: PlayerHudView) -> void:
	combat.weapon_fired.connect(func(_type, is_hit, hit_pos, _norm):
		add_recoil(1.4, 0.0)
		flash_muzzle(muzzle, mount, tree)
		SoundManager.play(AudioBank.BLASTER, -2.0, 0.04)
		var fire_origin = cam.global_position + (-cam.global_transform.basis.z * 0.42) + (cam.global_transform.basis.x * 0.18) + (cam.global_transform.basis.y * -0.14)
		spawn_tracer(world_root, fire_origin, hit_pos)
		if is_hit:
			spawn_impact(world_root, hit_pos)
			hud.show_hitmarker(tree)
			SoundManager.play(AudioBank.HITMARKER, 0.0, 0.02)
	)
	combat.grenade_pin_pulled.connect(func(): SoundManager.play(AudioBank.GRENADE_PIN, 0.0, 0.02))
	combat.grenade_thrown.connect(func():
		add_recoil(2.0, 0.0)
		SoundManager.play(AudioBank.GRENADE_THROW, 0.0, 0.03)
	)
	vine.vine_winch_tick.connect(func(): SoundManager.play(AudioBank.VINE_WINCH, -4.0, 0.05))

func play_tone_slide(start_freq: float, _end: float, _dur: float, _noise: bool = false) -> void:
	if start_freq > 700.0: SoundManager.play(AudioBank.BLASTER, -4.0)
	elif start_freq > 400.0: SoundManager.play(AudioBank.JUMP, -2.0)
	else: SoundManager.play(AudioBank.DASH, -2.0)

func update_camera_and_weapon(cam: Camera3D, gun_mount: Node3D, vel: Vector3, input_vec: Vector2, is_sliding: bool, swing_tilt: float, delta: float) -> void:
	if delta <= 0.0 or not cam: return
	var h_speed = sqrt(vel.x * vel.x + vel.z * vel.z)
	var target_fov = base_fov
	if h_speed > fov_speed_threshold:
		var t = clamp((h_speed - fov_speed_threshold) / 22.0, 0.0, 1.0)
		target_fov = lerp(base_fov, max_fov, t)
	cam.fov = lerp(cam.fov, target_fov, delta * 8.0)

	recoil_pitch = lerp(recoil_pitch, 0.0, delta * 14.0)
	recoil_roll = lerp(recoil_roll, 0.0, delta * 14.0)
	var target_tilt = -input_vec.x * deg_to_rad(3.5)
	if is_sliding: target_tilt *= 1.8
	target_tilt += swing_tilt

	cam.rotation.z = lerp_angle(cam.rotation.z, target_tilt + recoil_roll, delta * 10.0)
	cam.rotation.x = recoil_pitch
	cam.rotation.y = 0.0

	if gun_mount:
		weapon_sway_offset = weapon_sway_offset.lerp(Vector2.ZERO, delta * 12.0)
		gun_mount.position.x = lerp(gun_mount.position.x, weapon_sway_offset.x + 0.18, delta * 10.0)
		gun_mount.position.y = lerp(gun_mount.position.y, weapon_sway_offset.y - 0.15, delta * 10.0)
		gun_mount.position.z = lerp(gun_mount.position.z, -0.30, delta * 10.0)

func add_recoil(pitch_deg: float, roll_deg: float) -> void:
	recoil_pitch += deg_to_rad(pitch_deg)
	recoil_roll += (randf() - 0.5) * deg_to_rad(roll_deg)

func reset_camera(cam: Camera3D) -> void:
	recoil_pitch = 0.0
	recoil_roll = 0.0
	if cam: cam.rotation = Vector3.ZERO

func flash_muzzle(muzzle_flash: OmniLight3D, gun_mount: Node3D, tree: SceneTree) -> void:
	if gun_mount: gun_mount.position.z += 0.08
	if muzzle_flash:
		muzzle_flash.visible = true
		tree.create_timer(0.04).timeout.connect(func(): if muzzle_flash: muzzle_flash.visible = false)

func spawn_tracer(parent: Node, from_pos: Vector3, to_pos: Vector3) -> void:
	var line = ImmediateMesh.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = line
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.72, 0.15, 0.95)
	mesh_inst.material_override = mat
	parent.add_child(mesh_inst)
	line.surface_begin(Mesh.PRIMITIVE_LINES)
	line.surface_add_vertex(from_pos)
	line.surface_add_vertex(to_pos)
	line.surface_end()
	var tween = mesh_inst.create_tween()
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.06)
	tween.tween_callback(mesh_inst.queue_free)

func spawn_impact(parent: Node, point: Vector3) -> void:
	var effect = Node3D.new()
	parent.add_child(effect)
	effect.global_position = point
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.65, 0.12)
	light.light_energy = 3.5
	light.omni_range = 3.0
	effect.add_child(light)
	var mesh_inst = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.16, 0.16, 0.16)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.7, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = 2.5
	mesh_inst.mesh = box
	mesh_inst.material_override = mat
	effect.add_child(mesh_inst)
	var tween = effect.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.12)
	tween.parallel().tween_property(mesh_inst, "scale", Vector3.ZERO, 0.12)
	tween.tween_callback(effect.queue_free)
