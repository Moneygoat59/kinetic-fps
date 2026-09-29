class_name SkyZone
extends Node
## An underground place (the silo's generator hall): while the player is inside, the level's sun / moon (every visible
## DirectionalLight3D in the tree) is hidden, and leaving shows them again. The forest's moon only shadows 45 m out, so
## without this it leaks through the ground onto the hall's stair and every upward face further away.
## Owner calls update(inside) each frame with its own test of where the player is (like MusicZone / ViewZone take a
## distance); the scene is searched once per entry, not per frame.

enum State { OUTSIDE, INSIDE }

var state := State.OUTSIDE
var _hidden: Array[DirectionalLight3D] = []


static func make() -> SkyZone:
	var z := SkyZone.new()
	z.name = "SkyZone"
	return z


func update(inside: bool) -> void:
	if state == State.OUTSIDE and inside:
		_enter()
	elif state == State.INSIDE and not inside:
		_exit()


func _enter() -> void:
	if not is_inside_tree():
		return
	state = State.INSIDE
	for light in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		if light.visible:
			light.visible = false
			_hidden.append(light)


func _exit() -> void:
	state = State.OUTSIDE
	for light in _hidden:
		if is_instance_valid(light):
			light.visible = true
	_hidden.clear()


func _exit_tree() -> void:
	if state == State.INSIDE:
		_exit()
