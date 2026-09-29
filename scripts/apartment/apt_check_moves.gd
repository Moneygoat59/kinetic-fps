extends RefCounted
## How each apartment check is done (AptCheck): where the walker leans in to look, and what their hand does to the piece.
## id (AptUses) -> {"look": piece-local point to look at (Godot axes; default the use marker), "near": metres to stop short
##                  of it (default AptCheck.NEAR; small things closer),
##                  "moves": [[pivot node, offset (m), rotation (deg, the node's local axes), times, seconds, hold]]}
## A move goes out to rest * (rotation, offset) and back `times` times, `seconds` a round trip, pausing `hold` seconds at the
## far end; moves run one after another, the use's sound on each. Pivot nodes are the kit pieces' PIVOT()s (origin on the
## turning axis, rest = identity rotation): tools/blender/apt/fixtures.py, kitchen.py, counter.py, smalls.py.

const Z := Vector3.ZERO

const SPECS := {
	# front door: unlock and relock each deadbolt, then try the knob (it holds)
	&"locks": {"look": Vector3(0.4, 1.3, 0.0), "moves": [
		[&"turn_bolt1", Z, Vector3(0, 0, -90), 1, 1.3, 0.35],
		[&"turn_bolt0", Z, Vector3(0, 0, -90), 1, 1.3, 0.35],
		[&"turn_knob", Z, Vector3(0, 0, 22), 2, 0.55, 0.1]]},
	# front door: the hand goes to the knob, turns it, and stops
	&"leave": {"look": Vector3(0.4, 0.97, 0.0), "moves": [
		[&"turn_knob", Z, Vector3(0, 0, 35), 1, 1.6, 0.6]]},
	# every knob pressed against OFF (they are taped there), left to right
	&"stove": {"look": Vector3(0.0, 1.02, 0.07), "moves": [
		[&"turn_knob0", Z, Vector3(0, 0, -14), 1, 0.6, 0.15], [&"turn_knob1", Z, Vector3(0, 0, -14), 1, 0.6, 0.15],
		[&"turn_knob2", Z, Vector3(0, 0, -14), 1, 0.6, 0.15], [&"turn_knob3", Z, Vector3(0, 0, -14), 1, 0.6, 0.15]]},
	# the lever pushed down hard, twice: off is off
	&"tap": {"look": Vector3(0.06, 0.99, 0.07), "near": 0.55, "moves": [
		[&"turn_lever", Z, Vector3(0, 0, -9), 2, 0.7, 0.2]]},
	# the toaster's plug lifted and turned to the light: not in the wall
	&"plugs": {"look": Vector3(0.05, 0.05, 0.16), "near": 0.55, "moves": [
		[&"lift_plug", Vector3(0.0, 0.07, 0.03), Vector3(-70, 0, 20), 1, 2.2, 1.0]]},
	# today's compartment shut and opened again: empty, taken
	&"pills": {"look": Vector3(0.04, 0.03, 0.0), "near": 0.5, "moves": [
		[&"flip_lid", Z, Vector3(90, 0, 0), 2, 1.1, 0.3]]},
	# the sash lock tugged against its tape
	&"window": {"look": Vector3(0.0, 1.63, -0.14), "near": 0.55, "moves": [
		[&"turn_latch", Z, Vector3(0, 12, 0), 2, 0.7, 0.15]]},
}


static func spec(id: StringName) -> Dictionary:
	return SPECS.get(id, {})
