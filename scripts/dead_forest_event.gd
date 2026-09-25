class_name DeadForestEvent
extends Node3D

const BUNKER_SCRIPT = preload("res://scripts/bunker/outpost_bunker.gd")
const PYLON_SCRIPT = preload("res://scripts/nuclear_pylon.gd")
const DOSIMETER_SCRIPT = preload("res://scripts/radiation_dosimeter.gd")
const CAMPSITE_SCRIPT = preload("res://scripts/abandoned_campsite.gd")
const HUB_SCRIPT = preload("res://scripts/hub_building.gd")
const OUTPOST_SCRIPT = preload("res://scripts/outpost_building.gd")
const SILO_SCRIPT = preload("res://scripts/missile_silo.gd")

@export var player: CharacterBody3D; @export var terrain: Node3D; @export var props: Node3D

enum State { WANDERING, BUNKER_1, HUB_ACTIVE, OUTPOST_2_ACTIVE, OUTPOST_3_ACTIVE, SILO_ACTIVE, COMPLETED }
var current_state: State = State.WANDERING
var wander_distance: float = 0.0; var wander_target: float = 600.0; var campsite_target: float = 175.0
var campsite_spawned: bool = false; var last_pos: Vector3 = Vector3.ZERO
var campsite_instance: Node3D; var bunker_instance: Node3D; var hub_instance: Node3D
var outpost_2_instance: Node3D; var outpost_3_instance: Node3D; var silo_instance: Node3D
var pylons: Array[Node3D] = []; var dosimeter: Node; var hub_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	wander_target = randf_range(380.0, 720.0); campsite_target = randf_range(110.0, 150.0)
	if player: last_pos = player.global_position
	BUNKER_SCRIPT.preload_models()

func _physics_process(delta: float) -> void:
	if not player: return
	var p_pos = player.global_position
	match current_state:
		State.WANDERING:
			var d = p_pos.distance_to(last_pos)
			if d > 0.05 and d < 10.0: wander_distance += d
			last_pos = p_pos
			if not campsite_spawned and wander_distance >= campsite_target: _spawn_campsite_silently(p_pos)
			if wander_distance >= wander_target: _spawn_bunker_1(p_pos)
		State.BUNKER_1:
			if bunker_instance and bunker_instance.check_interaction(p_pos): _start_path_to_hub()
		State.HUB_ACTIVE:
			if hub_instance: hub_instance.check_interaction(p_pos)
		State.OUTPOST_2_ACTIVE:
			if outpost_2_instance: outpost_2_instance.check_interaction(p_pos)
		State.OUTPOST_3_ACTIVE:
			if outpost_3_instance: outpost_3_instance.check_interaction(p_pos)
		State.SILO_ACTIVE:
			if silo_instance: silo_instance.check_interaction(p_pos)

