class_name OutpostBuilding
extends Node3D

signal key_acquired(outpost_id: int)

const BunkerBuilder = preload("res://scripts/bunker_builder.gd")
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")

var outpost_id: int = 2; var theme_color: Color = Color(0.15, 0.8, 1.0); var is_claimed: bool = false
var terminal_light: OmniLight3D; var roof_light: OmniLight3D; var core_light: OmniLight3D
var item_node: Node3D; var prompt_canvas: CanvasLayer; var prompt_label: Label

func build_outpost(terrain: Node3D, pos_x: float, pos_z: float, id: int, col: Color) -> void:
	outpost_id = id; theme_color = col
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var b_mat = BunkerBuilder.mat_basalt(); var p_mat = BunkerBuilder.mat_panel()
	var m_mat = BunkerBuilder.mat_metal(); var h_mat = BunkerBuilder.mat_hazard()
	var glow_mat = BunkerBuilder.mat_glow(theme_color, 2.8, BunkerBuilder.meter_tex)

	# 1. Fortified basalt base foundation
	BunkerBuilder.cylinder(self, Vector3(0.0, -0.6, 0.0), 7.8, 7.8, 1.4, 16, b_mat)
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.1, 0.0), 6.9, 6.9, 0.25, 16, p_mat)

	if id == 2:
		# OUTPOST 02: HIGH-VOLTAGE RESONANCE SUBSTATION (Cyan)
		var bunker = BunkerBuilder.load_glb("res://models/bunker_structure_module.glb")
		if bunker:
			bunker.scale = Vector3(5.2, 4.0, 5.2)
			BunkerBuilder.recolor(bunker, b_mat, p_mat); BunkerBuilder.add_collisions(bunker); add_child(bunker)
		BunkerBuilder.spawn(self, "res://models/industrial/structure-doorway.glb", Vector3(0.0, 0.0, 2.9), Vector3(2.2, 1.4, 1.5), 0.0, b_mat, m_mat)
		BunkerBuilder.spawn(self, "res://models/prop_complex_transformer.glb", Vector3(4.8, 0.1, -1.0), Vector3(3.2, 3.2, 3.2), deg_to_rad(-30), m_mat, b_mat)
		BunkerBuilder.spawn(self, "res://models/prop_substation_tower.glb", Vector3(-4.6, 0.1, -0.8), Vector3(2.4, 2.8, 2.4), deg_to_rad(20), m_mat, b_mat)
		BunkerBuilder.spawn(self, "res://models/industrial/pipe-large-bend.glb", Vector3(2.8, 0.1, 2.0), Vector3(1.4, 1.4, 1.4), deg_to_rad(-90), m_mat, b_mat)
		# Interior alien power siphon core
		var orb = BunkerBuilder.spawn(self, "res://models/prop_alien_energy_orb.glb", Vector3(1.8, 1.2, -1.5), Vector3(0.6, 0.6, 0.6), 0.0, glow_mat, m_mat, false)
		core_light = BunkerBuilder.omni(self, Vector3(1.8, 1.2, -1.5), theme_color, 2.8, 5.0)
	else:
		# OUTPOST 03: XENOBIOLOGICAL CONTAINMENT LAB (Emerald Green)
		var bunker = BunkerBuilder.load_glb("res://models/bunker_small.glb")
		if bunker:
			bunker.scale = Vector3(4.8, 3.8, 4.8)
			var g2 = bunker.find_child("gate2", true, false)
			if g2: g2.get_parent().remove_child(g2); g2.queue_free()
			BunkerBuilder.recolor(bunker, b_mat, p_mat); BunkerBuilder.add_collisions(bunker); add_child(bunker)
		BunkerBuilder.spawn(self, "res://models/industrial/structure-doorway.glb", Vector3(0.0, 0.0, 3.6), Vector3(2.2, 1.4, 1.5), 0.0, b_mat, m_mat)
		BunkerBuilder.spawn(self, "res://models/prop_containment_vat.glb", Vector3(4.5, 0.1, -1.2), Vector3(3.4, 3.4, 3.4), deg_to_rad(-45), m_mat, glow_mat)
		BunkerBuilder.spawn(self, "res://models/prop_alien_biomech_spire.glb", Vector3(-4.4, 0.1, -1.0), Vector3(1.8, 2.2, 1.8), 0.0, b_mat, glow_mat)
		BunkerBuilder.box(self, Vector3(3.6, 0.4, 2.4), Vector3(0.6, 0.8, 2.2), h_mat, deg_to_rad(30))
		core_light = BunkerBuilder.omni(self, Vector3(4.5, 2.0, -1.2), theme_color, 3.2, 6.0)

	# Shared Interior: Wall machine, diagnostic panel, key extraction pedestal
	BunkerBuilder.spawn(self, "res://models/industrial/machine-fortified.glb", Vector3(-2.4, 0.1, -1.2), Vector3(1.3, 1.4, 1.3), deg_to_rad(90), m_mat, b_mat)
	BunkerBuilder.spawn(self, "res://models/industrial/screen-panel-flat.glb", Vector3(0.0, 1.5, -2.5), Vector3(1.6, 1.6, 1.6), 0.0, glow_mat, m_mat)
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.45, -1.8), 0.85, 0.95, 0.9, 12, m_mat)

	# Security Key extraction dock
	item_node = Node3D.new(); item_node.position = Vector3(0.0, 0.95, -1.8); add_child(item_node)
	BunkerBuilder.cylinder(item_node, Vector3(0.0, 0.05, 0.0), 0.28, 0.32, 0.10, 8, m_mat)
	BunkerBuilder.cylinder(item_node, Vector3(0.0, 0.16, 0.0), 0.14, 0.14, 0.22, 6, glow_mat, false)

	terminal_light = BunkerBuilder.omni(item_node, Vector3(0.0, 0.35, 0.0), theme_color, 2.4, 4.5)
	roof_light = BunkerBuilder.omni(self, Vector3(0.0, 4.8, 0.0), theme_color, 6.0, 45.0)
	_setup_prompt_ui()

