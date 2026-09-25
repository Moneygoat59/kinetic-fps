extends SceneTree

func _init() -> void:
	var scn = load("res://scenes/levels/dead_forest.tscn")
	var level = scn.instantiate()
	root.add_child(level)
	
	print("find_child('*Player*', true, false): ", root.find_child("*Player*", true, false))
	print("find_child('Player', true, false): ", root.find_child("Player", true, false))
	print("find_child('*Player*', true, true): ", root.find_child("*Player*", true, true))
	print("find_child('Player', true, true): ", root.find_child("Player", true, true))
	print("level.find_child('Player', true, false): ", level.find_child("Player", true, false))
	print("level.find_child('*Player*', true, false): ", level.find_child("*Player*", true, false))
	quit()
