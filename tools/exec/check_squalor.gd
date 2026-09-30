extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the apartment gone to squalor (AptSqualor). Builds the flat twice beside
## the forest, kept and squalor (ApartmentLevel.flat), and checks: the kept flat spawns no mess; in squalor every mess marker
## became a spawned piece (none missing from the kit), the tidy pieces were swapped, the grime and flies are there, the night
## data asks for it after the crash, and no mess that collides stands on the walker's routes (door to door, bed to window).

const APT := preload("res://scenes/levels/apartment.tscn")
const WALKER := 0.32                        # capsule radius (the player is 0.8 wide; a little slack for the scuffing)
## Blender plan points (x east, y north) along the routes that must stay open
const ROUTE := [[-2.3, 1.05], [-2.0, 0.6], [-2.0, 0.0], [-2.0, -0.8], [-0.2, -0.8], [-0.2, 0.0], [-0.2, 0.8], [-0.2, 1.6],
	[1.0, -1.0], [2.9, -0.6], [2.9, 0.3], [3.0, 1.2], [3.2, 2.5], [3.8, -2.4], [4.4, -2.4], [-3.5, 1.2], [-4.62, 2.0]]


func run(scene: Node, tree: SceneTree) -> void:
	scene.set_meta("squalor_check", self)
	tree.set_meta("capture_hold", true)
	var kept := _flat(scene, &"kept", Vector3(0, -200, 0))
	var foul := _flat(scene, &"squalor", Vector3(0, -400, 0))
	for i in 5:
		await tree.physics_frame
	_check("the kept flat spawns no mess", _mess_spawned(kept) == 0 and _count(kept, "marker_mess_") > 0)
	_check("squalor turned every mess marker into a piece (%d)" % _mess_spawned(foul), _count(foul, "marker_mess_") == 0
		and _mess_spawned(foul) >= 40)
	var missing := _missing(foul)
	_check("every kit marker in squalor has its piece %s" % [missing], missing.is_empty())
	var swapped := true
	for piece in AptSqualor.SWAPS:
		swapped = swapped and _count(foul.model, "marker_kit_" + piece + "__") == 0
	_check("the tidy pieces were swapped (bed, bowl, bin, blinds)", swapped and _count(foul.model, "marker_kit_bed_unmade") == 1)
	_check("grime and flies laid (%d decals, %d swarms)" % [foul.find_children("*", "Decal", true, false).size(),
		foul.find_children("*", "GPUParticles3D", true, false).size()],
		foul.find_children("*", "Decal", true, false).size() == AptSqualor.GRIME.size()
		and foul.find_children("*", "GPUParticles3D", true, false).size() == AptSqualor.FLIES.size())
	var buzzes := foul.find_children("*", "FlyBuzz", true, false)
	_check("every swarm has its own buzz, silent at the start (%d)" % buzzes.size(), buzzes.size() == AptSqualor.FLIES.size()
		and buzzes.all(func(b: FlyBuzz) -> bool: return not b.playing and b.state == FlyBuzz.State.SILENT))
	_check("the night after the crash wakes to squalor", ForestNights.spec(4).get("flat") == &"squalor"
		and ForestNights.spec(3).get("flat", &"kept") == &"kept")
	var blocked := _blocked(foul)
	_check("no colliding mess on the routes %s" % [blocked], blocked.is_empty())
	kept.queue_free()
	foul.queue_free()
	tree.set_meta("capture_hold", false)


func _flat(scene: Node, flat: StringName, at: Vector3) -> ApartmentLevel:
	var apt := APT.instantiate() as ApartmentLevel
	apt.flat = flat
	apt.position = at
	scene.add_child(apt)
	return apt


func _count(root: Node, prefix: String) -> int:
	var n := 0
	for child in (root.model if root is ApartmentLevel else root).get_children():
		n += 1 if String(child.name).begins_with(prefix) else 0
	return n


func _mess_spawned(apt: ApartmentLevel) -> int:
	var n := 0
	for child in apt.model.get_children():
		var name := String(child.name)
		if name.begins_with("marker_kit_") and child.get_child_count() > 0:
			n += 1 if AptKit.MESS.has(StringName(name.trim_prefix("marker_kit_").get_slice("__", 0))) else 0
	return n


func _missing(apt: ApartmentLevel) -> Array:
	var out := []
	for child in apt.model.get_children():
		if String(child.name).begins_with("marker_kit_") and child.get_child_count() == 0:
			out.append(String(child.name))
	return out


func _blocked(apt: ApartmentLevel) -> Array:
	var space := apt.get_world_3d().direct_space_state
	var shape := CapsuleShape3D.new()
	shape.radius = WALKER
	shape.height = 1.6
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	var out := []
	for p in ROUTE:
		q.transform = Transform3D(Basis(), apt.global_position + Vector3(p[0], 0.9, -p[1]))
		for hit in space.intersect_shape(q, 8):
			var piece := _piece_of(hit["collider"])
			if AptKit.MESS.has(piece):
				out.append("%s at %s" % [piece, p])
	return out


func _piece_of(node: Node) -> StringName:
	while node:
		var name := String(node.name)
		if name.begins_with("marker_kit_"):
			return StringName(name.trim_prefix("marker_kit_").get_slice("__", 0))
		node = node.get_parent()
	return &""


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
