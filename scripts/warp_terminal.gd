class_name WarpTerminal
extends StaticBody3D

@export var target_scene_path: String = "res://scenes/main.tscn"
@export var prompt_text: String = "Warp to Obstacle Course Trial"

func get_interaction_prompt() -> String:
	return "[E] " + prompt_text

func interact(_player: Node) -> void:
	if ResourceLoader.exists(target_scene_path):
		get_tree().change_scene_to_file(target_scene_path)
