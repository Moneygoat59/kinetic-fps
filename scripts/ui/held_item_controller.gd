class_name HeldItemController
extends Node

signal held_item_changed(index: int, item_data: Dictionary)

const SWITCH_SOUND = preload("res://audio/ui/Audio/switch_001.ogg")

var held_items: Array[Dictionary] = [
	{"id": "grenade", "name": "PINE-FRAG GRENADE", "type": 1, "ammo": "x3", "icon_path": "res://textures/ui/icons/icon_grenade.png"},
	{"id": "dosimeter", "name": "FIELD DOSIMETER MK-IV", "type": 2, "ammo": "RAD-ACTIVE", "icon_path": "res://textures/ui/icons/icon_dosimeter.png"},
	{"id": "torch", "name": "SURVIVAL FLARE TORCH", "type": 3, "ammo": "LIT", "icon_path": "res://textures/ui/icons/icon_torch.png"}
]

var current_idx: int = -1   # -1 = empty hands (the walker starts holding nothing)
var combat_ref: PlayerCombat
var sfx: AudioStreamPlayer
var torch_light: OmniLight3D
var player_cam: Camera3D

func setup(combat: PlayerCombat, camera: Camera3D) -> void:
	combat_ref = combat
	player_cam = camera
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -5.0
	sfx.stream = SWITCH_SOUND
	add_child(sfx)

	if player_cam:
		torch_light = OmniLight3D.new()
		torch_light.name = "HeldTorchLight"
		torch_light.position = Vector3(0.3, -0.2, -0.5)
		torch_light.light_color = Color(1.0, 0.65, 0.25)
		torch_light.light_energy = 2.8
		torch_light.omni_range = 18.0
		torch_light.shadow_enabled = true
		torch_light.visible = false
		player_cam.add_child(torch_light)

func rotate_next() -> void:
	current_idx = (current_idx + 1) % held_items.size()
	_apply_held_slot(current_idx)

func rotate_prev() -> void:
	current_idx = held_items.size() - 1 if current_idx < 0 else (current_idx - 1 + held_items.size()) % held_items.size()
	_apply_held_slot(current_idx)

func select_slot(idx: int) -> void:
	if idx >= 0 and idx < held_items.size() and idx != current_idx:
		current_idx = idx
		_apply_held_slot(current_idx)

func get_current_item() -> Dictionary:
	return held_items[current_idx] if current_idx >= 0 else {}

func _apply_held_slot(idx: int) -> void:
	current_idx = idx
	var it = held_items[idx]
	if sfx: sfx.play()

	var id: String = it["id"]
	if torch_light:
		torch_light.visible = (id == "torch")

	if player_cam:
		var gm = player_cam.get_node_or_null("GunMount")
		if gm: gm.visible = (id == "grenade")
		var tr = player_cam.get_node_or_null("HeldFieldTracker")
		if tr: tr.visible = (id == "dosimeter")

	if combat_ref:
		if id == "grenade":
			combat_ref.switch_to(PlayerCombat.WeaponType.GRENADE)
		else:
			if combat_ref.gun_mesh: combat_ref.gun_mesh.visible = false
			if combat_ref.grenade_mount: combat_ref.grenade_mount.visible = false

	emit_signal("held_item_changed", idx, it)

func handle_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			rotate_prev()
			return true
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			rotate_next()
			return true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			rotate_prev()
			return true
		elif event.keycode == KEY_E and not Input.is_action_pressed("interact"):
			rotate_next()
			return true
		elif event.keycode == KEY_1:
			select_slot(0); return true
		elif event.keycode == KEY_2:
			select_slot(1); return true
		elif event.keycode == KEY_3:
			select_slot(2); return true
	return false
