class_name OutpostBunker
extends Node3D
## Outpost 73 bunker: instances the Blender-built model and wires gameplay onto its named nodes.
## Drop-in replacement for SmallBunker's public API (build_bunker / check_interaction / dosimeter_acquired).
## Model contract: see tools/blender/props/outpost73_bunker.py.

signal dosimeter_acquired

const DoorScript = preload("res://scripts/bunker/bunker_door.gd")
const PickupScript = preload("res://scripts/bunker/bunker_pickup.gd")
const MODEL_PATH := "res://models/generated/outpost73_bunker.glb"
const DOOR_TRIGGER_DIST := 5.8
const DOOR_BLOCKER_SIZE := Vector3(1.8, 2.25, 0.3)
const AMBER := Color(1.0, 0.68, 0.15)
## marker name -> [colour, energy, range]. The roof light pulses (see _process).
const LIGHTS := {
	"marker_light_ceiling": [Color(1.0, 0.72, 0.2), 2.6, 8.0],
	"marker_light_front": [AMBER, 3.8, 7.5],
	"marker_light_side_l": [AMBER, 2.5, 5.0],
	"marker_light_side_r": [AMBER, 2.5, 5.0],
	"marker_light_roof": [AMBER, 4.0, 45.0],
}

var model: Node3D
var door: Node
var pickup: Node3D
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
	_setup_lights()
	_setup_door()
	_setup_pickup()


func _marker(marker_name: String) -> Node3D:
	return model.get_node_or_null(marker_name) as Node3D


func _setup_lights() -> void:
	for marker_name in LIGHTS:
		var m := _marker(marker_name)
		if m == null:
			continue
		var spec: Array = LIGHTS[marker_name]
		var light := OmniLight3D.new()
		light.light_color = spec[0]
		light.light_energy = spec[1]
		light.omni_range = spec[2]
		m.add_child(light)
		if marker_name == "marker_light_roof":
			_roof_light = light


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
	if door:
		door.request_open(global_position.distance_to(player_pos) < DOOR_TRIGGER_DIST)
	return pickup != null and pickup.update_proximity(player_pos, force)
