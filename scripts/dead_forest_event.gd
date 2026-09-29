class_name DeadForestEvent
extends Node3D
## The dead forest's progress and its relay network. Wander -> Outpost 73 appears; take its dosimeter, then its wall
## terminal programs the route to Relay Hub 00 (the first time lays that chain and raises the hub). At the hub the router
## writes routes 02 / 03 / 00 (each lays a chain and raises its building); outpost keys unlock the next write. Paths are
## only ever set at a terminal (RouteTerminal in every outer building, the router keys at the hub): chains stay standing
## in RelayNet, so any laid route can be walked either way whatever the progress.

const BUNKER_SCRIPT = preload("res://scripts/bunker/outpost_bunker.gd")
const DOSIMETER_SCRIPT = preload("res://scripts/radiation_dosimeter.gd")
const CAMPSITE_SCRIPT = preload("res://scripts/abandoned_campsite.gd")
const HUB_SCRIPT = preload("res://scripts/hub/relay_hub.gd")
const OUTPOST_SCRIPT = preload("res://scripts/outpost_building.gd")
const SILO_SCRIPT = preload("res://scripts/silo/missile_silo.gd")

@export var player: CharacterBody3D
@export var terrain: Node3D
@export var props: Node3D

enum State { WANDERING, NETWORK, COMPLETED }
var current_state: State = State.WANDERING
var wander_distance: float = 0.0
var wander_target: float = 600.0
var campsite_target: float = 175.0
var campsite_spawned: bool = false
var last_pos: Vector3 = Vector3.ZERO
var campsite_instance: Node3D
var bunker_instance: Node3D
var hub_instance: Node3D
var outpost_2_instance: Node3D
var outpost_3_instance: Node3D
var silo_instance: Node3D
var net := RelayNet.new()
var pylons: Array[Node3D] = []            # the chain laid last (spawn hooks, dev tools)
var dosimeter: Node
var hub_pos: Vector3 = Vector3.ZERO
var active_route: int = HubRoutes.Route.W73   # the route the dosimeter follows
var _buildings: Array[Node3D] = []        # every building raised so far, checked each physics frame

func _ready() -> void:
	wander_target = randf_range(380.0, 720.0)
	campsite_target = randf_range(110.0, 150.0)
	if player: last_pos = player.global_position
	BUNKER_SCRIPT.preload_models()
	HUB_SCRIPT.preload_models()
	OUTPOST_SCRIPT.preload_variants()
	SILO_SCRIPT.preload_models()

func _physics_process(_delta: float) -> void:
	if not player: return
	var p_pos = player.global_position
	if current_state == State.WANDERING:
		var d = p_pos.distance_to(last_pos)
		if d > 0.05 and d < 10.0: wander_distance += d
		last_pos = p_pos
		if not campsite_spawned and wander_distance >= campsite_target: _spawn_campsite_silently(p_pos)
		if wander_distance >= wander_target: _spawn_bunker_1(p_pos)
		return
	for b in _buildings: b.check_interaction(p_pos)   # every building stays live: routes work whatever the progress

