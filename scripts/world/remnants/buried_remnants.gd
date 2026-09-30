class_name BuriedRemnants
extends RefCounted
## Large pieces of Apartment 4C half-buried out in the dead forest: a fridge on its back in the ash, a sofa sunk to its
## cushions, the front door with all its locks leaning out of the ground. Rare: a chunk holds at most one, CHANCE of them do.
## DeadForestProps calls scatter() for every streamed chunk (seeded by the chunk, so a place always holds the same thing) and
## keeps its trees and rocks off the returned footprint. place() puts one anywhere (tests, set pieces).

enum Pose { UPRIGHT, LEANING, TOPPLED }

const CHANCE := 0.08                 # of chunks (48 m) with one: about one every 170 m of forest
const EDGE := 8.0                    # m kept from the chunk's edge
const CLEAR_ORIGIN := 40.0           # m: the start clearing stays as it is
const SEED := 913577
const FOOTPRINT_PAD := 1.5           # m around a piece that trees and rocks keep off
## piece -> poses it can take
const PIECES := {
	&"fridge": [Pose.UPRIGHT, Pose.LEANING, Pose.TOPPLED],
	&"stove": [Pose.UPRIGHT, Pose.LEANING],
	&"sofa": [Pose.UPRIGHT, Pose.LEANING],
	&"armchair": [Pose.UPRIGHT, Pose.LEANING, Pose.TOPPLED],
	&"bed_double": [Pose.UPRIGHT, Pose.LEANING],
	&"wardrobe_open": [Pose.LEANING, Pose.TOPPLED],
	&"dresser": [Pose.UPRIGHT, Pose.LEANING],
	&"tv_console": [Pose.UPRIGHT, Pose.LEANING],
	&"bookshelf": [Pose.LEANING],
	&"door_front": [Pose.LEANING],
	&"dining_table": [Pose.UPRIGHT, Pose.LEANING],
	&"toilet": [Pose.UPRIGHT],
	&"radiator": [Pose.LEANING],
}
## pose -> [share of its height sunk (min, max), tilt deg (min, max)]; TOPPLED lies on its back (front to the sky) first
const POSES := {
	Pose.UPRIGHT: [0.25, 0.4, 2.0, 8.0],
	Pose.LEANING: [0.3, 0.45, 14.0, 26.0],
	Pose.TOPPLED: [0.2, 0.4, 2.0, 10.0],
}


## The chunk's remnant, if it has one: placed under `parent`. Returns its footprint as [Vector3(x, z, radius)] (empty if none).
## `blocked(x, z) -> bool` says where not to put one (amber pools, cleared building sites).
static func scatter(parent: Node3D, terrain: Node3D, cx: int, cz: int, blocked: Callable) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if parent == null or terrain == null:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(cx, cz, SEED))
	if rng.randf() >= CHANCE:
		return out
	var size: float = DeadForestTerrain.CHUNK_SIZE
	var x := (cx - 0.5) * size + rng.randf_range(EDGE, size - EDGE)
	var z := (cz - 0.5) * size + rng.randf_range(EDGE, size - EDGE)
	if x * x + z * z < CLEAR_ORIGIN * CLEAR_ORIGIN or (blocked.is_valid() and blocked.call(x, z)):
		return out
	var kinds := PIECES.keys()
	var kind: StringName = kinds[rng.randi() % kinds.size()]
	var poses: Array = PIECES[kind]
	var piece := place(kind, parent, terrain, Vector3(x, 0.0, z), rng.randf() * TAU, poses[rng.randi() % poses.size()], rng)
	if piece:
		var box := Remnant.bounds(piece)
		out.append(Vector3(x, z, Vector2(box.size.x, box.size.z).length() * 0.5 + FOOTPRINT_PAD))
	return out


## One piece sunk into the ground at `at` (x, z; y is found), turned `yaw`, in `pose`. Returns it (null for an unknown piece).
static func place(kind: StringName, parent: Node3D, terrain: Node3D, at: Vector3, yaw: float, pose: Pose,
		rng: RandomNumberGenerator) -> Node3D:
	if parent == null or rng == null or not POSES.has(pose):
		return null
	var piece := Remnant.spawn(kind, parent)
	if piece == null:
		return null
	piece.name = "remnant_" + String(kind)
	var spec: Array = POSES[pose]
	var basis := Basis(Vector3.UP, yaw)
	if pose == Pose.TOPPLED:
		basis = basis * Basis(Vector3.RIGHT, -PI * 0.5)
	var lean := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	if lean.length_squared() > 0.0001:
		basis = Basis(lean.normalized(), deg_to_rad(rng.randf_range(spec[2], spec[3]))) * basis
	var local := Remnant.bounds(piece)
	var span := Transform3D(basis) * local
	var ground := _ground(terrain, at.x, at.z, Vector2(span.size.x, span.size.z).length() * 0.35)
	var sink := rng.randf_range(spec[0], spec[1]) * span.size.y
	piece.transform = Transform3D(basis, Vector3(at.x, ground - sink - span.position.y, at.z))
	Remnant.grime(piece, ground)
	return piece


## Lowest ground under the centre and four points `r` out, so no edge of the piece floats on a slope.
static func _ground(terrain: Node3D, x: float, z: float, r: float) -> float:
	if terrain == null:
		return 0.0
	var h: float = terrain.get_height(x, z)
	for d in [Vector2(r, 0.0), Vector2(-r, 0.0), Vector2(0.0, r), Vector2(0.0, -r)]:
		h = minf(h, terrain.get_height(x + d.x, z + d.y))
	return h
