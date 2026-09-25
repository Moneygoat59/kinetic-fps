class_name ItemTurntable3D
extends SubViewportContainer

var viewport: SubViewport
var camera: Camera3D
var pivot: Node3D
var current_model: Node3D
var is_dragging: bool = false
var yaw: float = 0.0
var pitch: float = 0.0
var idle_spin_speed: float = 0.65

func _init() -> void:
	custom_minimum_size = Vector2(180, 180)
	stretch = true
	_setup_3d_stage()

func _setup_3d_stage() -> void:
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(180, 180)
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)

	camera = Camera3D.new()
	camera.position = Vector3(0.0, 0.0, 2.3)
	camera.fov = 42.0
	viewport.add_child(camera)

	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-35.0, 40.0, 0.0)
	key_light.light_color = Color(1.0, 0.95, 0.88)
	key_light.light_energy = 1.4
	viewport.add_child(key_light)

	var rim_light = DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(25.0, -140.0, 0.0)
	rim_light.light_color = Color(0.35, 0.85, 0.70)
	rim_light.light_energy = 0.8
	viewport.add_child(rim_light)

	pivot = Node3D.new()
	viewport.add_child(pivot)

func load_model(path: String) -> void:
	if current_model:
		current_model.queue_free()
		current_model = null

	yaw = deg_to_rad(25.0)
	pitch = deg_to_rad(12.0)
	pivot.rotation = Vector3(pitch, yaw, 0.0)
	if path.is_empty(): return

	var inst: Node3D = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			inst = res.instantiate() as Node3D
	if not inst and (path.ends_with(".glb") or path.ends_with(".gltf")):
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path), state) == OK:
			inst = doc.generate_scene(state) as Node3D

	if not inst: return
	current_model = inst
	pivot.add_child(inst)

	# Calculate combined AABB and normalize scale to fit viewer
	var aabb = _calc_aabb(inst)
	var max_dim = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var target_scale = 1.35 / maxf(max_dim, 0.001)
	inst.scale = Vector3.ONE * target_scale
	inst.position = -aabb.get_center() * target_scale

func _calc_aabb(node: Node) -> AABB:
	var total = AABB()
	var first = true
	for child in node.find_children("*", "MeshInstance3D"):
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			var box = mi.transform * mi.mesh.get_aabb()
			if first:
				total = box; first = false
			else:
				total = total.merge(box)
	return total if not first else AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
	elif event is InputEventMouseMotion and is_dragging:
		yaw += event.relative.x * 0.015
		pitch = clampf(pitch + event.relative.y * 0.015, -1.25, 1.25)
		pivot.rotation = Vector3(pitch, yaw, 0.0)

func _process(delta: float) -> void:
	if not is_dragging and pivot:
		yaw += idle_spin_speed * delta
		pivot.rotation = Vector3(pitch, yaw, 0.0)
