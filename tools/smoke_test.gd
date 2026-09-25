extends SceneTree
## Load a scene, run N physics frames, report script errors / warnings. Works with --headless.
## godot --headless --path . --script tools/smoke_test.gd -- --scene res://scenes/levels/dead_forest.tscn --frames 300
## Exit code 0 = loaded and ran; 1 = load failure. Parse errors surface in Godot's own stderr (grep "SCRIPT ERROR").

var frames_left := 300
var frame := 0
var start_ms := 0
var worst_ms := 0.0
var last_ms := 0
var scene_path := "res://scenes/levels/dead_forest.tscn"

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	for i in a.size():
		if a[i] == "--scene" and i + 1 < a.size():
			scene_path = a[i + 1]
		elif a[i] == "--frames" and i + 1 < a.size():
			frames_left = int(a[i + 1])
	var res = load(scene_path)
	if not (res is PackedScene):
		printerr("SMOKE FAIL: cannot load ", scene_path)
		quit(1); return
	root.add_child(res.instantiate())
	start_ms = Time.get_ticks_msec()
	last_ms = start_ms

func _process(_delta: float) -> bool:
	var now := Time.get_ticks_msec()
	if frame > 5:
		worst_ms = maxf(worst_ms, float(now - last_ms))
	last_ms = now
	frame += 1
	if frame >= frames_left:
		var total := float(now - start_ms) / 1000.0
		print("SMOKE OK scene=%s frames=%d time=%.2fs avg_frame=%.1fms worst_frame=%.1fms nodes=%d orphans=%d" % [
			scene_path, frame, total, total * 1000.0 / frame, worst_ms,
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))])
		quit(0)
	return false
