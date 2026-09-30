class_name RelayChain
extends RefCounted
## Lays a chain of relay masts (NuclearPylon) through the forest from one building toward the next: alternating sweeps
## ~100-145 m apart, cleared ground, a small flat pad under each mast and roadside vignettes along each leg. Used by
## DeadForestEvent for every hub route; the chains then belong to RelayNet and stay standing.

const PYLON_SCRIPT = preload("res://scripts/nuclear_pylon.gd")
const SILO_SCRIPT = preload("res://scripts/silo/missile_silo.gd")

var masts: Array[Node3D] = []   # the laid masts, in the order they were laid
var building_pos := Vector3.ZERO


## From start_pos toward dir, `count` masts in the route colour, under `owner`. long = the silo route (longer legs, the last
## mast at the silo's approach distance). to_building = false: no approach mast at the far end (the hub has its own).
func lay(owner: Node3D, terrain: Node3D, props: Node3D, start_pos: Vector3, dir: Vector3, count: int, col: Color,
		to_building: bool = true) -> RelayChain:
	var long := count > 4
	var base_dir = dir.normalized()
	var side = base_dir.rotated(Vector3.UP, PI * 0.5)
	var pts: Array[Vector3] = [start_pos + base_dir * 14.0 + side * 4.5]
	var curr = pts[0]
	for i in range(2, count):
		var sweep = (1.0 if i % 2 == 0 else -1.0) * randf_range(0.65, 1.10)
		var step_dist = randf_range(110.0, 145.0) if long else randf_range(95.0, 130.0)
		curr += base_dir.rotated(Vector3.UP, sweep).normalized() * step_dist
		base_dir = base_dir.rotated(Vector3.UP, randf_range(-0.25, 0.25)).normalized()
		pts.append(curr)
	var bldg_dist = randf_range(175.0, 205.0) if long else randf_range(95.0, 125.0)
	building_pos = curr + base_dir * bldg_dist
	pts.append(building_pos - base_dir * (SILO_SCRIPT.APPROACH if long else 8.5) + side * 4.5)
	for i in range(pts.size() if to_building else pts.size() - 1):
		var pt = pts[i]
		var gy = terrain.get_height(pt.x, pt.z) if terrain else 0.0
		if props and props.has_method("clear_area"): props.clear_area(Vector3(pt.x, gy, pt.z), 12.0)
		if i > 0 and i < pts.size() - 1 and terrain and terrain.has_method("add_flat_zone"):
			terrain.add_flat_zone(pt.x, pt.z, 10.0, gy, 4.0)
		var p = PYLON_SCRIPT.new()
		p.station_id = i + 1
		p.pylon_color = col
		p.build_pylon(terrain, pt.x, pt.z)
		owner.add_child(p)
		masts.append(p)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(pts.size() - 1): KitVignettes.along_leg(owner, terrain, props, pts[i], pts[i + 1], rng)
	return self


## The last mast stands inside the destination's flat zone, laid after the chain: re-seat every mast on the new ground.
func settle(terrain: Node3D) -> void:
	for p in masts: if is_instance_valid(p): p.settle(terrain)
