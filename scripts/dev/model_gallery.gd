class_name ModelGallery
extends Node3D

const GALLERY_CATALOG = preload("res://scripts/dev/gallery_catalog.gd")
const GALLERY_SPAWNER = preload("res://scripts/dev/gallery_spawner.gd")
const GALLERY_FLYCAM = preload("res://scripts/dev/gallery_flycam.gd")
const GALLERY_UI = preload("res://scripts/dev/gallery_ui.gd")

var cam: Camera3D
var ui: CanvasLayer
var aisles: Array[Dictionary] = []
var teleport_points: Array[Dictionary] = []
var all_exhibits: Array[Node3D] = []

func _ready() -> void:
	_setup_environment()
	_setup_floor()
	_setup_camera()
	aisles = GALLERY_CATALOG.build_catalog()
	_setup_ui()
	_populate_gallery()

func _setup_environment() -> void:
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.07, 0.08, 0.10)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.38, 0.44)
	env.ambient_light_energy = 1.3
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 36.0, 0.0)
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	add_child(sun)

	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(45.0, -140.0, 0.0)
	fill.light_color = Color(0.40, 0.50, 0.65)
	fill.light_energy = 0.5
	add_child(fill)

func _setup_floor() -> void:
	var mi = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(2500.0, 3500.0)
	mi.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.11, 0.13)
	mat.roughness = 0.92
	mi.material_override = mat
	add_child(mi)

func _setup_camera() -> void:
	cam = GALLERY_FLYCAM.new()
	cam.name = "FlyCam"
	cam.position = Vector3(0.0, 6.0, -22.0)
	add_child(cam)

func _setup_ui() -> void:
	ui = GALLERY_UI.new()
	ui.name = "GalleryUI"
	add_child(ui)
	ui.setup(aisles)
	cam.speed_changed.connect(ui.on_speed_changed)
	ui.teleport_requested.connect(_on_teleport)

func _populate_gallery() -> void:
	var aisle_spacing_x = 28.0
	for i in range(aisles.size()):
		var cat = aisles[i]
		var ax = i * aisle_spacing_x
		GALLERY_SPAWNER.spawn_aisle_arch(self, Vector3(ax, 0.0, -12.0), cat["name"], cat["count"])
		teleport_points.append({
			"pos": Vector3(ax, 6.0, -24.0),
			"look": Vector3(ax, 4.0, 10.0)
		})

		var models: Array = cat["models"]
		var z_offset = 0.0
		var spawn_batch = 0
		for m_path in models:
			var pos = Vector3(ax, 0.0, z_offset)
			var ex = GALLERY_SPAWNER.spawn_exhibit(self, m_path, pos, cat["name"])
			if ex:
				all_exhibits.append(ex)
			z_offset += 7.5
			spawn_batch += 1
			if spawn_batch % 16 == 0:
				await get_tree().process_frame
				if not is_inside_tree(): return

	if teleport_points.size() > 0:
		_on_teleport(0)

func _on_teleport(idx: int) -> void:
	if idx >= 0 and idx < teleport_points.size():
		var tp = teleport_points[idx]
		cam.teleport_to(tp["pos"], tp["look"])

func _physics_process(_delta: float) -> void:
	if not cam: return
	var ray_from = cam.global_position
	var ray_dir = -cam.global_transform.basis.z
	var closest_dist = 45.0
	var hit_exhibit: Node3D = null

	for ex in all_exhibits:
		if not is_instance_valid(ex): continue
		var to_ex = ex.global_position - ray_from
		var proj = to_ex.dot(ray_dir)
		if proj > 0.0 and proj < closest_dist:
			var perp = (to_ex - ray_dir * proj).length()
			if perp < 3.5:
				closest_dist = proj
				hit_exhibit = ex

	if hit_exhibit and ui:
		ui.update_inspect("[%s]  %s  (Size: %s)" % [
			hit_exhibit.get_meta("aisle", ""),
			hit_exhibit.get_meta("model_name", ""),
			hit_exhibit.get_meta("bounds", "")
		])
	elif ui:
		ui.update_inspect("")
