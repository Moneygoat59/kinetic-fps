extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the reusable terminal (TerminalStation) on the silo data room's
## console (drive res://content/terminals/silo_data09.tres). Stands the walker at the screen, checks their aim finds it,
## uses it, clicks a folder and a file with real mouse events aimed at the 3D screen (so the ray -> pixel mapping is what is
## tested), goes back with Backspace, logs off with E and checks the walker gets control back.
## TERMINAL_SHOT=1: afterwards logs on again and leaves a file open, for the capture (the zoomed-in view);
## TERMINAL_SHOT=list leaves a folder listing open instead.

const SPAWN := preload("res://tools/exec/spawn_silo.gd")
const TIMEOUT := 5.0
const STAND := 1.35         # m out from the screen: behind the chair, inside TerminalStation.REACH

var _tree: SceneTree
var _opened: Array = []


func run(scene: Node, tree: SceneTree) -> void:
	_tree = tree
	SPAWN.new().run(scene, tree)
	scene.set_meta("terminal_check", self)           # capture.gd drops its reference to this hook; stay alive while awaiting
	tree.set_meta("capture_hold", true)
	await _frames(3)
	var player: Player = scene.get_node("DeadForestEvent").player
	tree.set_meta("capture_camera", player.camera)  # the station maps the mouse through the current camera: the walker's
	player.camera.make_current()
	var found := scene.find_children("TerminalStation", "TerminalStation", true, false)
	_check("the data room console is a terminal", found.size() == 1)
	if found.is_empty():
		tree.set_meta("capture_hold", false)
		return
	var st := found[0] as TerminalStation
	_check("its screen shows the live desktop", st.screen != null and st.screen.mesh.get_surface_override_material(
		st.screen.surface).emission_texture is ViewportTexture)
	st.drive.file_opened.connect(func(path: String, first: bool) -> void: _opened.append([path, first]))
	_stand_at(scene, player, st)
	await _frames(4)
	_aim(player, st)                                 # again, from where the walker settled
	await _tree.physics_frame
	await _tree.physics_frame
	_check("the walker's aim finds the screen", player.aim_ray.get_collider() == st and st.can_interact())
	await _log_on(st, player)
	_check("logged on: walker frozen, cursor hidden", st.state == TerminalStation.State.USING
		and not player.is_physics_processing() and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN)
	await _click_row(st, "EXAMPLE_FOLDER")
	_check("clicking a folder opens it", st.desktop.path_of() == "DATA09:/EXAMPLE_FOLDER")
	await _click_row(st, "EXAMPLE_A.TXT")
	_check("clicking a file opens it", st.desktop.view == TerminalDesktop.View.READING
		and _opened == [["DATA09:/EXAMPLE_FOLDER/EXAMPLE_A.TXT", true]])
	await _key(KEY_BACKSPACE)
	_check("Backspace: back to the folder, the file marked read", st.desktop.view == TerminalDesktop.View.LISTING
		and _row(st, "EXAMPLE_A.TXT") != null and _row(st, "EXAMPLE_A.TXT").text.begins_with(TerminalListing.FILE_READ))
	await _key(KEY_BACKSPACE)
	_check("Backspace again: the drive's root", st.desktop.path_of() == "DATA09:/")
	await _key(KEY_E)
	await _until(func() -> bool: return st.state == TerminalStation.State.IDLE)
	_check("E logs off and hands control back", st.state == TerminalStation.State.IDLE and player.is_physics_processing()
		and player.camera.transform.is_equal_approx(Transform3D.IDENTITY) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	if OS.has_environment("TERMINAL_SHOT"):
		await _log_on(st, player)
		await _click_row(st, "EXAMPLE_FOLDER" if OS.get_environment("TERMINAL_SHOT") == "list" else "README.TXT")
		await _frames(10)
	tree.set_meta("capture_hold", false)


## The walker in front of the screen (behind the console's chair), looking at its centre. Ends the forest's wake-up
## (DevPlaces.stand), which would otherwise still hold the camera tipped down.
func _stand_at(scene: Node, player: Player, st: TerminalStation) -> void:
	var f := st.screen.frame()
	var out := Vector3(f.basis.z.x, 0.0, f.basis.z.z).normalized()
	var feet := f.origin + out * STAND
	feet.y = st.get_parent().global_position.y
	DevPlaces.stand(scene, feet, f.origin)
	player.camera.transform = Transform3D.IDENTITY
	_aim(player, st)


func _aim(player: Player, st: TerminalStation) -> void:
	var at := st.screen.frame().origin
	var eye := player.camera.global_position
	player.rotation.y = atan2(eye.x - at.x, eye.z - at.z)
	var pitch := atan2(at.y - eye.y, Vector2(at.x - eye.x, at.z - eye.z).length())
	player.head.rotation.x = pitch
	player.input_ctrl.head_pitch = pitch


func _log_on(st: TerminalStation, player: Player) -> void:
	st.interact(player)
	await _until(func() -> bool: return st.state == TerminalStation.State.USING)
	await _frames(2)


## A real mouse move + click at the window position where the named row's centre shows on the 3D screen.
func _click_row(st: TerminalStation, row_name: String) -> void:
	var row := _row(st, row_name)
	if row == null:
		print("CHECK FAIL no row %s" % row_name)
		return
	var uv := row.get_global_rect().get_center() / Vector2(st.pixels.size)
	var vp := st.get_viewport()
	var at := vp.get_final_transform() * vp.get_camera_3d().unproject_position(st.screen.point_at(uv))   # window pixels
	var move := InputEventMouseMotion.new()
	move.position = at
	Input.parse_input_event(move)
	await _frames(2)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = at
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		Input.parse_input_event(click)
		await _frames(2)


func _row(st: TerminalStation, row_name: String) -> Button:
	for b in st.desktop.listing.find_children("*", "Button", true, false):
		if (b as Button).visible and (b as Button).text.contains(" " + row_name):
			return b as Button
	return null


func _key(code: Key) -> void:
	for down in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = down
		Input.parse_input_event(ev)
		await _frames(2)


func _until(done: Callable) -> void:
	var start := Time.get_ticks_msec()
	while not done.call() and Time.get_ticks_msec() - start < TIMEOUT * 1000.0:
		await _tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
