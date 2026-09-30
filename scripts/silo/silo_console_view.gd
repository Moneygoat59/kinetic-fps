class_name SiloConsoleView
extends RefCounted
## Presenter of the level 09 launch desk: a live readout (PixelScreen over the model's silo_scr_launch surface) with the
## silo's status rows and a typed log. SiloConsole decides what to show; this only draws. Text changes happen on events.

const SCREEN_MAT := "silo_scr_launch"
const PX := Vector2i(320, 176)
const AMBER := Color(1.0, 0.62, 0.16)
const DIM := Color(0.42, 0.26, 0.08)
const ROWS: Array[Array] = [["VEHICLE", "AWAY"], ["CRADLE", "EMPTY"], ["ROUTE 00", "ONLINE"], ["ELAPSED", "T+ 73,051 D"]]
const ROW_Y := 28
const ROW_H := 16
const LOG_Y := 100
const LINE_H := 16

var screen: PixelScreen
var _log: Label
var _cursor: ColorRect


func build(screens: MeshInstance3D, host: Node) -> void:
	screen = PixelScreen.make(PX)
	host.add_child(screen)
	screen.attach(screens, SCREEN_MAT)
	screen.label(Vector2(6, 2), 18, AMBER).text = "SILO 00 // LAUNCH CONTROL"
	screen.block(Rect2(6, 24, 308, 1), DIM)
	for r in ROWS.size():
		var y := ROW_Y + r * ROW_H
		screen.label(Vector2(10, y), 16, DIM).text = String(ROWS[r][0])
		screen.label(Vector2(150, y), 16, AMBER).text = String(ROWS[r][1])
	screen.block(Rect2(6, LOG_Y - 4, 308, 1), DIM)
	_log = screen.label(Vector2(6, LOG_Y), 16, AMBER)
	_cursor = screen.block(Rect2(22, LOG_Y, 7, 12), AMBER)
	set_live(false)


## Render the screen only while someone could see it.
func set_live(on: bool) -> void:
	var mode := SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	if screen and screen.render_target_update_mode != mode:
		screen.render_target_update_mode = mode


## The log under the status rows. typed = start hidden and reveal with type_to(); the cursor sits after the last line.
func set_log(text: String, typed: bool) -> void:
	_log.text = text
	_log.visible_characters = 0 if typed else -1
	_cursor.position.y = LOG_Y + text.count("\n") * LINE_H + 2


## Reveal the typed log up to `fraction` (0..1).
func type_to(fraction: float) -> void:
	_log.visible_characters = int(_log.get_total_character_count() * clampf(fraction, 0.0, 1.0))


## Per frame: cursor blink. t in seconds.
func blink(t: float) -> void:
	_cursor.visible = fmod(t * 1.8, 1.0) < 0.55
