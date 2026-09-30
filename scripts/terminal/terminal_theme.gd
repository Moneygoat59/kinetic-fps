class_name TerminalTheme
extends RefCounted
## The terminal screen's look (TerminalDesktop): amber VT323 on near-black, rows and buttons flat until pointed at or
## focused, then inverse video (amber bar, dark ink); a thin amber scrollbar. Same palette as the game's other screens
## (RouteTerminalView, HubConsoleView).

const AMBER := Color(1.0, 0.62, 0.16)
const DIM := Color(0.5, 0.31, 0.09)
const FAINT := Color(0.24, 0.15, 0.05)
const INK := Color(0.04, 0.025, 0.008)
const FONT_SIZE := 16
const SMALL := 13


static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font = FontLibrary.terminal_font()
	theme.default_font_size = FONT_SIZE
	for type in ["Label", "Button", "RichTextLabel"]:
		theme.set_color("font_color", type, AMBER)
	theme.set_color("default_color", "RichTextLabel", AMBER)
	theme.set_constant("line_separation", "RichTextLabel", 1)
	var flat := _box(Color(0, 0, 0, 0))
	var lit := _box(AMBER)
	theme.set_stylebox("normal", "Button", flat)
	theme.set_stylebox("pressed", "Button", lit)
	theme.set_stylebox("hover", "Button", lit)
	theme.set_stylebox("hover_pressed", "Button", lit)
	theme.set_stylebox("focus", "Button", lit)
	theme.set_stylebox("disabled", "Button", flat)
	for state in ["font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", DIM)
	theme.set_stylebox("normal", "RichTextLabel", _box(Color(0, 0, 0, 0)))
	theme.set_stylebox("focus", "RichTextLabel", _box(Color(0, 0, 0, 0)))
	theme.set_stylebox("panel", "ScrollContainer", _box(Color(0, 0, 0, 0)))
	for bar in ["VScrollBar", "HScrollBar"]:
		theme.set_stylebox("scroll", bar, _box(FAINT, 1))
		theme.set_stylebox("grabber", bar, _box(DIM, 1))
		theme.set_stylebox("grabber_highlight", bar, _box(AMBER, 1))
		theme.set_stylebox("grabber_pressed", bar, _box(AMBER, 1))
	return theme


static func _box(fill: Color, pad := 2) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.content_margin_left = pad
	box.content_margin_right = pad
	box.content_margin_top = 0
	box.content_margin_bottom = 0
	return box
