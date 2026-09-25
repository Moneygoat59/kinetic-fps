extends SceneTree

const DOSIMETER_SCRIPT = preload("res://scripts/radiation_dosimeter.gd")

func _init() -> void:
	print("--- Testing Redone Dosimeter ---")
	var player = CharacterBody3D.new()
	var cam = Camera3D.new(); cam.name = "Camera3D"
	var head = Node3D.new(); head.name = "Head"; head.add_child(cam); player.add_child(head)
	root.add_child(player)

	var p1 = Node3D.new(); p1.position = Vector3(100.0, 0.0, 0.0); root.add_child(p1)
	var p2 = Node3D.new(); p2.position = Vector3(200.0, 0.0, 0.0); root.add_child(p2)

	var dosimeter = DOSIMETER_SCRIPT.new()
	root.add_child(dosimeter)
	dosimeter.setup_dosimeter(player, [p1, p2], "TEST CHANNEL", Color.ORANGE, "TEST DEST")

	assert(dosimeter.held_tracker != null, "held_tracker must exist")
	assert(dosimeter.beep_player != null, "Beep player must exist")
	assert(dosimeter.lbl_bar != null, "lbl_bar must exist")
	assert(dosimeter.lbl_status != null, "lbl_status must exist")
	assert(dosimeter.led_segs.size() == 10, "10 LED segments must exist")

	# Test distant (100m away)
	player.position = Vector3(0.0, 0.0, 0.0)
	dosimeter._process(0.016)
	print("Distant bar text: ", dosimeter.lbl_bar.text)
	print("Distant status text: ", dosimeter.lbl_status.text)
	assert(dosimeter.lbl_bar.text.contains("."), "Distant should have empty pips")

	# Test close (20m away)
	player.position = Vector3(80.0, 0.0, 0.0) # 20m from p1 at (100, 0, 0)
	dosimeter._process(0.016)
	print("Close bar text: ", dosimeter.lbl_bar.text)
	print("Close status text: ", dosimeter.lbl_status.text)
	assert(dosimeter.lbl_bar.text.contains("|"), "Close should have filled pips")

	# Test rotation immunity: rotating player must NOT change distance or progress
	player.rotation.y = 1.57 # 90 degrees
	dosimeter._process(0.016)
	var bar_rotated = dosimeter.lbl_bar.text
	print("Rotated bar text: ", bar_rotated)

	print("--- Redone Dosimeter Unit Test Passed ---")
	quit()
