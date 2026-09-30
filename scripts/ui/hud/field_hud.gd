class_name FieldHud
extends CanvasLayer
## The game HUD, kept barebones (art bible: diegetic first, amber on soot):
##   a dust crosshair dot, the one interaction prompt (InteractPrompt.host), the bottom-centre DialogBox for thoughts and
##   voices, a quiet held-item tab bottom-right, and hud_stress.gdshader (edges darken and colour drains when hurt/stressed;
##   no red flashes, no numbers).
## Anything can talk to the player: FieldHud.speak("The pump. I can hear the pump.") or FieldHud.speak(text, "KOVAC").
## Attached by SurvivalUiSystem; feed it set_health, set_stress (0..1), show_item.

const LAYER := 12                          # the prompt sits on 13, above the stress overlay
const STRESS_SHADER = preload("res://shaders/hud_stress.gdshader")
const DUST := Color(0.86, 0.8, 0.7)
const MARGIN := 12.0                       # UI units (640 x 360 layout, scaled up)
const ITEM_SHOW := 2.6                     # seconds fully visible after a switch
const ITEM_GHOST := 0.22
const MAX_DELTA := 0.1
const ITEM_SLOTS := 3                      # HeldItemController.held_items: grenade, dosimeter, torch

static var current: FieldHud

var dialog: DialogBox
var prompt: InteractPrompt
var _item: Label
var _cross: ColorRect
var _ticks: Array[ColorRect] = []
var _mat: ShaderMaterial
var _hp := 100.0
var _hp_max := 100.0
var _stress_in := 0.0
var _stress := 0.0
var _hurt := 0.0
var _item_t := 99.0


## The walker's thought (speaker "") or another voice. Safe to call when no HUD is up.
static func speak(text: String, speaker: String = "") -> void:
	if current and is_instance_valid(current):
		current.dialog.say(text, speaker)


## Crosshair on / off (PlayerFocus hides it while the walker uses something up close). Safe when no HUD is up.
static func show_crosshair(on: bool) -> void:
	if current and is_instance_valid(current) and current._cross:
		current._cross.visible = on


func _init() -> void:
	layer = LAYER
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = STRESS_SHADER
	overlay.material = _mat
	add_child(overlay)
	var cross := ColorRect.new()
	cross.color = Color(DUST, 0.55)
	cross.size = Vector2(2, 2)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position = Vector2(-1.0, -1.0)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cross)
	_cross = cross
	dialog = DialogBox.new()
	add_child(dialog)
	_item = Label.new()
	_item.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_item.position = Vector2(-MARGIN - 160.0, -MARGIN - 16.0)
	_item.size = Vector2(160, 12)
	_item.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item.add_theme_font_override("font", FontLibrary.tech_font())
	_item.add_theme_font_size_override("font_size", 8)
	_item.add_theme_color_override("font_color", InteractPrompt.AMBER)
	_item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	add_child(_item)
	for i in ITEM_SLOTS:
		var tick := ColorRect.new()
		tick.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tick.position = Vector2(-MARGIN - 23.0 + i * 6.0, -MARGIN - 2.0)
		tick.size = Vector2(4, 1)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tick)
		_ticks.append(tick)
	prompt = InteractPrompt.new()
	add_child(prompt)


func _enter_tree() -> void:
	current = self
	InteractPrompt.host = prompt


func _exit_tree() -> void:
	if current == self:
		current = null
	if InteractPrompt.host == prompt:
		InteractPrompt.host = null


func _ready() -> void:
	var vp := get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("aspect", vp.x / maxf(vp.y, 1.0))


func set_health(hp: float, hp_max: float) -> void:
	if hp < _hp - 0.01:
		_hurt = 1.0
	_hp = hp
	_hp_max = maxf(hp_max, 1.0)


func set_stress(value: float) -> void:
	_stress_in = clampf(value, 0.0, 1.0)


func show_item(item_name: String, idx: int) -> void:
	_item.text = item_name
	_item_t = 0.0
	for i in _ticks.size():
		_ticks[i].color = Color(InteractPrompt.AMBER, 0.9) if i == idx else Color(DUST, 0.3)


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var wounded := clampf(1.0 - _hp / _hp_max, 0.0, 1.0)
	var target := clampf(maxf(_stress_in, wounded * 0.75) + _hurt * 0.25, 0.0, 1.0)
	_stress = lerpf(_stress, target, 1.0 - exp(-dt * 1.5))
	_hurt = maxf(_hurt - dt * 1.2, 0.0)
	_mat.set_shader_parameter("stress", _stress)
	_mat.set_shader_parameter("hurt", _hurt)
	_item_t += dt
	var item_a := 1.0 if _item_t < ITEM_SHOW else lerpf(1.0, ITEM_GHOST, clampf((_item_t - ITEM_SHOW) / 1.2, 0.0, 1.0))
	_item.modulate.a = item_a
	for tick in _ticks:
		tick.modulate.a = item_a
