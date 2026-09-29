class_name TerminalDrive
extends TerminalFolder
## A terminal's contents: the root folder (its `entries`, its `name` = the drive label in the path line) plus the header.
## One .tres per terminal in res://content/terminals/<id>.tres; TerminalStation.load_drive(id) loads it. Godot caches
## resources, so every load of one drive is the same object: story code hooks in with
##   TerminalStation.load_drive(&"silo_data09").file_opened.connect(_on_read)
## Read marks last for the session (nothing is saved yet).

signal file_opened(path: String, first_time: bool)

@export var title := "TERMINAL"      ## header bar, left
@export var user := "OPERATOR"       ## header bar, right

var _read := {}


## Called by the screen when a file opens. path = "LABEL/FOLDER/FILE.TXT".
func open_file(path: String) -> void:
	if path.is_empty():
		return
	var first := not _read.has(path)
	_read[path] = true
	file_opened.emit(path, first)


func is_read(path: String) -> bool:
	return _read.has(path)