func _process(delta: float) -> void:
	if is_claimed: return
	if item_node: item_node.position.y = 0.95 + sin(Time.get_ticks_msec() * 0.005) * 0.02
	if terminal_light: terminal_light.light_energy = lerpf(1.6, 3.4, (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5)

func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	var t_pos = item_node.global_position if is_instance_valid(item_node) else to_global(Vector3(0.0, 0.95, -1.8))
	var dist = t_pos.distance_to(player_pos)
	if dist > 4.8:
		if prompt_label: prompt_label.modulate.a = 0.0
		return false
	if prompt_label:
		prompt_label.modulate.a = clampf((4.8 - dist) / 1.5, 0.0, 1.0)
		prompt_label.text = "[ KEY ACQUIRED ] RETURN TO CENTRAL HUB" if is_claimed else ("[ E ] EXTRACT SECURITY KEY 0%d" % outpost_id)
	if not is_claimed and (force or Input.is_action_just_pressed("interact")):
		_claim_key(); return true
	return false

func _claim_key() -> void:
	is_claimed = true
	if is_instance_valid(item_node): item_node.queue_free()
	var s1 = AudioStreamPlayer.new(); s1.stream = PICKUP_SOUND; add_child(s1); s1.play()
	var s2 = AudioStreamPlayer.new(); s2.stream = SWITCH_SOUND; add_child(s2); s2.play()
	key_acquired.emit(outpost_id)

func _setup_prompt_ui() -> void:
	prompt_canvas = CanvasLayer.new(); prompt_canvas.layer = 13; add_child(prompt_canvas)
	prompt_label = Label.new(); prompt_label.set_anchors_preset(Control.PRESET_CENTER); prompt_label.position.y += 40
	prompt_label.modulate = Color(1.0, 0.85, 0.25, 0.0); prompt_canvas.add_child(prompt_label)
