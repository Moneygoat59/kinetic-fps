class_name TerminalInput
extends RefCounted
## The walker's input while logged on to a TerminalStation. E / Esc log off (they win over anything else that frame),
## Backspace goes back, other keys go to the screen's focus (arrows, Enter, Page Up / Down), F-keys pass through (dev
## tools, fullscreen). The OS cursor is hidden: the mouse is read as a camera ray onto the 3D screen (ScreenSurface), the
## hit becomes a pixel on the PixelScreen, the pointer is drawn there and the event is pushed into it, so the screen's
## buttons hover, click and scroll like any GUI.

var _station: TerminalStation


func setup(station: TerminalStation) -> void:
	_station = station


## Logged on: hide the cursor, park it mid-window and show the pointer where that lands on the screen.
func begin() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var window := _station.get_window()
	if window:
		Input.warp_mouse(Vector2(window.size) * 0.5)
	_point(_station.get_viewport().get_visible_rect().size * 0.5, null)


## Logged off: the pointer goes (PlayerFocus.release captures the mouse again).
func end() -> void:
	if _station and _station.desktop:
		_station.desktop.point_at(Vector2.ZERO, false)


## True when the event was the terminal's (the station marks it handled).
func handle(event: InputEvent) -> bool:
	if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN     # the window got focus back and captured it
	if event.is_action_pressed("interact") or event.is_action_pressed("toggle_mouse"):
		_station.log_off()
		return true
	var key := event as InputEventKey
	if key:
		if key.keycode >= KEY_F1 and key.keycode <= KEY_F12:
			return false
		if key.pressed and key.keycode == KEY_BACKSPACE:
			_station.desktop.back()
			return true
		_station.pixels.push_input(key, true)
		return true
	var mouse := event as InputEventMouse
	if mouse:
		_point(mouse.position, mouse)
		return true
	return false


## Maps a viewport position onto the screen; pushes `mouse` (a copy at that pixel) into it when it lands on the screen.
func _point(at: Vector2, mouse: InputEventMouse) -> void:
	var cam := _station.get_viewport().get_camera_3d()
	if cam == null or _station.screen == null:
		return
	var uv := _station.screen.ray_uv(cam.project_ray_origin(at), cam.project_ray_normal(at))
	var on := uv.x >= 0.0 and uv.y >= 0.0 and uv.x <= 1.0 and uv.y <= 1.0
	var px := uv * Vector2(_station.pixels.size)
	_station.desktop.point_at(px, on)
	if on and mouse:
		var ev := mouse.duplicate() as InputEventMouse
		ev.position = px
		ev.global_position = px
		_station.pixels.push_input(ev, true)
