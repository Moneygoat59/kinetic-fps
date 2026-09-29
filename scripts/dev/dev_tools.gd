class_name DevManager
extends Node
## Autoload `DevTools`: the dev menu and its tools, in every level.
##   F1 (Esc closes)  menu: JUMP TO a point in the story (DevWarps; 1-9 while open), GO TO a place here (DevPlaces)
##   F2 fog off / on (4 km view)    F3 fly (DevFlycam; Shift+F3 cancels back)    F5-F9 the first five GO TO places
## The game pauses while the menu is open. A level change drops the flight and the fog override (they belonged to it).

const DevHudScript = preload("res://scripts/dev/dev_hud.gd")
const DevFlycamScript = preload("res://scripts/dev/dev_flycam.gd")

enum Menu { CLOSED, OPEN }

var hud: DevHud
var flycam: DevFlycam
var menu_state := Menu.CLOSED
var fog := DevFog.new()
var _mouse_before := Input.MOUSE_MODE_CAPTURED
var _paused_before := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	flycam = DevFlycamScript.new()
	add_child(flycam)
	get_tree().scene_changed.connect(_on_scene_changed)
	if DisplayServer.get_name() == "headless":
		return
	hud = DevHudScript.new()
	add_child(hud)
	hud.menu.warp_chosen.connect(warp)
	hud.menu.place_chosen.connect(go_to_place)
	hud.menu.fly_pressed.connect(toggle_flycam)
	hud.menu.fog_pressed.connect(toggle_fog)
	flycam.changed.connect(func(_on, _speed): _refresh())


func _input(event: InputEvent) -> void:
	if flycam.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: Key = event.keycode
	if key == KEY_F1 or (key == KEY_ESCAPE and menu_state == Menu.OPEN): toggle_menu()
	elif key == KEY_F2: toggle_fog()
	elif key == KEY_F3: toggle_flycam(event.shift_pressed)
	elif key >= KEY_F5 and key <= KEY_F9: go_to_place(key - KEY_F5)
	elif menu_state == Menu.OPEN and key >= KEY_1 and key <= KEY_9: warp(key - KEY_1)
	else: return
	get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	if hud == null:
		return
	if menu_state == Menu.CLOSED:
		menu_state = Menu.OPEN
		_mouse_before = Input.mouse_mode
		_paused_before = get_tree().paused
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var labels := DevPlaces.list(get_tree()).map(func(p): return p["label"])
		hud.menu.open(DevWarps.status(get_tree()), labels, flycam.state == DevFlycam.State.FLYING, fog.is_off())
	else:
		menu_state = Menu.CLOSED
		hud.menu.close()
		get_tree().paused = _paused_before
		Input.mouse_mode = _mouse_before


func warp(index: int) -> void:
	if menu_state == Menu.OPEN: toggle_menu()
	if flycam.state == DevFlycam.State.FLYING: flycam.stop(false)
	get_tree().paused = false
	if DevWarps.jump(get_tree(), index):
		_toast(DevWarps.label(index))


## index into DevPlaces.list() for this level. Moves the flight if flying, else stands the walker there.
func go_to_place(index: int) -> void:
	var places := DevPlaces.list(get_tree())
	if index < 0 or index >= places.size():
		_toast("No place %d here" % (index + 1))
		return
	if menu_state == Menu.OPEN: toggle_menu()
	if _teleport(places[index]["key"]): _toast(places[index]["label"])
	else: _toast("Could not reach " + places[index]["label"])


## The forest's buildings by number (1 Bunker 1 .. 5 Missile Silo), built on demand; tools/nights_soak.gd uses it.
func teleport_to_poi(id: int) -> void:
	_teleport(id)


func _teleport(key: Variant) -> bool:
	var spot := DevPlaces.resolve(get_tree(), key)
	var scene := get_tree().current_scene
	if spot.is_empty() or scene == null:
		return false
	var pos: Vector3 = spot["pos"]
	var look: Vector3 = spot["look"]
	if flycam.state != DevFlycam.State.FLYING:
		return DevPlaces.stand(scene, pos, look)
	var away := Vector3(pos.x - look.x, 0.0, pos.z - look.z).normalized()
	flycam.place(pos + DevFlycam.EYE if scene is ApartmentLevel else pos + away * 5.0 + Vector3.UP * 7.0, look)
	return true


func toggle_flycam(cancel: bool = false) -> void:
	if flycam.state == DevFlycam.State.FLYING:
		flycam.stop(not cancel)
		fog.fit(get_viewport().get_camera_3d())
		_toast("Landed" if not cancel else "Flight cancelled")
		return
	var scene := get_tree().current_scene
	var player := scene.find_child("Player", true, false) as CharacterBody3D if scene else null
	if not flycam.start(player):
		_toast("Nothing to fly here")
		return
	if menu_state == Menu.OPEN: toggle_menu()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func toggle_fog() -> void:
	if not fog.toggle(get_tree().current_scene, get_viewport().get_camera_3d()):
		_toast("No WorldEnvironment here")
		return
	_toast("Fog " + ("off (4 km view)" if fog.is_off() else "on"))


func _on_scene_changed() -> void:
	flycam.drop()
	fog = DevFog.new()
	if menu_state == Menu.OPEN: toggle_menu()
	_refresh()


func _refresh() -> void:
	if hud == null:
		return
	var flying := flycam.state == DevFlycam.State.FLYING
	hud.update_strip(flying, fog.is_off(), flycam.speed)
	hud.menu.set_tools(flying, fog.is_off())


func _toast(msg: String) -> void:
	_refresh()
	if hud: hud.show_toast(msg)
