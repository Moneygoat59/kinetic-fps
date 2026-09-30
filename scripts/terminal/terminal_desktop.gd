class_name TerminalDesktop
extends Control
## What a terminal's screen shows, drawn inside its PixelScreen (a SubViewport on the kit screen): header (drive title,
## user), path line, the body, a hint line and a pixel mouse pointer. View + navigation only: TerminalStation pushes the
## player's input in and listens. View FSM: LISTING (TerminalListing: the folder's rows) / READING (TerminalReader: a
## file). Mouse: point and click; keys: arrows + Enter; back() = Backspace. Idle (not logged on) it rests at the root.

signal clicked()                      # a row or button was pressed (the station plays the key click)

enum View { LISTING, READING }

const T = preload("res://scripts/terminal/terminal_theme.gd")
const HINTS := {View.LISTING: "CLICK / ENTER: OPEN   BKSP: BACK   E: LOG OFF",
	View.READING: "WHEEL / ARROWS: SCROLL   BKSP: BACK   E: LOG OFF"}
const IDLE_HINT := "> READY_"
const POINTER: PackedVector2Array = [Vector2(0, 0), Vector2(0, 10), Vector2(3, 7), Vector2(5, 11), Vector2(7, 10),
	Vector2(5, 6), Vector2(8, 6)]

var view := View.LISTING
var drive: TerminalDrive
var active := false
var listing := TerminalListing.new()
var reader := TerminalReader.new()
var _stack: Array[TerminalFolder] = []
var _file: TerminalFile
var _path: Label
var _hint: Label
var _pointer: Polygon2D


func setup(d: TerminalDrive, px: Vector2) -> void:
	drive = d
	size = px
	theme = T.make()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(Rect2(4, 0, px.x - 8, 16), d.title, T.AMBER)
	_label(Rect2(4, 0, px.x - 8, 16), d.user, T.DIM).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rule(17)
	_path = _label(Rect2(4, 18, px.x - 8, 16), "", T.DIM)
	_rule(px.y - 17)
	_hint = _label(Rect2(4, px.y - 15, px.x - 8, 14), IDLE_HINT, T.DIM)
	_hint.add_theme_font_size_override("font_size", T.SMALL)
	var body := Rect2(2, 36, px.x - 4, px.y - 55)
	var char_w := theme.default_font.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, T.FONT_SIZE).x
	add_child(listing)
	listing.setup(body, char_w)
	listing.opened.connect(_open)
	listing.up.connect(_on_back)
	add_child(reader)
	reader.setup(body)
	reader.back.connect(_on_back)
	_pointer = Polygon2D.new()
	_pointer.polygon = POINTER
	_pointer.color = T.AMBER
	_pointer.visible = false
	add_child(_pointer)
	var edge := Line2D.new()                       # dark outline: the pointer still shows over a lit (amber) row
	edge.points = POINTER
	edge.closed = true
	edge.width = 1.0
	edge.default_color = T.INK
	_pointer.add_child(edge)
	home()


## Log on (the view has eased in) / off: keys and the pointer only work while on; logging off returns to the root.
func set_active(on: bool) -> void:
	active = on
	if not on:
		point_at(Vector2.ZERO, false)
		home()
		if get_viewport():
			get_viewport().gui_release_focus()
		return
	_show_listing()


func home() -> void:
	_stack.assign([drive])
	_file = null
	_show_listing()


## Back one step: a file to its folder, a folder to its parent. False at the root (nothing to go back to).
func back() -> bool:
	if view == View.READING:
		var came_from := _file
		_file = null
		clicked.emit()
		_show_listing(came_from)
		return true
	if _stack.size() > 1:
		clicked.emit()
		_show_listing(_stack.pop_back())
		return true
	return false


## The mouse pointer at screen pixel `px` (hidden when the mouse is off the screen or nobody is logged on).
func point_at(px: Vector2, show: bool) -> void:
	_pointer.visible = show and active
	_pointer.position = px.floor()


## "LABEL:/FOLDER/SUB[/ENTRY]": the current folder's path, or an entry's in it (the drive's read marks use these).
func path_of(entry: TerminalEntry = null) -> String:
	var names := PackedStringArray()
	for i in range(1, _stack.size()):
		names.append(_stack[i].name)
	if entry:
		names.append(entry.name)
	return "%s:/%s" % [drive.name, "/".join(names)]


func _open(entry: TerminalEntry) -> void:
	clicked.emit()
	if entry is TerminalFolder:
		_stack.append(entry as TerminalFolder)
		_show_listing()
		return
	_file = entry as TerminalFile
	if _file == null:
		return
	view = View.READING
	listing.visible = false
	reader.visible = true
	reader.show_file(_file)
	_path.text = path_of(_file)
	_hint.text = HINTS[view] if active else IDLE_HINT
	drive.open_file(path_of(_file))
	if active:
		reader.focus()


func _show_listing(select: TerminalEntry = null) -> void:
	view = View.LISTING
	listing.visible = true
	reader.visible = false
	_path.text = path_of()
	_hint.text = HINTS[view] if active else IDLE_HINT
	var row := listing.show_folder(_stack.back(), _stack.size() > 1, _is_read, select)
	if active and row:
		row.grab_focus.call_deferred()


func _is_read(entry: TerminalEntry) -> bool:
	return drive.is_read(path_of(entry))


func _on_back() -> void:
	back()


func _label(rect: Rect2, text: String, color: Color) -> Label:
	var line := Label.new()
	line.position = rect.position
	line.size = rect.size
	line.text = text
	line.clip_text = true
	line.add_theme_color_override("font_color", color)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	return line


func _rule(y: float) -> void:
	var rule := ColorRect.new()
	rule.color = T.DIM
	rule.position = Vector2(4, y)
	rule.size = Vector2(size.x - 8, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
