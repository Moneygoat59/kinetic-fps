class_name TunnelMaze
extends RefCounted
## The layout of a tunnel network as data (no nodes): interchange halls on a cols x rows grid, which neighbours are joined by
## an open tunnel or a caved-in one, and which hall mouths lead into a dead-end spur and how far. Seeded: one seed is one
## maze, every visit. A randomised depth-first spanning tree makes every hall reachable; `loops` extra open links give more
## than one way round; `caved` extra links are tunnels that end in rubble from both sides (false leads); of the mouths left,
## `spur_chance` open onto a short tunnel that ends in rubble. Hall (0, 0)'s south mouth is the entry (reserved). Spurs only
## leave the north and east edges of the grid (the other two face the way in). Grid y grows north (network -Z).

enum Link { NONE, OPEN, CAVED }

## mouth k of a hall -> grid step (0 N, 1 E, 2 S, 3 W: the order of tunnel_junction's marker_mouth_<k>)
const DIRS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]
const ENTRY := Vector3i(0, 0, 2)

var cols := 1
var rows := 1
var links := {}               # Vector3i(x, y, k), k 0 (north) or 1 (east) -> Link
var spurs := {}               # Vector3i(x, y, k) -> length in 8 m slots before the cave-in


func _init(c := 5, r := 5, seed_value := 7, loops := 4, caved := 5, spur_chance := 0.5) -> void:
	cols = maxi(c, 1)
	rows = maxi(r, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_tree(rng)
	var spare: Array[Vector3i] = []
	for key in _all_links():
		if link_of(key) == Link.NONE:
			spare.append(key)
	_shuffle(spare, rng)
	for i in spare.size():
		if i < loops:
			links[spare[i]] = Link.OPEN
		elif i < loops + caved:
			links[spare[i]] = Link.CAVED
	for x in cols:
		for y in rows:
			for k in 4:
				var at := Vector3i(x, y, k)
				if at != ENTRY and link(at) == Link.NONE and _may_spur(at) and rng.randf() < spur_chance:
					spurs[at] = rng.randi_range(1, 5)


## The link through mouth k of hall (x, y) (any k: west and south are the neighbour's east and north).
func link(at: Vector3i) -> Link:
	if at.z >= 2:
		var n := Vector2i(at.x, at.y) + DIRS[at.z]
		if not has_hall(n):
			return Link.NONE
		return link_of(Vector3i(n.x, n.y, at.z - 2))
	return link_of(at)


func link_of(key: Vector3i) -> Link:
	return links.get(key, Link.NONE)


func has_hall(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < cols and p.y < rows


## Halls reachable from (0, 0) through open links (the tree guarantees all of them).
func reachable() -> int:
	var seen := {Vector2i.ZERO: true}
	var todo: Array[Vector2i] = [Vector2i.ZERO]
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for k in 4:
			var n := p + DIRS[k]
			if has_hall(n) and not seen.has(n) and link(Vector3i(p.x, p.y, k)) == Link.OPEN:
				seen[n] = true
				todo.append(n)
	return seen.size()


func _tree(rng: RandomNumberGenerator) -> void:
	var seen := {Vector2i.ZERO: true}
	var stack: Array[Vector2i] = [Vector2i.ZERO]
	while not stack.is_empty():
		var p: Vector2i = stack.back()
		var ways: Array[int] = []
		for k in 4:
			if has_hall(p + DIRS[k]) and not seen.has(p + DIRS[k]):
				ways.append(k)
		if ways.is_empty():
			stack.pop_back()
			continue
		var k: int = ways[rng.randi_range(0, ways.size() - 1)]
		var n := p + DIRS[k]
		links[_canonical(Vector3i(p.x, p.y, k))] = Link.OPEN
		seen[n] = true
		stack.append(n)


func _canonical(at: Vector3i) -> Vector3i:
	if at.z < 2:
		return at
	var n := Vector2i(at.x, at.y) + DIRS[at.z]
	return Vector3i(n.x, n.y, at.z - 2)


func _all_links() -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for x in cols:
		for y in rows:
			if y + 1 < rows:
				out.append(Vector3i(x, y, 0))
			if x + 1 < cols:
				out.append(Vector3i(x, y, 1))
	return out


## Inside the grid a spur may point at any neighbour it is not linked to; at the edge only north and east.
func _may_spur(at: Vector3i) -> bool:
	return has_hall(Vector2i(at.x, at.y) + DIRS[at.z]) or at.z <= 1


func _shuffle(arr: Array[Vector3i], rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := arr[i]
		arr[i] = arr[j]
		arr[j] = t
