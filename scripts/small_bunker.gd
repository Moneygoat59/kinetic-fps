class_name SmallBunker
extends Node3D

signal dosimeter_acquired()

const BunkerBuilder = preload("res://scripts/bunker_builder.gd")
const BEACON_SOUND = preload("res://audio/digital/Audio/threeTone1.ogg")
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")
const DOOR_OPEN_SOUND = preload("res://audio/ui/Audio/open_001.ogg")
const DOOR_CLOSE_SOUND = preload("res://audio/ui/Audio/close_001.ogg")

static func preload_models() -> void:
	for p in [
		"res://models/bunker_satellite.glb",
		"res://models/finder_device.glb",
		"res://models/industrial/machine-fortified.glb",
		"res://models/industrial/box-large.glb",
		"res://models/industrial/box-wide.glb",
		"res://models/prop_containment_vat.glb",
		"res://models/prop_alien_floating_artifact.glb"
	]:
		BunkerBuilder.load_glb(p)

var is_claimed: bool = false
var item_node: Node3D
var item_light: OmniLight3D
var roof_light: OmniLight3D
var audio_beacon: AudioStreamPlayer3D
var prompt_canvas: CanvasLayer
var prompt_label: Label
var chirp_timer: float = 1.0

# Interactive Blast Door nodes
var door_left: Node3D
var door_right: Node3D
var door_open_factor: float = 0.0
var door_open_target: float = 0.0
var door_audio: AudioStreamPlayer3D
var was_door_open: bool = false

func is_barrier_active() -> bool:
	return true

func _ready() -> void:
	if audio_beacon and not audio_beacon.playing:
		audio_beacon.play()

