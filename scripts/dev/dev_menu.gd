class_name DevMenu
extends PanelContainer
## The dev menu panel (DevManager, F1 / Esc): where the walker is, JUMP TO a point in the story (DevWarps, keys 1-9),
## GO TO a place in this level (DevPlaces, F5-F9 for the first five), and the tools (fly F3, fog F2).
## Pure view: it emits what was picked and DevManager acts. Arrow keys / Enter work through normal focus.

signal warp_chosen(index: int)
signal place_chosen(index: int)
signal fly_pressed()
signal fog_pressed()

const INK := Color(0.86, 0.84, 0.78)
const DIM := Color(0.52, 0.52, 0.5)
const ACCENT := Color(0.96, 0.72, 0.3)
const BG := Color(0.05, 0.055, 0.06, 0.94)
const SIZE_BODY := 9
const SIZE_HEAD := 8

var _status: Label
var _warps: VBoxContainer
var _places: VBoxContainer
var _fly: Button
var _fog: Button
var _font: Font
var _head_font: Font


func _ready() -> void:
	_font = FontLibrary.tech_font()
	_head_font = FontLibrary.pixel_font()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(8, 8)
	custom_minimum_size = Vector2(396, 0)
	add_theme_stylebox_override("panel", _box(BG, Color(ACCENT, 0.35), 6))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	add_child(root)
	root.add_child(_label("DEV MENU", SIZE_HEAD, ACCENT, _head_font))
	_status = _label("", SIZE_BODY, INK, _font)
	root.add_child(_status)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	root.add_child(cols)
	_warps = _column(cols, "JUMP TO")
	_places = _column(cols, "GO TO")
	root.add_child(_label("TOOLS", SIZE_HEAD, DIM, _head_font))
	var tools := HBoxContainer.new()
	root.add_child(tools)
	_fly = _button(tools, "", fly_pressed.emit)
	_fog = _button(tools, "", fog_pressed.emit)
	root.add_child(_label("F1 / Esc  close        1-9 / F5-F9  pick while open / anytime
" +
		"fly  WASD, Space up, Ctrl down, Shift fast, wheel speed;  F3 lands, Shift+F3 goes back", SIZE_BODY - 1, DIM, _font))
	for i in DevWarps.count():
		var key := str(i + 1) + "  " if i < 9 else "   "
		_button(_warps, key + DevWarps.label(i), warp_chosen.emit.bind(i))


func open(status: String, place_labels: Array, flying: bool, fog_off: bool) -> void:
	_status.text = status
	for child in _places.get_children():
		if child.get_index() > 0: child.queue_free()      # keep the column title
	for i in place_labels.size():
		var key := "F%d  " % (i + 5) if i < 5 else "    "
		_button(_places, key + String(place_labels[i]), place_chosen.emit.bind(i))
	if place_labels.is_empty():
		_places.add_child(_label("nothing here", SIZE_BODY, DIM, _font))
	set_tools(flying, fog_off)
	visible = true
	var first := _warps.get_child(1) as Button
	if first: first.grab_focus()


func close() -> void:
	visible = false


func set_tools(flying: bool, fog_off: bool) -> void:
	_fly.text = "F3  Fly: " + ("ON" if flying else "off")
	_fog.text = "F2  Fog: " + ("off (4 km)" if fog_off else "on")


func _column(parent: Control, title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	col.add_child(_label(title, SIZE_HEAD, DIM, _head_font))
	parent.add_child(col)
	return col


func _button(parent: Control, text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _font: b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", SIZE_BODY)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", ACCENT)
	b.add_theme_color_override("font_focus_color", ACCENT)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.03), Color.TRANSPARENT, 2))
	b.add_theme_stylebox_override("hover", _box(Color(ACCENT, 0.12), Color.TRANSPARENT, 2))
	b.add_theme_stylebox_override("pressed", _box(Color(ACCENT, 0.25), Color.TRANSPARENT, 2))
	b.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, Color(ACCENT, 0.7), 2))
	b.pressed.connect(on_press)
	parent.add_child(b)
	return b


func _label(text: String, font_size: int, color: Color, font: Font) -> Label:
	var l := Label.new()
	l.text = text
	if font: l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _box(fill: Color, edge: Color, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1 if edge.a > 0.0 else 0)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(pad)
	s.content_margin_top = pad * 0.5
	s.content_margin_bottom = pad * 0.5
	return s
