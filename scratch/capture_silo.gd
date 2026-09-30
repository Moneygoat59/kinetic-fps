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
	var silo = event.silo_instance if event else null
	
	if frame == 2:
		print("Teleporting to Silo & Disabling Fog...")
		dev.teleport_to_poi(5)
		dev.toggle_fog()
	
	elif frame == 5:
		if silo:
			var s_pos = silo.global_position
			var s_basis = silo.global_transform.basis
			# Angle 1: On catwalk looking down at missile core & into pit
			var eye = s_pos + s_basis.z * 22.0 + Vector3(0.0, 3.5, 0.0)
			var target = s_pos + Vector3(0.0, -10.0, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 1 (Catwalk pit view)")
	
	elif frame == 8:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_catwalk.png")
		print("Saved silo_catwalk.png")
		if silo:
			var s_pos = silo.global_position
			var s_basis = silo.global_transform.basis
			# Angle 2: Steep angle looking directly into the 46m abyss at the blast shaft walls & engines
			var eye = s_pos + s_basis.z * 10.0 + Vector3(0.0, 1.0, 0.0)
			var target = s_pos + Vector3(0.0, -35.0, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 2 (Abyss depth view)")
	
	elif frame == 12:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_abyss.png")
		print("Saved silo_abyss.png")
		if silo:
			var s_pos = silo.global_position
			# Angle 3: Elevated 3/4 overview showing the cut hole, concrete apron, and Titan missile spire
			var eye = s_pos + Vector3(40.0, 35.0, 40.0)
			var target = s_pos + Vector3(0.0, -5.0, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set Angle 3 (Elevated overview)")
	
	elif frame == 16:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/silo_aerial.png")
		print("Saved silo_aerial.png")
		print("ALL SILO CAPTURES SAVED")
		quit()
		return true
	return false
