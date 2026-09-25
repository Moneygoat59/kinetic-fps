class_name HubBuilding
extends Node3D

signal hub_interacted(stage: int)

const BunkerBuilder = preload("res://scripts/bunker_builder.gd")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")
const POWER_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")

var current_stage: int = 0; var terminal_light: OmniLight3D; var roof_light: OmniLight3D
var screen_mat: StandardMaterial3D; var prompt_canvas: CanvasLayer; var prompt_label: Label
var terminal_node: Node3D; var overhead_screen: Node3D
var bay_lights: Array[OmniLight3D] = []

func build_hub(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)
	var b_mat = BunkerBuilder.mat_basalt(); var p_mat = BunkerBuilder.mat_panel()
	var m_mat = BunkerBuilder.mat_metal(); var h_mat = BunkerBuilder.mat_hazard()

	# 1. Colossal polygonal foundation apron & blast perimeter
	BunkerBuilder.cylinder(self, Vector3(0.0, -0.6, 0.0), 9.2, 9.2, 1.4, 18, b_mat)
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.1, 0.0), 8.4, 8.4, 0.25, 18, p_mat)
	BunkerBuilder.box(self, Vector3(-7.2, 0.5, 0.0), Vector3(1.5, 2.2, 7.5), b_mat, deg_to_rad(-12))
	BunkerBuilder.box(self, Vector3(7.2, 0.5, 0.0), Vector3(1.5, 2.2, 7.5), b_mat, deg_to_rad(12))

	# 2. Main structure: Reinforced large hangar facility
	var hangar = BunkerBuilder.load_glb("res://models/bunker_hangar_large.glb")
	if hangar:
		hangar.scale = Vector3(6.2, 4.6, 6.2)
		var g2 = hangar.find_child("gate2", true, false)
		if g2: g2.get_parent().remove_child(g2); g2.queue_free()
		BunkerBuilder.recolor(hangar, b_mat, p_mat); BunkerBuilder.add_collisions(hangar); add_child(hangar)

	# 3. Double-frame blast portal & industrial power conduits
	BunkerBuilder.spawn(self, "res://models/industrial/structure-doorway.glb", Vector3(0.0, 0.0, 4.2), Vector3(2.6, 1.6, 1.6), 0.0, b_mat, m_mat)
	BunkerBuilder.spawn(self, "res://models/industrial/pipe-large-bend.glb", Vector3(6.2, 0.1, 1.8), Vector3(1.8, 1.8, 1.8), deg_to_rad(-90), m_mat, b_mat)

	# 4. Heavy rooftop communications relay & exterior industrial generator
	BunkerBuilder.spawn(self, "res://models/bunker_satellite.glb", Vector3(0.0, 4.8, -3.2), Vector3(3.2, 3.2, 3.2), 0.0, m_mat, b_mat)
	BunkerBuilder.spawn(self, "res://models/prop_generator_large.glb", Vector3(6.8, 0.15, 1.8), Vector3(2.2, 2.2, 2.2), deg_to_rad(-40), m_mat, b_mat)

	# 5. Command interior: Wall computer banks & suspended overhead display
	BunkerBuilder.spawn(self, "res://models/industrial/machine-fortified.glb", Vector3(-3.4, 0.1, -1.8), Vector3(1.5, 1.6, 1.5), deg_to_rad(90), m_mat, b_mat)
	BunkerBuilder.spawn(self, "res://models/industrial/machine-fortified.glb", Vector3(3.4, 0.1, -1.8), Vector3(1.5, 1.6, 1.5), deg_to_rad(-90), m_mat, b_mat)
	overhead_screen = BunkerBuilder.spawn(self, "res://models/industrial/screen-hanging-wide.glb", Vector3(0.0, 3.6, -2.6), Vector3(2.2, 2.0, 2.2), 0.0, null, m_mat)

	# 6. Central Triangulation Console with 3 receptacle bays
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.5, -2.4), 1.6, 1.8, 1.0, 12, m_mat)
	screen_mat = BunkerBuilder.mat_glow(Color(0.15, 0.8, 1.0), 3.0, BunkerBuilder.meter_tex)
	BunkerBuilder.cylinder(self, Vector3(0.0, 1.05, -2.4), 0.75, 0.85, 0.18, 10, screen_mat, false)
	terminal_node = Node3D.new(); terminal_node.position = Vector3(0.0, 1.1, -2.4); add_child(terminal_node)

	# Triangulation frequency receptacle bays (Bay 1 Amber, Bay 2 Cyan, Bay 3 Green)
	bay_lights.clear()
	for i in range(3):
		var ang = -PI * 0.4 + float(i) * PI * 0.4; var b_pos = Vector3(sin(ang) * 1.25, 0.85, -2.4 + cos(ang) * 0.7)
		BunkerBuilder.cylinder(self, b_pos, 0.16, 0.20, 0.35, 8, m_mat)
		var col = Color(1.0, 0.65, 0.12) if i == 0 else (Color(0.15, 0.8, 1.0) if i == 1 else Color(0.2, 0.95, 0.35))
		bay_lights.append(BunkerBuilder.omni(self, b_pos + Vector3(0.0, 0.25, 0.0), col, 0.4, 2.0))

	terminal_light = BunkerBuilder.omni(self, Vector3(0.0, 2.2, -2.4), Color(0.15, 0.8, 1.0), 2.2, 8.0)
	roof_light = BunkerBuilder.omni(self, Vector3(0.0, 5.8, 0.0), Color(1.0, 0.72, 0.2), 6.5, 55.0)

	_setup_prompt_ui(); set_stage(0)

