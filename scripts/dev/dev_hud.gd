class_name DevHud
extends CanvasLayer
## The dev layer (DevManager): a quiet corner strip with what dev tools are on, short toasts, and the DevMenu panel.

const DevMenuScript = preload("res://scripts/dev/dev_menu.gd")

var menu: DevMenu
var _strip: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_strip = _corner_label(Control.PRESET_TOP_RIGHT, Color(0.86, 0.84, 0.78, 0.45), 8)
	_strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_strip.offset_left = -300.0; _strip.offset_right = -6.0; _strip.offset_top = 4.0
	_toast = _corner_label(Control.PRESET_CENTER_TOP, Color(0.96, 0.72, 0.3), 10)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_left = -250.0; _toast.offset_right = 250.0; _toast.offset_top = 30.0
	_toast.modulate.a = 0.0
	menu = DevMenuScript.new()
	add_child(menu)
	update_strip(false, false, 0.0)


func update_strip(flying: bool, fog_off: bool, speed: float) -> void:
	var parts := PackedStringArray(["F1 dev"])
	if flying: parts.append("FLY %.0f m/s" % speed)
	if fog_off: parts.append("FOG OFF")
	_strip.text = "   ".join(parts)


func show_toast(msg: String, dur: float = 2.0) -> void:
	_toast.text = msg
	_toast.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid(): _toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(dur)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func _corner_label(preset: Control.LayoutPreset, color: Color, size: int) -> Label:
	var l := Label.new()
	l.set_anchors_preset(preset)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var font := FontLibrary.tech_font()
	if font: l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	add_child(l)
	return l
