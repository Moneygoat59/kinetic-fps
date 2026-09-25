class_name GalleryUI
extends CanvasLayer

signal teleport_requested(aisle_index: int)

var top_label: Label
var bottom_label: Label
var inspect_label: Label
var aisle_list_container: VBoxContainer
var current_speed: float = 18.0
var aisles_data: Array[Dictionary] = []

func setup(aisles: Array[Dictionary]) -> void:
	aisles_data = aisles
	layer = 100

	# Top Header
	top_label = Label.new()
	top_label.position = Vector2(24, 16)
	top_label.modulate = Color(1.0, 0.85, 0.35)
	top_label.text = "=== DEVELOPER MODEL GALLERY (821 MODELS) ==="
	add_child(top_label)

	# Bottom Controls Bar
	bottom_label = Label.new()
	bottom_label.position = Vector2(24, 670)
	bottom_label.modulate = Color(0.85, 0.90, 0.95)
	_update_bottom_text()
	add_child(bottom_label)

	# Center Crosshair
	var crosshair = Label.new()
	crosshair.text = "+"
	crosshair.position = Vector2(572, 316)
	crosshair.modulate = Color(1.0, 1.0, 1.0, 0.5)
	add_child(crosshair)

	# Inspect Info Badge
	inspect_label = Label.new()
	inspect_label.position = Vector2(300, 625)
	inspect_label.modulate = Color(0.35, 1.0, 0.75)
	inspect_label.text = ""
	add_child(inspect_label)

	# Left Sidebar Teleport Buttons
	_build_sidebar()

func _build_sidebar() -> void:
	aisle_list_container = VBoxContainer.new()
	aisle_list_container.position = Vector2(24, 48)
	aisle_list_container.custom_minimum_size = Vector2(240, 500)
	add_child(aisle_list_container)

	var hotkeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
	for i in range(aisles_data.size()):
		var data = aisles_data[i]
		var key_str = "[%s]" % hotkeys[i] if i < hotkeys.size() else "   "
		var btn = Button.new()
		btn.text = "%s %s (%d)" % [key_str, data["name"], data["count"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): emit_signal("teleport_requested", i))
		aisle_list_container.add_child(btn)

func on_speed_changed(speed: float) -> void:
	current_speed = speed
	_update_bottom_text()

func update_inspect(text: String) -> void:
	inspect_label.text = text

func _update_bottom_text() -> void:
	if not bottom_label: return
	bottom_label.text = "WASD: Fly | Space/Ctrl: Up/Down | Shift: Boost (3x) | Wheel: Speed [%.0f m/s] | Esc: Toggle Cursor | [1-9, 0, -, =]: Jump" % current_speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_map = {
			KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_5: 4, KEY_6: 5,
			KEY_7: 6, KEY_8: 7, KEY_9: 8, KEY_0: 9, KEY_MINUS: 10, KEY_EQUAL: 11
		}
		if key_map.has(event.keycode):
			var idx = key_map[event.keycode]
			if idx < aisles_data.size():
				emit_signal("teleport_requested", idx)
