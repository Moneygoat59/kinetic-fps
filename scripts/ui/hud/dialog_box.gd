class_name DialogBox
extends Control
## Bottom-centre text box for the walker's own thoughts and for other voices (NPCs, radio, recordings). Lines queue and show
## one at a time: type in, hold long enough to read, fade. Same plate as the interaction prompt. Thoughts (no speaker) are
## handwritten; other voices get an amber speaker tag and typewriter type (art bible: human thought handwritten, voices typed).
## Usually reached through FieldHud.speak(text, speaker).

enum Phase { IDLE, TYPING, HOLDING, FADING }

const WIDTH := 360.0                        # UI units: the project lays UI out at 640 x 360 and scales it up
const BOTTOM := 20.0                        # above the screen's bottom edge
const TYPE_RATE := 34.0                     # characters per second
const READ_RATE := 15.0                     # characters per second the hold allows for reading
const MIN_HOLD := 2.2
const FADE := 0.7
const MAX_QUEUE := 6
const INK := Color(0.87, 0.83, 0.75)
const MAX_DELTA := 0.1

var phase: Phase = Phase.IDLE
var _plate: PanelContainer
var _speaker: Label
var _body: Label
var _thought_font: Font
var _voice_font: Font
var _queue: Array[PackedStringArray] = []   # [text, speaker]
var _t := 0.0
var _hold := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_thought_font = FontLibrary.get_font("Caveat-Regular.ttf")
	_voice_font = FontLibrary.dream_font()
	_plate = PanelContainer.new()
	_plate.add_theme_stylebox_override("panel", InteractPrompt.plate(Color(0.03, 0.024, 0.02, 0.78), Color(InteractPrompt.AMBER, 0.4), 10, 5))
	_plate.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_plate.offset_left = -WIDTH / 2.0
	_plate.offset_right = WIDTH / 2.0
	_plate.offset_top = -BOTTOM
	_plate.offset_bottom = -BOTTOM
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_plate)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 1)
	_plate.add_child(lines)
	_speaker = Label.new()
	_speaker.add_theme_font_override("font", FontLibrary.tech_font())
	_speaker.add_theme_font_size_override("font_size", 7)
	_speaker.add_theme_color_override("font_color", InteractPrompt.AMBER)
	lines.add_child(_speaker)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH - 20.0, 0.0)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_color_override("font_color", INK)
	lines.add_child(_body)
	_plate.visible = false


## Queue a line. speaker "" = the walker's own thought.
func say(text: String, speaker: String = "") -> void:
	if text.is_empty() or _queue.size() >= MAX_QUEUE:
		return
	_queue.append(PackedStringArray([text, speaker]))
	if phase == Phase.IDLE:
		_next()


func clear() -> void:
	_queue.clear()
	phase = Phase.IDLE
	_plate.visible = false


func _next() -> void:
	if _queue.is_empty():
		phase = Phase.IDLE
		_plate.visible = false
		return
	var line: PackedStringArray = _queue.pop_front()
	var thought := line[1].is_empty()
	_speaker.text = line[1].to_upper()
	_speaker.visible = not thought
	_body.add_theme_font_override("font", _thought_font if thought else _voice_font)
	_body.add_theme_font_size_override("font_size", 15 if thought else 10)
	_body.text = line[0]
	_body.visible_characters = 0
	_hold = maxf(MIN_HOLD, float(line[0].length()) / READ_RATE)
	_t = 0.0
	phase = Phase.TYPING
	_plate.modulate.a = 1.0
	_plate.visible = true


func _process(delta: float) -> void:
	if phase == Phase.IDLE:
		return
	_t += clampf(delta, 0.0, MAX_DELTA)
	match phase:
		Phase.TYPING:
			_body.visible_characters = int(_t * TYPE_RATE)
			if _body.visible_characters >= _body.text.length():
				_body.visible_characters = -1
				phase = Phase.HOLDING
				_t = 0.0
		Phase.HOLDING:
			if _t >= _hold:
				phase = Phase.FADING
				_t = 0.0
		Phase.FADING:
			_plate.modulate.a = 1.0 - _t / FADE
			if _t >= FADE:
				_next()
