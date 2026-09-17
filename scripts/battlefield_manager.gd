class_name BattlefieldManager
extends Node3D

static var instance: BattlefieldManager = null

@export var drone_scene: PackedScene = preload("res://scenes/enemies/drone_enemy.tscn")
@export var mech_scene: PackedScene = preload("res://scenes/enemies/mech_enemy.tscn")

var active_enemies: Array[Node3D] = []
var total_enemies: int = 0
var status_label: Label = null
var victory_banner: PanelContainer = null
var banner_label: Label = null

# Spawn data
var initial_spawn_points: Array[Dictionary] = []

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_init_retro_environment()
	_create_hud()
	_collect_initial_enemies()
	_update_hud()

func _create_hud() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "BattlefieldHUD"
	add_child(canvas)

	status_label = Label.new()
	status_label.name = "HostileCount"
	status_label.anchors_preset = Control.PRESET_TOP_RIGHT
	status_label.anchor_left = 1.0
	status_label.anchor_right = 1.0
	status_label.offset_left = -140.0
	status_label.offset_right = -10.0
	status_label.offset_top = 8.0
	status_label.offset_bottom = 24.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))
	status_label.text = "HOSTILES: INITIALIZING..."
	canvas.add_child(status_label)

	# Center victory banner
	victory_banner = PanelContainer.new()
	victory_banner.name = "VictoryBanner"
	victory_banner.visible = false
	victory_banner.anchors_preset = Control.PRESET_CENTER
	victory_banner.anchor_left = 0.5
	victory_banner.anchor_top = 0.25
	victory_banner.anchor_right = 0.5
	victory_banner.anchor_bottom = 0.25
	victory_banner.offset_left = -120.0
	victory_banner.offset_top = -20.0
	victory_banner.offset_right = 120.0
	victory_banner.offset_bottom = 20.0
	victory_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.06, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.1, 0.95, 0.4, 1.0)
	style.content_margin_left = 10.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	victory_banner.add_theme_stylebox_override("panel", style)
	
	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 10)
	banner_label.add_theme_color_override("font_color", Color(0.15, 1.0, 0.45, 1.0))
	banner_label.text = "SECTOR SECURED\n[R] Respawn Wave"
	victory_banner.add_child(banner_label)
	canvas.add_child(victory_banner)

func _collect_initial_enemies() -> void:
	active_enemies.clear()
	initial_spawn_points.clear()
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		active_enemies.append(enemy)
		var enemy_type = "drone" if enemy is DroneEnemy else "mech"
		initial_spawn_points.append({
			"type": enemy_type,
			"transform": enemy.global_transform
		})
		_connect_enemy_death(enemy)
		
	total_enemies = active_enemies.size()

func _connect_enemy_death(enemy: Node3D) -> void:
	if enemy.has_signal("enemy_died"):
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

func _on_enemy_died(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	_update_hud()
	
	if active_enemies.size() == 0:
		_trigger_victory()

func _update_hud() -> void:
	if status_label:
		var remaining = active_enemies.size()
		status_label.text = "HOSTILES: %d / %d REMAINING" % [remaining, total_enemies]
		if remaining == 0:
			status_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		else:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25, 1.0))

func _trigger_victory() -> void:
	if victory_banner:
		victory_banner.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			respawn_wave()

func respawn_wave() -> void:
	if victory_banner:
		victory_banner.visible = false

	# Clean up any surviving enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

	# Respawn all enemies at initial locations
	for data in initial_spawn_points:
		var new_enemy: Node3D = null
		if data["type"] == "drone":
			new_enemy = drone_scene.instantiate()
		else:
			new_enemy = mech_scene.instantiate()
		
		add_child(new_enemy)
		new_enemy.global_transform = data["transform"]
		active_enemies.append(new_enemy)
		_connect_enemy_death(new_enemy)

	total_enemies = active_enemies.size()
	_update_hud()

func _init_retro_environment() -> void:
	# Textures
	var floor_tex: Texture2D = _load_texture("res://textures/floor_grate_rust.png")
	var wall_tex: Texture2D = _load_texture("res://textures/alien_blast_wall.png")
	var hazard_tex: Texture2D = _load_texture("res://textures/hazard_stripes.png")
	var metal_tex: Texture2D = _load_texture("res://textures/gun_metal_scratched.png")

	# Materials
	var mat_floor = _create_triplanar_material(floor_tex, Vector3(0.35, 0.35, 0.35))
	var mat_wall = _create_triplanar_material(wall_tex, Vector3(0.22, 0.22, 0.22))
	var mat_hazard = _create_triplanar_material(hazard_tex, Vector3(0.6, 0.6, 0.6))
	var mat_metal = _create_triplanar_material(metal_tex, Vector3(0.4, 0.4, 0.4))

	var geom = get_node_or_null("Geometry")
	if geom:
		_apply_env_materials_recursive(geom, mat_floor, mat_wall, mat_hazard, mat_metal)

	# Atmospheric alien dark lighting & fog
	var world_env = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env and world_env.environment:
		var env = world_env.environment
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.04, 0.03, 0.07, 1.0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.2, 0.18, 0.28, 1.0)
		env.ambient_light_energy = 1.0
		env.fog_enabled = true
		env.fog_light_color = Color(0.05, 0.04, 0.09, 1.0)
		env.fog_density = 0.007
		env.fog_aerial_perspective = 0.5

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

func _create_triplanar_material(tex: Texture2D, uv_scale: Vector3) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if tex:
		mat.albedo_texture = tex
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = uv_scale
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 0.9
	mat.metallic = 0.2
	return mat

func _apply_env_materials_recursive(node: Node, mat_floor: Material, mat_wall: Material, mat_hazard: Material, mat_metal: Material) -> void:
	var name_lower = node.name.to_lower()
	var assigned_mat: Material = null
	
	if "floor" in name_lower or "ground" in name_lower:
		assigned_mat = mat_floor
	elif "wall" in name_lower or "pillar" in name_lower or "tower" in name_lower or "bunker" in name_lower:
		assigned_mat = mat_wall
	elif "crane" in name_lower or "ramp" in name_lower or "barrier" in name_lower:
		assigned_mat = mat_hazard
	elif "container" in name_lower:
		assigned_mat = mat_metal

	if assigned_mat:
		if node is CSGBox3D:
			(node as CSGBox3D).material = assigned_mat
		elif node is MeshInstance3D:
			(node as MeshInstance3D).material_override = assigned_mat

	for child in node.get_children():
		_apply_env_materials_recursive(child, mat_floor, mat_wall, mat_hazard, mat_metal)
