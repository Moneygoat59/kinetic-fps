class_name MegaLevelManager
extends Node3D

static var instance: MegaLevelManager = null

const WorldDecorator = preload("res://scripts/world_decorator.gd")
@export var drone_scene: PackedScene = preload("res://scenes/enemies/drone_enemy.tscn")
@export var mech_scene: PackedScene = preload("res://scenes/enemies/mech_enemy.tscn")

var player: CharacterBody3D = null
var current_sector_index: int = 0
var current_checkpoint: Vector3 = Vector3(0, 2.0, 25.0)
var top_speed_record: float = 0.0

# Enemy tracking
var active_enemies: Array[Node3D] = []
var initial_enemy_spawns: Array[Dictionary] = []

# HUD References
var hud_layer: CanvasLayer = null
var sector_banner: PanelContainer = null
var sector_title_label: Label = null
var sector_desc_label: Label = null
var banner_tween: Tween = null

var stats_panel: PanelContainer = null
var speed_metric_label: Label = null
var top_speed_label: Label = null
var sector_name_label: Label = null
var hostile_count_label: Label = null
var hint_label: Label = null

var milestone_label: Label = null
var milestone_tween: Tween = null

# Sector Definitions
var sectors: Array[Dictionary] = [
	{
		"id": "citadel",
		"name": "SECTOR 00 // THE CORE CITADEL",
		"desc": "CENTRAL TRANSIT HUB & 75M VERTICAL HYPER-LIFT",
		"checkpoint": Vector3(0, 2.0, 25.0),
		"bounds": AABB(Vector3(-75, -5, -75), Vector3(150, 95, 150))
	},
	{
		"id": "sky_cranes",
		"name": "SECTOR 01 // STRATOSPHERE SLINGSHOT ARCS",
		"desc": "VOID CANYON CRANE CHAIN - AERIAL PENDULUM SLINGSHOTS",
		"checkpoint": Vector3(0, 14.0, -100.0),
		"bounds": AABB(Vector3(-120, -30, -320), Vector3(240, 130, 230))
	},
	{
		"id": "super_slide",
		"name": "SECTOR 02 // VELOCITY CHUTE CANYON",
		"desc": "HIGH BASTION 300M DOWNHILL SLIDE & SKI-JUMP CATAPULT",
		"checkpoint": Vector3(100.0, 62.0, -100.0),
		"bounds": AABB(Vector3(80, -25, -160), Vector3(240, 110, 300))
	},
	{
		"id": "foundry",
		"name": "SECTOR 03 // INDUSTRIAL FOUNDRY & BASIN",
		"desc": "SUNKEN EXCAVATION COMBAT ZONE & HEAVY MECH PATROLS",
		"checkpoint": Vector3(0, 14.0, 95.0),
		"bounds": AABB(Vector3(-150, -25, 80), Vector3(300, 70, 240))
	},
	{
		"id": "speedway",
		"name": "SECTOR 04 // MACH-SPEED BHOP HIGHWAY",
		"desc": "350M SUSPENDED RUNWAY - UNRESTRICTED AIR-STRAFE ACCELERATION",
		"checkpoint": Vector3(-95.0, 12.0, 0.0),
		"bounds": AABB(Vector3(-320, -10, -180), Vector3(230, 60, 360))
	},
	{
		"id": "orbital_spire",
		"name": "SECTOR 05 // ORBITAL CATAPULT GANTRY",
		"desc": "75M DIAGONAL SKY-LAUNCH PAD & APEX TETHER BEACONS",
		"checkpoint": Vector3(170.0, 22.0, 170.0),
		"bounds": AABB(Vector3(130, -10, 130), Vector3(140, 110, 140))
	},
	{
		"id": "skyway_loop",
		"name": "SECTOR 06 // PERIMETER SKYWAY RING",
		"desc": "ELEVATED 1.5KM MEGAPLEX INTERCONNECT SPEEDWAY",
		"checkpoint": Vector3(-200.0, 24.0, -200.0),
		"bounds": AABB(Vector3(-320, 15, -320), Vector3(640, 50, 640))
	}
]

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	_init_retro_environment()
	_create_hud()
	_collect_initial_enemies()
	_spawn_decorations()
	
	# Find player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Search by type or name
		player = find_child("Player", true, false) as CharacterBody3D
	
	# Show initial sector banner
	_announce_sector(sectors[0])

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Speed Tracking (computed without Vector2 heap allocation)
	var vx = player.velocity.x
	var vz = player.velocity.z
	var current_spd = sqrt(vx * vx + vz * vz)
	if current_spd > top_speed_record:
		top_speed_record = current_spd

	# Update HUD Stats
	if speed_metric_label:
		speed_metric_label.text = "VELOCITY: %5.1f M/S" % current_spd
		if current_spd > 45.0:
			speed_metric_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.9))
		elif current_spd > 30.0:
			speed_metric_label.add_theme_color_override("font_color", Color(0.1, 0.95, 1.0))
		elif current_spd > 18.0:
			speed_metric_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
		else:
			speed_metric_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))

	if top_speed_label:
		top_speed_label.text = "PEAK: %4.1f M/S" % top_speed_record

	# Sector Detection
	_check_current_sector()

	# Void Hazard Safety Net
	if player.global_position.y < -38.0:
		respawn_player()

