class_name GallerySpawner
extends RefCounted

static var _pedestal_mat: StandardMaterial3D

static func _ensure_materials() -> void:
	if _pedestal_mat: return
	_pedestal_mat = StandardMaterial3D.new()
	_pedestal_mat.albedo_color = Color(0.12, 0.13, 0.16)
	_pedestal_mat.roughness = 0.85
	_pedestal_mat.metallic = 0.2

static func instantiate_model(path: String) -> Node3D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is PackedScene:
			return res.instantiate() as Node3D
	if path.ends_with(".glb") or path.ends_with(".gltf"):
		var doc = GLTFDocument.new()
		var state = GLTFState.new()
		if doc.append_from_file(ProjectSettings.globalize_path(path), state) == OK:
			return doc.generate_scene(state) as Node3D
	return null

static func compute_aabb(node: Node) -> AABB:
	var total_aabb = AABB()
	var first = true
	var meshes = node.find_children("*", "MeshInstance3D")
	for child in meshes:
		var mi = child as MeshInstance3D
		if mi and mi.mesh:
			var box = mi.transform * mi.mesh.get_aabb()
			if first:
				total_aabb = box
				first = false
			else:
				total_aabb = total_aabb.merge(box)
	if first:
		total_aabb = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 1.0, 1.0))
	return total_aabb

static func spawn_exhibit(parent: Node, path: String, pos: Vector3, aisle_name: String) -> Node3D:
	_ensure_materials()
	var model = instantiate_model(path)
	if not model: return null

	var exhibit = Node3D.new()
	exhibit.name = path.get_file().get_basename()
	exhibit.position = pos
	parent.add_child(exhibit)

	var aabb = compute_aabb(model)
	var ped_w = maxf(aabb.size.x + 0.8, 2.2)
	var ped_d = maxf(aabb.size.z + 0.8, 2.2)
	var ped_h = 0.3

	# Display pedestal
	var ped_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(ped_w, ped_h, ped_d)
	ped_mesh.mesh = box
	ped_mesh.material_override = _pedestal_mat
	ped_mesh.position.y = ped_h * 0.5
	exhibit.add_child(ped_mesh)

	# Center model on pedestal
	model.position = Vector3(
		-aabb.get_center().x,
		-aabb.position.y + ped_h,
		-aabb.get_center().z
	)
	exhibit.add_child(model)

	# Label 3D billboard
	var label = Label3D.new()
	label.name = "Label"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 26
	label.outline_size = 6
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.95)
	label.modulate = Color(0.92, 0.96, 1.0)
	var fname = path.get_file()
	label.text = "%s\n[%.1fm × %.1fm × %.1fm]" % [fname, aabb.size.x, aabb.size.y, aabb.size.z]
	label.position = Vector3(0.0, ped_h + aabb.size.y + 0.75, 0.0)
	exhibit.add_child(label)

	exhibit.set_meta("model_path", path)
	exhibit.set_meta("model_name", fname)
	exhibit.set_meta("aisle", aisle_name)
	exhibit.set_meta("bounds", aabb.size)
	return exhibit

static func spawn_aisle_arch(parent: Node, pos: Vector3, title: String, count: int) -> void:
	var arch = Node3D.new()
	arch.name = "Arch_" + title.validate_node_name()
	arch.position = pos
	parent.add_child(arch)

	var banner = Label3D.new()
	banner.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	banner.font_size = 48
	banner.outline_size = 10
	banner.outline_modulate = Color(0.0, 0.0, 0.0, 0.95)
	banner.modulate = Color(1.0, 0.82, 0.30)
	banner.text = "=== %s (%d MODELS) ===" % [title.to_upper(), count]
	banner.position = Vector3(0.0, 6.0, 0.0)
	arch.add_child(banner)
