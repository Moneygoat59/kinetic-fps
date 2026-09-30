class_name AptSqualor
extends RefCounted
## The flat gone to squalor (ForestNights "flat" = squalor, from night 4 on): weeks of not leaving. ApartmentLevel calls
## prepare(model) before furnishing, dress(host) after:
##   prepare  every marker_mess_* of the shell (rows in tools/blender/props/apartment_mess.py) becomes a marker_kit_* so the
##            rubbish is furnished like any other piece, and the tidy pieces in SWAPS turn into their neglected selves
##   dress    grime projected onto floors, walls and ceilings (AptGrime, GRIME), flies over what is rotting (FlySwarm, FLIES)
## Layout rows are in the plan's Blender coordinates (x east, y north, z up; Godot = (x, z, -y)), like apartment.py.

const MESS_PREFIX := "marker_mess_"
const KIT_PREFIX := "marker_kit_"
const SWAPS := {
	"window_blinds": "window_blinds_shut", "window_blinds_raised": "window_blinds_shut_check", "bed_double": "bed_unmade",
	"fruit_bowl": "fruit_bowl_rotten", "trash_bin": "trash_bin_full",
}
const FACING := {"+z": Vector3.UP, "-z": Vector3.DOWN, "+x": Vector3.RIGHT, "-x": Vector3.LEFT, "+y": Vector3.FORWARD,
	"-y": Vector3.BACK}
