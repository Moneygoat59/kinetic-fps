class_name MissileSilo
extends Node3D

signal silo_activated()

const BunkerBuilder = preload("res://scripts/bunker_builder.gd")
const SMALL_BUNKER_SCRIPT = preload("res://scripts/small_bunker.gd")
const SIREN_SOUND = preload("res://audio/digital/Audio/zapThreeToneUp.ogg")
const CONFIRM_SOUND = preload("res://audio/digital/Audio/powerUp7.ogg")

var is_activated: bool = false
var alarm_lights: Array[OmniLight3D] = []
var silo_beam: OmniLight3D
var abyss_light: OmniLight3D
var flame_trench_light: OmniLight3D
var prompt_canvas: CanvasLayer
var prompt_label: Label
var status_banner: Label
var console_node: Node3D

func _ready() -> void:
	if get_child_count() == 0:
		build_silo(null, 0.0, 0.0)

func build_silo(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var b_mat = BunkerBuilder.mat_basalt()
	var bp_mat = BunkerBuilder.mat_basalt_panel()
	var bs_mat = BunkerBuilder.mat_basalt_strata()
	var m_mat = BunkerBuilder.mat_metal()
	var iron_mat = BunkerBuilder.mat_dark_iron()
	var rust_mat = BunkerBuilder.mat_rust_gantry()
	var grate_mat = BunkerBuilder.mat_grate()
	var visor_mat = BunkerBuilder.mat_visor(Color(1.0, 0.68, 0.14))
	var crt_amber = BunkerBuilder.mat_crt_amber()
	var crt_radar = BunkerBuilder.mat_crt_radar()
	var graffiti_mat = BunkerBuilder.mat_graffiti()
	var danger_mat = BunkerBuilder.mat_danger()
	var lum_mat = BunkerBuilder.mat_luminaire()
	var sludge_mat = BunkerBuilder.mat_sludge()
	var hazard_mat = BunkerBuilder.mat_hazard()
	var cable_mat = BunkerBuilder.mat_cable()

	# =========================================================================
	# 1. EXTERIOR OVERVIEW & SCALE (SURFACE RIM AT Y = 0.0)
	# =========================================================================
	# 1a. Volcanic Basalt Ground Apron (Surrounding ground collar with central hole)
	BunkerBuilder.box(self, Vector3(0.0, -0.6, 75.0), Vector3(220.0, 1.2, 100.0), bs_mat)
	BunkerBuilder.box(self, Vector3(0.0, -0.6, -75.0), Vector3(220.0, 1.2, 100.0), bs_mat)
	BunkerBuilder.box(self, Vector3(75.0, -0.6, 0.0), Vector3(100.0, 1.2, 50.0), bs_mat)
	BunkerBuilder.box(self, Vector3(-75.0, -0.6, 0.0), Vector3(100.0, 1.2, 50.0), bs_mat)

	# 1b. Segmented Outer Basalt Buttresses ("OUTPOST PLINEER") - 24 radial slabs
	for i in range(24):
		var ang = float(i) * (TAU / 24.0)
		var p_x = sin(ang) * 33.5
		var p_z = cos(ang) * 33.5
		BunkerBuilder.box_rot(self, Vector3(p_x, 0.6, p_z), Vector3(8.5, 3.2, 11.5), Vector3(deg_to_rad(-8.0), ang, 0.0), b_mat)
		var c_x = sin(ang) * 29.8
		var c_z = cos(ang) * 29.8
		BunkerBuilder.box_rot(self, Vector3(c_x, 1.4, c_z), Vector3(7.8, 1.8, 3.8), Vector3(0.0, ang, 0.0), bp_mat)

	# 1c. Retracted Silo Cap Mechanism (Rusted heavy teeth & hydraulic rams)
	for i in range(24):
		var ang = float(i) * (TAU / 24.0)
		var t_x = sin(ang) * 27.6
		var t_z = cos(ang) * 27.6
		BunkerBuilder.box_rot(self, Vector3(t_x, 1.6, t_z), Vector3(5.2, 2.4, 3.6), Vector3(0.0, ang, 0.0), rust_mat)
		var r_x = sin(ang) * 29.5
		var r_z = cos(ang) * 29.5
		BunkerBuilder.cylinder(self, Vector3(r_x, 0.9, r_z), 0.45, 0.45, 2.6, 8, iron_mat)

	# 1d. Inner Steel Guide Flange Track
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.2, 0.0), 28.2, 28.2, 0.8, 32, iron_mat, false)

	# 1e. OUTPOST 73 (FOR SCALE REFERENCE) - Placed directly on perimeter apron
	var scale_ref_bunker = SMALL_BUNKER_SCRIPT.new()
	scale_ref_bunker.build_bunker(null, 38.0, 14.0)
	scale_ref_bunker.rotation.y = deg_to_rad(-115.0)
	add_child(scale_ref_bunker)

	# =========================================================================
	# 2. CROSS-SECTIONAL ELEVATION: 70M DEEP VERTICAL BLAST SHAFT
	# =========================================================================
	# 2a. 24-sided Faceted Reinforced Basalt Shaft Wall (Y = 0 down to Y = -70)
	for i in range(24):
		var ang = float(i) * (TAU / 24.0)
		var w_x = sin(ang) * 27.5
		var w_z = cos(ang) * 27.5
		var wall_mat = bs_mat if i % 2 == 0 else bp_mat
		BunkerBuilder.box_rot(self, Vector3(w_x, -35.0, w_z), Vector3(7.4, 70.0, 2.4), Vector3(0.0, ang, 0.0), wall_mat)

	# 2b. 4 Massive Structural Steel Ring Girders (Y = -16, -34, -52, -68)
	var ring_depths: Array[float] = [-16.0, -34.0, -52.0, -68.0]
	for depth in ring_depths:
		for i in range(24):
			var ang = float(i) * (TAU / 24.0)
			var g_x = sin(ang) * 26.5
			var g_z = cos(ang) * 26.5
			BunkerBuilder.box_rot(self, Vector3(g_x, depth, g_z), Vector3(7.2, 1.4, 1.2), Vector3(0.0, ang, 0.0), iron_mat)
			BunkerBuilder.box_rot(self, Vector3(g_x, depth, g_z), Vector3(1.2, 2.0, 1.5), Vector3(0.0, ang, 0.0), rust_mat)

	# 2c. 8 Heavy Vertical Seismic Pilasters / Column Risers
	for i in range(8):
		var ang = float(i) * (TAU / 8.0)
		var p_x = sin(ang) * 26.7
		var p_z = cos(ang) * 26.7
		BunkerBuilder.box_rot(self, Vector3(p_x, -35.0, p_z), Vector3(1.6, 70.0, 1.2), Vector3(0.0, ang, 0.0), iron_mat)

	# 2d. Decayed Ventilation Shafts (Twin vertical duct columns down the wall)
	var vent_ang1 = deg_to_rad(40.0)
	var vent_ang2 = deg_to_rad(48.0)
	for va in [vent_ang1, vent_ang2]:
		var vx = sin(va) * 25.5
		var vz = cos(va) * 25.5
		BunkerBuilder.cylinder(self, Vector3(vx, -35.0, vz), 1.2, 1.2, 70.0, 12, rust_mat)
		for d in [-14.0, -32.0, -50.0, -66.0]:
			BunkerBuilder.cylinder(self, Vector3(vx * 1.04, d, vz * 1.04), 0.9, 0.9, 2.5, 8, iron_mat)
			BunkerBuilder.box(self, Vector3(vx * 1.06, d, vz * 1.06), Vector3(2.0, 1.6, 0.5), grate_mat)

	# =========================================================================
	# 3. LEVEL 1: SURFACE ACCESS & UPPER GANTRY (Y = -16.0)
	# =========================================================================
	for i in range(-5, 6):
		var ang = float(i) * 0.12
		var g_x = sin(ang) * 23.5
		var g_z = cos(ang) * 23.5
		BunkerBuilder.box_rot(self, Vector3(g_x, -16.0, g_z), Vector3(3.2, 0.35, 3.5), Vector3(0.0, ang, 0.0), grate_mat)
		var h_x = sin(ang) * 21.8
		var h_z = cos(ang) * 21.8
		BunkerBuilder.box_rot(self, Vector3(h_x, -15.4, h_z), Vector3(0.12, 1.1, 3.5), Vector3(0.0, ang, 0.0), rust_mat)
		BunkerBuilder.box_rot(self, Vector3(h_x, -15.8, h_z), Vector3(0.14, 0.3, 3.5), Vector3(0.0, ang, 0.0), hazard_mat)

	# Upper Control Room Alcove (Recessed into basalt wall at Y = -16.0)
	BunkerBuilder.box(self, Vector3(0.0, -14.5, 29.5), Vector3(10.0, 5.0, 6.0), b_mat)
	BunkerBuilder.box(self, Vector3(0.0, -14.5, 26.4), Vector3(6.5, 1.8, 0.3), visor_mat)
	BunkerBuilder.omni(self, Vector3(0.0, -14.5, 25.5), Color(1.0, 0.68, 0.14), 3.5, 16.0)

	# =========================================================================
	# 4. CONTINUOUS INTERIOR STAIRCASE / SCAFFOLDING (ZIGZAG RUNS)
	# =========================================================================
	_build_stair_flight(Vector3(12.0, -16.0, 20.0), Vector3(18.0, -25.0, 14.0), rust_mat, grate_mat)
	_build_stair_flight(Vector3(18.0, -25.0, 14.0), Vector3(14.0, -34.0, 8.0), rust_mat, grate_mat)
	_build_stair_flight(Vector3(14.0, -34.0, 8.0), Vector3(20.0, -48.0, 0.0), rust_mat, grate_mat)
	_build_stair_flight(Vector3(20.0, -48.0, 0.0), Vector3(15.0, -68.0, -8.0), rust_mat, grate_mat)

	# =========================================================================
	# 5. LEVEL 15: MID-SECTION GANTRY & DECAYED CONTROL CONSOLE (Y = -34.0)
	# =========================================================================
	# 5a. Cantilevered Main Observation Catwalk projecting into shaft towards Z=8
	BunkerBuilder.box(self, Vector3(0.0, -34.0, 18.0), Vector3(5.5, 0.45, 18.0), grate_mat)
	BunkerBuilder.box(self, Vector3(-2.8, -33.4, 18.0), Vector3(0.15, 1.1, 18.0), rust_mat)
	BunkerBuilder.box(self, Vector3(2.8, -33.4, 18.0), Vector3(0.15, 1.1, 18.0), rust_mat)
	BunkerBuilder.box(self, Vector3(-2.8, -33.8, 18.0), Vector3(0.18, 0.35, 18.0), hazard_mat)
	BunkerBuilder.box(self, Vector3(2.8, -33.8, 18.0), Vector3(0.18, 0.35, 18.0), hazard_mat)

	# Cantilever Diagonal Truss Struts underneath
	BunkerBuilder.box_rot(self, Vector3(-2.2, -37.5, 19.5), Vector3(0.4, 7.5, 0.4), Vector3(deg_to_rad(38.0), 0.0, 0.0), iron_mat)
	BunkerBuilder.box_rot(self, Vector3(2.2, -37.5, 19.5), Vector3(0.4, 7.5, 0.4), Vector3(deg_to_rad(38.0), 0.0, 0.0), iron_mat)

	# 5b. Mid-Level Control Room Alcove (Basalt chamber at Z = 27.5)
	BunkerBuilder.box(self, Vector3(0.0, -32.5, 29.5), Vector3(12.0, 6.0, 6.5), b_mat)
	BunkerBuilder.box(self, Vector3(-4.5, -32.5, 26.8), Vector3(2.2, 3.8, 1.2), iron_mat)
	BunkerBuilder.box(self, Vector3(-4.5, -31.8, 26.15), Vector3(1.4, 1.0, 0.1), danger_mat)
	BunkerBuilder.box(self, Vector3(4.5, -32.5, 26.8), Vector3(2.2, 3.8, 1.2), iron_mat)

	# 5c. Overhead Industrial Piping (Steam conduits running across basalt wall)
	BunkerBuilder.cylinder(self, Vector3(0.0, -29.5, 26.8), 0.55, 0.55, 18.0, 10, rust_mat)
	var pipe1 = get_child(get_child_count() - 1) as Node3D
	if pipe1: pipe1.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	BunkerBuilder.cylinder(self, Vector3(0.0, -28.2, 26.8), 0.38, 0.38, 18.0, 10, iron_mat)
	var pipe2 = get_child(get_child_count() - 1) as Node3D
	if pipe2: pipe2.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))

	# 5d. DECAYED CONTROL CONSOLE (Facing the walkway at Z = 11.5)
	# Positioned facing +Z so someone on the walkway approaches the screen and controls
	BunkerBuilder.box(self, Vector3(0.0, -33.2, 10.5), Vector3(3.2, 1.2, 1.6), rust_mat)
	BunkerBuilder.box(self, Vector3(0.0, -33.2, 11.32), Vector3(3.0, 1.0, 0.05), graffiti_mat)
	# Slanted keyboard counter
	BunkerBuilder.box_rot(self, Vector3(0.0, -32.55, 10.8), Vector3(3.0, 0.15, 0.8), Vector3(deg_to_rad(-18.0), 0.0, 0.0), iron_mat)
	# Left screen: Tactical Green Radar CRT
	BunkerBuilder.box_rot(self, Vector3(-0.85, -32.0, 10.2), Vector3(1.1, 0.95, 0.6), Vector3(deg_to_rad(12.0), 0.0, 0.0), iron_mat)
	BunkerBuilder.box_rot(self, Vector3(-0.85, -32.0, 10.52), Vector3(0.9, 0.75, 0.05), Vector3(deg_to_rad(12.0), 0.0, 0.0), crt_radar)
	# Right screen: Amber Telemetry Readout CRT
	BunkerBuilder.box_rot(self, Vector3(0.85, -32.0, 10.2), Vector3(1.1, 0.95, 0.6), Vector3(deg_to_rad(12.0), 0.0, 0.0), iron_mat)
	BunkerBuilder.box_rot(self, Vector3(0.85, -32.0, 10.52), Vector3(0.9, 0.75, 0.05), Vector3(deg_to_rad(12.0), 0.0, 0.0), crt_amber)

	# 5e. Overhead Amber Bulkhead Luminaires (Mounted above console and catwalk)
	BunkerBuilder.box(self, Vector3(-1.8, -30.8, 12.0), Vector3(1.6, 0.5, 0.4), lum_mat)
	BunkerBuilder.box(self, Vector3(1.8, -30.8, 12.0), Vector3(1.6, 0.5, 0.4), lum_mat)
	BunkerBuilder.omni(self, Vector3(0.0, -31.2, 12.0), Color(1.0, 0.70, 0.18), 4.5, 18.0)

	console_node = Node3D.new()
	console_node.position = Vector3(0.0, -32.5, 12.0)
	add_child(console_node)

	# =========================================================================
	# 6. LEVEL 30: BASE PLATFORM & EMPTY MISSILE MOUNT (Y = -70.0)
	# =========================================================================
	# 6a. Silo Base Floor Subterranean Basin
	BunkerBuilder.cylinder(self, Vector3(0.0, -71.5, 0.0), 27.5, 27.5, 3.0, 24, b_mat)

	# 6b. DEBRIS POOL (Murky toxic sludge / water surrounding launch mount)
	BunkerBuilder.cylinder(self, Vector3(0.0, -69.8, 0.0), 26.8, 26.8, 0.5, 24, sludge_mat, false)

	# Partially submerged debris: fallen crates, grates, conduit remnants
	BunkerBuilder.box_rot(self, Vector3(-14.0, -69.4, 8.0), Vector3(2.4, 1.5, 1.8), Vector3(deg_to_rad(15.0), deg_to_rad(35.0), deg_to_rad(-8.0)), rust_mat)
	BunkerBuilder.box_rot(self, Vector3(16.0, -69.5, -10.0), Vector3(3.2, 0.2, 4.0), Vector3(deg_to_rad(8.0), deg_to_rad(-20.0), deg_to_rad(12.0)), grate_mat)
	BunkerBuilder.box_rot(self, Vector3(-10.0, -69.3, -15.0), Vector3(2.0, 1.8, 2.0), Vector3(0.0, deg_to_rad(45.0), 0.0), iron_mat)

	# 6c. EMPTY MISSILE MOUNT (Colossal Tiered Launch Pedestal with Hollow Core)
	# We build a true hollow launch ring using 16 radial segments around radius 7.5m to 10.5m
	for i in range(16):
		var ang = float(i) * (TAU / 16.0)
		var rx = sin(ang) * 8.5
		var rz = cos(ang) * 8.5
		# Lower tiered launch pedestal segment
		BunkerBuilder.box_rot(self, Vector3(rx * 1.05, -67.5, rz * 1.05), Vector3(3.4, 2.6, 3.2), Vector3(0.0, ang, 0.0), iron_mat)
		# Upper beveled launch table segment
		BunkerBuilder.box_rot(self, Vector3(rx * 0.92, -65.6, rz * 0.92), Vector3(2.8, 1.8, 2.8), Vector3(0.0, ang, 0.0), rust_mat)
		# Radial structural stiffener ribs
		var fx = sin(ang) * 10.6
		var fz = cos(ang) * 10.6
		BunkerBuilder.box_rot(self, Vector3(fx, -67.4, fz), Vector3(0.35, 2.2, 2.4), Vector3(0.0, ang, 0.0), rust_mat)

	# Central Hollow Exhaust Trench (Drop into flame pit at Y = -76)
	BunkerBuilder.cylinder(self, Vector3(0.0, -74.0, 0.0), 4.6, 4.6, 8.0, 16, iron_mat)

	# 8 Radial Hydraulic Missile Hold-Down Clamp Pedestals
	for i in range(8):
		var ang = float(i) * (TAU / 8.0)
		var cx = sin(ang) * 7.2
		var cz = cos(ang) * 7.2
		BunkerBuilder.box_rot(self, Vector3(cx, -64.2, cz), Vector3(1.6, 1.2, 2.0), Vector3(0.0, ang, 0.0), iron_mat)
		BunkerBuilder.box_rot(self, Vector3(cx * 0.82, -63.8, cz * 0.82), Vector3(0.9, 0.6, 0.9), Vector3(0.0, ang, 0.0), rust_mat)

	# 6d. BASE SEISMIC ISOLATORS (DETERIORATED) - 12 heavy damping cylinders
	for i in range(12):
		var ang = float(i) * (TAU / 12.0)
		var ix = sin(ang) * 9.2
		var iz = cos(ang) * 9.2
		BunkerBuilder.cylinder(self, Vector3(ix, -69.2, iz), 0.55, 0.55, 1.8, 10, iron_mat)
		BunkerBuilder.cylinder(self, Vector3(ix, -70.3, iz), 0.85, 0.85, 1.2, 10, rust_mat)

	# 6e. Base Control Room (Recessed into basalt wall at Y = -68.0)
	BunkerBuilder.box(self, Vector3(0.0, -67.5, -29.5), Vector3(12.0, 5.5, 6.0), b_mat)
	BunkerBuilder.box(self, Vector3(0.0, -67.5, -26.4), Vector3(7.0, 1.8, 0.3), visor_mat)
	BunkerBuilder.omni(self, Vector3(0.0, -67.5, -25.0), Color(1.0, 0.68, 0.14), 3.5, 16.0)

	# =========================================================================
	# 7. ATMOSPHERIC LIGHTING & ILLUMINATION RIG
	# =========================================================================
	# 7a. Shaft Interior Floodlights (Illuminating the 70m vertical strata)
	for d in [-18.0, -35.0, -52.0]:
		for a in [0.0, PI * 0.5, PI, PI * 1.5]:
			var lx = sin(a) * 22.0
			var lz = cos(a) * 22.0
			BunkerBuilder.omni(self, Vector3(lx, d, lz), Color(1.0, 0.68, 0.16), 3.2, 28.0)

	# 7b. Flame Deflector Trench Under-Glow (Rising from central hollow hole)
	flame_trench_light = BunkerBuilder.omni(self, Vector3(0.0, -72.5, 0.0), Color(1.0, 0.28, 0.06), 7.5, 32.0)

	# 7c. Base Platform & Sludge Illumination
	BunkerBuilder.omni(self, Vector3(0.0, -62.0, 0.0), Color(1.0, 0.55, 0.12), 4.5, 35.0)
	BunkerBuilder.omni(self, Vector3(12.0, -68.5, 10.0), Color(0.25, 0.65, 0.20), 2.2, 18.0)

	# 7d. Surface rim alarm beacons (6 pulsing rotators)
	for a in [0.0, PI * 0.33, PI * 0.67, PI, PI * 1.33, PI * 1.67]:
		var lx = sin(a) * 31.0
		var lz = cos(a) * 31.0
		alarm_lights.append(BunkerBuilder.omni(self, Vector3(lx, 2.5, lz), Color(1.0, 0.45, 0.12), 3.2, 24.0))

	# Launch aperture column light
	silo_beam = BunkerBuilder.omni(self, Vector3(0.0, 10.0, 0.0), Color(1.0, 0.35, 0.10), 0.0, 120.0)

	_setup_prompt_ui()

