extends SceneTree
## Compiles every GDScript under res://scripts and res://tools in one Godot process (tools\check.ps1 runs it; one
## launch instead of one per script). Prints `SYNTAX res://...` for each script that fails to load (parse or compile
## error, or a broken dependency); Godot's own `SCRIPT ERROR` lines say why. Exit code = number of failures (capped).
## Usage: godot --headless --path . --script tools/check_scripts.gd

const ROOTS: Array[String] = ["res://scripts", "res://tools"]


func _initialize() -> void:
	var files: Array[String] = []
	for root in ROOTS:
		_collect(root, files)
	var failed := 0
	for path in files:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as Script
		if script == null or not script.can_instantiate():      # a script that failed to compile still loads: invalid
			print("SYNTAX  " + path)
			failed += 1
	print("CHECKED %d script(s), %d failed" % [files.size(), failed])
	quit(mini(failed, 100))


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			_collect(dir_path.path_join(sub), out)
	for file in dir.get_files():
		if file.get_extension() == "gd":
			out.append(dir_path.path_join(file))