func set_stage(stage: int) -> void:
	current_stage = stage
	var col = Color(0.15, 0.8, 1.0)
	if stage >= 2 and stage < 4: col = Color(0.2, 0.95, 0.35)
	elif stage >= 4: col = Color(1.0, 0.15, 0.1)
	if terminal_light: terminal_light.light_color = col
	if screen_mat: screen_mat.emission = col
	if roof_light: roof_light.light_color = col
	if bay_lights.size() >= 3:
		bay_lights[0].light_energy = 2.5
		bay_lights[1].light_energy = 2.5 if stage >= 2 else 0.4
		bay_lights[2].light_energy = 2.5 if stage >= 4 else 0.4

func _process(delta: float) -> void:
	if terminal_light: terminal_light.light_energy = lerpf(1.8, 3.5, (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5)

func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	var t_pos = terminal_node.global_position if is_instance_valid(terminal_node) else to_global(Vector3(0.0, 1.1, -2.4))
	var dist = t_pos.distance_to(player_pos)
	if dist > 4.8:
		if prompt_label: prompt_label.modulate.a = 0.0
		return false
	var interactable = (current_stage == 0 or current_stage == 2 or current_stage == 4)
	if prompt_label:
		prompt_label.modulate.a = clampf((4.8 - dist) / 1.5, 0.0, 1.0)
		prompt_label.text = _get_prompt_text()
	if interactable and (force or dist < 2.5 or Input.is_action_just_pressed("interact")):
		_interact(); return true
	return false

func _interact() -> void:
	var s1 = AudioStreamPlayer.new(); s1.stream = SWITCH_SOUND; add_child(s1); s1.play()
	var s2 = AudioStreamPlayer.new(); s2.stream = POWER_SOUND; add_child(s2); s2.play()
	var activated_stage = current_stage
	set_stage(current_stage + 1)
	hub_interacted.emit(activated_stage)

func _get_prompt_text() -> String:
	match current_stage:
		0: return "[ E ] ACCESS HUB TERMINAL: TUNE FREQUENCY 2 [CYAN]"
		1: return "[ FREQUENCY 2 ONLINE ] LOCATE OUTPOST 02 IN DEEP FOREST"
		2: return "[ E ] INSERT OUTPOST 02 KEY: TUNE FREQUENCY 3 [GREEN]"
		3: return "[ FREQUENCY 3 ONLINE ] LOCATE OUTPOST 03 IN DEEP FOREST"
		4: return "[ E ] ENGAGE TRIANGULATION ARRAY: UNSEAL SILO GRID [CRIMSON]"
		_: return "[ SILO GRID ACTIVE ] PROCEED ALONG CRIMSON BEACONS"

func _setup_prompt_ui() -> void:
	prompt_canvas = CanvasLayer.new(); prompt_canvas.layer = 13; add_child(prompt_canvas)
	prompt_label = Label.new(); prompt_label.set_anchors_preset(Control.PRESET_CENTER); prompt_label.position.y += 40
	prompt_label.modulate = Color(1.0, 0.85, 0.25, 0.0); prompt_canvas.add_child(prompt_label)
