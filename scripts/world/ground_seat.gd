class_name GroundSeat
extends RefCounted
## Seats a footed prop on uneven terrain so none of its ground contacts float: the base goes as low as the lowest contact
## needs. Reusable for anything with buried feet (relay masts, guyed towers, tripods):
##   position.y = GroundSeat.base_y(terrain, position, rotation.y, FOOTPRINT, 0.05)
## FOOTPRINT rows are Vector3(local x, how far the base may sit above the ground at that point, local z): e.g. a footing
## 0.5 m deep may stand at most ~0.4 above the ground at its rim before its underside shows.


## Base height for a prop at `pos` turned `yaw` about Y. `sink` = how far the base settles below the ground at its centre.
static func base_y(terrain: Node3D, pos: Vector3, yaw: float, footprint: Array[Vector3], sink: float = 0.0) -> float:
	if terrain == null:
		return pos.y
	var turn := Basis(Vector3.UP, yaw)
	var y: float = terrain.get_height(pos.x, pos.z) - sink
	for contact in footprint:
		var p := pos + turn * Vector3(contact.x, 0.0, contact.z)
		y = minf(y, terrain.get_height(p.x, p.z) + contact.y)
	return y
