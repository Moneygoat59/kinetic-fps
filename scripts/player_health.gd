class_name PlayerHealth
extends RefCounted

signal health_changed(current_hp: float, max_hp: float)
signal player_died
signal player_respawned

var max_health: float = 100.0
var current_health: float = 100.0
var is_dead: bool = false
var spawn_position: Vector3 = Vector3.ZERO

func init(max_hp: float, spawn_pos: Vector3) -> void:
	max_health = max_hp
	current_health = max_hp
	spawn_position = spawn_pos
	is_dead = false

func take_damage(amount: float) -> bool:
	if is_dead or amount <= 0.0:
		return false
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		player_died.emit()
		return true
	return false

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func reset() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)
	player_respawned.emit()
