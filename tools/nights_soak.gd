extends SceneTree
## Soak test of the real night loop on the GPU (not headless): apartment -> forest night 1 -> apartment -> night 2 -> ...
## -> night 4, walking forward in every forest, then on night 4 builds every POI (DevTools.teleport_to_poi 1..5).
## Prints one SOAK line per second (frame ms, VRAM, draw calls, nodes, orphans) so leaks across nights show up.
## godot --path . --script tools/nights_soak.gd -- [--apt 6] [--night 10] [--final 40]

var apt_time := 6.0
var night_time := 10.0
var final_time := 40.0
var _flow: Node
var _level: StringName = &""
var _in_level := 0.0
var _log_t := 0.0
var _poi := 0
var _worst := 0.0
var _started := false


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	for i in a.size() - 1:
		match a[i]:
			"--apt": apt_time = float(a[i + 1])
			"--night": night_time = float(a[i + 1])
			"--final": final_time = float(a[i + 1])


func _process(delta: float) -> bool:
	_flow = root.get_node_or_null(^"LevelFlow")
	if _flow == null:
		printerr("SOAK FAIL: LevelFlow autoload missing")
		quit(1); return true
	if not _started:
		_started = true
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		_flow.go(&"apartment", 0.0, 0.01)
		return false
	_worst = maxf(_worst, delta)
	if _flow.current != _level:
		_level = _flow.current; _in_level = 0.0
		print("SOAK enter %s visit=%d" % [_level, _flow.visits(_level)])
	_in_level += delta
	_log_t += delta
	if _log_t >= 1.0:
		_log(); _log_t = 0.0; _worst = 0.0
	if _flow.state != 0:
		return false
	var night: int = _flow.visits(&"forest")
	if _level == &"apartment":
		Input.action_release("move_forward")
		if _in_level > apt_time:
			if night >= 4: return _finish()
			_flow.go(&"forest")
	elif _level == &"forest":
		if _in_level > 4.0: Input.action_press("move_forward")
		if night < 4 and _in_level > night_time:
			_flow.go(&"apartment")
		elif night >= 4:
			_night_three()
	return false


func _night_three() -> void:
	var step := int((_in_level - night_time) / (final_time / 6.0))
	if step > _poi and _poi < 5:
		_poi += 1
		var dev := root.get_node_or_null(^"DevTools")
		if dev: dev.teleport_to_poi(_poi)
		print("SOAK poi %d" % _poi)
	if _in_level > night_time + final_time:
		_finish()


func _finish() -> bool:
	Input.action_release("move_forward")
	_census()
	print("SOAK OK")
	quit(0)
	return true


## What the GPU pays for per frame, beyond plain meshes: lights (and which cast shadows), live sub-viewports, particles.
func _census() -> void:
	var n := {"omni": 0, "omni_shadow": 0, "spot": 0, "spot_shadow": 0, "subviewport_live": 0, "particles": 0, "mesh": 0}
	for node in root.find_children("*", "", true, false):
		if node is OmniLight3D: n["omni"] += 1; n["omni_shadow"] += int(node.shadow_enabled)
		elif node is SpotLight3D: n["spot"] += 1; n["spot_shadow"] += int(node.shadow_enabled)
		elif node is SubViewport: n["subviewport_live"] += int(node.render_target_update_mode == SubViewport.UPDATE_ALWAYS)
		elif node is GPUParticles3D: n["particles"] += 1
		elif node is MeshInstance3D: n["mesh"] += 1
	print("SOAK census ", n)


func _log() -> void:
	print("SOAK %s v%d t=%.0f fps=%d gpu=%.1fms worst=%.1fms vram=%.0fMB tex=%.0fMB draws=%d prims=%dk nodes=%d orphans=%d objs=%d" % [
		_level, _flow.visits(_level), _in_level, Engine.get_frames_per_second(),
		RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()), _worst * 1000.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000.0),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_COUNT))])
