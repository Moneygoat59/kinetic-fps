class_name HubRouterKeys
extends Node
## The four route keys on the hub router's deck (kit terminal_router, keys kit_glow_route_1..4) as things to look at and
## press: the player's aim ray finds a key, the prompt names what it will do, [E] presses it. Per key one Mode, resolved
## from the network in refresh(): ROUTE (the route exists: program the dosimeter onto it), WRITE (the next route to write
## into the network: progress), LOCKED (no carrier yet: the console refuses and says why). Prompts are built in refresh,
## never per frame. Key geometry: tools/blender/kit/router.py (KEY_X, deck face).

enum Mode { ROUTE, WRITE, LOCKED }

const KEY_X: Array[float] = [-0.66, -0.36, -0.06, 0.24]   # router.py KEY_X (R-73, R-02, R-03, R-00)
## Hit box per key cap, local to the router (router.py: keys on the sloped deck at y 1.01, z 0.118). The router's
## collision leaves the deck open (body below it, block behind the screen), so the aim ray reaches the caps.
const HIT_SIZE := Vector3(0.2, 0.12, 0.2)
const HIT_CENTER := Vector3(0.0, 1.03, 0.118)

var _areas: Array[KeyArea] = []
var _modes: Array[Mode] = [Mode.ROUTE, Mode.LOCKED, Mode.LOCKED, Mode.LOCKED]
var _console: HubConsole


class KeyArea extends Area3D:
	var route := 0
	var title := ""
	var sub := ""
	var enabled := true
	var keys: HubRouterKeys

	func can_interact() -> bool:
		return enabled

	func get_interaction_prompt() -> String:
		return title

	func get_interaction_detail() -> String:
		return sub

	func interact(_player: Node) -> void:
		if enabled:
			keys._press(route)


func setup(prop: Node3D, console: HubConsole) -> void:
	if prop == null or console == null:
		return
	_console = console
	console.programmed.connect(func(_r: int) -> void: set_enabled(true))
	console.routed.connect(func(_r: int) -> void: set_enabled(true))
	for r in KEY_X.size():
		var area := KeyArea.new()
		area.route = r
		area.keys = self
		area.monitoring = false
		area.position = HIT_CENTER + Vector3(KEY_X[r], 0.0, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = HIT_SIZE
		shape.shape = box
		area.add_child(shape)
		prop.add_child(area)
		_areas.append(area)


func mode_of(r: int) -> Mode:
	return _modes[r] if r >= 0 and r < _modes.size() else Mode.LOCKED


## Re-resolve every key from the network: route flows (HubRoutes.flow), hub stage, the route the dosimeter follows out.
func refresh(flow: Array, stage: int, on_route: int) -> void:
	for r in _modes.size():
		if r == HubRoutes.Route.W73 or flow[r] != HubRoutes.Flow.DRY:
			_modes[r] = Mode.ROUTE
		elif stage < 5 and stage % 2 == 0 and RelayHub.STAGE_ROUTE[stage] == r:
			_modes[r] = Mode.WRITE
		else:
			_modes[r] = Mode.LOCKED
		if r >= _areas.size():
			continue
		var key := HubRoutes.KEYS[r]
		match _modes[r]:
			Mode.ROUTE:
				_prompt(r, "PROGRAM ROUTE TO " + HubRoutes.NAMES[r], "R-%s  //  %s" % [key, "ROUTE SET" if r == on_route else "RELAYS ONLINE"])
			Mode.WRITE:
				_prompt(r, "PROGRAM RELAY ROUTE " + key, "ROUTER  //  R-%s CARRIER LOST" % key)
			Mode.LOCKED:
				_prompt(r, "R-%s  %s" % [key, HubRoutes.NAMES[r]], _locked_reason(r))


func _locked_reason(r: int) -> String:
	if r == HubRoutes.Route.SILO:
		return "SILO PATH LOCKED // KEYS MISSING"
	return "NO CARRIER // KEY %s MISSING" % HubRoutes.KEYS[maxi(r - 1, 0)]


func _prompt(r: int, title: String, sub: String) -> void:
	_areas[r].title = title
	_areas[r].sub = sub


func _press(r: int) -> void:
	if _console == null or _console.is_busy():
		return
	match mode_of(r):
		Mode.WRITE: _console.write(r)
		Mode.ROUTE: _console.program(r)
		Mode.LOCKED: _console.deny(r, _locked_reason(r))
	set_enabled(not _console.is_busy())


## While the console writes, the keys take no presses and show no prompt.
func set_enabled(on: bool) -> void:
	for area in _areas:
		area.enabled = on
