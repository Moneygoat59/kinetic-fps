class_name CourseTrigger
extends Area3D

const CourseManager = preload("res://scripts/course_manager.gd")

@export_enum("start", "checkpoint", "finish", "teleport_start") var trigger_type: String = "checkpoint"
@export var checkpoint_number: int = 1
@export var total_checkpoints: int = 3

var triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not (body is CharacterBody3D):
		return
	
	if trigger_type == "start":
		if CourseManager.instance:
			CourseManager.instance.start_course()
	elif trigger_type == "checkpoint":
		if not triggered:
			triggered = true
			if CourseManager.instance:
				CourseManager.instance.reach_checkpoint(global_position, checkpoint_number, total_checkpoints)
	elif trigger_type == "finish":
		if CourseManager.instance:
			CourseManager.instance.finish_course()
	elif trigger_type == "teleport_start":
		if CourseManager.instance:
			CourseManager.instance.restart_full_run()