func _spawn_campsite_silently(p_pos: Vector3) -> void:
	campsite_spawned = true
	var cam = player.get_node_or_null("Head/Camera3D") as Camera3D
	var fwd = -cam.global_transform.basis.z if cam else Vector3(0.0, 0.0, -1.0)
	fwd.y = 0.0
	fwd = fwd.normalized()
	var c_pos = p_pos + (fwd if fwd.length_squared() > 0.1 else Vector3.FORWARD) * 58.0
	var gy = terrain.get_height(c_pos.x, c_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(c_pos.x, gy, c_pos.z), 14.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(c_pos.x, c_pos.z, 18.0, gy, 9.5)
	campsite_instance = CAMPSITE_SCRIPT.new()
	campsite_instance.build_campsite(terrain, c_pos.x, c_pos.z)
	add_child(campsite_instance)

func _spawn_bunker_1(p_pos: Vector3) -> void:
	current_state = State.NETWORK
	var ang = randf_range(0.0, TAU)
	var b_pos = p_pos + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(58.0, 72.0)
	var gy = terrain.get_height(b_pos.x, b_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(b_pos.x, gy, b_pos.z), 16.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(b_pos.x, b_pos.z, 20.0, gy, 9.0)
	bunker_instance = BUNKER_SCRIPT.new()
	bunker_instance.build_bunker(terrain, b_pos.x, b_pos.z)
	bunker_instance.rotation.y = atan2(p_pos.x - b_pos.x, p_pos.z - b_pos.z)
	add_child(bunker_instance)
	_buildings.append(bunker_instance)
	bunker_instance.dosimeter_acquired.connect(_ensure_dosimeter)
	bunker_instance.route_programmed.connect(_on_terminal_programmed)

## Relay chain from start_pos toward dir (RelayChain); keeps it in `pylons` and returns the building spot.
func _lay_chain(start_pos: Vector3, dir: Vector3, count: int, col: Color, to_building: bool = true) -> RelayChain:
	var chain := RelayChain.new().lay(self, terrain, props, start_pos, dir, count, col, to_building)
	pylons = chain.masts
	return chain

## Route 73 out of Outpost 73 and the hub at its end (first use of Outpost 73's terminal).
func _start_path_to_hub() -> void:
	if hub_instance or not bunker_instance: return
	current_state = State.NETWORK
	var b_pos = bunker_instance.global_position if bunker_instance.is_inside_tree() else bunker_instance.position
	var b_fwd = bunker_instance.transform.basis.z
	b_fwd.y = 0.0
	var dir = b_fwd.normalized() if b_fwd.length_squared() > 0.1 else Vector3(0.0, 0.0, 1.0)
	var chain := _lay_chain(Vector3(b_pos.x, 0.0, b_pos.z), dir, 4, HubRoutes.COLORS[HubRoutes.Route.W73], false)
	hub_pos = chain.building_pos
	var gy = terrain.get_height(hub_pos.x, hub_pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"): props.clear_area(Vector3(hub_pos.x, gy, hub_pos.z), 34.0)
	if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(hub_pos.x, hub_pos.z, 30.0, gy, 17.0)
	chain.settle(terrain)
	var from = pylons.back().global_position if not pylons.is_empty() else b_pos
	hub_instance = HUB_SCRIPT.new()
	hub_instance.build_hub(terrain, hub_pos.x, hub_pos.z, from)
	hub_instance.hub_interacted.connect(_on_hub_interacted)
	hub_instance.route_selected.connect(_follow.bind(false))
	add_child(hub_instance)
	_buildings.append(hub_instance)
	net.add_route(HubRoutes.Route.W73, pylons, false)

## An outer building's terminal: follow its route home to the hub (Outpost 73's first use lays that route).
func _on_terminal_programmed(route: int) -> void:
	if route == HubRoutes.Route.W73: _start_path_to_hub()
	_follow(route, true)

## Put the dosimeter on `route`, toward the hub or out to the route's building; every terminal shows which route is set.
func _follow(route: int, to_hub: bool) -> void:
	if not hub_instance or not net.has_route(route): return
	_ensure_dosimeter()
	active_route = route
	var dest: String = "CENTRAL HUB" if to_hub else HubRoutes.NAMES[route]
	dosimeter.set_track(net.track(route, to_hub, hub_instance.route_mast(route)), "R-%s // %s" % [HubRoutes.KEYS[route], dest],
		HubRoutes.COLORS[route], dest + " AHEAD", false)
	hub_instance.show_route(-1 if to_hub else route)
	for b in [bunker_instance, outpost_2_instance, outpost_3_instance, silo_instance]:
		if b and b.terminal: b.terminal.show_route(to_hub and b.terminal.route == route)

func _ensure_dosimeter() -> void:
	if dosimeter: return
	dosimeter = DOSIMETER_SCRIPT.new()
	add_child(dosimeter)
	dosimeter.setup_dosimeter(player, [], "NO ROUTE", HubRoutes.COLORS[HubRoutes.Route.W73], "")

## A route was written at the hub's router (stage 0 / 2 / 4): relay chain out of its corner, its building at the end, and
## the dosimeter on it (writing a route is programming it).
func _on_hub_interacted(stage: int) -> void:
	if not hub_instance or stage not in [0, 2, 4]: return
	if hub_instance.current_stage <= stage: hub_instance.set_stage(stage + 1)   # dev tools call this directly
	var route: int = [HubRoutes.Route.W02, HubRoutes.Route.W03, HubRoutes.Route.SILO][stage >> 1]
	if net.has_route(route): return
	var col: Color = HubRoutes.COLORS[route]
	var dir: Vector3 = hub_instance.route_out(route)
	var chain := _lay_chain(hub_instance.route_mast(route).global_position, dir, 5 if stage == 4 else 4, col)
	var dest := chain.building_pos
	var gy = terrain.get_height(dest.x, dest.z) if terrain else 0.0
	if stage == 4:
		if props and props.has_method("clear_area"): props.clear_area(Vector3(dest.x, gy, dest.z), SILO_SCRIPT.CLEAR_RADIUS)
		if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(dest.x, dest.z, SILO_SCRIPT.FLAT_RADIUS, gy, SILO_SCRIPT.FLAT_INNER)
		if terrain and terrain.has_method("add_hole"): terrain.add_hole(dest.x, dest.z, SILO_SCRIPT.HOLE_RADIUS, SILO_SCRIPT.HOLE_SINK, SILO_SCRIPT.PIT_DEPTH)
		chain.settle(terrain)
		silo_instance = SILO_SCRIPT.new()
		silo_instance.build_silo(terrain, dest.x, dest.z, props)
		silo_instance.rotation.y = atan2(-dir.x, -dir.z)
		silo_instance.silo_activated.connect(func(): current_state = State.COMPLETED)
		add_child(silo_instance)
		silo_instance.route_programmed.connect(_on_terminal_programmed)
		_buildings.append(silo_instance)
	else:
		var id = 2 if stage == 0 else 3
		if props and props.has_method("clear_area"): props.clear_area(Vector3(dest.x, gy, dest.z), 24.0)
		if terrain and terrain.has_method("add_flat_zone"): terrain.add_flat_zone(dest.x, dest.z, 20.0, gy, 10.0)   # yard: tree / tanks
		chain.settle(terrain)
		var outpost = OUTPOST_SCRIPT.new()
		outpost.build_outpost(terrain, dest.x, dest.z, id, col)
		outpost.rotation.y = atan2(-dir.x, -dir.z)
		outpost.key_acquired.connect(_on_outpost_key_acquired)
		add_child(outpost)
		outpost.route_programmed.connect(_on_terminal_programmed)
		set("outpost_%d_instance" % id, outpost)
		_buildings.append(outpost)
	net.add_route(route, pylons, true)
	_follow(route, false)

## An outpost's route key: the hub can write the next route. The way back is programmed at the outpost's terminal.
func _on_outpost_key_acquired(outpost_id: int) -> void:
	if hub_instance: hub_instance.set_stage(2 if outpost_id == 2 else 4)
