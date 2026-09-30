class_name TerminalListing
extends ScrollContainer
## A folder's contents on a terminal screen (TerminalDesktop's LISTING view): one row per entry in one monospace line,
## "[+] NAME ... META" for folders, " *  NAME ... META" for files not read yet ("    " once read), "[<] .." first when
## there is a folder to go up to. Rows are Buttons (pointer hover moves the focus, so one row is lit at a time).

signal opened(entry: TerminalEntry)
signal up()

const T = preload("res://scripts/terminal/terminal_theme.gd")
const UP_ROW := "[<] .."
const FOLDER := "[+] "
const FILE_NEW := " *  "
const FILE_READ := "    "
const EMPTY := "    (EMPTY)"
const ROW_SPARE := 24.0              # px of a row's width left unused: button padding, the scrollbar, glyph overhang

var _rows: VBoxContainer
var _cols := 40


func setup(rect: Rect2, char_w: float) -> void:
	position = rect.position
	size = rect.size
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_cols = maxi(int((rect.size.x - ROW_SPARE) / maxf(char_w, 1.0)), 12)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 0)
	add_child(_rows)


## Lists `folder`; is_read(entry) -> bool marks the files. Returns the row to focus: `select`'s, else the first entry's
## (the up row only when the folder is empty).
func show_folder(folder: TerminalFolder, can_go_up: bool, is_read: Callable, select: TerminalEntry = null) -> Button:
	for row in _rows.get_children():
		_rows.remove_child(row)
		row.queue_free()
	var first: Button = null
	var chosen: Button = null
	var up_row: Button = null
	if can_go_up:
		up_row = _row(UP_ROW, "")
		up_row.pressed.connect(up.emit)
	for entry in folder.entries:
		if entry == null:
			continue
		var prefix := FOLDER if entry is TerminalFolder else (FILE_READ if is_read.call(entry) else FILE_NEW)
		var row := _row(prefix + entry.name, _meta(entry))
		row.pressed.connect(opened.emit.bind(entry))
		first = row if first == null else first
		chosen = row if entry == select else chosen
	if folder.entries.is_empty():
		_row(EMPTY, "").disabled = true
	scroll_vertical = 0
	return chosen if chosen else first if first else up_row


func _meta(entry: TerminalEntry) -> String:
	if entry.meta != "" or not entry is TerminalFolder:
		return entry.meta
	var n := (entry as TerminalFolder).entries.size()
	return "%d ITEM%s" % [n, "" if n == 1 else "S"]


func _row(left: String, right: String) -> Button:
	var room := _cols - right.length() - 1
	if left.length() > room:
		left = left.substr(0, maxi(room - 1, 0)) + "~"
	var row := Button.new()
	row.text = left + " ".repeat(maxi(_cols - left.length() - right.length(), 1)) + right
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.clip_text = true
	row.mouse_entered.connect(row.grab_focus)
	_rows.add_child(row)
	return row
