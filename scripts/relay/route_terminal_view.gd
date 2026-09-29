class_name RouteTerminalView
extends RefCounted
## Presenter of a RouteTerminal: its route on the terminal_wall screen (PixelScreen over the kit_scr_seal surface, which
## otherwise cycles the keypad's seal frames). Site, route key in the channel colour, destination, and a status line with a
## write-progress bar. RouteTerminal decides; this only draws. Text changes on events, never per frame.

const SCREEN_MAT := "kit_scr_seal"
const PX := Vector2i(160, 120)
const AMBER := Color(1.0, 0.62, 0.16)
const DIM := Color(0.42, 0.26, 0.08)
const STATUS_Y := 78
const BAR := Rect2(8, 100, 144, 8)
const STATUS: Array[String] = ["NO RECEIVER", "STANDBY", "WRITING", "ROUTE SET"]   # per RouteTerminal.State

var screen: PixelScreen
var _status: Label
var _bar: ColorRect
var _cursor: ColorRect
var _color := AMBER


func build(prop: Node3D, host: Node, route: int) -> void:
	_color = HubRoutes.COLORS[route]
	screen = PixelScreen.make(PX)
	host.add_child(screen)
	screen.label(Vector2(6, 2), 16, AMBER).text = HubRoutes.NAMES[route]
	screen.block(Rect2(6, 22, 148, 1), DIM)
	screen.block(Rect2(8, 30, 8, 12), _color)
	screen.label(Vector2(22, 26), 16, _color).text = "ROUTE R-%s" % HubRoutes.KEYS[route]
	screen.label(Vector2(8, 46), 16, AMBER).text = "> CENTRAL HUB"
	screen.block(Rect2(6, 70, 148, 1), DIM)
	_status = screen.label(Vector2(8, STATUS_Y), 16, AMBER)
	screen.block(BAR, Color(DIM, 0.5))
	_bar = screen.block(Rect2(BAR.position, Vector2(0, BAR.size.y)), _color)
	_cursor = screen.block(Rect2(0, STATUS_Y + 4, 6, 11), AMBER)
	_attach.call_deferred(prop)      # after KitProp claims its screen material, so this override is the one shown


func _attach(prop: Node3D) -> void:
	if is_instance_valid(prop) and is_instance_valid(screen):
		screen.attach(prop.get_node_or_null("screens") as MeshInstance3D, SCREEN_MAT)


## Render the screen only while someone could see it.
func set_live(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if screen and screen.render_target_update_mode != mode:
		screen.render_target_update_mode = mode


func show_state(state: int) -> void:
	if _status == null or state < 0 or state >= STATUS.size():
		return
	_status.text = STATUS[state]
	_status.add_theme_color_override("font_color", _color if state == RouteTerminal.State.SET else AMBER)
	_cursor.position.x = 8 + STATUS[state].length() * 8 + 3
	show_progress(1.0 if state == RouteTerminal.State.SET else 0.0)


## Write progress 0..1 on the bar.
func show_progress(fraction: float) -> void:
	if _bar:
		_bar.size.x = BAR.size.x * clampf(fraction, 0.0, 1.0)


## Per frame while live: the cursor blinks. t in seconds.
func blink(t: float) -> void:
	if _cursor:
		_cursor.visible = fmod(t * 1.8, 1.0) < 0.55
