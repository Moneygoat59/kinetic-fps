class_name DevManager
extends Node

const DEV_HUD = preload("res://scripts/dev/dev_hud.gd")

var hud: CanvasLayer; var fog_disabled: bool = false; var flycam_active: bool = false
var flycam: Camera3D; var cached_player_cam: Camera3D; var cached_player: CharacterBody3D
var cached_env: Environment; var cached_sun: DirectionalLight3D
var original_shadow_dist: float = 45.0; var fly_speed: float = 35.0; var fly_boost: float = 3.0
var fly_vel: Vector3 = Vector3.ZERO; var cam_rot: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_priority = -100; if DisplayServer.get_name() == "headless": return
	hud = DEV_HUD.new(); add_child(hud)
	hud.fog_toggled.connect(toggle_fog); hud.flycam_toggled.connect(toggle_flycam); hud.teleport_requested.connect(teleport_to_poi)
	_find_env()

func _get_search_root() -> Node:
	if is_inside_tree() and get_tree().root: return get_tree().root
	var p: Node = self; while p.get_parent(): p = p.get_parent()
	return p

func _find_env() -> void:
	var r = _get_search_root(); if not r: return
	var we = r.find_child("WorldEnvironment", true, false) as WorldEnvironment; if we: cached_env = we.environment
	var sun = r.find_child("Moonlight", true, false) as DirectionalLight3D
	if not sun: sun = r.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	if sun: cached_sun = sun; original_shadow_dist = sun.directional_shadow_max_distance

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F1: if hud: hud.toggle_help(); get_viewport().set_input_as_handled()
			KEY_F2: toggle_fog(); get_viewport().set_input_as_handled()
			KEY_F3: toggle_flycam(event.shift_pressed); get_viewport().set_input_as_handled()
			KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9: teleport_to_poi(event.keycode - KEY_F5 + 1); get_viewport().set_input_as_handled()
	if not flycam_active: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		cam_rot.y -= event.relative.x * 0.0028; cam_rot.x = clampf(cam_rot.x - event.relative.y * 0.0028, -1.48, 1.48)
		if flycam: flycam.rotation = Vector3(cam_rot.x, cam_rot.y, 0.0); get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var mult = 1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else (0.80 if event.button_index == MOUSE_BUTTON_WHEEL_DOWN else 1.0)
		if mult != 1.0:
			fly_speed = clampf(fly_speed * mult, 5.0, 300.0)
			if hud: hud.show_toast("Fly Speed: %.0f m/s" % fly_speed, 1.0); hud.update_bar(fog_disabled, flycam_active, fly_speed)
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not flycam_active or not flycam or delta <= 0.0: return
	var b = flycam.global_transform.basis; var dir = Vector3.ZERO
	if Input.is_key_pressed(KEY_W): dir -= b.z; if Input.is_key_pressed(KEY_S): dir += b.z
	if Input.is_key_pressed(KEY_A): dir -= b.x; if Input.is_key_pressed(KEY_D): dir += b.x
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_E): dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C) or Input.is_key_pressed(KEY_Q): dir -= Vector3.UP
	var spd = fly_speed * (fly_boost if Input.is_key_pressed(KEY_SHIFT) else 1.0)
	fly_vel = fly_vel.lerp(dir.normalized() * spd if dir.length_squared() > 0.01 else Vector3.ZERO, 14.0 * delta); flycam.global_position += fly_vel * delta

func toggle_fog() -> void:
	if not cached_env: _find_env()
	if not cached_env: if hud: hud.show_toast("No WorldEnvironment found!"); return
	fog_disabled = not fog_disabled; cached_env.fog_enabled = not fog_disabled
	if cached_sun: cached_sun.directional_shadow_max_distance = 200.0 if fog_disabled else original_shadow_dist
	if hud: hud.show_toast("FOG: " + ("OFF (Clear View 4000m)" if fog_disabled else "ON (Atmospheric)")); hud.update_bar(fog_disabled, flycam_active, fly_speed)

func toggle_flycam(cancel: bool = false) -> void:
	if flycam_active: _deactivate_flycam(cancel)
	else: _activate_flycam()

func _activate_flycam() -> void:
	_find_player(); if not cached_player: return
	var p_cam = cached_player.get_node_or_null("Head/Camera3D") as Camera3D
	if not p_cam: p_cam = cached_player.find_child("Camera3D", true, false) as Camera3D
	if not p_cam: return
	cached_player_cam = p_cam; flycam = Camera3D.new(); flycam.name = "DevFlyCam"
	flycam.transform = p_cam.global_transform if p_cam.is_inside_tree() else p_cam.transform
	flycam.fov = p_cam.fov; flycam.near = 0.05; flycam.far = 4000.0
	var r = _get_search_root(); r.add_child(flycam); flycam.current = true
	cam_rot = Vector2(flycam.rotation.x, flycam.rotation.y); fly_vel = Vector3.ZERO; flycam_active = true
	cached_player.set_physics_process(false); cached_player.set_process_unhandled_input(false); cached_player.velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if hud: hud.show_toast("FLYCAM ACTIVATED (WASD to Fly, Shift=Boost, Wheel=Speed)"); hud.update_bar(fog_disabled, flycam_active, fly_speed)

