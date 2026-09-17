class_name SmallBunker
extends Node3D

signal dosimeter_acquired()

const CONCRETE_TEX = preload("res://textures/concrete_seamless.png")
const METAL_TEX = preload("res://textures/gun_metal_scratched.png")
const HAZARD_TEX = preload("res://textures/hazard_stripes.png")
const BEACON_SOUND = preload("res://audio/digital/Audio/twoTone1.ogg")
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")

var is_claimed: bool = false
var item_node: Node3D
var item_light: OmniLight3D
var roof_light: OmniLight3D
var audio_beacon: AudioStreamPlayer3D
var prompt_canvas: CanvasLayer
var prompt_label: Label
var chirp_timer: float = 0.5

func build_bunker(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var c_mat = StandardMaterial3D.new()
	c_mat.albedo_texture = CONCRETE_TEX; c_mat.albedo_color = Color(0.68, 0.70, 0.72)
	c_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; c_mat.uv1_triplanar = true
	c_mat.uv1_scale = Vector3(0.2, 0.2, 0.2); c_mat.roughness = 0.95

	var m_mat = StandardMaterial3D.new()
	m_mat.albedo_texture = METAL_TEX; m_mat.albedo_color = Color(0.35, 0.38, 0.42)
	m_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST; m_mat.roughness = 0.65; m_mat.metallic = 0.8

	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_texture = HAZARD_TEX; h_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	# Concrete Bunker Structure (6.2m wide, 2.9m tall, 5.4m deep)
	_box(Vector3(0.0, -0.6, 0.0), Vector3(6.4, 1.4, 5.6), c_mat)  # Deep foundation skirt
	_box(Vector3(0.0, 0.18, 0.0), Vector3(6.2, 0.36, 5.4), c_mat) # Floor slab
	_box(Vector3(-2.8, 1.5, 0.0), Vector3(0.6, 2.7, 5.4), c_mat)  # Left wall
	_box(Vector3(2.8, 1.5, 0.0), Vector3(0.6, 2.7, 5.4), c_mat)   # Right wall
	_box(Vector3(0.0, 1.5, -2.4), Vector3(6.2, 2.7, 0.6), c_mat)  # Back wall
	_box(Vector3(-2.1, 1.5, 2.4), Vector3(1.8, 2.7, 0.6), c_mat)  # Front left portal
	_box(Vector3(2.1, 1.5, 2.4), Vector3(1.8, 2.7, 0.6), c_mat)   # Front right portal
	_box(Vector3(0.0, 2.95, 0.0), Vector3(6.6, 0.4, 5.8), c_mat)  # Cantilever roof
	_box(Vector3(0.0, 2.65, 2.45), Vector3(2.4, 0.3, 0.2), h_mat, false) # Doorway hazard trim

	# Equipment Console Desk in back of bunker
	_box(Vector3(0.0, 0.45, -1.2), Vector3(1.5, 0.85, 0.7), m_mat)

	# Overhead interior utility light & roof beacon
	var int_light = OmniLight3D.new(); int_light.position = Vector3(0.0, 2.4, -0.8)
	int_light.light_color = Color(1.0, 0.78, 0.3); int_light.light_energy = 2.4; int_light.omni_range = 9.0
	add_child(int_light)

	roof_light = OmniLight3D.new(); roof_light.position = Vector3(0.0, 3.6, 0.0)
	roof_light.light_color = Color(1.0, 0.68, 0.15); roof_light.light_energy = 4.0; roof_light.omni_range = 35.0
	add_child(roof_light)

	audio_beacon = AudioStreamPlayer3D.new(); audio_beacon.stream = BEACON_SOUND
	audio_beacon.unit_size = 12.0; audio_beacon.max_distance = 90.0; audio_beacon.volume_db = 2.5
	add_child(audio_beacon)

	_create_physical_item(m_mat)
	_setup_prompt_ui()

func _create_physical_item(m_mat: Material) -> void:
	item_node = Node3D.new(); item_node.position = Vector3(0.0, 0.95, -1.2); add_child(item_node)
	var scrn_mat = StandardMaterial3D.new(); scrn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scrn_mat.albedo_color = Color(1.0, 0.82, 0.2)

	var body = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = Vector3(0.28, 0.14, 0.22)
	body.mesh = bm; body.material_override = m_mat; item_node.add_child(body)

	var scrn = MeshInstance3D.new(); var sm = BoxMesh.new(); sm.size = Vector3(0.14, 0.02, 0.10)
	scrn.mesh = sm; scrn.material_override = scrn_mat; scrn.position = Vector3(0.0, 0.075, 0.0); item_node.add_child(scrn)

	item_light = OmniLight3D.new(); item_light.position = Vector3(0.0, 0.3, 0.0)
	item_light.light_color = Color(1.0, 0.85, 0.25); item_light.light_energy = 2.2; item_light.omni_range = 3.2
	item_node.add_child(item_light)

func _box(pos: Vector3, sz: Vector3, mat: Material, col: bool = true) -> void:
	var mi = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = sz
	mi.mesh = bm; mi.position = pos; mi.material_override = mat; add_child(mi)
	if col:
		var sb = StaticBody3D.new(); var cs = CollisionShape3D.new()
		var shape = BoxShape3D.new(); shape.size = sz; cs.shape = shape; cs.position = pos
		sb.add_child(cs); add_child(sb)

func _setup_prompt_ui() -> void:
	prompt_canvas = CanvasLayer.new(); prompt_canvas.layer = 13; add_child(prompt_canvas)
	prompt_label = Label.new(); prompt_label.text = "[ E ] TAKE RAD-DOSIMETER"
	prompt_label.set_anchors_preset(Control.PRESET_CENTER); prompt_label.position.y += 40
	prompt_label.modulate = Color(1.0, 0.85, 0.2, 0.0); prompt_canvas.add_child(prompt_label)

func _process(delta: float) -> void:
	if is_claimed: return
	var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
	if roof_light: roof_light.light_energy = lerpf(1.8, 4.5, pulse)
	if item_node: item_node.position.y = 0.95 + sin(Time.get_ticks_msec() * 0.005) * 0.03
	chirp_timer -= delta
	if chirp_timer <= 0.0:
		chirp_timer = 1.5
		if audio_beacon: audio_beacon.play()

func check_interaction(player_pos: Vector3) -> bool:
	if is_claimed or not item_node: return false
	var dist = item_node.global_position.distance_to(player_pos)
	if dist < 3.2:
		prompt_label.modulate.a = clampf((3.2 - dist) / 1.2, 0.0, 1.0)
		if dist < 1.6 or Input.is_action_just_pressed("interact"):
			_claim_item()
			return true
	else:
		prompt_label.modulate.a = 0.0
	return false

func _claim_item() -> void:
	is_claimed = true
	if prompt_canvas: prompt_canvas.queue_free()
	if is_instance_valid(item_node): item_node.queue_free()
	if audio_beacon: audio_beacon.stop()
	var sfx = AudioStreamPlayer.new(); sfx.stream = PICKUP_SOUND; sfx.volume_db = 0.0; add_child(sfx); sfx.play()
	var sfx2 = AudioStreamPlayer.new(); sfx2.stream = SWITCH_SOUND; sfx2.volume_db = -3.0; add_child(sfx2); sfx2.play()
	dosimeter_acquired.emit()
