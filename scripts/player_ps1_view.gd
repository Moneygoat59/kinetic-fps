class_name PlayerPs1View
extends RefCounted

static func apply_ps1_visuals(parent: Node, gun_mesh: Node3D, grenade_mount: Node3D) -> void:
	# Screen Post-Processing: PS1 Bayer Dithering & Color Quantization
	var pp_shader = load("res://shaders/ps1_post_process.gdshader") as Shader
	if pp_shader:
		var pp_layer = CanvasLayer.new()
		pp_layer.name = "PS1PostProcessLayer"
		pp_layer.layer = 1
		var pp_rect = ColorRect.new()
		pp_rect.name = "PS1Effect"
		pp_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		pp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pp_mat = ShaderMaterial.new()
		pp_mat.shader = pp_shader
		pp_mat.set_shader_parameter("pixel_size", 1.0)
		pp_mat.set_shader_parameter("color_depth", 64.0)
		pp_mat.set_shader_parameter("dither_amount", 0.0)
		pp_rect.material = pp_mat
		pp_layer.add_child(pp_rect)
		parent.add_child(pp_layer)

	# Model Shaders with Retro Triplanar & Vertex Jitter
	var model_shader = load("res://shaders/ps1_triplanar_model.gdshader") as Shader
	if not model_shader:
		return

	var gun_tex: Texture2D = _load_texture("res://textures/gun_metal_scratched.png")
	if gun_tex and gun_mesh:
		var gun_mat = ShaderMaterial.new()
		gun_mat.shader = model_shader
		gun_mat.set_shader_parameter("albedo_texture", gun_tex)
		gun_mat.set_shader_parameter("uv_scale", Vector3(8.0, 8.0, 8.0))
		gun_mat.set_shader_parameter("jitter_resolution", 180.0)
		gun_mat.set_shader_parameter("metallic", 0.3)
		gun_mat.set_shader_parameter("roughness", 0.8)
		gun_mat.set_shader_parameter("tint_color", Color.WHITE)
		_apply_material_recursive(gun_mesh, gun_mat)

	var haz_tex: Texture2D = _load_texture("res://textures/hazard_stripes.png")
	if haz_tex and grenade_mount:
		var g_model = grenade_mount.get_node_or_null("GrenadeModel")
		if g_model:
			var haz_mat = ShaderMaterial.new()
			haz_mat.shader = model_shader
			haz_mat.set_shader_parameter("albedo_texture", haz_tex)
			haz_mat.set_shader_parameter("uv_scale", Vector3(10.0, 10.0, 10.0))
			haz_mat.set_shader_parameter("jitter_resolution", 180.0)
			haz_mat.set_shader_parameter("metallic", 0.2)
			haz_mat.set_shader_parameter("roughness", 0.85)
			haz_mat.set_shader_parameter("tint_color", Color(0.9, 0.85, 0.8))
			_apply_material_recursive(g_model, haz_mat)

static func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	var img = Image.new()
	if img.load(path) == OK:
		return ImageTexture.create_from_image(img)
	return null

static func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)
