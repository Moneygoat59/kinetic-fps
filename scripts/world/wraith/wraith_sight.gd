class_name WraithSight
extends RefCounted
## What the walker can see, for WraithStalk: their flat forward, whether they are looking straight at a point (within
## `seen_dot` of the view axis, nothing in between), and whether a spot is in clear line of sight. One pre-built ray query.

const CHEST := Vector3(0.0, 1.8, 0.0)   # where on the wraith the eyes land

var player: Player
var seen_dot := 0.974
var _ray := PhysicsRayQueryParameters3D.new()


func _init(p: Player, dot: float) -> void:
	player = p
	seen_dot = dot
	_ray.exclude = [p.get_rid()]


func forward() -> Vector3:
	var f := -player.camera.global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.001 else Vector3.FORWARD


func sees(pos: Vector3) -> bool:
	var to := pos + CHEST - player.camera.global_position
	if (-player.camera.global_transform.basis.z).dot(to.normalized()) < seen_dot:
		return false
	return clear(pos)


func clear(pos: Vector3) -> bool:
	_ray.from = player.camera.global_position
	_ray.to = pos + CHEST
	return player.get_world_3d().direct_space_state.intersect_ray(_ray).is_empty()
