class_name SurvivalUiSystem
extends Node

const INVENTORY_SCRIPT = preload("res://scripts/ui/horror_inventory_menu.gd")
const HELD_CTRL_SCRIPT = preload("res://scripts/ui/held_item_controller.gd")
const HORROR_HUD_SCRIPT = preload("res://scripts/ui/horror_hud.gd")

var inventory: CanvasLayer
var held_ctrl: Node
var horror_hud: CanvasLayer
var player_ref: CharacterBody3D
var health_ref: RefCounted

static func attach(player: CharacterBody3D, combat: RefCounted, camera: Camera3D, health: RefCounted) -> Node:
	var script_res = load("res://scripts/ui/survival_ui_system.gd") as GDScript
	var sys = script_res.new()
	sys.name = "SurvivalUiSystem"
	player.add_child(sys)
	sys.init_system(player, combat, camera, health)
	return sys

func init_system(player: CharacterBody3D, combat: RefCounted, camera: Camera3D, health: RefCounted) -> void:
	player_ref = player
	health_ref = health

	held_ctrl = HELD_CTRL_SCRIPT.new()
	held_ctrl.name = "HeldItemController"
	add_child(held_ctrl)

	horror_hud = HORROR_HUD_SCRIPT.new()
	horror_hud.name = "HorrorHud"
	add_child(horror_hud)
	held_ctrl.held_item_changed.connect(horror_hud.on_held_item_changed)

	held_ctrl.setup(combat, camera)
	horror_hud.on_held_item_changed(0, held_ctrl.get_current_item())

	inventory = INVENTORY_SCRIPT.new()
	inventory.name = "HorrorInventoryMenu"
	add_child(inventory)

	inventory.item_equipped.connect(_on_item_equipped)
	inventory.item_used.connect(_on_item_used)
	inventory.inventory_toggled.connect(_on_inventory_toggled)

	if health_ref:
		health_ref.health_changed.connect(func(cur, _m):
			if horror_hud: horror_hud.on_health_changed(cur)
			if inventory: inventory.update_health(cur)
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_TAB, KEY_I]:
			if inventory: inventory.toggle()
			get_viewport().set_input_as_handled()
			return

	if inventory and inventory.is_open:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			inventory.close()
			get_viewport().set_input_as_handled()
		return

	if held_ctrl:
		if held_ctrl.handle_input(event):
			get_viewport().set_input_as_handled()

func _on_item_equipped(item_id: String, _slot_idx: int) -> void:
	match item_id:
		"blaster": held_ctrl.select_slot(0)
		"grenade": held_ctrl.select_slot(1)
		"dosimeter": held_ctrl.select_slot(2)
		"torch": held_ctrl.select_slot(3)

func _on_item_used(item_id: String, _slot_idx: int) -> void:
	if item_id == "med_injector" and health_ref:
		health_ref.heal(45.0)

func _on_inventory_toggled(is_open: bool) -> void:
	if player_ref and "input_ctrl" in player_ref and player_ref.input_ctrl:
		player_ref.input_ctrl.mouse_captured = not is_open
