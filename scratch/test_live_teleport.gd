extends SceneTree

var frame = 0
var level: Node3D
var dev: Node

func _init() -> void:
	print("[LIVE TEST] Loading dead_forest.tscn...")
	var scn = load("res://scenes/levels/dead_forest.tscn")
	level = scn.instantiate()
	root.add_child(level)
	dev = root.get_node_or_null("DevTools")
	if not dev:
		var dev_cls = load("res://scripts/dev/dev_tools.gd")
		dev = dev_cls.new()
		dev.name = "DevTools"
		root.add_child(dev)

func _process(delta: float) -> bool:
	frame += 1
	var player = level.find_child("Player", true, false) as CharacterBody3D
	var event = level.find_child("DeadForestEvent", true, false)
	
	if frame == 2:
		print("[LIVE TEST] 1. Teleporting to Bunker 1 (F5)...")
		dev.teleport_to_poi(1)
		var b_pos = event.bunker_instance.global_position
		var d = player.global_position.distance_to(b_pos)
		print("  Bunker 1 dist: %.2fm" % d)
		assert(d > 5.0 and d < 10.0, "Player should be at Bunker 1 entrance")
		print("  Bunker 1: PASS")
	
	elif frame == 4:
		print("[LIVE TEST] 2. Teleporting to Central Hub (F6)...")
		dev.teleport_to_poi(2)
		var h_pos = event.hub_instance.global_position
		var d = player.global_position.distance_to(h_pos)
		print("  Hub dist: %.2fm" % d)
		assert(d > 5.0 and d < 12.0, "Player should be at Hub entrance")
		print("  Hub: PASS")
	
	elif frame == 6:
		print("[LIVE TEST] 3. Teleporting to Outpost 2 (F7)...")
		dev.teleport_to_poi(3)
		var op2_pos = event.outpost_2_instance.global_position
		var d = player.global_position.distance_to(op2_pos)
		print("  Outpost 2 dist: %.2fm" % d)
		assert(d > 4.0 and d < 10.0, "Player should be at Outpost 2 entrance")
		print("  Outpost 2: PASS")
	
	elif frame == 8:
		print("[LIVE TEST] 4. Teleporting to Outpost 3 (F8)...")
		dev.teleport_to_poi(4)
		var op3_pos = event.outpost_3_instance.global_position
		var d = player.global_position.distance_to(op3_pos)
		print("  Outpost 3 dist: %.2fm" % d)
		assert(d > 4.0 and d < 10.0, "Player should be at Outpost 3 entrance")
		print("  Outpost 3: PASS")
	
	elif frame == 10:
		print("[LIVE TEST] 5. Teleporting to Missile Silo (F9)...")
		dev.teleport_to_poi(5)
		var s_pos = event.silo_instance.global_position
		var d = player.global_position.distance_to(s_pos)
		print("  Silo dist: %.2fm" % d)
		assert(d > 18.0 and d < 36.0, "Player should be at Silo observation catwalk entrance")
		print("  Silo: PASS")
		print("[LIVE TEST] ALL 5 IN-LEVEL TELEPORTS VERIFIED SUCCESSFULLY!")
		quit()
		return true
	return false