const H := 2.7                              # ceiling (apt_dims.CEILING); tabletops below (AptKit)
const D_TABLE := 0.75
const D_COFFEE := 0.42
const D_NIGHT := 0.56
const D_COUNTER := 0.92
## [kind, x, y, z, width, height, facing (the surface's normal, Blender axes), yaw, opacity(, depth)]
const GRIME := [
	# a film of dust and dirt over every floor
	[&"dust", 0.0, -1.7, 0.0, 10.0, 3.8, "+z", 0.0, 0.85], [&"dust", 3.02, 1.97, 0.0, 3.96, 3.26, "+z", 90.0, 0.9],
	[&"dust", -3.2, 1.97, 0.0, 3.6, 3.26, "+z", 180.0, 0.85], [&"dust", -0.18, 1.97, 0.0, 2.16, 3.26, "+z", 0.0, 0.9],
	# spills, dried sticky
	[&"spill", -3.2, -2.45, 0.0, 0.9, 0.7, "+z", 20.0, 1.0], [&"spill", 1.5, 2.9, 0.0, 0.9, 0.8, "+z", 0.0, 1.0],
	[&"spill", 4.0, 2.65, 0.0, 0.7, 0.6, "+z", 50.0, 1.0], [&"spill", -2.6, 2.2, 0.0, 0.6, 0.6, "+z", 0.0, 0.9],
	[&"spill", 2.4, -1.2, 0.0, 0.6, 0.5, "+z", 0.0, 1.0], [&"spill", 4.35, -1.9, 0.0, 0.9, 0.8, "+z", 140.0, 1.0],
	[&"spill", 1.1, -0.35, 0.0, 0.7, 0.6, "+z", 70.0, 1.0],
	# cup and can rings on every flat top
	[&"rings", 2.8, -1.7, D_TABLE, 0.8, 0.6, "+z", 0.0, 1.0], [&"rings", -3.7, -1.9, D_COFFEE, 1.0, 0.55, "+z", 30.0, 1.0],
	[&"rings", -2.55, 3.4, D_NIGHT, 0.4, 0.35, "+z", 0.0, 0.8], [&"rings", 3.9, 3.3, D_COUNTER, 0.8, 0.5, "+z", 0.0, 1.0],
	# crumbs where they eat
	[&"crumbs", -3.7, -2.45, 0.0, 1.4, 0.55, "+z", 0.0, 1.0], [&"crumbs", 2.8, -1.7, 0.0, 1.4, 1.2, "+z", 60.0, 1.0],
	[&"crumbs", -2.6, 1.9, 0.0, 0.8, 0.8, "+z", 0.0, 0.9], [&"crumbs", 3.0, 2.4, 0.0, 1.2, 0.9, "+z", 0.0, 1.0],
	# hand grime: round the switches, round the door they keep trying, where the head rests on the sofa
	[&"smudge", 5.0, -1.65, 1.15, 0.7, 0.6, "-x", 0.0, 1.0], [&"smudge", 5.0, -2.4, 1.05, 1.6, 1.4, "-x", 0.0, 1.0],
	[&"smudge", -2.68, 0.34, 1.15, 0.6, 0.5, "+y", 0.0, 1.0], [&"smudge", 1.3, 3.6, 0.55, 0.8, 0.7, "-y", 0.0, 1.0],
	[&"smudge", -3.7, -3.6, 0.95, 2.4, 0.6, "+y", 90.0, 0.8],
	# black mould in the wet corners
	[&"mould", -1.0, 3.3, H, 1.0, 0.8, "-z", 0.0, 1.0], [&"mould", -1.26, 3.2, 1.9, 0.8, 1.2, "+x", 0.0, 1.0],
	[&"mould", -0.9, 3.6, 1.3, 0.9, 0.8, "-y", 0.0, 0.9], [&"mould", 4.8, 3.4, H, 0.7, 0.6, "-z", 0.0, 1.0],
	[&"mould", -5.0, 2.8, 2.2, 0.5, 0.8, "+x", 0.0, 1.0],
	# the flat above has leaked
	[&"water", -1.0, -1.4, H, 1.6, 1.3, "-z", 30.0, 1.0], [&"water", -3.8, 2.0, H, 1.1, 1.0, "-z", 0.0, 1.0],
	# living room walls: condensation run under the sills, scuffs where the sofa and the bags lean, the door jambs handled,
	# a leak coming down the partition
	[&"streaks", -3.7, -3.6, 0.72, 1.3, 0.9, "+y", 0.0, 0.9], [&"streaks", -0.9, -3.6, 0.72, 1.3, 0.9, "+y", 0.0, 0.8],
	[&"streaks", 2.2, -3.6, 0.72, 1.3, 0.9, "+y", 0.0, 0.9], [&"streaks", -5.0, -1.6, 0.72, 1.3, 0.9, "+x", 0.0, 0.8],
	[&"smudge", -3.7, -3.6, 0.35, 2.6, 0.5, "+y", 90.0, 0.9], [&"smudge", 1.1, 0.2, 0.45, 1.4, 0.8, "-y", 90.0, 1.0],
	[&"smudge", -1.45, 0.2, 1.1, 0.5, 0.9, "-y", 0.0, 1.0], [&"smudge", 0.35, 0.2, 1.1, 0.5, 0.9, "-y", 0.0, 1.0],
	[&"smudge", 4.5, -3.6, 0.5, 1.4, 0.7, "+y", 90.0, 0.9], [&"water", 2.5, 0.2, 2.25, 1.1, 0.9, "-y", 0.0, 0.9],
	[&"streaks", 2.5, 0.2, 1.75, 0.9, 1.0, "-y", 0.0, 0.9], [&"mould", -5.0, -2.3, 2.35, 0.5, 0.7, "+x", 0.0, 0.9],
	[&"smudge", -2.6, 0.2, 1.3, 1.2, 1.0, "-y", 0.0, 0.9], [&"streaks", 3.6, 0.2, 1.4, 0.8, 1.2, "-y", 0.0, 0.9],
	[&"smudge", 5.0, -0.6, 1.0, 1.0, 1.0, "-x", 0.0, 0.9], [&"streaks", -2.3, -3.6, 1.5, 0.8, 1.4, "+y", 0.0, 0.8],
	# kitchen: grease run down behind the hob, handprints on the fridge and the cupboards, mould behind the bin
	[&"streaks", 4.02, 3.6, 1.25, 0.9, 0.7, "-y", 0.0, 1.0], [&"smudge", 4.2, 3.6, 1.15, 1.2, 0.5, "-y", 90.0, 0.9],
	[&"smudge", 1.86, 2.96, 1.05, 0.6, 1.2, "-y", 0.0, 0.9], [&"smudge", 3.0, 2.96, 0.45, 1.4, 0.6, "-y", 90.0, 0.8],
	[&"mould", 1.04, 3.45, 0.35, 0.5, 0.6, "+x", 0.0, 1.0], [&"smudge", 1.04, 1.6, 1.0, 1.1, 1.0, "+x", 0.0, 0.8],
	[&"streaks", 5.0, 2.0, 1.6, 0.8, 1.0, "-x", 0.0, 0.8],
	# bathroom: the bath wall black and running, the tub itself, round the toilet, the basin and the mirror, the floor
	[&"streaks", -0.46, 3.6, 0.95, 1.6, 0.7, "-y", 0.0, 1.0], [&"mould", -0.1, 3.6, 1.55, 0.8, 1.0, "-y", 0.0, 1.0],
	[&"mould", -0.95, 3.6, 0.75, 0.6, 0.5, "-y", 0.0, 0.9], [&"streaks", -1.26, 3.0, 1.15, 0.7, 1.2, "+x", 0.0, 1.0],
	[&"mould", -1.26, 2.6, 0.6, 0.5, 0.6, "+x", 0.0, 0.8], [&"spill", -0.46, 3.22, 0.25, 1.4, 0.6, "+z", 0.0, 0.9, 0.25],
	[&"spill", 0.62, 2.2, 0.0, 0.7, 0.6, "+z", 90.0, 1.0], [&"streaks", 0.9, 2.2, 0.75, 0.6, 0.8, "-x", 0.0, 1.0],
	[&"smudge", -1.0, 1.5, 0.84, 0.5, 0.7, "+z", 0.0, 1.0, 0.06], [&"smudge", -1.26, 1.5, 1.55, 0.5, 0.5, "+x", 0.0, 0.8],
	[&"mould", 0.8, 3.5, 0.0, 0.5, 0.5, "+z", 0.0, 0.9], [&"crumbs", -0.2, 1.2, 0.0, 1.0, 0.8, "+z", 0.0, 0.6],
	[&"smudge", 0.5, 0.34, 1.2, 0.6, 0.8, "+y", 0.0, 1.0], [&"streaks", -0.2, 0.34, 2.1, 1.2, 0.6, "+y", 0.0, 0.8],
	[&"smudge", -0.2, 2.0, 0.0, 2.1, 3.0, "+z", 0.0, 1.0], [&"streaks", 0.45, 2.2, 0.3, 0.5, 0.6, "-x", 0.0, 1.0, 0.35],
	[&"spill", 0.62, 2.2, 0.42, 0.45, 0.4, "+z", 0.0, 0.9, 0.08], [&"spill", -1.0, 1.5, 0.86, 0.45, 0.6, "+z", 30.0, 0.8, 0.08],
	[&"smudge", -0.76, 1.5, 0.45, 0.7, 0.7, "+x", 0.0, 1.0, 0.1], [&"streaks", -0.46, 2.85, 0.3, 1.5, 0.5, "-y", 0.0, 1.0, 0.1],
	[&"mould", 0.9, 3.3, 1.8, 0.7, 0.8, "-x", 0.0, 1.0], [&"streaks", 0.9, 2.9, 1.3, 0.8, 1.4, "-x", 0.0, 1.0],
	[&"smudge", 0.9, 1.6, 0.35, 1.2, 0.6, "-x", 90.0, 0.9], [&"mould", -1.26, 1.0, 2.3, 0.6, 0.7, "+x", 0.0, 0.9],
	# bedroom: beside the bed where the hand goes, the sill run, a leak on the north wall, the door jamb, scuffs low down
	[&"smudge", -2.7, 3.6, 0.85, 0.6, 0.6, "-y", 0.0, 1.0], [&"streaks", -5.0, 2.0, 0.72, 1.3, 0.9, "+x", 0.0, 0.9],
	[&"water", -4.5, 3.6, 2.25, 0.9, 0.9, "-y", 0.0, 0.9], [&"smudge", -1.4, 0.9, 1.1, 0.6, 0.8, "-x", 0.0, 1.0],
	[&"smudge", -3.5, 0.34, 0.3, 1.8, 0.4, "+y", 90.0, 0.8],
	[&"streaks", -1.9, 3.6, 1.3, 0.7, 1.2, "-y", 0.0, 0.9], [&"mould", -1.4, 3.2, 1.2, 0.5, 0.8, "-x", 0.0, 0.9],
	[&"smudge", -4.2, 0.34, 1.3, 1.0, 0.9, "+y", 0.0, 0.9],
]
## [x, y, z, radius, count]: flies over the bin, the fruit, the dishes, the pizza, the bags at the door, the bedside mug
const FLIES := [
	[1.28, 3.3, 0.72, 0.35, 8], [2.7, -1.62, 0.95, 0.4, 7], [4.6, 3.1, 1.15, 0.3, 6], [-3.8, -1.9, 0.62, 0.35, 6],
	[4.45, -1.2, 0.95, 0.55, 10], [-4.6, 3.2, 0.72, 0.2, 3], [4.55, 1.4, 0.9, 0.5, 8], [1.1, -0.35, 0.7, 0.4, 6],
]