func _spawn_campsite_silently(p_pos: Vector3) -> void:
	campsite_spawned = true
	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	var fwd = -cam.global_transform.basis.z if cam else Vector3(0.0, 0.0, -1.0)
	fwd.y = 0.0; fwd = fwd.normalized()
	var c_pos = p_pos + (fwd if fwd.length_squared() > 0.1 else Vector3.FORWARD) * 58.0
	var gy = terrain.get_height(c_pos.x, c_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(c_pos.x, gy, c_pos.z), 14.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(c_pos.x, c_pos.z, 18.0, gy, 9.5)
	campsite_instance = CAMPSITE_SCRIPT.new(); campsite_instance.build_campsite(terrain, c_pos.x, c_pos.z)
	add_child(campsite_instance)

func _spawn_bunker_1(p_pos: Vector3) -> void:
	current_state = State.BUNKER_1
	var ang = randf_range(0.0, TAU); var b_pos = p_pos + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(58.0, 72.0)
	var gy = terrain.get_height(b_pos.x, b_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(b_pos.x, gy, b_pos.z), 16.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(b_pos.x, b_pos.z, 18.0, gy, 7.5)
	bunker_instance = BUNKER_SCRIPT.new(); bunker_instance.build_bunker(terrain, b_pos.x, b_pos.z)
	bunker_instance.rotation.y = atan2(p_pos.x - b_pos.x, p_pos.z - b_pos.z); add_child(bunker_instance)

func _spawn_pylon_path(start_pos: Vector3, dir: Vector3, count: int, col: Color) -> Vector3:
	for p in pylons: if is_instance_valid(p): p.queue_free()
	pylons.clear()
	var base_dir = dir.normalized(); var side = base_dir.rotated(Vector3.UP, PI * 0.5)
	var pts: Array[Vector3] = [start_pos + base_dir * 14.0 + side * 4.5]; var curr = pts[0]
	for i in range(2, count):
		var sweep = (1.0 if i % 2 == 0 else -1.0) * randf_range(0.65, 1.10)
		var step_dist = randf_range(110.0, 145.0) if count > 4 else randf_range(95.0, 130.0)
		curr += base_dir.rotated(Vector3.UP, sweep).normalized() * step_dist
		base_dir = base_dir.rotated(Vector3.UP, randf_range(-0.25, 0.25)).normalized()
		pts.append(curr)
	var bldg_dist = randf_range(110.0, 140.0) if count > 4 else randf_range(95.0, 125.0)
	var bldg_pos = curr + base_dir * bldg_dist
	pts.append(bldg_pos - base_dir * (34.0 if count > 4 else 8.5) + side * 4.5)
	for i in range(pts.size()):
		var pt = pts[i]; var gy = terrain.get_height(pt.x, pt.z) if terrain else 0.0
		if props and props.has_method("clear_area"): props.clear_area(Vector3(pt.x, gy, pt.z), 12.0)
		if i > 0 and i < pts.size() - 1 and terrain and terrain.has_method("add_flat_zone"):
			terrain.add_flat_zone(pt.x, pt.z, 10.0, gy, 4.0)
		var p = PYLON_SCRIPT.new(); p.station_id = i + 1; p.pylon_color = col; p.build_pylon(terrain, pt.x, pt.z)
		add_child(p); pylons.append(p)
	return bldg_pos

func _start_path_to_hub() -> void:
	current_state = State.HUB_ACTIVE
	var b_pos = bunker_instance.global_position if bunker_instance.is_inside_tree() else bunker_instance.position
	var b_fwd = bunker_instance.transform.basis.z if bunker_instance else Vector3(0.0, 0.0, 1.0)
	b_fwd.y = 0.0; var dir = b_fwd.normalized() if b_fwd.length_squared() > 0.1 else Vector3(0.0, 0.0, 1.0)
	hub_pos = _spawn_pylon_path(Vector3(b_pos.x, 0.0, b_pos.z), dir, 4, Color(1.0, 0.65, 0.12))
	var gy = terrain.get_height(hub_pos.x, hub_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(hub_pos.x, gy, hub_pos.z), 32.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(hub_pos.x, hub_pos.z, 28.0, gy, 12.0)
	hub_instance = HUB_SCRIPT.new(); hub_instance.build_hub(terrain, hub_pos.x, hub_pos.z); hub_instance.rotation.y = atan2(-dir.x, -dir.z)
	hub_instance.hub_interacted.connect(_on_hub_interacted); add_child(hub_instance)
	dosimeter = DOSIMETER_SCRIPT.new(); add_child(dosimeter)
	dosimeter.setup_dosimeter(player, pylons, "CHANNEL 01 // HUB", Color(1.0, 0.65, 0.12), "CENTRAL HUB AHEAD")

func _on_hub_interacted(stage: int) -> void:
	match stage:
		0:
			var dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
			var op2_pos = _spawn_pylon_path(hub_pos, dir, 4, Color(0.15, 0.8, 1.0)); var gy = terrain.get_height(op2_pos.x, op2_pos.z) if terrain else 0.0
			if props and props.has_method("clear_area"): props.clear_area(Vector3(op2_pos.x, gy, op2_pos.z), 24.0)
			if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(op2_pos.x, op2_pos.z, 20.0, gy, 8.0)
			outpost_2_instance = OUTPOST_SCRIPT.new(); outpost_2_instance.build_outpost(terrain, op2_pos.x, op2_pos.z, 2, Color(0.15, 0.8, 1.0))
			outpost_2_instance.rotation.y = atan2(-dir.x, -dir.z); outpost_2_instance.key_acquired.connect(_on_outpost_key_acquired); add_child(outpost_2_instance)
			dosimeter.set_track(pylons, "CHANNEL 02 // OUTPOST 2", Color(0.15, 0.8, 1.0), "OUTPOST 02 AHEAD"); current_state = State.OUTPOST_2_ACTIVE
		2:
			var dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
			var op3_pos = _spawn_pylon_path(hub_pos, dir, 4, Color(0.2, 0.95, 0.35)); var gy = terrain.get_height(op3_pos.x, op3_pos.z) if terrain else 0.0
			if props and props.has_method("clear_area"): props.clear_area(Vector3(op3_pos.x, gy, op3_pos.z), 24.0)
			if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(op3_pos.x, op3_pos.z, 20.0, gy, 8.0)
			outpost_3_instance = OUTPOST_SCRIPT.new(); outpost_3_instance.build_outpost(terrain, op3_pos.x, op3_pos.z, 3, Color(0.2, 0.95, 0.35))
			outpost_3_instance.rotation.y = atan2(-dir.x, -dir.z); outpost_3_instance.key_acquired.connect(_on_outpost_key_acquired); add_child(outpost_3_instance)
			dosimeter.set_track(pylons, "CHANNEL 03 // OUTPOST 3", Color(0.2, 0.95, 0.35), "OUTPOST 03 AHEAD"); current_state = State.OUTPOST_3_ACTIVE
		4:
			var dir = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
			var silo_pos = _spawn_pylon_path(hub_pos, dir, 5, Color(1.0, 0.15, 0.1)); var gy = terrain.get_height(silo_pos.x, silo_pos.z) if terrain else 0.0
			if props and props.has_method("clear_area"): props.clear_area(Vector3(silo_pos.x, gy, silo_pos.z), 85.0)
			if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(silo_pos.x, silo_pos.z, 85.0, gy, 31.0)
			if terrain and terrain.has_method("add_hole"): terrain.add_hole(silo_pos.x, silo_pos.z, 28.5)
			silo_instance = SILO_SCRIPT.new(); silo_instance.build_silo(terrain, silo_pos.x, silo_pos.z); silo_instance.rotation.y = atan2(-dir.x, -dir.z)
			silo_instance.silo_activated.connect(func(): current_state = State.COMPLETED); add_child(silo_instance)
			dosimeter.set_track(pylons, "CHANNEL 04 // MISSILE SILO", Color(1.0, 0.15, 0.1), "MISSILE SILO AHEAD"); current_state = State.SILO_ACTIVE

func _on_outpost_key_acquired(outpost_id: int) -> void:
	if hub_instance: hub_instance.set_stage(2 if outpost_id == 2 else 4)
	var rev: Array[Node3D] = []
	for i in range(pylons.size() - 1, -1, -1):
		pylons[i].is_cleared = false; rev.append(pylons[i])
	dosimeter.set_track(rev, "RETURN // CENTRAL HUB", Color(0.15, 0.8, 1.0) if outpost_id == 2 else Color(0.2, 0.95, 0.35), "CENTRAL HUB AHEAD")
	current_state = State.HUB_ACTIVE
