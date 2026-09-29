extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the walker's thoughts in the apartment (AptThoughts). Builds the flat in
## squalor beside the forest and checks: the wake thought comes after WAKE_DELAY; a check's thought comes the first time it
## is made and not the second (LevelFlow.first_time, or the visit's count without it); trying the front door thinks every
## time; every thought belongs to a real use.

const APT := preload("res://scenes/levels/apartment.tscn")
const Uses = preload("res://scripts/apartment/apt_uses.gd")


func run(scene: Node, tree: SceneTree) -> void:
	scene.set_meta("thoughts_check", self)
	tree.set_meta("capture_hold", true)
	var apt := APT.instantiate() as ApartmentLevel
	apt.flat = &"squalor"
	apt.position = Vector3(0, -300, 0)
	scene.add_child(apt)
	await tree.create_timer(0.5).timeout
	var line: String = AptThoughts.WAKE[&"squalor"]
	_check("no wake thought before the room fades up", not _said(line))
	await tree.create_timer(AptThoughts.WAKE_DELAY).timeout
	_check("waking to squalor: \"%s\"" % line, _said(line))
	_clear()
	apt._on_use(&"stove", 1)
	_check("first stove check thinks", _said(AptThoughts.FIRST_CHECK[&"stove"]))
	_clear()
	apt._on_use(&"stove", 2)
	_check("second stove check is quiet", not _said(AptThoughts.FIRST_CHECK[&"stove"]))
	apt._on_use(&"leave", 1)
	apt._on_use(&"leave", 2)
	_check("the front door thinks every time", _count(AptThoughts.ALWAYS[&"leave"]) == 2)
	var real := true
	for id in AptThoughts.FIRST_CHECK:
		real = real and not Uses.spec(id).is_empty()
	_check("every check thought belongs to a use", real)
	var flow := tree.root.get_node_or_null(^"LevelFlow")
	if flow:
		_check("LevelFlow.first_time: once, then never", flow.first_time(&"test_once") and not flow.first_time(&"test_once"))
	apt.queue_free()
	tree.set_meta("capture_hold", false)


func _box() -> DialogBox:
	return FieldHud.current.dialog if FieldHud.current and is_instance_valid(FieldHud.current) else null


func _said(text: String) -> bool:
	return _count(text) > 0


func _count(text: String) -> int:
	var box := _box()
	if box == null:
		return 0
	var n := 1 if box._body.text == text and box.phase != DialogBox.Phase.IDLE else 0
	for entry in box._queue:
		n += 1 if entry[0] == text else 0
	return n


func _clear() -> void:
	if _box():
		_box().clear()


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
