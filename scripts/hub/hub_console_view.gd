class_name HubConsoleView
extends RefCounted
## Presenter of the router console (kit terminal_router): a live routing table on its screen (PixelScreen over the
## kit_scr_route surface) and its four route keys (kit_glow_route_1..4) lit in each route's channel colour. Under the table,
## the silo gate: the security keys of routes 02 (blue) and 03 (green) that the silo path needs, blinking MISSING until held.
## HubConsole decides what to show; this only draws. Text changes happen on events, never per frame.

const SCREEN_MAT := "kit_scr_route"
const KEY_MAT := "kit_glow_route_%d"
const PX := Vector2i(320, 176)
const AMBER := Color(1.0, 0.62, 0.16)
const DIM := Color(0.42, 0.26, 0.08)
const BG := Color(0.016, 0.012, 0.004)
const ROW_Y := 25
const ROW_H := 14
const GATE_Y := 84
const GATE_KEYS_Y := 99
const LOG_Y := 116
const LINE_H := 15
const CURSOR_X := 22
const KEY_DARK := 0.012
const KEY_LIT := 1.4
const KEY_BLINK_HZ := 1.4
const SECURITY_ROUTES: Array[int] = [HubRoutes.Route.W02, HubRoutes.Route.W03]
const SECURITY_NAMES: Array[String] = ["BLUE", "GREEN"]
const GATE_LOCKED := "ALL SECURITY KEYS REQUIRED FOR SILO PATH ACCESS"
const GATE_OPEN := "SECURITY KEYS ACCEPTED // SILO PATH ACCESS"

var screen: PixelScreen
var _status: Array[Label] = []
var _log: Label
var _cursor: ColorRect
var _keys: Array[BaseMaterial3D] = []
var _key_on := [false, false, false, false]
var _blink_route := -1
var _gate: Label
var _key_hole: Array[ColorRect] = []
var _key_state: Array[Label] = []
var _key_held := [false, false]


func build(prop: Node3D, host: Node) -> void:
	screen = PixelScreen.make(PX)
	host.add_child(screen)
	screen.attach(prop.get_node_or_null("screens") as MeshInstance3D, SCREEN_MAT)
	screen.label(Vector2(6, 2), 18, AMBER).text = "RELAY HUB 00 // ROUTER"
	screen.block(Rect2(6, 22, 308, 1), DIM)
	for r in HubRoutes.KEYS.size():
		var y: int = ROW_Y + r * ROW_H
		screen.block(Rect2(8, y + 4, 6, 9), HubRoutes.COLORS[r])
		screen.label(Vector2(20, y), 16, AMBER).text = "R-%s  %s" % [HubRoutes.KEYS[r], HubRoutes.NAMES[r]]
		_status.append(screen.label(Vector2(214, y), 16, DIM))
	screen.block(Rect2(6, GATE_Y - 2, 308, 1), DIM)
	_build_gate()
	screen.block(Rect2(6, LOG_Y - 2, 308, 1), DIM)
	_log = screen.label(Vector2(6, LOG_Y), 16, AMBER)
	_log.add_theme_constant_override("line_spacing", LINE_H - int(FontLibrary.terminal_font().get_height(16)))   # lines on LINE_H
	_cursor = screen.block(Rect2(CURSOR_X, LOG_Y, 7, 12), AMBER)
	for i in HubRoutes.KEYS.size():
		_keys.append(O73Kit.own_material(prop, KEY_MAT % (i + 1)))
		set_key(i, false)


## The silo gate: headline plus one chip per security key (hollow square = missing, filled = held).
func _build_gate() -> void:
	_gate = screen.label(Vector2(6, GATE_Y), 14, AMBER)
	for i in SECURITY_ROUTES.size():
		var r := SECURITY_ROUTES[i]
		var x := 8 + i * 156
		screen.block(Rect2(x, GATE_KEYS_Y + 3, 10, 10), HubRoutes.COLORS[r])
		_key_hole.append(screen.block(Rect2(x + 2, GATE_KEYS_Y + 5, 6, 6), BG))
		screen.label(Vector2(x + 16, GATE_KEYS_Y), 14, HubRoutes.COLORS[r]).text = "%s KEY %s" % [SECURITY_NAMES[i], HubRoutes.KEYS[r]]
		_key_state.append(screen.label(Vector2(x + 92, GATE_KEYS_Y), 14, HubRoutes.COLORS[r]))
		set_security_key(i, false)


## Security key i (0 = blue / route 02, 1 = green / route 03) held or still missing.
func set_security_key(i: int, held: bool) -> void:
	if i < 0 or i >= _key_state.size():
		return
	_key_held[i] = held
	_key_hole[i].visible = not held
	_key_state[i].text = "INSERTED" if held else "MISSING"
	_key_state[i].visible = true
	_gate.text = GATE_OPEN if not _key_held.has(false) else GATE_LOCKED


## Render the screen only while someone could see it.
func set_live(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if screen and screen.render_target_update_mode != mode:
		screen.render_target_update_mode = mode


## One routing-table row: status text, lit in the route colour or dim.
func set_row(r: int, status: String, lit: bool) -> void:
	if r < 0 or r >= _status.size():
		return
	_status[r].text = status
	_status[r].add_theme_color_override("font_color", HubRoutes.COLORS[r] if lit else DIM)


## The log under the table. typed = start hidden and reveal with type_to(); the cursor sits on the last line.
func set_log(text: String, typed: bool) -> void:
	_log.text = text
	_log.visible_characters = 0 if typed else -1
	_cursor.position.y = LOG_Y + (text.count("\n")) * LINE_H + 2


## Reveal the typed log up to `fraction` (0..1).
func type_to(fraction: float) -> void:
	_log.visible_characters = int(_log.get_total_character_count() * clampf(fraction, 0.0, 1.0))


func set_key(r: int, on: bool) -> void:
	if r < 0 or r >= _keys.size():
		return
	_key_on[r] = on
	if _keys[r]:
		_keys[r].emission = HubRoutes.COLORS[r]
		_keys[r].emission_energy_multiplier = KEY_LIT if on else KEY_DARK


## The key of the route waiting to be programmed pulses (-1 = none).
func set_blink(r: int) -> void:
	if _blink_route >= 0:
		set_key(_blink_route, _key_on[_blink_route])
	_blink_route = r


## Per frame: cursor blink and the waiting key's pulse. t in seconds.
func blink(t: float) -> void:
	var on := fmod(t * 1.8, 1.0) < 0.55
	_cursor.visible = on
	for i in _key_state.size():
		_key_state[i].visible = on or _key_held[i]
	if _blink_route >= 0 and _keys[_blink_route]:
		_keys[_blink_route].emission_energy_multiplier = lerpf(KEY_DARK, KEY_LIT, (sin(t * TAU * KEY_BLINK_HZ) + 1.0) * 0.5)
