class_name InteractPrompt
extends CanvasLayer
## The one interaction prompt: a dark plate with an amber hairline, a key cap and two lines of tech type, just under the
## crosshair. FieldHud owns it (InteractPrompt.host); every interactable offers its text each frame it is in reach and the
## strongest recent offer is shown, so all interactions share one place, one layout and one language:
##   title = VERB + OBJECT ("TAKE FIELD DOSIMETER", "READ NOTE")   sub = IDENTITY // STATE ("LOOSE PAGE  //  HANDWRITTEN")
##   InteractPrompt.offer(self, "READ NOTE", "LOOSE PAGE  //  HANDWRITTEN", strength_0_to_1)   (sub may be "": amber is just "DRINK")
## The key only ever appears in the key cap, never in the text.

const AMBER := Color(1.0, 0.72, 0.22)
const AMBER_DIM := Color(0.72, 0.52, 0.26)
const PLATE := Color(0.035, 0.028, 0.022, 0.82)
const KEY_FILL := Color(0.14, 0.09, 0.03, 0.95)
const OFFSET_Y := 34.0                      # UI units below the crosshair (640 x 360 layout, scaled up)
const OFFER_TTL_MS := 120                   # an offer shows this long after its last refresh

static var host: InteractPrompt

var _root: Control
var _key: Label
var _title: Label
var _sub: Label
var _owner: Object
var _strength := 0.0
var _offer_ms := -100000
var _raw_title := ""
var _raw_sub := ""


func _init(key_text: String = "E", layer_index: int = 13) -> void:
	layer = layer_index
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", _box(PLATE, Color(AMBER, 0.55), 6, 3))
	plate.set_anchors_preset(Control.PRESET_CENTER)
	plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	plate.grow_vertical = Control.GROW_DIRECTION_BOTH
	plate.offset_top = OFFSET_Y
	plate.offset_bottom = OFFSET_Y
	_root.add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	plate.add_child(row)
	var cap := PanelContainer.new()
	cap.add_theme_stylebox_override("panel", _box(KEY_FILL, AMBER, 4, 1))
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(cap)
	_key = _text(cap, key_text, 10, AMBER)
	var lines := VBoxContainer.new()
	lines.add_theme_constant_override("separation", 0)
	row.add_child(lines)
	_title = _text(lines, "", 10, AMBER)
	_sub = _text(lines, "", 7, AMBER_DIM)
	set_strength(0.0)


## Offer the prompt for this frame. Ignored when no HUD hosts it or when a stronger offer from something else is live.
static func offer(owner: Object, title: String, sub: String, strength: float) -> void:
	if host == null or not is_instance_valid(host) or strength <= 0.01:
		return
	host._take(owner, title, sub, clampf(strength, 0.0, 1.0))


func _take(owner: Object, title: String, sub: String, strength: float) -> void:
	var now := Time.get_ticks_msec()
	var live := now - _offer_ms < OFFER_TTL_MS / 2
	if owner != _owner and live and strength < _strength:
		return
	_owner = owner
	_strength = strength
	_offer_ms = now
	set_text(title, sub)


func _process(_delta: float) -> void:
	if host != self:
		return
	set_strength(_strength if Time.get_ticks_msec() - _offer_ms < OFFER_TTL_MS else 0.0)


func set_text(title: String, sub: String = "") -> void:
	if title == _raw_title and sub == _raw_sub:           # offered every frame: only re-set on a real change
		return
	_raw_title = title
	_raw_sub = sub
	_title.text = title.to_upper()
	_sub.text = sub.to_upper()
	_sub.visible = sub != ""


## 0 = hidden, 1 = fully shown (fade it in with distance).
func set_strength(strength: float) -> void:
	_root.modulate.a = clampf(strength, 0.0, 1.0)
	_root.visible = strength > 0.01


func _text(parent: Control, value: String, font_size: int, color: Color) -> Label:
	var line := Label.new()
	line.text = value
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_font_override("font", FontLibrary.tech_font())
	line.add_theme_font_size_override("font_size", font_size)
	line.add_theme_color_override("font_color", color)
	line.add_theme_color_override("font_outline_color", Color(0.1, 0.06, 0.02, 0.9))
	line.add_theme_constant_override("outline_size", 1)
	parent.add_child(line)
	return line


## The plate style shared by the prompt and the dialog box (soot fill, 1 px amber hairline).
static func plate(fill: Color = PLATE, border: Color = Color(AMBER, 0.55), pad_x: int = 10, pad_y: int = 6) -> StyleBoxFlat:
	return _box(fill, border, pad_x, pad_y)


static func _box(fill: Color, border: Color, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.content_margin_left = pad_x
	box.content_margin_right = pad_x
	box.content_margin_top = pad_y
	box.content_margin_bottom = pad_y
	return box