func _deactivate_flycam(cancel_teleport: bool = false) -> void:
	flycam_active = false
	if cached_player and is_instance_valid(cached_player) and not cancel_teleport and flycam:
		var target_pos = (flycam.global_position if flycam.is_inside_tree() else flycam.position) - Vector3(0.0, 1.4, 0.0)
		if cached_player.is_inside_tree(): cached_player.global_position = target_pos
		else: cached_player.position = target_pos
		cached_player.rotation.y = cam_rot.y
		var head = cached_player.get_node_or_null("Head") as Node3D; if head: head.rotation.x = cam_rot.x
		cached_player.velocity = Vector3.ZERO
	if is_instance_valid(cached_player_cam): cached_player_cam.current = true
	if is_instance_valid(cached_player): cached_player.set_physics_process(true); cached_player.set_process_unhandled_input(true)
	if is_instance_valid(flycam): flycam.queue_free(); flycam = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if hud: hud.show_toast("FLYCAM DEACTIVATED" + (" (Canceled)" if cancel_teleport else " (Player Teleported)")); hud.update_bar(fog_disabled, flycam_active, fly_speed)

func _find_player() -> void:
	if cached_player and is_instance_valid(cached_player): return
	var r = _get_search_root(); if not r: return
	var p = r.find_child("Player", true, false) as CharacterBody3D
	if not p: var ev = r.find_child("DeadForestEvent", true, false); if ev and ev.get("player"): p = ev.get("player") as CharacterBody3D
	if not p: var list = r.find_children("*", "CharacterBody3D", true, false); if not list.is_empty(): p = list[0] as CharacterBody3D
	cached_player = p

func _ensure_poi(ev: Node, id: int) -> Node3D:
	var p_pos = cached_player.global_position if (cached_player and is_instance_valid(cached_player)) else Vector3.ZERO
	if id >= 1 and not ev.get("bunker_instance"): ev.call("_spawn_bunker_1", p_pos)
	if id >= 2 and not ev.get("hub_instance"): ev.call("_start_path_to_hub")
	if id >= 3 and not ev.get("outpost_2_instance"): ev.call("_on_hub_interacted", 0)
	if id >= 4 and not ev.get("outpost_3_instance"):
		if not ev.get("outpost_2_instance"): ev.call("_on_hub_interacted", 0)
		ev.call("_on_outpost_key_acquired", 2); ev.call("_on_hub_interacted", 2)
	if id >= 5 and not ev.get("silo_instance"):
		if not ev.get("outpost_2_instance"): ev.call("_on_hub_interacted", 0)
		if not ev.get("outpost_3_instance"): ev.call("_on_outpost_key_acquired", 2); ev.call("_on_hub_interacted", 2)
		ev.call("_on_outpost_key_acquired", 3); ev.call("_on_hub_interacted", 4)
	var targets = [ev.get("bunker_instance"), ev.get("hub_instance"), ev.get("outpost_2_instance"), ev.get("outpost_3_instance"), ev.get("silo_instance")]
	return targets[id - 1] as Node3D if (id >= 1 and id <= targets.size()) else null

func teleport_to_poi(id: int) -> void:
	_find_player(); var r = _get_search_root(); if not r: return
	var ev = r.find_child("DeadForestEvent", true, false) as Node; if not ev: return
	var names = ["Bunker 1", "Central Hub", "Outpost 02", "Outpost 03", "Missile Silo"]
	var target = _ensure_poi(ev, id)
	if not target or not is_instance_valid(target):
		if hud: hud.show_toast("Could not spawn %s" % names[clampi(id - 1, 0, names.size() - 1)]); return
	var label = names[id - 1]; var offsets = [6.8, 7.5, 5.5, 5.5, 33.0]
	var t_pos = target.global_position if target.is_inside_tree() else target.position
	var t_basis = target.global_transform.basis if target.is_inside_tree() else target.transform.basis
	var dest = t_pos + t_basis.z * offsets[id - 1]
	var terrain = r.find_child("DeadForestTerrain", true, false) as Node3D
	if terrain and terrain.has_method("update_player_pos"): terrain.update_player_pos(dest)
	dest.y = (terrain.get_height(dest.x, dest.z) + 0.15) if (terrain and terrain.has_method("get_height")) else (t_pos.y + 0.15)
	var wake = r.find_child("WakeCanvas", true, false); if wake: wake.queue_free()
	var dfm = r.find_child("DeadForest", true, false); if dfm: dfm.set("spawn_point", dest)
	if flycam_active and flycam:
		var f_dest = dest + t_basis.z * 5.0 + Vector3(0.0, 7.0, 0.0)
		if flycam.is_inside_tree(): flycam.global_position = f_dest
		else: flycam.position = f_dest
		flycam.look_at(t_pos + Vector3(0.0, 1.5, 0.0), Vector3.UP); cam_rot = Vector2(flycam.rotation.x, flycam.rotation.y)
	elif cached_player:
		cached_player.set_physics_process(true); cached_player.set_process_unhandled_input(true)
		if cached_player.is_inside_tree(): cached_player.global_position = dest
		else: cached_player.position = dest
		cached_player.rotation.y = atan2(-t_basis.z.x, -t_basis.z.z); cached_player.velocity = Vector3.ZERO
		var head = cached_player.get_node_or_null("Head") as Node3D; if head: head.rotation.x = 0.0
	if hud: hud.show_toast("Teleported to %s (Terrain & Model Ready)" % label)
