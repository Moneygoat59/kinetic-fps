class_name HorrorHud
extends CanvasLayer

const THEME = preload("res://scripts/ui/horror_ui_theme.gd")

var dock_panel: TextureRect
var held_icon: TextureRect
var pips: Array[TextureRect] = []

func _ready() -> void:
	layer = 90
	_build_dock()

func _build_dock() -> void:
	dock_panel = TextureRect.new()
	dock_panel.texture = THEME.get_hud_dock()
	dock_panel.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	dock_panel.offset_left = -90.0
	dock_panel.offset_top = -90.0
	dock_panel.offset_right = -10.0
	dock_panel.offset_bottom = -10.0
	dock_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dock_panel)

	held_icon = TextureRect.new()
	held_icon.position = Vector2(16, 12)
	held_icon.size = Vector2(48, 48)
	held_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	held_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dock_panel.add_child(held_icon)

	for i in range(4):
		var pip = TextureRect.new()
		pip.position = Vector2(16 + i * 13, 64)
		pip.size = Vector2(10, 8)
		pip.texture = THEME.get_hud_pip_active() if i == 0 else THEME.get_hud_pip_inactive()
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dock_panel.add_child(pip)
		pips.append(pip)

func on_held_item_changed(idx: int, item_data: Dictionary) -> void:
	if held_icon and item_data.has("icon_path"):
		held_icon.texture = THEME.load_icon(item_data["icon_path"])
	for i in range(pips.size()):
		pips[i].texture = THEME.get_hud_pip_active() if i == idx else THEME.get_hud_pip_inactive()

func on_health_changed(_hp: float) -> void:
	pass
