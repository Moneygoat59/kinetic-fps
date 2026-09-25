extends SceneTree

var frame = 0
var level: Node3D
var dev: Node
var player: CharacterBody3D
var bunker: SmallBunker
var dosimeter_got = false

func _init() -> void:
	root.size = Vector2i(1280, 720)
	var scn = load("res://scenes/levels/dead_forest.tscn")
	level = scn.instantiate()
	root.add_child(level)
	dev = root.get_node_or_null("DevTools")
	if not dev:
		var dev_cls = load("res://scripts/dev/dev_tools.gd")
		dev = dev_cls.new(); dev.name = "DevTools"; root.add_child(dev)

func _process(delta: float) -> bool:
	frame += 1
	var event = level.find_child("DeadForestEvent", true, false)
	player = level.find_child("Player", true, false) as CharacterBody3D
	bunker = event.bunker_instance as SmallBunker if event else null
	
	if frame == 2:
		print("[WALKTHROUGH] Teleporting player to Bunker 1...")
		dev.teleport_to_poi(1)
	
	elif frame == 3:
		bunker = event.bunker_instance as SmallBunker if event else null
		if bunker:
			bunker.dosimeter_acquired.connect(func(): dosimeter_got = true; print("[WALKTHROUGH] Signal dosimeter_acquired received!"))
			print("[WALKTHROUGH] Bunker resolved and signal connected.")
	
	elif frame >= 4 and frame <= 110:
		if bunker:
			var b_pos = bunker.global_position
			var target = b_pos - bunker.global_transform.basis.z * 1.8
			var dir = (target - player.global_position).normalized()
			player.velocity = Vector3(dir.x * 6.0, 0.0, dir.z * 6.0)
			player.move_and_slide()
			bunker.check_interaction(player.global_position)
			if frame % 20 == 0:
				print("  Frame %d: dist = %.2fm" % [frame, player.global_position.distance_to(b_pos)])
	
	elif frame == 111:
		var dist_to_center = player.global_position.distance_to(bunker.global_position)
		print("  Player position: %s, dist to bunker center: %.2fm" % [str(player.global_position), dist_to_center])
		print("  Dosimeter acquired: %s" % str(dosimeter_got))
		assert(dist_to_center < 3.0, "Player must successfully walk through the door into the bunker interior")
		assert(dosimeter_got, "Player must successfully interact and acquire the dosimeter/field tracker")
		print("[WALKTHROUGH] TEST PASSED: Player entered bunker without collision obstruction & claimed item!")
		quit()
		return true
	return false
