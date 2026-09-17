class_name DeadForestEvent
extends Node3D

const BUNKER_SCRIPT = preload("res://scripts/small_bunker.gd")
const PYLON_SCRIPT = preload("res://scripts/nuclear_pylon.gd")
const DOSIMETER_SCRIPT = preload("res://scripts/radiation_dosimeter.gd")
const FACILITY_SCRIPT = preload("res://scripts/concrete_facility.gd")

@export var player: CharacterBody3D
@export var terrain: Node3D
@export var props: Node3D

enum State { WANDERING, BUNKER_ACTIVE, BEACONS_ACTIVE, COMPLETED }
var current_state: State = State.WANDERING

var wander_distance: float = 0.0
var wander_target: float = 600.0
var last_pos: Vector3 = Vector3.ZERO
var bunker_instance: Node3D
var facility_instance: Node3D
var pylons: Array[Node3D] = []
var dosimeter: Node
var end_facility_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	wander_target = randf_range(400.0, 800.0)
	if player: last_pos = player.global_position

func _physics_process(delta: float) -> void:
	if not player: return
	var p_pos = player.global_position

	match current_state:
		State.WANDERING:
			var d = p_pos.distance_to(last_pos)
			if d > 0.05 and d < 10.0: wander_distance += d
			last_pos = p_pos
			if wander_distance >= wander_target:
				_spawn_small_bunker_silently(p_pos)
		State.BUNKER_ACTIVE:
			if bunker_instance and not bunker_instance.is_claimed:
				if bunker_instance.check_interaction(p_pos):
					_on_dosimeter_picked_up()

func _spawn_small_bunker_silently(p_pos: Vector3) -> void:
	current_state = State.BUNKER_ACTIVE
	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	var fwd = -cam.global_transform.basis.z if cam else -player.global_transform.basis.z
	fwd.y = 0.0; fwd = fwd.normalized()
	if fwd.length_squared() < 0.1: fwd = Vector3(0.0, 0.0, -1.0)
	var b_pos = p_pos + fwd * 34.0

	var gy = terrain.get_height(b_pos.x, b_pos.z) if terrain else 0.0
	if terrain and terrain.has_method("add_flat_zone"):
		terrain.add_flat_zone(b_pos.x, b_pos.z, 10.0, gy)
	if props and props.has_method("clear_area"):
		props.clear_area(Vector3(b_pos.x, gy, b_pos.z), 11.0)

	bunker_instance = BUNKER_SCRIPT.new()
	bunker_instance.build_bunker(terrain, b_pos.x, b_pos.z)
	add_child(bunker_instance)

func _on_dosimeter_picked_up() -> void:
	current_state = State.BEACONS_ACTIVE
	var bx = bunker_instance.global_position.x
	var bz = bunker_instance.global_position.z
	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	var trail_dir = -cam.global_transform.basis.z if cam else Vector3(0.0, 0.0, -1.0)
	trail_dir.y = 0.0; trail_dir = trail_dir.normalized()
	if trail_dir.length_squared() < 0.1: trail_dir = Vector3(0.0, 0.0, -1.0)

	# Spawn 5 beacons spaced 60m apart
	for i in range(1, 6):
		var dist = float(i) * 60.0
		var lateral = sin(float(i) * 1.5) * 14.0
		var wx = bx + trail_dir.x * dist - trail_dir.z * lateral
		var wz = bz + trail_dir.z * dist + trail_dir.x * lateral
		var p_gy = terrain.get_height(wx, wz) if terrain else 0.0
		if props and props.has_method("clear_area"):
			props.clear_area(Vector3(wx, p_gy, wz), 5.0)

		var p = PYLON_SCRIPT.new()
		p.station_id = i; p.build_pylon(terrain, wx, wz)
		p.station_reached.connect(_on_pylon_reached)
		add_child(p); pylons.append(p)

	end_facility_pos = Vector3(bx + trail_dir.x * 360.0, 0.0, bz + trail_dir.z * 360.0)

	dosimeter = DOSIMETER_SCRIPT.new(); add_child(dosimeter)
	dosimeter.setup_dosimeter(player, pylons)

func _on_pylon_reached(pylon: Node3D) -> void:
	if pylon.station_id == 1 and not facility_instance:
		_spawn_end_facility()

func _spawn_end_facility() -> void:
	var f_gy = terrain.get_height(end_facility_pos.x, end_facility_pos.z) if terrain else 0.0
	if terrain and terrain.has_method("add_flat_zone"):
		terrain.add_flat_zone(end_facility_pos.x, end_facility_pos.z, 36.0, f_gy)
	if props and props.has_method("clear_area"):
		props.clear_area(Vector3(end_facility_pos.x, f_gy, end_facility_pos.z), 36.0)

	facility_instance = FACILITY_SCRIPT.new()
	facility_instance.build_facility(terrain, end_facility_pos.x, end_facility_pos.z)
	add_child(facility_instance)
