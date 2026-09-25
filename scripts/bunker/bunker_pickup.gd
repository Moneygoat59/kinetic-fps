extends Node3D
## Item station: the hovering Analog Field Tracker, its [E] prompt and the locator beacon chirp.
## Emits `claimed` once; then goes inert.

signal claimed

enum State { AVAILABLE, CLAIMED }

const Builder = preload("res://scripts/bunker_builder.gd")
const DEVICE_PATH := "res://models/finder_device.glb"
const BEACON_SOUND = preload("res://audio/digital/Audio/threeTone1.ogg")
const PICKUP_SOUND = preload("res://audio/ui/Audio/confirmation_001.ogg")
const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")
const PROMPT_TEXT := "[ E ] TAKE ANALOG FIELD TRACKER"
const SHOW_DIST := 3.4
const AUTO_CLAIM_DIST := 1.8
const CHIRP_INTERVAL := 1.1

var state: State = State.AVAILABLE
var _item: Node3D
var _beacon: AudioStreamPlayer3D
var _canvas: CanvasLayer
var _label: Label
var _chirp: float = 1.0


func setup() -> void:
	var b_mat := Builder.mat_basalt()  # first: initialises BunkerBuilder's shared textures
	var di_mat := Builder.mat_dark_iron()
	var glow := Builder.mat_glow(Color(1.0, 0.72, 0.16), 2.8, Builder.meter_tex)
	_item = Node3D.new()
	add_child(_item)
	_build_device(b_mat, di_mat, glow)
	Builder.omni(_item, Vector3(0.0, 0.25, 0.0), Color(1.0, 0.72, 0.16), 2.8, 3.8)

	_beacon = AudioStreamPlayer3D.new()
	_beacon.stream = BEACON_SOUND
	_beacon.unit_size = 28.0
	_beacon.max_distance = 160.0
	_beacon.volume_db = 9.0
	add_child(_beacon)

	_canvas = CanvasLayer.new()
	_canvas.layer = 13
	add_child(_canvas)
	_label = Label.new()
	_label.text = PROMPT_TEXT
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.position.y += 40.0
	_label.modulate = Color(1.0, 0.75, 0.18, 0.0)
	_canvas.add_child(_label)


func _build_device(b_mat: Material, di_mat: Material, glow: Material) -> void:
	var scene := load(DEVICE_PATH) as PackedScene
	if scene == null:
		var fallback := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.24, 0.12, 0.18)
		fallback.mesh = box
		fallback.material_override = glow
		_item.add_child(fallback)
		return
	var dev := scene.instantiate() as Node3D
	dev.scale = Vector3(0.42, 0.42, 0.42)
	dev.rotation = Vector3(deg_to_rad(65.0), deg_to_rad(15.0), 0.0)
	var mi := dev.find_child("Multmeter_Cube", true, false) as MeshInstance3D
	if mi:
		mi.set_surface_override_material(2, glow)
		mi.set_surface_override_material(1, b_mat)
		mi.set_surface_override_material(0, di_mat)
	_item.add_child(dev)


func _process(delta: float) -> void:
	if state == State.CLAIMED:
		return
	_item.position.y = sin(Time.get_ticks_msec() * 0.005) * 0.015
	_chirp -= delta
	if _chirp <= 0.0:
		_chirp = CHIRP_INTERVAL
		_beacon.play()


## Called every physics frame by the level. Returns true on the frame the item is taken.
func update_proximity(player_pos: Vector3, force: bool = false) -> bool:
	if state == State.CLAIMED or _item == null:
		return false
	var dist := _item.global_position.distance_to(player_pos)
	if dist >= SHOW_DIST:
		_label.modulate.a = 0.0
		return false
	_label.modulate.a = clampf((SHOW_DIST - dist) / 1.2, 0.0, 1.0)
	if force or dist < AUTO_CLAIM_DIST or Input.is_action_just_pressed("interact"):
		_claim()
		return true
	return false


func _claim() -> void:
	state = State.CLAIMED
	_canvas.queue_free()
	_item.queue_free()
	_beacon.stop()
	for snd in [[PICKUP_SOUND, 0.0], [SWITCH_SOUND, -3.0]]:
		var p := AudioStreamPlayer.new()
		p.stream = snd[0]
		p.volume_db = snd[1]
		add_child(p)
		p.play()
	claimed.emit()
