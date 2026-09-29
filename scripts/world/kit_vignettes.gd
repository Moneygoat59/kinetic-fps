class_name KitVignettes
extends RefCounted
## Small abandoned scenes built from the Outpost 73 prop kit, dropped beside the long walks between relay masts so every leg
## passes something: a supply cache, a checkpoint, dumped amber drums, a surfacing section of the buried amber main, a dead relay.
## Data-driven (VIGNETTES) and reusable anywhere: KitVignettes.along_leg(...) or KitVignettes.build(kind, ...).
## These stand in open forest, so only outdoor pieces: indoor kit (O73Kit.TERMINALS, FURNITURE, SERVERS, ARCHIVE) is refused.

const MIN_LEG := 60.0                       # shorter legs get nothing
const SIDE_OFFSET := Vector2(8.0, 14.0)     # m off the straight line: seen through the fog, never in the way
const PAD_RADIUS := 7.0                     # cleared + flattened around each vignette
const DEAD_RELAY_TILT := 10.0               # degrees (with the 0.4 m sink every guy anchor stays buried)
## kind -> rows of [prop, local x, local z, yaw deg, height above the pad]
const VIGNETTES := {
	"supply_cache": [[&"crate_large", 0.0, 0.0, 15.0, 0.0], [&"crate_small", 0.05, -0.05, 40.0, 0.6],
		[&"amber_cell", 0.0, 0.05, 0.0, 1.0], [&"drum_amber", 1.4, 0.6, 60.0, 0.0], [&"barrier_concrete_broken", 0.3, -2.3, 8.0, 0.0]],
	"checkpoint": [[&"barrier_concrete", -2.0, 0.0, 0.0, 0.0], [&"barrier_concrete", 0.0, 0.0, 0.0, 0.0],
		[&"barrier_concrete_broken", 2.0, 0.0, 0.0, 0.0], [&"floodlight", 3.4, 2.4, 200.0, 0.0], [&"crate_small", -3.2, 1.4, 30.0, 0.0]],
	"drum_dump": [[&"drum_amber", 0.0, 0.0, 0.0, 0.0], [&"drum_amber", 0.7, 0.25, 40.0, 0.0], [&"drum_amber", -1.5, 0.9, 200.0, 0.0],
		[&"crate_small", 1.7, -0.6, 25.0, 0.0], [&"barrier_concrete_broken", -0.3, -2.2, 172.0, 0.0]],
	"exposed_main": [[&"pipe_riser", -4.0, 0.0, 180.0, 0.0], [&"pipe_valve", -2.0, 0.0, 0.0, 0.0], [&"pipe_riser", 0.0, 0.0, 0.0, 0.0]],
	"dead_relay": [[&"relay_pylon", 0.0, 0.0, 0.0, -0.4], [&"crate_small", 1.8, 1.2, 25.0, 0.0]],
}


## One vignette part-way along the leg a -> b, off to one side. Returns the vignette root (null for a short leg).
static func along_leg(parent: Node3D, terrain: Node3D, props: Node3D, a: Vector3, b: Vector3,
		rng: RandomNumberGenerator) -> Node3D:
	var leg := Vector3(b.x - a.x, 0.0, b.z - a.z)
	if parent == null or rng == null or leg.length() < MIN_LEG:
		return null
	var side := leg.normalized().rotated(Vector3.UP, PI * 0.5) * rng.randf_range(SIDE_OFFSET.x, SIDE_OFFSET.y)
	var pos := a.lerp(b, rng.randf_range(0.35, 0.65)) + (side if rng.randf() < 0.5 else -side)
	var kinds := VIGNETTES.keys()
	return build(kinds[rng.randi() % kinds.size()], parent, terrain, props, pos, rng.randf() * TAU)


static func build(kind: String, parent: Node3D, terrain: Node3D, props: Node3D, pos: Vector3, yaw: float) -> Node3D:
	if not VIGNETTES.has(kind) or parent == null:
		return null
	var gy: float = terrain.get_height(pos.x, pos.z) if terrain else 0.0
	if props and props.has_method("clear_area"):
		props.clear_area(Vector3(pos.x, gy, pos.z), PAD_RADIUS)
	if terrain and terrain.has_method("add_flat_zone"):
		terrain.add_flat_zone(pos.x, pos.z, PAD_RADIUS + 3.0, gy, PAD_RADIUS - 2.0)
	var root := Node3D.new()
	root.name = "Vignette_" + kind
	root.position = Vector3(pos.x, gy, pos.z)
	root.rotation.y = yaw
	parent.add_child(root)
	for row in VIGNETTES[kind]:
		if row[0] in O73Kit.TERMINALS or row[0] in O73Kit.FURNITURE or row[0] in O73Kit.SERVERS or row[0] in O73Kit.ARCHIVE:
			push_error("KitVignettes: '%s' is indoor kit, not placed in the forest (%s)" % [row[0], kind])
			continue
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(row[3])), Vector3(row[1], row[4], row[2]))
		var piece := O73Kit.spawn(row[0], root, xf)
		if piece and row[0] == &"relay_pylon":
			_kill_relay(piece)
	return root


## A dead mast: leaning on its failed guys, lamp and band dark.
static func _kill_relay(mast: Node3D) -> void:
	mast.rotation.x = deg_to_rad(DEAD_RELAY_TILT)
	var glow := O73Kit.own_material(mast, "kit_glow_pylon")
	if glow:
		glow.emission = Color.BLACK
