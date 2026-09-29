class_name Terminal
extends StaticBody3D

@export var terminal_title: String = "TERMINAL #09 // BIO-KINETIC LABS"
@export_multiline var log_content: String = (
	"LOG ENTRY: 04-B\n" +
	"----------------------------------------\n" +
	"SUBJECT STATUS: ACCELERATED.\n\n" +
	"The kinetic dampeners have failed. Momentum accumulation is unbounded.\n" +
	"Whatever you do, do NOT stop moving.\n" +
	"The sector purge protocol triggers if velocity drops below critical thresholds.\n\n" +
	"OBJECTIVE: Breach Sector 4.\n" +
	"Use high-speed sliding and air-strafing to bypass the security chasms."
)

var dialogue_layer: CanvasLayer
var dialogue_panel: PanelContainer
var text_label: RichTextLabel
var title_label: Label
var is_open: bool = false

func _ready():
	_setup_dialogue_ui()

func get_interaction_prompt() -> String:
	return "READ TERMINAL"

func get_interaction_detail() -> String:
	return terminal_title

func interact(_player: Node) -> void:
	is_open = !is_open
	dialogue_layer.visible = is_open
	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if is_open and (event.is_action_pressed("interact") or event.is_action_pressed("toggle_mouse")):
		interact(null)
		get_viewport().set_input_as_handled()

func _setup_dialogue_ui() -> void:
	dialogue_layer = CanvasLayer.new()
	dialogue_layer.visible = false
	add_child(dialogue_layer)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.set_anchors_preset(Control.PRESET_CENTER)
	dialogue_panel.custom_minimum_size = Vector2(600, 350)
	dialogue_panel.position = Vector2(340, 185)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.05, 0.95)
	style.border_color = Color(0.1, 0.9, 0.4)
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	dialogue_panel.add_theme_stylebox_override("panel", style)
	dialogue_layer.add_child(dialogue_panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	dialogue_panel.add_child(vbox)

	title_label = Label.new()
	title_label.text = terminal_title
	title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	vbox.add_child(title_label)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.text = log_content
	text_label.custom_minimum_size = Vector2(550, 220)
	text_label.add_theme_color_override("default_color", Color(0.8, 0.95, 0.85))
	vbox.add_child(text_label)

	var hint = Label.new()
	hint.text = "[Press E or ESC to close]"
	hint.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
	vbox.add_child(hint)