func _build_stair_flight(p_start: Vector3, p_end: Vector3, m_str: Material, m_step: Material) -> void:
	var delta = p_end - p_start
	var steps = int(clampf(abs(delta.y) / 0.5, 6.0, 24.0))
	var step_vec = delta / float(steps)
	for s in range(steps):
		var spos = p_start + step_vec * (float(s) + 0.5)
		BunkerBuilder.box(self, spos, Vector3(2.4, 0.18, 0.8), m_step)
	var mid = (p_start + p_end) * 0.5 + Vector3(1.25, 0.9, 0.0)
	var len_d = p_start.distance_to(p_end)
	var ang_y = atan2(delta.x, delta.z)
	var ang_x = atan2(delta.y, Vector2(delta.x, delta.z).length())
	BunkerBuilder.box_rot(self, mid, Vector3(0.12, 0.12, len_d), Vector3(ang_x, ang_y, 0.0), m_str)

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * (0.015 if is_activated else 0.006)
	for i in range(alarm_lights.size()):
		alarm_lights[i].light_energy = lerpf(0.8, 5.5, (sin(t + float(i) * 1.05) + 1.0) * 0.5)

func check_interaction(player_pos: Vector3) -> bool:
	var c_pos = console_node.global_position if (is_instance_valid(console_node) and console_node.is_inside_tree()) else (global_transform * Vector3(0.0, -32.5, 12.0) if is_inside_tree() else position + Vector3(0.0, -32.5, 12.0))
	var dist = c_pos.distance_to(player_pos)
	if dist > 6.0:
		if prompt_label: prompt_label.modulate.a = 0.0
		return false
	if prompt_label:
		prompt_label.modulate.a = clampf((6.0 - dist) / 1.5, 0.0, 1.0)
		prompt_label.text = "[ SILO OVERRIDE ENGAGED ]" if is_activated else "[ E ] INITIATE SILO LAUNCH OVERRIDE"
	if not is_activated and (dist < 3.2 or Input.is_action_just_pressed("interact")):
		_activate_silo()
		return true
	return false