func _check_current_sector() -> void:
	var pos = player.global_position
	# Check specific sectors first, default to loop/citadel
	for i in range(1, sectors.size()):
		var sec = sectors[i]
		var aabb: AABB = sec["bounds"]
		if aabb.has_point(pos):
			if current_sector_index != i:
				current_sector_index = i
				current_checkpoint = sec["checkpoint"]
				_announce_sector(sec)
			return

	# If none of the outer ones match, check citadel
	var citadel_aabb: AABB = sectors[0]["bounds"]
	if citadel_aabb.has_point(pos) and current_sector_index != 0:
		current_sector_index = 0
		current_checkpoint = sectors[0]["checkpoint"]
		_announce_sector(sectors[0])

func _announce_sector(sec: Dictionary) -> void:
	if sector_name_label:
		sector_name_label.text = sec["name"]

	if not sector_banner:
		return

	sector_title_label.text = sec["name"]
	sector_desc_label.text = sec["desc"]
	sector_banner.visible = true
	sector_banner.modulate.a = 0.0
	sector_banner.position.y = 2.0

	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	banner_tween = create_tween()
	banner_tween.set_parallel(true)
	banner_tween.tween_property(sector_banner, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD)
	banner_tween.tween_property(sector_banner, "position:y", 10.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	banner_tween.chain().tween_interval(2.5)
	banner_tween.chain().tween_property(sector_banner, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD)
	banner_tween.chain().tween_callback(func(): sector_banner.visible = false)

	SoundManager.play(AudioBank.CHECKPOINT, 1.0)

func _show_milestone(text: String, color: Color) -> void:
	if not milestone_label:
		return
	milestone_label.text = text
	milestone_label.add_theme_color_override("font_color", color)
	milestone_label.visible = true
	milestone_label.modulate.a = 0.0
	milestone_label.scale = Vector2(1.3, 1.3)

	if milestone_tween and milestone_tween.is_valid():
		milestone_tween.kill()

	milestone_tween = create_tween()
	milestone_tween.set_parallel(true)
	milestone_tween.tween_property(milestone_label, "modulate:a", 1.0, 0.15)
	milestone_tween.tween_property(milestone_label, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	milestone_tween.chain().tween_interval(1.8)
	milestone_tween.chain().tween_property(milestone_label, "modulate:a", 0.0, 0.4)
	milestone_tween.chain().tween_callback(func(): milestone_label.visible = false)

	SoundManager.play(AudioBank.GATE_TARGET, 1.0)

func respawn_player() -> void:
	if not player:
		return
	player.global_position = current_checkpoint + Vector3(0, 1.2, 0)
	player.velocity = Vector3.ZERO
	if player.has_method("reset_for_respawn"):
		player.reset_for_respawn()
	SoundManager.play(AudioBank.WEAPON_SWITCH, 0.0)
	_show_milestone("RECOVERED AT SECTOR CHECKPOINT", Color(1.0, 0.4, 0.4))

func teleport_to_hub() -> void:
	current_sector_index = 0
	current_checkpoint = sectors[0]["checkpoint"]
	respawn_player()
	_announce_sector(sectors[0])

func teleport_to_sector(index: int) -> void:
	if index >= 0 and index < sectors.size():
		current_sector_index = index
		current_checkpoint = sectors[index]["checkpoint"]
		respawn_player()
		_announce_sector(sectors[index])

func _collect_initial_enemies() -> void:
	active_enemies.clear()
	initial_enemy_spawns.clear()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		active_enemies.append(enemy)
		var enemy_type = "drone" if enemy is DroneEnemy else "mech"
		initial_enemy_spawns.append({
			"type": enemy_type,
			"transform": enemy.global_transform
		})
		if enemy.has_signal("enemy_died"):
			enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

	_update_hostile_hud()

func _on_enemy_died(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	_update_hostile_hud()

func respawn_wave() -> void:
	# Clean up any leftover active enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

	var enemies_parent = get_node_or_null("Enemies")
	if not enemies_parent:
		enemies_parent = self

	for data in initial_enemy_spawns:
		var scene_to_spawn = drone_scene if data["type"] == "drone" else mech_scene
		if scene_to_spawn:
			var new_enemy = scene_to_spawn.instantiate()
			enemies_parent.add_child(new_enemy)
			new_enemy.global_transform = data["transform"]
			active_enemies.append(new_enemy)
			if new_enemy.has_signal("enemy_died"):
				new_enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

	_update_hostile_hud()
	_show_milestone("SECURITY HOSTILES RE-ENGAGED!", Color(1.0, 0.85, 0.2))

func _update_hostile_hud() -> void:
	if not hostile_count_label:
		return
	var count = active_enemies.size()
	if count > 0:
		hostile_count_label.text = "HOSTILES IN COMPLEX: %d" % count
		hostile_count_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	else:
		hostile_count_label.text = "ALL HOSTILES PURGED [R to Respawn]"
		hostile_count_label.add_theme_color_override("font_color", Color(0.1, 0.95, 0.4))

func _create_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "MegaLevelHUD"
	add_child(hud_layer)

	# 1. Top Banner for Sector Announcements (compact & centered)
	sector_banner = PanelContainer.new()
	sector_banner.name = "SectorBanner"
	sector_banner.visible = false
	sector_banner.anchors_preset = Control.PRESET_CENTER_TOP
	sector_banner.anchor_left = 0.5
	sector_banner.anchor_right = 0.5
	sector_banner.offset_left = -130.0
	sector_banner.offset_right = 130.0
	sector_banner.offset_top = 8.0
	sector_banner.offset_bottom = 36.0
	sector_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = Color(0.04, 0.07, 0.06, 0.9)
	banner_style.border_width_left = 1
	banner_style.border_width_right = 1
	banner_style.border_width_top = 1
	banner_style.border_width_bottom = 1
	banner_style.border_color = Color(0.1, 0.95, 0.45)
	banner_style.content_margin_left = 8.0
	banner_style.content_margin_right = 8.0
	banner_style.content_margin_top = 3.0
	banner_style.content_margin_bottom = 3.0
	sector_banner.add_theme_stylebox_override("panel", banner_style)

	var banner_vbox = VBoxContainer.new()
	banner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_vbox.add_theme_constant_override("separation", 1)
	sector_banner.add_child(banner_vbox)

	sector_title_label = Label.new()
	sector_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sector_title_label.add_theme_font_size_override("font_size", 10)
	sector_title_label.add_theme_color_override("font_color", Color(0.15, 1.0, 0.5))
	banner_vbox.add_child(sector_title_label)

	sector_desc_label = Label.new()
	sector_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sector_desc_label.add_theme_font_size_override("font_size", 8)
	sector_desc_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.8))
	banner_vbox.add_child(sector_desc_label)

	hud_layer.add_child(sector_banner)

	# 2. Stats Panel (Tucked neatly in Top-Right corner)
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.anchors_preset = Control.PRESET_TOP_RIGHT
	stats_panel.anchor_left = 1.0
	stats_panel.anchor_right = 1.0
	stats_panel.offset_left = -140.0
	stats_panel.offset_right = -8.0
	stats_panel.offset_top = 8.0
	stats_panel.offset_bottom = 54.0
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.04, 0.05, 0.08, 0.75)
	stats_style.border_width_left = 1
	stats_style.border_color = Color(0.2, 0.8, 1.0, 0.6)
	stats_style.content_margin_left = 6.0
	stats_style.content_margin_right = 6.0
	stats_style.content_margin_top = 3.0
	stats_style.content_margin_bottom = 3.0
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 1)
	stats_panel.add_child(stats_vbox)

	sector_name_label = Label.new()
	sector_name_label.text = sectors[0]["name"]
	sector_name_label.add_theme_font_size_override("font_size", 9)
	sector_name_label.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	stats_vbox.add_child(sector_name_label)

	top_speed_label = Label.new()
	top_speed_label.text = "PEAK:  0.0 M/S"
	top_speed_label.add_theme_font_size_override("font_size", 8)
	top_speed_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	stats_vbox.add_child(top_speed_label)

	hostile_count_label = Label.new()
	hostile_count_label.text = "HOSTILES: INITIALIZING..."
	hostile_count_label.add_theme_font_size_override("font_size", 8)
	hostile_count_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
	stats_vbox.add_child(hostile_count_label)

	hint_label = Label.new()
	hint_label.text = "[R] Wave | [Shift+R] Hub"
	hint_label.add_theme_font_size_override("font_size", 7)
	hint_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.7))
	stats_vbox.add_child(hint_label)

	hud_layer.add_child(stats_panel)

	# 3. Center Screen Milestone Flashes (Compact & high above reticle)
	milestone_label = Label.new()
	milestone_label.name = "SpeedMilestone"
	milestone_label.visible = false
	milestone_label.anchors_preset = Control.PRESET_CENTER
	milestone_label.anchor_left = 0.5
	milestone_label.anchor_top = 0.16
	milestone_label.anchor_right = 0.5
	milestone_label.anchor_bottom = 0.16
	milestone_label.offset_left = -150.0
	milestone_label.offset_top = -12.0
	milestone_label.offset_right = 150.0
	milestone_label.offset_bottom = 12.0
	milestone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	milestone_label.pivot_offset = Vector2(150, 12)
	milestone_label.add_theme_font_size_override("font_size", 12)
	milestone_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(milestone_label)

func _init_retro_environment() -> void:
	# Ensure lighting and fog exist if not in scene
	pass

func _spawn_decorations() -> void:
	var decorator = WorldDecorator.new()
	decorator.name = "WorldDecorations"
	add_child(decorator)
