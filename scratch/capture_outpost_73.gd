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
	cam.fov = 75.0
	root.add_child(cam)

func _process(delta: float) -> bool:
	frame += 1
	var event = level.find_child("DeadForestEvent", true, false)
	var bunker = event.bunker_instance if event else null
	
	if frame == 2:
		print("Teleporting to Bunker 1 & Disabling Fog...")
		dev.teleport_to_poi(1)
		dev.toggle_fog()
	
	elif frame == 4:
		var props = level.find_child("DeadForestProps", true, false)
		if props and bunker and props.has_method("clear_area"):
			props.clear_area(bunker.global_position, 32.0)
			print("Cleared trees within 32m of bunker")
	
	elif frame == 6:
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 1: Front Elevation
			var eye = b_pos + b_basis.z * 9.5 + Vector3(0.0, 2.2, 0.0)
			var target = b_pos + b_basis.z * 1.0 + Vector3(0.0, 2.2, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 1: Front Elevation")
	
	elif frame == 9:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_front.png")
		print("Saved outpost_73_front.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 2: Rear Elevation (HVAC Louver & Electrical Cabinet)
			var eye = b_pos - b_basis.z * 9.5 + Vector3(0.0, 2.2, 0.0)
			var target = b_pos - b_basis.z * 1.0 + Vector3(0.0, 2.2, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 2: Rear Elevation")
	
	elif frame == 12:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_rear.png")
		print("Saved outpost_73_rear.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 3: Left Side Elevation (Basalt panels & amber slit)
			var eye = b_pos - b_basis.x * 9.5 + Vector3(0.0, 2.2, 0.0)
			var target = b_pos - b_basis.x * 1.0 + Vector3(0.0, 2.2, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 3: Left Side Elevation")
	
	elif frame == 15:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_left.png")
		print("Saved outpost_73_left.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 4: Right Side Elevation (Exterior Service Ladder & amber slit)
			var eye = b_pos + b_basis.x * 9.5 + Vector3(0.0, 2.2, 0.0)
			var target = b_pos + b_basis.x * 1.0 + Vector3(0.0, 2.2, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 4: Right Side Elevation")
	
	elif frame == 18:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_right.png")
		print("Saved outpost_73_right.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 5: Interior Front Wall (looking towards door from inside)
			var eye = b_pos - b_basis.z * 1.8 + Vector3(0.0, 1.8, 0.0)
			var target = b_pos + b_basis.z * 4.5 + Vector3(0.0, 1.8, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 5: Int Front Wall")
	
	elif frame == 21:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_int_front.png")
		print("Saved outpost_73_int_front.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 6: Interior Rear Wall (Interior HVAC Louver & Panels)
			var eye = b_pos + b_basis.z * 1.8 + Vector3(0.0, 1.8, 0.0)
			var target = b_pos - b_basis.z * 4.5 + Vector3(0.0, 1.8, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 6: Int Rear Wall")
	
	elif frame == 24:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_int_rear.png")
		print("Saved outpost_73_int_rear.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 7: Interior Left Wall (Workstation & CRT Static)
			var eye = b_pos + b_basis.x * 1.8 + Vector3(0.0, 1.6, 0.0)
			var target = b_pos - b_basis.x * 3.8 + Vector3(0.0, 1.3, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 7: Int Left Wall")
	
	elif frame == 27:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_int_left.png")
		print("Saved outpost_73_int_left.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 8: Interior Right Wall (Generator Machinery)
			var eye = b_pos - b_basis.x * 1.8 + Vector3(0.0, 1.6, 0.0)
			var target = b_pos + b_basis.x * 3.8 + Vector3(0.0, 1.1, -0.2)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 8: Int Right Wall")
	
	elif frame == 30:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_int_right.png")
		print("Saved outpost_73_int_right.png")
		if bunker:
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 9: Hero 3/4 Exterior Perspective
			var eye = b_pos + b_basis.z * 11.0 + b_basis.x * 9.0 + Vector3(0.0, 4.5, 0.0)
			var target = b_pos + Vector3(0.0, 2.0, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 9: Hero Exterior Perspective")
	
	elif frame == 33:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_hero.png")
		print("Saved outpost_73_hero.png")
		if bunker:
			# Open the blast doors!
			bunker.door_open_target = 1.0
			bunker.door_open_factor = 1.0
			bunker.door_left.position.x = -1.25
			bunker.door_right.position.x = 1.25
			var b_pos = bunker.global_position
			var b_basis = bunker.global_transform.basis
			# View 10: Blast Door Open, looking into glowing interior!
			var eye = b_pos + b_basis.z * 6.5 + b_basis.x * 0.4 + Vector3(0.0, 1.8, 0.0)
			var target = b_pos - b_basis.z * 1.2 + Vector3(0.0, 1.4, 0.0)
			cam.look_at_from_position(eye, target, Vector3.UP)
			print("Set View 10: Blast Door Open")
	
	elif frame == 36:
		var img = root.get_texture().get_image()
		if img: img.save_png("scratch/outpost_73_door_open.png")
		print("Saved outpost_73_door_open.png")
		print("ALL 10 VIEWS CAPTURED SUCCESSFULLY!")
		quit()
		return true
	return false
