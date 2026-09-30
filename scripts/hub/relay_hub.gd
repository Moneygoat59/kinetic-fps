class_name RelayHub
extends Node3D
## Relay Hub 00: the routing station every amber well feeds (model: tools/blender/props/relay_hub.py). Instances the
## model and wires its door, lights (HubAmbience), kit furniture, the four routes with their corner relay masts (HubRoutes) and the
## router console (HubConsole) with its route keys (HubRouterKeys): the hub's route terminal. Progress API for
## DeadForestEvent and the dev tools: build_hub, check_interaction, set_stage, hub_interacted(stage). Stage 0 / 2 / 4 =
## route 02 / 03 / silo ready to write, 1 / 3 = waiting on that outpost's key, 5 = every route online. Traversal API:
## route_selected(route) when a key programs the dosimeter onto an existing route, show_route(route) marks the one it
## follows. route_mast / route_out give the event each route's corner mast and outward direction.

signal hub_interacted(stage: int)
signal route_selected(route: int)

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const MODEL_PATH := "res://models/generated/relay_hub.glb"
const ROUTER_MARKER := "marker_kit_terminal_router__0"
const DOOR_BLOCKER := Vector3(2.0, 2.35, 0.3)
const DOOR_TRIGGER_DIST := 6.5
const ACTIVE_DIST := 34.0
const STAGE_ROUTE: Array[int] = [HubRoutes.Route.W02, HubRoutes.Route.W02, HubRoutes.Route.W03, HubRoutes.Route.W03,
	HubRoutes.Route.SILO, HubRoutes.Route.SILO]

var current_stage := 0
var model: Node3D
var routes := HubRoutes.new()
var console := HubConsole.new()
var ambience := HubAmbience.new()
var keys := HubRouterKeys.new()
var _on_route := -1              # the route the dosimeter follows out of the hub (-1: none / heading here)
var _door: BunkerDoor
var _door_center: Node3D


static func preload_models() -> void:
	load(MODEL_PATH)
	load(O73Kit.path(&"terminal_router"))


## Places the hub at (pos_x, pos_z) on the terrain, turned so route 73's corner (the end of the arrival chain) points at
## `arrive_from` (world position the player comes from).
func build_hub(terrain: Node3D, pos_x: float, pos_z: float, arrive_from: Vector3) -> void:
	var scene := load(MODEL_PATH) as PackedScene
	if scene == null:
		push_error("RelayHub: cannot load " + MODEL_PATH)
		return
	position = Vector3(pos_x, terrain.get_height(pos_x, pos_z) if terrain else 0.0, pos_z)
	model = scene.instantiate() as Node3D
	add_child(model)
	var corner := model.get_node_or_null("marker_route_73") as Node3D
	var local := corner.position if corner else Vector3(-1.0, 0.0, 1.0)
	rotation.y = atan2(arrive_from.x - pos_x, arrive_from.z - pos_z) - atan2(local.x, local.z)
	Fx.make_matte(model)
	add_child(ambience)
	ambience.setup(model)
	Fx.add_grime(self)
	_door = BunkerDoor.mount(self, model, DOOR_BLOCKER)
	_door_center = model.get_node_or_null("marker_door_center") as Node3D
	KitScript.furnish(model)
	RemnantSmalls.dress(model)
	add_child(routes)
	routes.setup(model, self, terrain)
	routes.set_online(HubRoutes.Route.W73, false)            # the one well still pumping; its mast is the player's to align
	add_child(console)
	var router := model.get_node_or_null(ROUTER_MARKER)
	add_child(keys)
	if router and router.get_child_count() > 0:
		console.setup(router.get_child(0) as Node3D)
		keys.setup(router.get_child(0) as Node3D, console)
	console.programmed.connect(_on_programmed)
	console.routed.connect(_on_routed)
	set_stage(0)


## The corner relay mast of a route (HubRoutes.Route).
func route_mast(route: int) -> Node3D:
	return routes.masts[route] if route >= 0 and route < routes.masts.size() else null


## World-space horizontal direction from the hub out through a route's corner mast.
func route_out(route: int) -> Vector3:
	var mast := route_mast(route)
	if mast == null:
		return global_transform.basis.z
	var out := mast.global_position - global_position
	out.y = 0.0
	return out.normalized() if out.length_squared() > 0.01 else global_transform.basis.z


func set_stage(stage: int) -> void:
	current_stage = clampi(stage, 0, 5)
	for s in range(1, current_stage + 1, 2):                  # every route written before this stage is online
		if routes.flow[STAGE_ROUTE[s]] == HubRoutes.Flow.DRY:
			routes.set_online(STAGE_ROUTE[s])
	for r in HubRoutes.KEYS.size():
		var online := routes.flow[r] != HubRoutes.Flow.DRY
		console.view.set_row(r, "ONLINE" if online else "NO CARRIER", online)
		console.view.set_key(r, online)
	console.view.set_security_key(0, current_stage >= 2)     # key 02 taken at Outpost 02 -> stage 2
	console.view.set_security_key(1, current_stage >= 4)     # key 03 taken at Outpost 03 -> stage 4
	keys.refresh(routes.flow, current_stage, _on_route)
	if current_stage >= 5:
		console.finish_all()
	else:
		console.show_stage(STAGE_ROUTE[current_stage], current_stage % 2 == 1)


## The dosimeter now follows `route` out of the hub (-1: none, or it is heading back here).
func show_route(route: int) -> void:
	_on_route = route
	keys.refresh(routes.flow, current_stage, _on_route)


func _on_programmed(route: int) -> void:
	routes.open(route)
	var stage := current_stage
	set_stage(stage + 1)
	hub_interacted.emit(stage)


func _on_routed(route: int) -> void:
	set_stage(current_stage)                                  # idle log back to where the network stands
	route_selected.emit(route)


## Called every physics frame by DeadForestEvent. force = write the offered route now (dev tools). True on that frame.
func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	if model == null:
		return false
	var near := global_position.distance_to(player_pos) < ACTIVE_DIST
	if _door and _door_center:
		_door.request_open(_door_center.global_position.distance_to(player_pos) < DOOR_TRIGGER_DIST)
	routes.set_active(near)
	console.set_active(near)
	var stage := current_stage
	if force and not console.is_busy() and keys.mode_of(STAGE_ROUTE[mini(stage, 5)]) == HubRouterKeys.Mode.WRITE:
		console.write(STAGE_ROUTE[stage])
		console.force_finish()
	return current_stage != stage

