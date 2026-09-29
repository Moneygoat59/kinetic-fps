class_name TunnelNetwork
extends Node3D
## A maze of the underground line: interchange halls (tunnel_junction) on a grid, joined by long tunnels laid from the kit
## (TunnelLine, TunnelRuns), laid out by a seeded TunnelMaze. Open links are tunnels hall to hall, caved links end in
## rubble from both sides, spurs are short dead ends, every unused mouth keeps its concrete plug. Emergency pylons stand in
## every refuge and on every hall's diagonals: they only light the way. The entry run leaves hall (0, 0) south and passes
## a tunnel_vent (a duct mouth in its right wall, VentDuct mounted: `vent`) before ending in rubble. The records vault
## (tunnel_vault, furnished as it is laid) ends a short run out of `vault_mouth`, a mouth the maze leaves unlinked; a
## station (tunnel_station) stands just before it, its platform running on into the vault's approach.
## build() once it is in the tree (runs are batched); then place the whole network by its vent with place_by_mouth(). While `player` is
## inside its bounds the level's air is the tunnels' (TunnelAir) and the line's music plays (TunnelMusic). Hall (x, y) sits at (x, 0, -y) * pitch.

signal inside_changed(inside: bool)     # the walker went into / out of the network's bounds

const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const HALL := &"tunnel_junction"
const VAULT_CENTRE := Vector3(0.0, 0.0, -22.0)   # tunnel_vault: the hall's middle (piece space) ...
const VAULT_REACH := 14.0                        # ... and how far the network's bounds reach round it
const STATION_CENTRE := Vector3(0.0, 0.0, -12.0) # tunnel_station: the platform's middle (piece space) ...
const STATION_REACH := 13.0                      # ... and its reach

@export var cols := 5
@export var rows := 5
@export var maze_seed := 7
@export var slots := 12                  # 8 m slots between two halls' mouths (a multiple of 4)
@export var loops := 4
@export var caved := 5
@export var spur_chance := 0.5
@export var entry_before_vent := 4       # slots between hall (0, 0) and the vent piece
@export var vault_mouth := Vector3i(4, 4, 0)   # hall (x, y), mouth k: the far corner's north mouth (off the grid, never linked)

var player: Node3D
var maze: TunnelMaze
var halls := {}                          # Vector2i -> tunnel_junction piece
var runs: Array[Node3D] = []             # one node per run: its pieces (batched) and pylons
var pylons: Array[EmergencyPylon] = []
var vent: VentDuct
var vent_mouth: Node3D                   # the duct_mouth piece in the entry run's vent
var vault: Node3D                        # the tunnel_vault piece (null if vault_mouth is linked or off the grid)
var station: Node3D                      # the tunnel_station in front of it
var bounds := AABB()                     # network space
var air: TunnelAir
var music: TunnelMusic
var _inside := false


func pitch() -> float:
	return 2.0 * O73Kit.JUNC_R + float(slots) * O73Kit.TUN_LEN


func build() -> void:
	if maze != null or not is_inside_tree():
		return
	maze = TunnelMaze.new(cols, rows, maze_seed, loops, caved, spur_chance)
	for x in cols:
		for y in rows:
			_hall(Vector2i(x, y))
	for x in cols:
		for y in rows:
			for k in 4:
				_run_from(Vector3i(x, y, k))
	_entry()
	air = TunnelAir.new()
	add_child(air)
	music = TunnelMusic.new()
	add_child(music)


## Moves the whole network so the entry vent's duct mouth sits at `mouth` (global): its front (+Z) into the tunnel.
func place_by_mouth(mouth: Transform3D) -> void:
	if vent_mouth == null:
		return
	var local := global_transform.affine_inverse() * vent_mouth.global_transform
	global_transform = mouth * local.affine_inverse()


func _physics_process(_delta: float) -> void:
	if player == null or air == null:
		return
	var inside := bounds.has_point(to_local(player.global_position))
	if inside != _inside:
		_inside = inside
		inside_changed.emit(inside)
	air.update(inside)
	var from_entry := vent_mouth.global_position.distance_to(player.global_position) if vent_mouth else 0.0
	music.update(inside, from_entry)


