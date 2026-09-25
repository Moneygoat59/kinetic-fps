extends SceneTree
## Screenshot any scene or model from chosen camera angles (needs a renderer, not --headless).
## godot --path . --script tools/capture.gd -- --scene res://x.tscn --out shots/x [options]
##   --scene PATH   .tscn or .glb/.gltf to load            --out PREFIX   output prefix (png appended)
##   --cam x,y,z    camera position (single view)          --look x,y,z   look-at point (default 0,1,0)
##   --views LIST   orbit presets: front,back,left,right,top,iso,eye (comma list; uses --look/--dist)
##   --dist N       orbit distance (default 8)             --frames N     frames to settle (default 30)
##   --size WxH     image size (default 1280x720)          --fov N        camera fov (default 70)
##   --wait SECS    world time to run before the first shot (e.g. skip a wake-up intro)
##   --no-ui        hide every CanvasLayer (HUD, DevTools, overlays)
##   --fit          auto-frame: --look/--dist derived from the content's bounds (best for models)
##   --lit          add sun + ambient (for bare models)    --exec PATH    GDScript with `func run(scene, tree)` to set up state

const PRESETS := {
	"front": Vector3(0, 0.25, 1), "back": Vector3(0, 0.25, -1), "left": Vector3(-1, 0.25, 0),
	"right": Vector3(1, 0.25, 0), "top": Vector3(0, 1, 0.001), "iso": Vector3(1, 0.8, 1),
	"eye": Vector3(0, 0, 1),
}

var args: Dictionary = {}
var cam: Camera3D
var jobs: Array = []  # [name, pos, look]
var job_idx := 0
var frame := 0
var settle := 30
var loaded: Node
var setup_done := false
var elapsed := 0.0

func _init() -> void:
	args = _parse(OS.get_cmdline_user_args())
	var size := _vec2i(args.get("size", "1280x720"))
	root.size = size
	var path: String = args.get("scene", "")
	if path == "":
		push_error("capture: --scene required"); quit(2); return
	loaded = _load(path)
	if loaded == null:
		push_error("capture: failed to load " + path); quit(2); return
	root.add_child(loaded)
	if args.has("lit"):
		_add_light()
	cam = Camera3D.new()
	cam.fov = float(args.get("fov", 70))
	cam.far = 2000.0
	root.add_child(cam)
	settle = int(args.get("frames", 30))

func _setup_first_frame() -> void:  # tree is live only from the first frame on
	_build_jobs()
	if args.has("exec"):
		var s: GDScript = load(args["exec"])
		var o = s.new()
		if o.has_method("run"):
			o.run(loaded, self)

func _bounds(n: Node, box: Array) -> void:
	if n is MeshInstance3D and n.mesh:
		var b: AABB = n.global_transform * n.mesh.get_aabb()
		box[0] = b if box[0] == null else (box[0] as AABB).merge(b)
	for c in n.get_children():
		_bounds(c, box)

func _build_jobs() -> void:
	var look := _vec3(args.get("look", "0,1,0"))
	var auto_d := 8.0
	if args.has("fit"):  # frame the loaded content: look at its bounds centre, distance from its size
		var box: Array = [null]
		_bounds(loaded, box)
		if box[0] != null:
			var bb: AABB = box[0]
			look = bb.get_center()
			auto_d = maxf(bb.size.length() * 1.1, 2.0)
	if args.has("views"):
		var d := float(args.get("dist", auto_d))
		for v in String(args["views"]).split(","):
			if PRESETS.has(v):
				var dir: Vector3 = PRESETS[v]
				var p := look + dir.normalized() * d
				if v == "eye":
					p = look + Vector3(0, 1.7 - look.y, 0) + Vector3(0, 0, d)
				jobs.append([v, p, look])
	else:
		jobs.append(["", _vec3(args.get("cam", "0,2,6")), look])

func _hide_ui(n: Node) -> void:
	if n is CanvasLayer:
		n.visible = false
		return
	for c in n.get_children():
		_hide_ui(c)

func _process(_delta: float) -> bool:
	frame += 1
	if not setup_done:
		setup_done = true
		_setup_first_frame()
	if job_idx >= jobs.size():
		quit(0); return true
	var j: Array = jobs[job_idx]
	cam.global_position = j[1]
	cam.look_at(j[2], Vector3.UP)
	cam.make_current()
	elapsed += _delta
	if args.has("no-ui"):
		_hide_ui(root)
	if frame >= settle and elapsed >= float(args.get("wait", 0.0)):
		var img := root.get_texture().get_image()
		var out := String(args.get("out", "shots/capture"))
		if j[0] != "":
			out += "_" + j[0]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out).get_base_dir())
		var err := img.save_png(out + ".png")
		print("CAPTURE ", "ok " if err == OK else "FAIL ", out, ".png")
		job_idx += 1
		frame = 0
	return false

func _load(path: String) -> Node:
	if path.ends_with(".glb") or path.ends_with(".gltf"):
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path), st) != OK:
			return null
		var scn := doc.generate_scene(st)
		_hide_colonly(scn)
		return scn
	var res = load(path)
	return res.instantiate() if res is PackedScene else null

func _hide_colonly(n: Node) -> void:  # editor import makes "-colonly" nodes collision-only; hide them like the editor would
	if n is Node3D and (String(n.name).ends_with("-colonly") or String(n.name).ends_with("-col")):
		n.visible = false
	for c in n.get_children():
		_hide_colonly(c)

func _add_light() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.25)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	root.add_child(sun)

func _parse(a: PackedStringArray) -> Dictionary:
	var d := {}
	var i := 0
	while i < a.size():
		if a[i].begins_with("--"):
			var k := a[i].substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				d[k] = a[i + 1]; i += 1
			else:
				d[k] = true
		i += 1
	return d

func _vec3(s: String) -> Vector3:
	var p := s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))

func _vec2i(s: String) -> Vector2i:
	var p := s.split("x")
	return Vector2i(int(p[0]), int(p[1]))
