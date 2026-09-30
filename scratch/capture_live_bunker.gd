extends SceneTree

var frame = 0
var level: Node3D
var dev: Node
var cam: Camera3D

func _init() -> void:
	root.size = Vector2i(1280, 720)
	var scn = load("res://scenes/levels/dead_forest.tscn")
	level = scn.instantiate()
	root.add_child(level)
	dev = root.get_node_or_null("DevTools")
	if not dev:
		var dev_cls = load("res://scripts/dev/dev_tools.gd")
		dev = dev_cls.new(); dev.name = "DevTools"; root.add_child(dev)
	
	cam = Camera3D.new()
	cam.current = true
	root.add_child(cam)

func _process(delta: float) -> bool:
	frame += 1
	var event = level.find_child("DeadForestEvent", true, false)
	var bunker = event.bunker_instance if event else null
	
	if frame == 2:
		print("Teleporting to Bunker 1 & Disabling Fog...")
		dev.teleport_to_poi(1)
		dev.toggle_fog()
	
	elif frame == 5:
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# Angle 1: 3/4 Exterior Perspective (Front & Flank Buttresses)
			var eye = b_pos + b_basis.z * 11.5 + b_basis.x * 9.5 + Vector3(0.0, 5.0, 0.0)
			var target = b_pos + Vector3(0.0, 1.8, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 1 (Exterior 3/4 Perspective)")
	
	elif frame == 8:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/live_bunker_front.png")
		print("Saved live_bunker_front.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# Angle 2: Close-up Entryway Detail
			var eye = b_pos + b_basis.z * 6.5 + b_basis.x * 1.2 + Vector3(0.0, 1.6, 0.0)
			var target = b_pos + b_basis.z * 4.2 + Vector3(0.0, 1.8, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 2 (Entryway Detail)")
	
	elif frame == 12:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/live_bunker_entry.png")
		print("Saved live_bunker_entry.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# Angle 3: Interior Workstation View
			var eye = b_pos + b_basis.z * 1.2 + b_basis.x * 0.6 + Vector3(0.0, 1.6, 0.0)
			var target = b_pos - b_basis.z * 2.8 + Vector3(0.0, 1.4, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 3 (Interior Workstation View)")
	
	elif frame == 16:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/live_bunker_inside.png")
		print("Saved live_bunker_inside.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# Angle 4: Flank Buttress Elevation View
			var eye = b_pos - b_basis.x * 11.0 + b_basis.z * 1.0 + Vector3(0.0, 3.5, 0.0)
			var target = b_pos + Vector3(0.0, 1.8, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 4 (Flank Buttress View)")
	
	elif frame == 20:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/live_bunker_side.png")
		print("Saved live_bunker_side.png")
		print("ALL LIVE BUNKER CAPTURES SAVED SUCCESSFULLY!")
		quit()
		return true
	return false
