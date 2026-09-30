extends SceneTree

const SILO_SCRIPT = preload("res://scripts/missile_silo.gd")

func _init() -> void:
	print("Testing colossal missile silo construction...")
	var silo = SILO_SCRIPT.new()
	root.add_child(silo)
	silo.build_silo(null, 0.0, 0.0)
	var p_at_console = silo.position + Vector3(0.0, 1.0, 16.0)
	var can_interact = silo.check_interaction(p_at_console)
	print("Interaction at console: ", can_interact)
	assert(can_interact, "Must be able to interact at console")

	silo._activate_silo()
	assert(silo.is_activated, "Silo must activate")
	print("Colossal silo test passed!")
	quit()