func _activate_silo() -> void:
	is_activated = true
	var s1 = AudioStreamPlayer.new()
	s1.stream = CONFIRM_SOUND
	add_child(s1)
	s1.play()
	var s2 = AudioStreamPlayer.new()
	s2.stream = SIREN_SOUND
	s2.volume_db = 4.0
	add_child(s2)
	s2.play()
	if silo_beam:
		silo_beam.light_energy = 28.0
	if status_banner:
		status_banner.visible = true
	silo_activated.emit()

func _setup_prompt_ui() -> void:
	prompt_canvas = CanvasLayer.new()
	prompt_canvas.layer = 13
	add_child(prompt_canvas)
	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.position.y += 40
	prompt_label.modulate = Color(1.0, 0.72, 0.25, 0.0)
	prompt_canvas.add_child(prompt_label)
	status_banner = Label.new()
	status_banner.set_anchors_preset(Control.PRESET_CENTER)
	status_banner.position.y -= 80
	status_banner.text = "★★★ COLOSSAL SILO OVERRIDE COMPLETE ★★★\nLAUNCH CRADLE TELEMETRY ACTIVE"
	status_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner.modulate = Color(1.0, 0.75, 0.22, 1.0)
	status_banner.visible = false
	prompt_canvas.add_child(status_banner)