## Before BunkerKit.furnish: turn the mess markers into kit markers and swap the tidy pieces. Returns how many changed.
static func prepare(model: Node3D) -> int:
	if model == null:
		return 0
	var changed := 0
	for child in model.get_children():
		var n := String(child.name)
		if n.begins_with(MESS_PREFIX):
			child.name = KIT_PREFIX + n.trim_prefix(MESS_PREFIX)
			changed += 1
		elif n.begins_with(KIT_PREFIX):
			var rest := n.trim_prefix(KIT_PREFIX)
			var piece := rest.get_slice("__", 0)
			if SWAPS.has(piece):
				child.name = KIT_PREFIX + SWAPS[piece] + rest.trim_prefix(piece)
				changed += 1
	return changed


## After furnishing: grime and flies under `host`.
static func dress(host: Node3D) -> void:
	if host == null:
		return
	for g in GRIME:
		AptGrime.make(host, g[0], _g(g[1], g[2], g[3]), Vector2(g[4], g[5]), FACING.get(g[6], Vector3.UP), g[7], g[8],
			g[9] if g.size() > 9 else AptGrime.DEPTH)
	for f in FLIES:
		FlySwarm.make(host, _g(f[0], f[1], f[2]), f[3], f[4])


static func _g(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, z, -y)