func build_bunker(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy, pos_z)

	var b = BunkerBuilder.mat_basalt()
	var bp = BunkerBuilder.mat_basalt_panel()
	var m = BunkerBuilder.mat_metal()
	var di = BunkerBuilder.mat_dark_iron()
	var bd = BunkerBuilder.mat_blast_door()
	var g_grate = BunkerBuilder.mat_grate()
	var g_amber = BunkerBuilder.mat_glow(Color(1.0, 0.72, 0.16), 2.8, BunkerBuilder.meter_tex)
	var g_visor = BunkerBuilder.mat_visor()
	var crt_amber = BunkerBuilder.mat_crt_amber()
	var crt_static = BunkerBuilder.mat_crt_static()
	var danger_mat = BunkerBuilder.mat_danger()
	var cable_mat = BunkerBuilder.mat_cable()

	# =========================================================================
	# 1. FOUNDATION, PLINTH & SLANTED BASE SKIRTS (Matching All Elevations)
	# =========================================================================
	# Deep foundation apron
	BunkerBuilder.box(self, Vector3(0.0, -0.45, 0.0), Vector3(10.8, 0.9, 11.4), b)
	# Interior basalt floor perimeter & recessed rust grating walkway
	BunkerBuilder.box(self, Vector3(0.0, 0.02, 0.0), Vector3(8.2, 0.04, 8.6), bp, 0.0, false)
	BunkerBuilder.box(self, Vector3(0.0, 0.03, 0.0), Vector3(1.8, 0.04, 7.8), g_grate, 0.0, false)
	# Front entrance steel ramp
	BunkerBuilder.box(self, Vector3(0.0, 0.02, 4.9), Vector3(3.0, 0.08, 1.8), di)

	# Flared chamfered base skirts (Basalt plinth flare)
	BunkerBuilder.box_rot(self, Vector3(0.0, 0.22, 5.20), Vector3(9.2, 0.55, 0.35), Vector3(deg_to_rad(28.0), 0, 0), b)
	BunkerBuilder.box_rot(self, Vector3(0.0, 0.22, -5.20), Vector3(9.2, 0.55, 0.35), Vector3(deg_to_rad(-28.0), 0, 0), b)
	BunkerBuilder.box_rot(self, Vector3(-5.05, 0.22, 0.0), Vector3(0.35, 0.55, 9.8), Vector3(0, 0, deg_to_rad(-28.0)), b)
	BunkerBuilder.box_rot(self, Vector3(5.05, 0.22, 0.0), Vector3(0.35, 0.55, 9.8), Vector3(0, 0, deg_to_rad(28.0)), b)

	# 4 Corner chamfered plinth blocks
	for cx in [-4.75, 4.75]:
		for cz in [-4.85, 4.85]:
			BunkerBuilder.box(self, Vector3(cx, 0.3, cz), Vector3(1.4, 0.7, 1.4), b)

	# =========================================================================
	# 2. MAIN ENCLOSURE WALLS & CORNICE / PARAPET TRIM
	# =========================================================================
	# Left and Right main walls
	BunkerBuilder.box(self, Vector3(-4.0, 2.0, 0.0), Vector3(1.0, 4.0, 8.6), bp)
	BunkerBuilder.box(self, Vector3(4.0, 2.0, 0.0), Vector3(1.0, 4.0, 8.6), bp)
	# Rear main wall
	BunkerBuilder.box(self, Vector3(0.0, 2.0, -4.5), Vector3(9.0, 4.0, 1.0), bp)
	# Front portal walls
	BunkerBuilder.box(self, Vector3(-2.8, 2.0, 4.5), Vector3(3.2, 4.0, 1.0), bp)
	BunkerBuilder.box(self, Vector3(2.8, 2.0, 4.5), Vector3(3.2, 4.0, 1.0), bp)
	BunkerBuilder.box(self, Vector3(0.0, 3.4, 4.5), Vector3(2.6, 1.2, 1.0), bp)

	# 4 Heavy Corner Pilasters
	for cx in [-4.4, 4.4]:
		for cz in [-4.5, 4.5]:
			BunkerBuilder.box(self, Vector3(cx, 2.1, cz), Vector3(1.25, 4.3, 1.25), b)

	# Roof Slab & Heavy Overhanging Parapet Cornice
	BunkerBuilder.box(self, Vector3(0.0, 3.95, 0.0), Vector3(9.4, 0.45, 10.2), b)
	for p in [Vector3(-4.65, 4.25, 0.0), Vector3(4.65, 4.25, 0.0)]:
		BunkerBuilder.box(self, p, Vector3(0.5, 0.45, 10.4), b, 0.0, false)
	for p in [Vector3(0.0, 4.25, 5.15), Vector3(0.0, 4.25, -5.15)]:
		BunkerBuilder.box(self, p, Vector3(9.4, 0.45, 0.5), b, 0.0, false)

	# =========================================================================
	# 3. FRONT ELEVATION & BLAST DOOR (Faceted Portal & Interlocking Zig-Zag)
	# =========================================================================
	# Outer beveled portal arch (Angled chamfer frame around doorway)
	BunkerBuilder.box_rot(self, Vector3(-1.62, 1.35, 4.82), Vector3(0.38, 2.7, 0.42), Vector3(0, 0, deg_to_rad(6.0)), b)
	BunkerBuilder.box_rot(self, Vector3(1.62, 1.35, 4.82), Vector3(0.38, 2.7, 0.42), Vector3(0, 0, deg_to_rad(-6.0)), b)
	BunkerBuilder.box(self, Vector3(0.0, 2.82, 4.82), Vector3(3.35, 0.38, 0.42), b)

	# Inner steel portal casing
	BunkerBuilder.box(self, Vector3(-1.35, 1.3, 4.65), Vector3(0.22, 2.6, 0.35), di)
	BunkerBuilder.box(self, Vector3(1.35, 1.3, 4.65), Vector3(0.22, 2.6, 0.35), di)
	BunkerBuilder.box(self, Vector3(0.0, 2.62, 4.65), Vector3(2.7, 0.24, 0.35), di)

	# Recessed Amber Visor Slit Light (Front Elevation - bright horizontal amber bar)
	BunkerBuilder.box(self, Vector3(0.0, 3.28, 4.88), Vector3(2.9, 0.42, 0.22), di)
	BunkerBuilder.box(self, Vector3(0.0, 3.52, 5.06), Vector3(3.1, 0.08, 0.32), m, 0.0, false) # Overhanging steel brow
	BunkerBuilder.box(self, Vector3(0.0, 3.28, 5.04), Vector3(2.6, 0.18, 0.08), g_visor, 0.0, false)
	BunkerBuilder.omni(self, Vector3(0.0, 3.28, 5.35), Color(1.0, 0.68, 0.15), 3.8, 7.5)

	# --- Heavy Armored Blast Door with Zig-Zag Interlocking Seam ---
	var blast_door_root = Node3D.new(); blast_door_root.name = "BlastDoorRoot"; add_child(blast_door_root)
	door_left = Node3D.new(); door_left.name = "DoorLeft"; blast_door_root.add_child(door_left)
	door_right = Node3D.new(); door_right.name = "DoorRight"; blast_door_root.add_child(door_right)

	# Left Door Leaf (Main body + Zig-zag stepped finger teeth)
	BunkerBuilder.box(door_left, Vector3(-0.68, 1.3, 4.52), Vector3(1.18, 2.45, 0.24), bd)
	# Upper finger (extends right to +0.12)
	BunkerBuilder.box(door_left, Vector3(-0.02, 2.15, 4.52), Vector3(0.24, 0.45, 0.26), m)
	# Mid finger (extends right to +0.12)
	BunkerBuilder.box(door_left, Vector3(-0.02, 1.15, 4.52), Vector3(0.24, 0.45, 0.26), m)
	# Reinforcing horizontal bars & locking brackets on left leaf
	BunkerBuilder.box(door_left, Vector3(-0.65, 2.2, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	BunkerBuilder.box(door_left, Vector3(-0.65, 1.3, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	BunkerBuilder.box(door_left, Vector3(-0.65, 0.4, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	# Contrasting edge bevel trim on left leaf
	BunkerBuilder.box(door_left, Vector3(0.09, 2.15, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_left, Vector3(-0.13, 1.65, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_left, Vector3(0.09, 1.15, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_left, Vector3(-0.13, 0.65, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)

	# Right Door Leaf (Main body + Complementary zig-zag stepped finger teeth)
	BunkerBuilder.box(door_right, Vector3(0.68, 1.3, 4.52), Vector3(1.18, 2.45, 0.24), bd)
	# High-mid finger (extends left to -0.12)
	BunkerBuilder.box(door_right, Vector3(0.02, 1.65, 4.52), Vector3(0.24, 0.45, 0.26), m)
	# Bottom finger (extends left to -0.12)
	BunkerBuilder.box(door_right, Vector3(0.02, 0.65, 4.52), Vector3(0.24, 0.45, 0.26), m)
	# Reinforcing horizontal bars & locking brackets on right leaf
	BunkerBuilder.box(door_right, Vector3(0.65, 2.2, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	BunkerBuilder.box(door_right, Vector3(0.65, 1.3, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	BunkerBuilder.box(door_right, Vector3(0.65, 0.4, 4.66), Vector3(1.0, 0.12, 0.08), m, 0.0, false)
	# Contrasting edge bevel trim on right leaf
	BunkerBuilder.box(door_right, Vector3(0.13, 2.15, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_right, Vector3(-0.09, 1.65, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_right, Vector3(0.13, 1.15, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)
	BunkerBuilder.box(door_right, Vector3(-0.09, 0.65, 4.52), Vector3(0.03, 0.45, 0.27), di, 0.0, false)

	# Door sound player
	door_audio = AudioStreamPlayer3D.new()
	door_audio.stream = DOOR_OPEN_SOUND
	door_audio.unit_size = 18.0
	door_audio.position = Vector3(0.0, 1.5, 4.5)
	add_child(door_audio)

	# =========================================================================
	# 4. ROOFTOP COMM ARRAY (Front-Right Roof: Dish & 3 Antenna Masts)
	# =========================================================================
	# Mounting pedestal on roof deck
	BunkerBuilder.box(self, Vector3(2.3, 4.18, 1.8), Vector3(2.0, 0.35, 2.0), di)
	var sat = BunkerBuilder.load_glb("res://models/bunker_satellite.glb")
	if sat:
		sat.position = Vector3(2.3, 4.35, 1.8)
		sat.scale = Vector3(1.8, 1.8, 1.8)
		sat.rotation = Vector3(deg_to_rad(-18.0), deg_to_rad(25.0), 0)
		BunkerBuilder.recolor(sat, m, di)
		BunkerBuilder.add_collisions(sat)
		add_child(sat)
	else:
		# Procedural fallback satellite dish
		BunkerBuilder.cylinder(self, Vector3(2.3, 4.5, 1.8), 0.12, 0.12, 0.6, 8, di)
		var dish = MeshInstance3D.new(); var cm = CylinderMesh.new()
		cm.top_radius = 0.95; cm.bottom_radius = 0.25; cm.height = 0.35; cm.radial_segments = 16
		dish.mesh = cm; dish.position = Vector3(2.3, 5.0, 1.8); dish.rotation = Vector3(deg_to_rad(40.0), deg_to_rad(-25.0), 0)
		dish.material_override = m; add_child(dish)

	# 3 Antenna Rods / Whip Masts behind dish
	BunkerBuilder.cylinder(self, Vector3(2.8, 6.0, 1.3), 0.035, 0.045, 3.6, 6, m, false)
	BunkerBuilder.cylinder(self, Vector3(2.3, 5.3, 1.1), 0.025, 0.035, 2.4, 6, m, false)
	BunkerBuilder.cylinder(self, Vector3(1.7, 5.0, 1.4), 0.02, 0.03, 1.8, 6, m, false)
	roof_light = BunkerBuilder.omni(self, Vector3(2.8, 7.8, 1.3), Color(1.0, 0.65, 0.12), 5.0, 45.0)

	# =========================================================================
	# 5. REAR ELEVATION: HVAC VENTILATION UNIT & ELECTRICAL SWITCHBOX
	# =========================================================================
	# Protruding square HVAC ventilation louver unit (centered/slightly right of center)
	BunkerBuilder.box(self, Vector3(0.3, 2.3, -4.95), Vector3(2.5, 2.4, 0.68), di)
	BunkerBuilder.box(self, Vector3(0.3, 2.3, -5.30), Vector3(2.7, 2.6, 0.08), m, 0.0, false) # Outer steel rim
	# 7 Angled horizontal louver slats
	for i in range(7):
		var y_slat = 1.35 + i * 0.31
		BunkerBuilder.box_rot(self, Vector3(0.3, y_slat, -5.31), Vector3(2.25, 0.04, 0.30), Vector3(deg_to_rad(32.0), 0, 0), m, false)

	# Electrical Transformer / Switchgear Cabinet (Mounted at X = -2.3, so on RIGHT when viewing from rear)
	BunkerBuilder.box(self, Vector3(-2.3, 1.85, -4.95), Vector3(1.25, 2.2, 0.55), di)
	# Warning placard on switchbox
	BunkerBuilder.box(self, Vector3(-2.3, 2.25, -5.24), Vector3(0.55, 0.30, 0.02), danger_mat, 0.0, false)
	# Diagnostic amber meter & LED
	BunkerBuilder.box(self, Vector3(-2.3, 1.6, -5.24), Vector3(0.38, 0.38, 0.02), g_amber, 0.0, false)
	# Twin vertical conduits rising from switchbox past the roof cornice
	BunkerBuilder.cylinder(self, Vector3(-2.1, 3.8, -4.95), 0.05, 0.05, 2.5, 8, m, false)
	BunkerBuilder.cylinder(self, Vector3(-2.5, 3.8, -4.95), 0.045, 0.045, 2.5, 8, m, false)

	# Heavy conduit pipes exiting HVAC unit and routing into the electrical switchbox
	# Pipe 1 (curving upper conduit)
	BunkerBuilder.cylinder(self, Vector3(-1.0, 1.8, -4.9), 0.07, 0.07, 1.0, 8, m, false)
	BunkerBuilder.box(self, Vector3(-1.5, 1.3, -4.9), Vector3(1.0, 0.14, 0.14), m, 0.0, false)
	# Pipe 2 (lower direct conduit)
	BunkerBuilder.box(self, Vector3(-1.3, 0.85, -4.9), Vector3(1.4, 0.12, 0.12), m, 0.0, false)

	# Hanging loose wire harness dangling beneath cabinet
	for wx in [-0.25, -0.08, 0.1, 0.26]:
		BunkerBuilder.cylinder(self, Vector3(-2.3 + wx, 0.45, -4.95), 0.018, 0.018, 0.75, 6, cable_mat, false)

	# =========================================================================
	# 6. LEFT ELEVATION: BASALT PANELING & RECESSED AMBER SLIT
	# =========================================================================
	# Recessed horizontal amber slit window/light (upper right area of left wall at Z = 1.2)
	BunkerBuilder.box(self, Vector3(-4.95, 3.0, 1.2), Vector3(0.25, 0.38, 1.6), di)
	BunkerBuilder.box(self, Vector3(-5.06, 3.0, 1.2), Vector3(0.04, 0.18, 1.3), g_visor, 0.0, false)
	BunkerBuilder.omni(self, Vector3(-5.4, 3.0, 1.2), Color(1.0, 0.65, 0.12), 2.5, 5.0)
	# Maintenance inspection access hatch
	BunkerBuilder.box(self, Vector3(-4.95, 1.5, -1.2), Vector3(0.08, 1.4, 1.2), di, 0.0, false)
	BunkerBuilder.box(self, Vector3(-4.99, 1.5, -1.2), Vector3(0.04, 0.12, 0.22), m, 0.0, false)

	# =========================================================================
	# 7. RIGHT ELEVATION: SERVICE LADDER & AMBER SLIT
	# =========================================================================
	# Exterior Service Ladder on right wall (positioned at Z = -1.6, so on RIGHT when viewing right elevation)
	var ladder_z = -1.6
	BunkerBuilder.cylinder(self, Vector3(5.08, 2.15, ladder_z - 0.26), 0.03, 0.03, 4.3, 6, m, false) # Left rail
	BunkerBuilder.cylinder(self, Vector3(5.08, 2.15, ladder_z + 0.26), 0.03, 0.03, 4.3, 6, m, false) # Right rail
	for ri in range(12):
		var yr = 0.25 + ri * 0.35
		BunkerBuilder.cylinder(self, Vector3(5.08, yr, ladder_z), 0.022, 0.022, 0.52, 6, m, false) # Rungs
	# Ladder standoff wall brackets
	for yb in [0.8, 2.2, 3.6]:
		BunkerBuilder.box(self, Vector3(4.88, yb, ladder_z), Vector3(0.36, 0.06, 0.58), di, 0.0, false)

	# Recessed horizontal amber slit window/light (to the left of ladder at Z = 1.2)
	BunkerBuilder.box(self, Vector3(4.95, 3.0, 1.2), Vector3(0.25, 0.38, 1.6), di)
	BunkerBuilder.box(self, Vector3(5.06, 3.0, 1.2), Vector3(0.04, 0.18, 1.3), g_visor, 0.0, false)
	BunkerBuilder.omni(self, Vector3(5.4, 3.0, 1.2), Color(1.0, 0.65, 0.12), 2.5, 5.0)

	# =========================================================================
	# 8. INTERIOR ARCHITECTURE, CEILING BEAMS & CONDUITS
	# =========================================================================
	# 2 Transverse ceiling bulkhead arch beams
	for za in [-1.2, 1.6]:
		BunkerBuilder.box(self, Vector3(0.0, 3.45, za), Vector3(7.2, 0.45, 0.45), b)
		BunkerBuilder.box_rot(self, Vector3(-3.2, 3.15, za), Vector3(0.45, 0.55, 0.45), Vector3(0, 0, deg_to_rad(45.0)), b)
		BunkerBuilder.box_rot(self, Vector3(3.2, 3.15, za), Vector3(0.45, 0.55, 0.45), Vector3(0, 0, deg_to_rad(-45.0)), b)

	# Perimeter ceiling conduit pipes
	BunkerBuilder.cylinder(self, Vector3(-3.1, 3.3, 0.0), 0.05, 0.05, 7.6, 8, m, false)
	BunkerBuilder.cylinder(self, Vector3(3.1, 3.3, 0.0), 0.05, 0.05, 7.6, 8, m, false)

	# 2 Recessed amber ceiling luminaires
	for zl in [-1.0, 1.8]:
		BunkerBuilder.box(self, Vector3(0.0, 3.65, zl), Vector3(1.6, 0.12, 0.7), di, 0.0, false)
		BunkerBuilder.box(self, Vector3(0.0, 3.62, zl), Vector3(1.3, 0.06, 0.5), g_amber, 0.0, false)
		BunkerBuilder.omni(self, Vector3(0.0, 3.2, zl), Color(1.0, 0.75, 0.20), 3.2, 7.0)

	# Ambient interior fill light
	BunkerBuilder.omni(self, Vector3(0.0, 2.0, 0.0), Color(0.85, 0.70, 0.35), 1.6, 9.0)

	# =========================================================================
	# 9. INT. FRONT WALL (Looking towards entrance from inside)
	# =========================================================================
	# Standing terminal console on left (facing doorway)
	var term1 = _create_terminal_console(Vector3(-2.3, 0.0, 3.4), deg_to_rad(150.0), crt_amber, di, m)
	add_child(term1)
	# Bulkhead ventilation wire mesh behind standing terminal
	BunkerBuilder.box(self, Vector3(-2.3, 2.1, 3.92), Vector3(1.4, 1.5, 0.06), g_grate, 0.0, false)

	# Desk workstation on right (facing doorway)
	BunkerBuilder.box(self, Vector3(2.4, 0.45, 3.4), Vector3(1.6, 0.88, 0.75), di)
	# Desktop CRT monitor with amber telemetry display
	var mon1 = _create_crt_monitor(Vector3(2.35, 1.22, 3.4), deg_to_rad(-165.0), crt_amber, di)
	add_child(mon1)
	# Low-poly computer keyboard
	BunkerBuilder.box_rot(self, Vector3(2.35, 0.92, 3.25), Vector3(0.48, 0.04, 0.22), Vector3(deg_to_rad(12.0), deg_to_rad(-165.0), 0), m, false)

	# =========================================================================
	# 10. INT. REAR WALL (Interior HVAC Louver & Masterius Bulky Panels)
	# =========================================================================
	# Interior side of HVAC ventilation unit with horizontal slats
	BunkerBuilder.box(self, Vector3(0.0, 2.2, -3.88), Vector3(2.4, 2.2, 0.35), di)
	for i in range(6):
		var y_slat_int = 1.35 + i * 0.34
		BunkerBuilder.box_rot(self, Vector3(0.0, y_slat_int, -3.72), Vector3(2.1, 0.035, 0.24), Vector3(deg_to_rad(-32.0), 0, 0), m, false)

	# Standing terminal console on left rear wall
	var term2 = _create_terminal_console(Vector3(-2.4, 0.0, -2.8), deg_to_rad(30.0), crt_amber, di, m)
	add_child(term2)

	# Masterius Bulky Panels & Power Distribution on right rear wall
	BunkerBuilder.box(self, Vector3(2.5, 1.8, -3.85), Vector3(1.6, 2.6, 0.45), di)
	BunkerBuilder.box(self, Vector3(2.5, 2.4, -3.61), Vector3(0.5, 0.28, 0.04), danger_mat, 0.0, false)
	BunkerBuilder.box(self, Vector3(2.5, 1.6, -3.61), Vector3(0.8, 0.6, 0.04), g_amber, 0.0, false)

	# =========================================================================
	# 11. INT. LEFT WALL (Workstation, 2000s CRT Static & Mesh Panel)
	# =========================================================================
	# Industrial workstation desk
	BunkerBuilder.box(self, Vector3(-3.35, 0.45, 0.1), Vector3(0.85, 0.88, 2.4), di)
	# Classic 2000s CRT monitor with authentic television static / noise texture
	var static_mon = _create_crt_monitor(Vector3(-3.25, 1.25, 0.1), deg_to_rad(90.0), crt_static, di)
	add_child(static_mon)
	# Beige keyboard on workstation desk
	BunkerBuilder.box_rot(self, Vector3(-3.05, 0.92, 0.1), Vector3(0.24, 0.04, 0.52), Vector3(0, 0, deg_to_rad(14.0)), m, false)
	# Bulkhead wall mesh / ventilation grating on left wall
	BunkerBuilder.box(self, Vector3(-3.45, 2.2, 0.1), Vector3(0.06, 1.4, 2.2), g_grate, 0.0, false)

	# =========================================================================
	# 12. INT. RIGHT WALL (Low-Poly Machinery: Heavy Generator Unit)
	# =========================================================================
	# Heavy industrial generator block
	var gen_pos = Vector3(2.7, 0.0, -0.2)
	BunkerBuilder.box(self, gen_pos + Vector3(0.0, 0.55, 0.0), Vector3(1.3, 1.1, 1.6), di)
	# Cylindrical motor / turbine with 4 cooling ribs
	var turb = BunkerBuilder.cylinder(self, gen_pos + Vector3(-0.15, 0.6, 0.0), 0.42, 0.42, 1.5, 12, m)
	turb.rotation.x = deg_to_rad(90.0)
	for ri in range(4):
		var rib = BunkerBuilder.cylinder(self, gen_pos + Vector3(-0.15, 0.6, -0.45 + ri * 0.3), 0.47, 0.47, 0.06, 12, di, false)
		rib.rotation.x = deg_to_rad(90.0)

	# Generator side control box with DANGER sign plate
	BunkerBuilder.box(self, gen_pos + Vector3(-0.7, 0.6, 0.0), Vector3(0.25, 0.55, 0.65), di)
	BunkerBuilder.box(self, gen_pos + Vector3(-0.83, 0.65, 0.0), Vector3(0.02, 0.24, 0.42), danger_mat, 0.0, false)

	# Heavy power cables snaking out of generator across the floor
	BunkerBuilder.cylinder(self, gen_pos + Vector3(-0.6, 0.05, 0.45), 0.045, 0.045, 0.9, 8, cable_mat, false)
	BunkerBuilder.cylinder(self, gen_pos + Vector3(-0.3, 0.05, 0.8), 0.04, 0.04, 1.1, 8, cable_mat, false)

	# Wall electrical distribution box on right wall
	BunkerBuilder.box(self, Vector3(3.45, 1.8, 0.8), Vector3(0.12, 0.75, 1.1), di, 0.0, false)
	BunkerBuilder.box(self, Vector3(3.38, 1.8, 0.8), Vector3(0.04, 0.55, 0.9), g_amber, 0.0, false)

	# =========================================================================
	# 13. QUEST INTERACTIVE ITEM STATION & AMBIENT AUDIO BEACON
	# =========================================================================
	_spawn_device(b, di, g_amber)

	# Audio beacon & ambient sound
	audio_beacon = AudioStreamPlayer3D.new()
	audio_beacon.stream = BEACON_SOUND
	audio_beacon.unit_size = 28.0
	audio_beacon.max_distance = 160.0
	audio_beacon.volume_db = 9.0
	audio_beacon.position = Vector3(0.0, 1.5, 0.0)
	add_child(audio_beacon)
	if is_inside_tree():
		audio_beacon.play()

	_setup_prompt_ui()

func _create_terminal_console(pos: Vector3, rot_y: float, screen_mat: Material, casing_mat: Material, trim_mat: Material) -> Node3D:
	var n = Node3D.new(); n.position = pos; n.rotation.y = rot_y
	# Pedestal base
	BunkerBuilder.box(n, Vector3(0.0, 0.45, 0.0), Vector3(0.55, 0.9, 0.55), casing_mat)
	# Angled keypad deck
	BunkerBuilder.box_rot(n, Vector3(0.0, 0.92, 0.12), Vector3(0.5, 0.08, 0.32), Vector3(deg_to_rad(25.0), 0, 0), casing_mat, false)
	BunkerBuilder.box_rot(n, Vector3(0.0, 0.96, 0.12), Vector3(0.42, 0.02, 0.24), Vector3(deg_to_rad(25.0), 0, 0), trim_mat, false)
	# CRT Monitor Head
	BunkerBuilder.box_rot(n, Vector3(0.0, 1.35, -0.05), Vector3(0.58, 0.5, 0.45), Vector3(deg_to_rad(-12.0), 0, 0), casing_mat, false)
	# Glowing phosphor screen
	BunkerBuilder.box_rot(n, Vector3(0.0, 1.35, 0.18), Vector3(0.46, 0.38, 0.04), Vector3(deg_to_rad(-12.0), 0, 0), screen_mat, false)
	return n

func _create_crt_monitor(pos: Vector3, rot_y: float, screen_mat: Material, casing_mat: Material) -> Node3D:
	var n = Node3D.new(); n.position = pos; n.rotation.y = rot_y
	# Monitor casing
	BunkerBuilder.box(n, Vector3(0.0, 0.0, 0.0), Vector3(0.62, 0.52, 0.48), casing_mat, 0.0, false)
	# Bezel recess
	BunkerBuilder.box(n, Vector3(0.0, 0.0, 0.24), Vector3(0.52, 0.42, 0.04), casing_mat, 0.0, false)
	# Screen
	BunkerBuilder.box(n, Vector3(0.0, 0.0, 0.25), Vector3(0.48, 0.38, 0.02), screen_mat, 0.0, false)
	return n

func _spawn_device(b_mat: Material, di_mat: Material, glow_amber: Material) -> void:
	# Central item station on center table / console
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.45, -1.2), 0.5, 0.55, 0.9, 10, di_mat)
	BunkerBuilder.cylinder(self, Vector3(0.0, 0.93, -1.2), 0.32, 0.35, 0.06, 8, b_mat)

	item_node = Node3D.new()
	item_node.position = Vector3(0.0, 1.0, -1.2)
	add_child(item_node)

	var dev = BunkerBuilder.load_glb("res://models/finder_device.glb")
	if dev:
		dev.scale = Vector3(0.42, 0.42, 0.42)
		dev.rotation = Vector3(deg_to_rad(65.0), deg_to_rad(15.0), 0)
		var mi = dev.find_child("Multmeter_Cube", true, false) as MeshInstance3D
		if mi:
			mi.set_surface_override_material(2, glow_amber)
			mi.set_surface_override_material(1, b_mat)
			mi.set_surface_override_material(0, di_mat)
		item_node.add_child(dev)
	else:
		# Procedural fallback device
		var bm = BoxMesh.new(); bm.size = Vector3(0.24, 0.12, 0.18)
		var bmi = MeshInstance3D.new(); bmi.mesh = bm; bmi.material_override = di_mat
		item_node.add_child(bmi)
		var sm = BoxMesh.new(); sm.size = Vector3(0.14, 0.02, 0.10)
		var smi = MeshInstance3D.new(); smi.mesh = sm; smi.material_override = glow_amber
		smi.position.y = 0.065
		item_node.add_child(smi)

	item_light = BunkerBuilder.omni(item_node, Vector3(0.0, 0.25, 0.0), Color(1.0, 0.72, 0.16), 2.8, 3.8)

func _setup_prompt_ui() -> void:
	prompt_canvas = CanvasLayer.new()
	prompt_canvas.layer = 13
	add_child(prompt_canvas)

	prompt_label = Label.new()
	prompt_label.text = "[ E ] TAKE ANALOG FIELD TRACKER"
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.position.y += 40
	prompt_label.modulate = Color(1.0, 0.75, 0.18, 0.0)
	prompt_canvas.add_child(prompt_label)

func _process(delta: float) -> void:
	# Subtle rooftop light pulse
	if roof_light:
		roof_light.light_energy = lerpf(2.5, 6.5, (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5)

	# Hovering bob of interactive item
	if not is_claimed and item_node:
		item_node.position.y = 1.0 + sin(Time.get_ticks_msec() * 0.005) * 0.015

	# Audio beacon chirping
	if not is_claimed:
		chirp_timer -= delta
		if chirp_timer <= 0.0:
			chirp_timer = 1.1
			if audio_beacon:
				audio_beacon.play()

	# Interactive Blast Door animation
	_update_blast_door(delta)

func _update_blast_door(delta: float) -> void:
	if not door_left or not door_right:
		return

	# Smoothly open/close the blast door leaves
	if absf(door_open_factor - door_open_target) > 0.001:
		door_open_factor = move_toward(door_open_factor, door_open_target, delta * 1.8)
		door_left.position.x = lerpf(0.0, -1.25, door_open_factor)
		door_right.position.x = lerpf(0.0, 1.25, door_open_factor)

		var is_open_now = door_open_factor > 0.1
		if is_open_now != was_door_open:
			was_door_open = is_open_now
			if door_audio:
				door_audio.stream = DOOR_OPEN_SOUND if is_open_now else DOOR_CLOSE_SOUND
				door_audio.play()

func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	# Proximity check for the blast door opening
	var dist_door = global_position.distance_to(player_pos)
	if dist_door < 5.8:
		door_open_target = 1.0
	else:
		door_open_target = 0.0

	if is_claimed or not item_node:
		return false

	var dist = item_node.global_position.distance_to(player_pos)
	if dist < 3.4:
		if prompt_label:
			prompt_label.modulate.a = clampf((3.4 - dist) / 1.2, 0.0, 1.0)
		if force or dist < 1.8 or Input.is_action_just_pressed("interact"):
			_claim_item()
			return true
	else:
		if prompt_label:
			prompt_label.modulate.a = 0.0
	return false

func _claim_item() -> void:
	is_claimed = true
	if prompt_canvas:
		prompt_canvas.queue_free()
	if is_instance_valid(item_node):
		item_node.queue_free()
	if audio_beacon:
		audio_beacon.stop()
	var s1 = AudioStreamPlayer.new()
	s1.stream = PICKUP_SOUND
	add_child(s1)
	s1.play()
	var s2 = AudioStreamPlayer.new()
	s2.stream = SWITCH_SOUND
	s2.volume_db = -3.0
	add_child(s2)
	s2.play()
	dosimeter_acquired.emit()
