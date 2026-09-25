class_name DevHud
extends CanvasLayer

signal fog_toggled()
signal flycam_toggled()
signal teleport_requested(poi_id: int)

var top_bar: Label
var toast_label: Label
var help_panel: PanelContainer
var toast_tween: Tween

func _ready() -> void:
	layer = 50
	_build_ui()

func _build_ui() -> void:
	top_bar = Label.new()
	top_bar.name = "DevTopBar"
	top_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_bar.offset_left = -460.0; top_bar.offset_top = 8.0; top_bar.offset_right = -10.0; top_bar.offset_bottom = 26.0
	top_bar.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7, 0.85))
	top_bar.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	top_bar.add_theme_font_size_override("font_size", 9)
	top_bar.text = "[F1] Dev Help | [F2] Fog: ON | [F3] Flycam: OFF | [F5-F9] Teleport"
	add_child(top_bar)

	toast_label = Label.new()
	toast_label.name = "DevToast"
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.offset_top = 40.0; toast_label.offset_left = -250.0; toast_label.offset_right = 250.0
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	toast_label.add_theme_font_size_override("font_size", 11)
	toast_label.modulate.a = 0.0
	add_child(toast_label)

	_build_help_panel()

func _build_help_panel() -> void:
	help_panel = PanelContainer.new()
	help_panel.name = "DevHelpPanel"
	help_panel.set_anchors_preset(Control.PRESET_CENTER)
	help_panel.offset_left = -220.0; help_panel.offset_top = -140.0; help_panel.offset_right = 220.0; help_panel.offset_bottom = 150.0
	help_panel.visible = false
	add_child(help_panel)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	help_panel.add_child(vb)

	var title = Label.new()
	title.text = "=== DEVELOPER CONTROLS ==="; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7, 1.0))
	title.add_theme_font_size_override("font_size", 11); vb.add_child(title)

	var info = Label.new()
	info.text = "[F1] Toggle This Menu  |  [F2] Toggle Fog (Clear View 4000m)\n[F3] Toggle 6DOF Flycam  (WASD / Space=Up / Ctrl=Down)\n[Shift] Flycam Boost  |  [Mouse Wheel] Fly Speed\n[F5] Bunker 1  |  [F6] Hub  |  [F7] Outpost 2  |  [F8] Outpost 3  |  [F9] Silo"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 9); vb.add_child(info)

	var hb_toggles = HBoxContainer.new(); hb_toggles.alignment = BoxContainer.ALIGNMENT_CENTER; vb.add_child(hb_toggles)
	var btn_fog = Button.new(); btn_fog.text = "Toggle Fog [F2]"; btn_fog.pressed.connect(func(): fog_toggled.emit()); hb_toggles.add_child(btn_fog)
	var btn_fly = Button.new(); btn_fly.text = "Toggle Flycam [F3]"; btn_fly.pressed.connect(func(): flycam_toggled.emit()); hb_toggles.add_child(btn_fly)

	var grid = GridContainer.new(); grid.columns = 3; vb.add_child(grid)
	_add_poi_btn(grid, "Bunker 1 [F5]", 1); _add_poi_btn(grid, "Central Hub [F6]", 2); _add_poi_btn(grid, "Outpost 02 [F7]", 3)
	_add_poi_btn(grid, "Outpost 03 [F8]", 4); _add_poi_btn(grid, "Missile Silo [F9]", 5)

	var btn_close = Button.new(); btn_close.text = "Close Menu [F1]"; btn_close.pressed.connect(toggle_help); grid.add_child(btn_close)

func _add_poi_btn(parent: Control, txt: String, id: int) -> void:
	var btn = Button.new(); btn.text = txt; btn.pressed.connect(func(): teleport_requested.emit(id)); parent.add_child(btn)

func update_bar(fog_off: bool, fly_on: bool, speed: float) -> void:
	var f_txt = "OFF (Clear)" if fog_off else "ON"
	var fly_txt = "ON (%.0fm/s)" % speed if fly_on else "OFF"
	top_bar.text = "[F1] Dev Help | [F2] Fog: %s | [F3] Flycam: %s | [F5-F9] Teleport" % [f_txt, fly_txt]

func show_toast(msg: String, dur: float = 2.4) -> void:
	toast_label.text = msg; toast_label.modulate.a = 1.0
	if toast_tween and toast_tween.is_valid(): toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(dur)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func toggle_help() -> void:
	help_panel.visible = !help_panel.visible
	if help_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
