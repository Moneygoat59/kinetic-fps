class_name OutpostBunker
extends Node3D
## Outpost 73 bunker: instances the Blender-built model and wires gameplay onto its named nodes.
## Drop-in replacement for SmallBunker's public API (build_bunker / check_interaction / dosimeter_acquired).
## Its wall terminal (RouteTerminal) programs the dosimeter onto the route to the hub: route_programmed(route); locked
## until the dosimeter is taken.
## Model contract: see tools/blender/props/outpost73_bunker.py. The other wells (OutpostBuilding) extend this and override
## _model_path / _setup_pickup / _setup_pump.

signal dosimeter_acquired
signal route_programmed(route: int)

const DoorScript = preload("res://scripts/bunker/bunker_door.gd")
const PickupScript = preload("res://scripts/bunker/bunker_pickup.gd")
const ScreensScript = preload("res://scripts/bunker/bunker_screens.gd")
const PumpScript = preload("res://scripts/bunker/bunker_pump.gd")
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const BEACON_RATE := 3.2                  # rad/s: slow warning pulse of the roof beacon and the cabinet status lamp
const MODEL_PATH := "res://models/generated/outpost73_bunker.glb"
const DOOR_TRIGGER_DIST := 5.8
const SCREENS_ACTIVE_DIST := 24.0
const DOOR_BLOCKER_SIZE := Vector3(1.8, 2.25, 0.3)

var model: Node3D
var door: Node
var pickup: Node3D
var screens: Node
var pump: Node
var terminal: RouteTerminal
var _roof_light: OmniLight3D
var _beacon: BaseMaterial3D
var _pulse: Array[OmniLight3D] = []       # amber well lights that breathe
var _pulse_base := PackedFloat32Array()
var _flick: Array[OmniLight3D] = []       # failing lamps
var _flick_base := PackedFloat32Array()


static func preload_models() -> void:
	load(MODEL_PATH)
	load(PickupScript.DEVICE_PATH)
	KitScript.preload_props()


func build_bunker(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var scene := load(_model_path()) as PackedScene
	if scene == null:
		push_error("OutpostBunker: cannot load " + _model_path())
		return
	position = Vector3(pos_x, terrain.get_height(pos_x, pos_z) if terrain else 0.0, pos_z)
	model = scene.instantiate() as Node3D
	add_child(model)
	Fx.make_matte(model)
	var made := Fx.add_lights(model)
	_roof_light = made.get(Fx.ROOF_LIGHT) as OmniLight3D
	Fx.collect(made, Fx.PULSE_LIGHTS, _pulse, _pulse_base)
	Fx.collect(made, Fx.FLICKER_LIGHTS, _flick, _flick_base)
	Fx.add_grime(self)
	_setup_door()
	_setup_pickup()
	KitScript.furnish(model)
	RemnantSmalls.dress(model)
	terminal = RouteTerminal.mount(self, model, _route(), pickup is PickupScript)
	if terminal:
		terminal.programmed.connect(route_programmed.emit)
		if pickup is PickupScript:
			pickup.claimed.connect(terminal.unlock)
	screens = ScreensScript.new()
	add_child(screens)
	screens.setup(model)
	_setup_pump()
	_beacon = Fx.find_material(model, Fx.BEACON_MAT)


func _model_path() -> String:
	return MODEL_PATH


## The hub route this building's terminal programs.
func _route() -> int:
	return HubRoutes.Route.W73


func _setup_pump() -> void:
	pump = PumpScript.new()
	add_child(pump)
	pump.setup(model)


func _marker(marker_name: String) -> Node3D:
	return model.get_node_or_null(marker_name) as Node3D


func _setup_door() -> void:
	door = DoorScript.mount(self, model, DOOR_BLOCKER_SIZE)


func _setup_pickup() -> void:
	var anchor := _marker("marker_pickup")
	if anchor == null:
		push_warning("OutpostBunker: marker_pickup missing from model")
		return
	pickup = PickupScript.new()
	anchor.add_child(pickup)
	pickup.setup()
	pickup.claimed.connect(dosimeter_acquired.emit)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var blink := (sin(t * BEACON_RATE) + 1.0) * 0.5
	if _roof_light:
		_roof_light.light_energy = lerpf(1.0, 4.5, blink)
	if _beacon:
		_beacon.emission_energy_multiplier = lerpf(0.3, 2.6, blink)
	for i in _pulse.size():
		_pulse[i].light_energy = _pulse_base[i] * (0.75 + 0.25 * sin(t * 2.1 + i * 1.3))
	for i in _flick.size():
		_flick[i].light_energy = _flick_base[i] * Fx.flicker(t, i * 1.7)


## Called every physics frame by DeadForestEvent. Returns true on the frame the tracker is taken.
func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	if model == null:
		return false
	var dist := global_position.distance_to(player_pos)
	if door:
		door.request_open(dist < DOOR_TRIGGER_DIST)
	if screens:
		screens.set_active(dist < SCREENS_ACTIVE_DIST)
	if terminal and dist < SCREENS_ACTIVE_DIST:
		terminal.update(player_pos)
	return pickup != null and pickup.update_proximity(player_pos, force)
