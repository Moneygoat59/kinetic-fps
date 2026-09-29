extends RefCounted
## Furnishes the Outpost 73 interior with prop-kit pieces (scripts/props/o73_kit.gd): one live prop under every
## marker_kit_<prop>__<n>[__no_<part>...][__drive_<id>] empty of the model (placement + yaw set in the building generator's
## KIT rows; __no_<part> drops that piece's optional opt_<part>, e.g. a landing rail where a bridge or deck joins;
## __drive_<id> makes the piece a usable TerminalStation showing res://content/terminals/<id>.tres).
## Each piece brings its own collision, screens, lamps and lights (KitProp).

const PREFIX := "marker_kit_"

## Kept loaded so building the bunker mid-game does not hit the disk for each piece.
static var _held: Array[PackedScene] = []


static func preload_props() -> void:
	if not _held.is_empty():
		return
	for group in [O73Kit.TERMINALS, O73Kit.FURNITURE, O73Kit.STORAGE, O73Kit.STRUCTURE, O73Kit.DUCTS, O73Kit.SERVERS,
			O73Kit.ARCHIVE]:
		for prop in group:
			var scene := load(O73Kit.path(prop)) as PackedScene
			if scene:
				_held.append(scene)


## Spawns the kit pieces under their markers. Returns how many were placed. `dir` = the kit folder the pieces come from
## (O73Kit.DIR, AptKit.DIR).
static func furnish(model: Node3D, dir := O73Kit.DIR) -> int:
	if model == null:
		return 0
	var placed := 0
	for child in model.get_children():
		var marker_name := String(child.name)
		if not (child is Node3D and marker_name.begins_with(PREFIX)):
			continue
		var parts := marker_name.trim_prefix(PREFIX).split("__")
		var piece := O73Kit.spawn(StringName(parts[0]), child, Transform3D.IDENTITY, dir)
		if piece == null:
			continue
		placed += 1
		for flag in parts.slice(2):                        # __no_<part>: drop the piece's opt_<part> nodes (and their collision)
			if flag.begins_with("no_"):
				drop_part(piece, flag.trim_prefix("no_"))
			elif flag.begins_with("drive_"):               # __drive_<id>: a usable terminal (res://content/terminals/<id>.tres)
				TerminalStation.mount(piece, TerminalStation.load_drive(flag.trim_prefix("drive_")))
	return placed


## Removes a kit piece's optional part `part` (nodes opt_<part>, opt_<part>_col). Returns how many nodes went.
static func drop_part(piece: Node, part: String) -> int:
	if piece == null or part.is_empty():
		return 0
	var dropped := 0
	for node in piece.get_children():
		if String(node.name).begins_with("opt_" + part):
			piece.remove_child(node)
			node.free()
			dropped += 1
	return dropped
