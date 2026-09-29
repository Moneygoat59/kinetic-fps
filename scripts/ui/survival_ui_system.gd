class_name SurvivalUiSystem
extends Node
## Player-side UI: the held-item controller (Q / E / 1-4 / mouse wheel) and the barebones FieldHud (crosshair, the one
## interaction prompt, the dialog box, a quiet item tab, stress edges). The old item dock and the Tab inventory screen are
## gone (art bible: no screen UI unless it earns its place).

const HELD_CTRL_SCRIPT = preload("res://scripts/ui/held_item_controller.gd")

var held_ctrl: Node
var hud: FieldHud
var player_ref: CharacterBody3D
var health_ref: RefCounted


static func attach(player: CharacterBody3D, combat: RefCounted, camera: Camera3D, health: RefCounted) -> Node:
	var sys := (load("res://scripts/ui/survival_ui_system.gd") as GDScript).new() as Node
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
	hud = FieldHud.new()
	hud.name = "FieldHud"
	add_child(hud)
	held_ctrl.held_item_changed.connect(func(idx: int, item: Dictionary): hud.show_item(item.get("name", ""), idx))
	held_ctrl.setup(combat, camera)
	if health_ref:
		health_ref.health_changed.connect(hud.set_health)


func _unhandled_input(event: InputEvent) -> void:
	if held_ctrl and held_ctrl.handle_input(event):
		get_viewport().set_input_as_handled()
