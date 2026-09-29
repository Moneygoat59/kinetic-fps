class_name RemnantSmalls
extends RefCounted
## Small things from Apartment 4C left in the forest's buildings: pill bottles, a water glass, the organizer, the alarm clock,
## set down on the Outpost 73 kit furniture as the walker would set them down (squared to the edge, labels forward, in pairs).
## They stay clean: the only clean things in the building.
## Works on any model furnished by BunkerKit.furnish: call RemnantSmalls.dress(model) after it. Surfaces come from the kit pieces
## the model places (HOSTS); a set only goes where it fits, clear of whatever already stands on that surface (a CRT and its
## keyboard, a route key case, a crate); the choice is seeded by the model file, so a building always holds the same things.

const PREFIX := "marker_kit_"
const PER_BUILDING := 2
const GAP := 0.03              # m kept between a set and anything else on the surface
const REACH_UP := 0.6          # m above a surface a piece still counts as standing on it
const SPREAD := 0.5            # m between two sets
## kit piece -> spots on its surfaces, piece space: [x, top height, z, room along x each side of the spot (edges, baked clutter)]
const HOSTS := {
	&"table_steel": [[-0.68, 0.78, 0.2, 0.11], [0.68, 0.78, 0.2, 0.11], [-0.3, 0.78, 0.22, 0.2], [0.3, 0.78, 0.22, 0.2]],
	&"shelf_rack": [[-0.015, 1.6325, 0.03, 0.13]],               # top shelf, between the box stack and the cable coil
	&"crate_large": [[0.0, 0.6, 0.0, 0.3]],
}
## sets: [half width along x, rows of [piece, x, z, yaw deg] about the spot]
const SETS := [
	[0.03, [[&"pill_bottle", 0.0, 0.0, 0.0]]],
	[0.065, [[&"pill_bottle", -0.035, 0.0, 0.0], [&"pill_bottle", 0.035, 0.0, 0.0]]],
	[0.1, [[&"pill_bottle_small", -0.06, 0.0, 0.0], [&"water_glass", 0.05, 0.0, 0.0]]],
	[0.13, [[&"pill_organizer", 0.0, 0.0, 0.0]]],
	[0.1, [[&"alarm_clock", 0.0, 0.0, 0.0]]],
	[0.12, [[&"book_stack", 0.0, 0.0, 0.0]]],
	[0.13, [[&"pill_bottle_tall", -0.09, 0.0, 0.0], [&"pill_bottle", -0.03, 0.0, 0.0], [&"pill_bottle_wide", 0.035, 0.0, 0.0],
		[&"pill_bottle_small", 0.095, 0.0, 0.0]]],
]


## Sets up to PER_BUILDING sets on free host spots of `model`. Returns how many pieces were placed.
static func dress(model: Node3D) -> int:
	if model == null:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(model.scene_file_path)
	var spots := free_spots(model)
	var sets := SETS.duplicate()
	var placed := 0
	var used := 0
	while used < PER_BUILDING and not spots.is_empty():
		var spot: Array = spots.pop_at(rng.randi() % spots.size())
		var pick := _fitting(sets, spot[1], rng)
		if pick < 0:
			continue
		var at: Transform3D = spot[0]
		for row in sets.pop_at(pick)[1]:
			var xf := at * Transform3D(Basis(Vector3.UP, deg_to_rad(row[3])), Vector3(row[1], 0.0, row[2]))
			var piece := Remnant.spawn(row[0], model, xf)
			if piece:
				piece.name = "remnant_" + String(row[0])
				placed += 1
		used += 1
		spots = spots.filter(func(s: Array) -> bool: return s[0].origin.distance_to(at.origin) >= SPREAD)
	return placed


## Every host spot of the model as [transform (model space, squared to its host), room along x]: the host's own room,
## narrowed by whatever else stands on that surface.
static func free_spots(model: Node3D) -> Array[Array]:
	var out: Array[Array] = []
	var hosts: Array[Node3D] = []
	var others: Array[AABB] = []
	for child in model.get_children():
		var n := String(child.name)
		if not (child is Node3D and n.begins_with("marker_")):
			continue
		if HOSTS.has(_kind(n)):
			hosts.append(child)
		else:
			var box := Remnant.bounds(child)
			var at := (child as Node3D).transform
			others.append(at * box if box.has_volume() else AABB(at.origin, Vector3.ZERO))
	for host in hosts:
		for s in HOSTS[_kind(String(host.name))]:
			var spot := host.transform * Transform3D(Basis(), Vector3(s[0], s[1], s[2]))
			var room := minf(s[3], _clearance(spot.origin, others))
			if room > 0.0:
				out.append([spot, room])
	return out


static func _kind(marker_name: String) -> StringName:
	return StringName(marker_name.trim_prefix(PREFIX).get_slice("__", 0)) if marker_name.begins_with(PREFIX) else &""


## Horizontal room from `at` to the nearest piece standing on the same surface, less GAP.
static func _clearance(at: Vector3, others: Array[AABB]) -> float:
	var room := INF
	for box in others:
		if box.position.y > at.y + REACH_UP or box.end.y < at.y + 0.02 or box.position.y < at.y - 0.05:
			continue
		var dx := maxf(maxf(box.position.x - at.x, at.x - box.end.x), 0.0)
		var dz := maxf(maxf(box.position.z - at.z, at.z - box.end.z), 0.0)
		room = minf(room, Vector2(dx, dz).length() - GAP)
	return room


## Index in `sets` of a random set no wider than `room`, or -1.
static func _fitting(sets: Array, room: float, rng: RandomNumberGenerator) -> int:
	var fits: Array[int] = []
	for i in sets.size():
		if sets[i][0] <= room:
			fits.append(i)
	return fits[rng.randi() % fits.size()] if not fits.is_empty() else -1
