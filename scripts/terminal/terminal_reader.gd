class_name TerminalReader
extends Control
## An open file on a terminal screen (TerminalDesktop's READING view): its name and meta, the body as a scrolling page
## (BBCode; mouse wheel, arrows, Page Up / Down), and a < BACK button.

signal back()

const T = preload("res://scripts/terminal/terminal_theme.gd")

var _title: Label
var _meta: Label
var _doc: RichTextLabel
var _back: Button


func setup(rect: Rect2) -> void:
	position = rect.position
	size = rect.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title = _label(Rect2(2, 0, rect.size.x - 4, 16), T.AMBER)
	_meta = _label(Rect2(2, 0, rect.size.x - 4, 16), T.DIM)
	_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var rule := ColorRect.new()
	rule.color = T.FAINT
	rule.position = Vector2(2, 17)
	rule.size = Vector2(rect.size.x - 4, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	_doc = RichTextLabel.new()
	_doc.bbcode_enabled = true
	_doc.scroll_active = true
	_doc.focus_mode = Control.FOCUS_ALL
	_doc.position = Vector2(2, 20)
	_doc.size = Vector2(rect.size.x - 4, rect.size.y - 40)
	add_child(_doc)
	_back = Button.new()
	_back.text = "< BACK"
	_back.position = Vector2(0, rect.size.y - 18)
	_back.pressed.connect(back.emit)
	_back.mouse_entered.connect(_back.grab_focus)
	add_child(_back)


func show_file(file: TerminalFile) -> void:
	_title.text = file.name
	_meta.text = file.meta
	_doc.text = file.body
	_doc.scroll_to_line(0)


## The page takes the keys (arrows scroll it).
func focus() -> void:
	_doc.grab_focus()


func _label(rect: Rect2, color: Color) -> Label:
	var line := Label.new()
	line.position = rect.position
	line.size = rect.size
	line.clip_text = true
	line.add_theme_color_override("font_color", color)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	return line
