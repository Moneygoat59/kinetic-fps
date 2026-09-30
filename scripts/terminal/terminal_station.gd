class_name TerminalStation
extends Area3D
## A computer the walker can use: any kit piece with a screen surface (kit_scr_*) becomes one. Its TerminalDrive's folders
## and files are drawn live on that screen (TerminalDesktop in a PixelScreen). Aim at the screen, [E] USE TERMINAL: the
## view eases in until the screen fills it (PlayerFocus: frozen, crosshair and held item down), the mouse becomes a pixel
## pointer on the screen, click (or arrows + Enter) to open, Backspace to go back, E / Esc to log off and ease back out.
## FSM: IDLE, ZOOM_IN, USING, ZOOM_OUT. Emits used / left; the drive emits file_opened(path, first_time) for story.
## Three ways to put one on a piece:
##   TerminalStation.mount(piece, TerminalStation.load_drive(&"silo_data09"))       # from code
##   a kit marker suffix __drive_<id>: marker_kit_terminal_server__srv2__drive_silo_data09   (BunkerKit.furnish)
##   in the editor: add a TerminalStation node as a child of the piece and set `drive`

signal used(player: Player)
signal left(player: Player)

enum State { IDLE, ZOOM_IN, USING, ZOOM_OUT }

const DRIVE_DIR := "res://content/terminals/"
const REACH := 2.0                   # m from the camera to the screen centre: [E] works
const ZOOM_TIME := 0.7
const FOCUS_FOV := 50.0              # narrower than the walker's: less perspective on the screen
const MARGIN := 1.1                  # the screen fills the view with a tenth of the bezel round it
const SCREEN_H := 288                # pixels; the width follows the screen's aspect
const TITLE := "USE TERMINAL"
const CLICKS: Array[AudioStream] = [preload("res://audio/ui/Audio/click_001.ogg"), preload("res://audio/ui/Audio/click_002.ogg"),
	preload("res://audio/ui/Audio/click_003.ogg"), preload("res://audio/ui/Audio/click_004.ogg")]
const SND_ON = preload("res://audio/sci-fi/Audio/computerNoise_001.ogg")
const SND_OFF = preload("res://audio/rpg/Audio/metalClick.ogg")

@export var drive: TerminalDrive
@export var screen_material := ""    ## "" = the piece's first kit_scr_* surface

var state := State.IDLE
var screen: ScreenSurface
var desktop := TerminalDesktop.new()
var pixels: PixelScreen
var _focus: PlayerFocus
var _bridge := TerminalInput.new()


static func load_drive(id: String) -> TerminalDrive:
	var path := DRIVE_DIR + id + ".tres"
	var d := load(path) as TerminalDrive if ResourceLoader.exists(path) else null
	if d == null:
		push_warning("TerminalStation: no drive at " + path)
	return d


## Makes `piece` a terminal showing `d`. Returns the station (set up once the piece is in the tree), or null.
static func mount(piece: Node3D, d: TerminalDrive, material := "") -> TerminalStation:
	if piece == null or d == null:
		return null
	var station := TerminalStation.new()
	station.name = "TerminalStation"
	station.drive = d
	station.screen_material = material
	piece.add_child(station)
	return station


func _ready() -> void:
	set_process_input(false)
	screen = ScreenSurface.find(get_parent(), screen_material)
	if screen == null or drive == null:
		push_warning("TerminalStation: %s has no %s or no drive" % [get_parent().name, screen_material if screen_material else "kit_scr_* screen"])
		return
	monitoring = false
	var px := Vector2i(roundi(SCREEN_H * screen.size.x / maxf(screen.size.y, 0.01)), SCREEN_H)
	pixels = PixelScreen.make(px)
	add_child(pixels)
	pixels.canvas.add_child(desktop)
	desktop.setup(drive, Vector2(px))
	desktop.clicked.connect(_click)
	_bridge.setup(self)
	_add_shape()
	_attach.call_deferred()          # after KitProp claims its screen material, so this override is the one shown


func _attach() -> void:
	var before := screen.mesh.get_surface_override_material(screen.surface) as BaseMaterial3D
	pixels.attach(screen.mesh, screen.material_name)
	var own := screen.mesh.get_surface_override_material(screen.surface) as BaseMaterial3D
	if before and own:
		own.disable_fog = before.disable_fog   # keep the look the building gave the surface (SiloServers: glows through fog)


## A thin box over the screen for the walker's aim ray (an Area3D: never in the way).
func _add_shape() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(screen.size.x, screen.size.y, 0.04)
	shape.shape = box
	add_child(shape)
	var f := screen.frame()
	shape.global_transform = Transform3D(f.basis, f.origin + f.basis.z * 0.025)


func can_interact() -> bool:
	if state != State.IDLE or screen == null:
		return false
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(screen.frame().origin) < REACH


func get_interaction_prompt() -> String:
	return TITLE


func get_interaction_detail() -> String:
	return drive.title if drive else ""


func interact(p: Node) -> void:
	if not can_interact():
		return
	_focus = PlayerFocus.grab(p as Player)
	if _focus == null:
		return
	state = State.ZOOM_IN
	var aspect := get_viewport().get_visible_rect().size.aspect()
	_focus.ease_to(self, screen.view_from(FOCUS_FOV, aspect, MARGIN), FOCUS_FOV, ZOOM_TIME).finished.connect(_log_on)
	SoundManager.play(SND_ON, -10.0, 0.03)
	used.emit(_focus.player)


func _log_on() -> void:
	state = State.USING
	desktop.set_active(true)
	_bridge.begin()
	set_process_input(true)


## E / Esc (or code): log off and ease the view back out.
func log_off() -> void:
	if state != State.USING:
		return
	state = State.ZOOM_OUT
	set_process_input(false)
	_bridge.end()
	desktop.set_active(false)
	SoundManager.play(SND_OFF, -8.0, 0.05)
	_focus.ease_back(self, ZOOM_TIME).finished.connect(_logged_off)


func _logged_off() -> void:
	state = State.IDLE
	var who := _focus.player if _focus else null
	if _focus:
		_focus.release()
	_focus = null
	left.emit(who)


func _input(event: InputEvent) -> void:
	if state == State.USING and _bridge.handle(event):
		get_viewport().set_input_as_handled()


func _click() -> void:
	SoundManager.play(CLICKS[randi() % CLICKS.size()], -12.0, 0.1)


func _exit_tree() -> void:
	if _focus:                        # freed mid-use (a level change): never leave the walker frozen
		_bridge.end()
		_focus.release()
		_focus = null
