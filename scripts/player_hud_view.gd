class_name PlayerHudView
extends Node

var speed_label: Label
var weapon_label: Label
var health_label: Label
var interact_label: Label
var damage_rect: ColorRect
var controls_guide: Label
var crosshair_dot: ColorRect

func setup_ui(hud_node: CanvasLayer) -> void:
	if not hud_node:
		return
	speed_label = hud_node.get_node_or_null("SpeedLabel")
	weapon_label = hud_node.get_node_or_null("WeaponLabel")
	interact_label = hud_node.get_node_or_null("InteractPrompt")
	controls_guide = hud_node.get_node_or_null("ControlsGuide")
	var crosshair = hud_node.get_node_or_null("Crosshair")
	if crosshair:
		crosshair_dot = crosshair.get_node_or_null("ColorRect") as ColorRect
	
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "HP: 100"
	health_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	health_label.offset_left = 10.0
	health_label.offset_top = -22.0
	health_label.offset_right = 90.0
	health_label.offset_bottom = -6.0
	health_label.add_theme_font_size_override("font_size", 10)
	health_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	hud_node.add_child(health_label)

	damage_rect = ColorRect.new()
	damage_rect.name = "DamageFlash"
	damage_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_rect.color = Color(0.8, 0.05, 0.05, 0.0)
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_node.add_child(damage_rect)

func update_speed(speed: float, is_grappling: bool, strain: float, dist: float, is_winching: bool, state_name: String) -> void:
	if not speed_label:
		return
	speed_label.text = "VEL: %4.1f m/s" % speed
	if is_grappling:
		if strain > 0.25:
			speed_label.text += " [STRAIN: %d%%!]" % int(strain * 100.0)
		elif is_winching:
			speed_label.text += " [WINCHING: %2.0fm]" % dist
		else:
			speed_label.text += " [VINE: %2.0fm]" % dist
	elif state_name == "SLIDE":
		speed_label.text += " [SLIDING]"
	elif state_name == "AIR":
		speed_label.text += " [AIR]"

func update_weapon(weapon_type: int, grenade_state: int, cook_time: float) -> void:
	if not weapon_label:
		return
	if weapon_type == 0:
		weapon_label.text = "[1] BLASTER   [G] GRENADE"
		weapon_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.12))
	else:
		match grenade_state:
			0:
				weapon_label.text = "[G] GRENADE [PIN IN - LMB TO PULL]"
				weapon_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.3))
			1:
				weapon_label.text = "[G] FUSE: %1.1fs! [LMB TO THROW!]" % max(0.0, cook_time)
				weapon_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15))
			2:
				weapon_label.text = "[G] THROWING..."
				weapon_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func update_health(current_hp: float) -> void:
	if not health_label:
		return
	health_label.text = "HP: %d" % int(current_hp)
	var col = Color(0.2, 1.0, 0.4) if current_hp > 50.0 else (Color(1.0, 0.8, 0.2) if current_hp > 25.0 else Color(1.0, 0.2, 0.2))
	health_label.add_theme_color_override("font_color", col)

func flash_damage() -> void:
	if damage_rect:
		damage_rect.color.a = clamp(damage_rect.color.a + 0.38, 0.0, 0.65)

func decay_damage_flash(delta: float) -> void:
	if damage_rect and damage_rect.color.a > 0.0:
		damage_rect.color.a = max(0.0, damage_rect.color.a - delta * 2.5)

func set_death_overlay(visible: bool) -> void:
	if damage_rect:
		damage_rect.color.a = 0.85 if visible else 0.0

func show_prompt(text: String, font: Font = null) -> void:
	if not interact_label: return
	interact_label.text = text
	if font:
		interact_label.add_theme_font_override("font", font)
		interact_label.add_theme_font_size_override("font_size", 13)
		interact_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
		interact_label.add_theme_constant_override("outline_size", 3)
		interact_label.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 0.95))
	elif interact_label.has_theme_font_override("font"):
		interact_label.remove_theme_font_override("font")
		interact_label.remove_theme_font_size_override("font_size")
		interact_label.remove_theme_color_override("font_color")
		interact_label.remove_theme_constant_override("outline_size")
	interact_label.visible = true

func hide_prompt() -> void:
	if interact_label:
		interact_label.visible = false

func show_hitmarker(tree: SceneTree) -> void:
	if crosshair_dot:
		crosshair_dot.color = Color(1.0, 0.2, 0.2, 1.0)
		tree.create_timer(0.08).timeout.connect(func():
			if crosshair_dot: crosshair_dot.color = Color(0.1, 1.0, 0.6, 0.85)
		)

func toggle_help() -> void:
	if controls_guide:
		controls_guide.visible = not controls_guide.visible

func set_walking_mode(enabled: bool) -> void:
	if speed_label: speed_label.visible = not enabled
	if weapon_label: weapon_label.visible = not enabled
	if controls_guide: controls_guide.visible = not enabled
	if health_label: health_label.visible = true