func _hall(p: Vector2i) -> void:
	var piece := O73Kit.spawn(HALL, self, Transform3D(Basis(), Vector3(p.x, 0.0, -p.y) * pitch()))
	if piece == null:
		return
	piece.name = "hall_%d_%d" % [p.x, p.y]
	halls[p] = piece
	_grow(piece.position, O73Kit.JUNC_R + 2.0)
	for k in 4:
		var at := piece.get_node_or_null("marker_pylon_%d" % k) as Node3D
		if at:
			var pylon := EmergencyPylon.new()
			pylon.cast_shadows = false
			pylon.transform = at.transform
			piece.add_child(pylon)
			pylons.append(pylon)


## Lays whatever leaves mouth `at` (x, y, k): the tunnel of a link it owns (k 0 / 1), its half of a caved link (any k), a spur.
func _run_from(at: Vector3i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(at) ^ maze_seed
	var names: Array[StringName] = []
	var link := maze.link(at)
	if at == vault_mouth and link == TunnelMaze.Link.NONE:
		_vault(at)
		return
	if link == TunnelMaze.Link.OPEN and at.z < 2:
		names = TunnelRuns.open(slots, rng)
	elif link == TunnelMaze.Link.CAVED:
		names = TunnelRuns.caved_half(slots)
	elif maze.spurs.has(at):
		names = TunnelRuns.spur(mini(maze.spurs[at], slots / 2 - 1))
	if link != TunnelMaze.Link.NONE or not names.is_empty():
		KitScript.drop_part(halls[Vector2i(at.x, at.y)], "seal_%d" % at.z)
	if not names.is_empty():
		_lay("run_%d_%d_%d" % [at.x, at.y, at.z], _mouth(at), names)


func _entry() -> void:
	var spec := TunnelRuns.entry(entry_before_vent)
	KitScript.drop_part(halls[Vector2i.ZERO], "seal_%d" % TunnelMaze.ENTRY.z)
	var pieces := _lay("run_entry", _mouth(TunnelMaze.ENTRY), spec[0])
	var piece: Node3D = pieces[spec[1]] if pieces.size() > spec[1] else null
	var at := piece.get_node_or_null("marker_vent") as Node3D if piece else null
	if at == null:
		return
	vent_mouth = O73Kit.spawn(&"duct_mouth", piece, at.transform)
	vent = VentDuct.mount(vent_mouth)


func _vault(at: Vector3i) -> void:
	KitScript.drop_part(halls[Vector2i(at.x, at.y)], "seal_%d" % at.z)
	var pieces := _lay("run_vault", _mouth(at), TunnelRuns.vault())
	vault = pieces.back() if not pieces.is_empty() and pieces.back().name.begins_with(TunnelRuns.VAULT) else null
	for piece in pieces:
		if piece.name.begins_with(TunnelRuns.STATION):
			station = piece
			_grow(piece.transform * STATION_CENTRE, STATION_REACH)
	if vault:
		_grow(vault.transform * VAULT_CENTRE, VAULT_REACH)


func _lay(label: String, start: Transform3D, names: Array[StringName]) -> Array[Node3D]:
	var run := Node3D.new()
	run.name = label
	add_child(run)
	runs.append(run)
	var pieces := TunnelLine.lay(run, start, names)
	for piece in pieces:
		_grow(piece.position, O73Kit.TUN_LEN + 4.0)
	TunnelLine.batch(run, pieces)
	pylons.append_array(TunnelLine.pylons(pieces))
	return pieces


func _mouth(at: Vector3i) -> Transform3D:
	var hall: Node3D = halls[Vector2i(at.x, at.y)]
	var m := hall.get_node("marker_mouth_%d" % at.z) as Node3D
	return hall.transform * m.transform


func _grow(p: Vector3, reach: float) -> void:
	var box := AABB(p - Vector3(reach, 2.0, reach), Vector3(2.0 * reach, 10.0, 2.0 * reach))
	bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
