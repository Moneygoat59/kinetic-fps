class_name OutpostBunker
extends Node3D
## Outpost 73 bunker: instances the Blender-built model and wires gameplay onto its named nodes.
## Drop-in replacement for SmallBunker's public API (build_bunker / check_interaction / dosimeter_acquired).
## Model contract: see tools/blender/props/outpost73_bunker.py.

signal dosimeter_acquired

const DoorScript = preload("res://scripts/bunker/bunker_door.gd")
const PickupScript = preload("res://scripts/bunker/bunker_pickup.gd")
const ScreensScript = preload("res://scripts/bunker/bunker_screens.gd")
const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const MODEL_PATH := "res://models/generated/outpost73_bunker.glb"
const DOOR_TRIGGER_DIST := 5.8
const SCREENS_ACTIVE_DIST := 24.0
const DOOR_BLOCKER_SIZE := Vector3(1.8, 2.25, 0.3)

var model: Node3D
var door: Node
var pickup: Node3D
var screens: Node
var _roof_light: OmniLight3D


static func preload_models() -> void:
	load(MODEL_PATH)
	load(PickupScript.DEVICE_PATH)


func build_bunker(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	var scene := load(MODEL_PATH) as PackedScene
	if scene == null:
		push_error("OutpostBunker: cannot load " + MODEL_PATH)
		return
	position = Vector3(pos_x, terrain.get_height(pos_x, pos_z) if terrain else 0.0, pos_z)
	model = scene.instantiate() as Node3D
	add_child(model)
	Fx.make_matte(model)
	_roof_light = Fx.add_lights(model)
	Fx.add_grime(self)
	_setup_door()
	_setup_pickup()
	screens = ScreensScript.new()
	add_child(screens)
	screens.setup(model)


func _marker(marker_name: String) -> Node3D:
	return model.get_node_or_null(marker_name) as Node3D


func _setup_door() -> void:
	var left := model.get_node_or_null("door_left") as Node3D
	var right := model.get_node_or_null("door_right") as Node3D
	var center := _marker("marker_door_center")
	if left == null or right == null or center == null:
		push_warning("OutpostBunker: door nodes missing from model")
		return
	var body := StaticBody3D.new()
	body.position = center.position + Vector3(0.0, DOOR_BLOCKER_SIZE.y * 0.5, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = DOOR_BLOCKER_SIZE
	shape.shape = box
	body.add_child(shape)
	model.add_child(body)
	var audio := AudioStreamPlayer3D.new()
	audio.unit_size = 18.0
	audio.position = center.position + Vector3(0.0, 1.25, 0.0)
	model.add_child(audio)
	door = DoorScript.new()
	add_child(door)
	door.setup(left, right, shape, audio)


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
	if _roof_light:
		_roof_light.light_energy = lerpf(2.5, 6.5, (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5)


## Called every physics frame by DeadForestEvent. Returns true on the frame the tracker is taken.
func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	if model == null:
		return false
	var dist := global_position.distance_to(player_pos)
	if door:
		door.request_open(dist < DOOR_TRIGGER_DIST)
	if screens:
		screens.set_active(dist < SCREENS_ACTIVE_DIST)
	return pickup != null and pickup.update_proximity(player_pos, force)
