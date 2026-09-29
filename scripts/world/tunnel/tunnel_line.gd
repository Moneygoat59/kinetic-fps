class_name TunnelLine
extends RefCounted
## Lays a run of rail tunnel kit pieces (O73Kit.TUNNELS) end to end: each piece's origin goes on the previous piece's
## marker_next (its exit face and heading), so a line is just a list of piece names:
##   var pieces := TunnelLine.lay(self, start, [&"tunnel_bulkhead", &"tunnel_straight", &"tunnel_curve_r", &"tunnel_refuge"])
## `start` = where the first piece's entry face sits (parent space; the line runs along its -Z). A piece without
## marker_next (tunnel_collapse, tunnel_vault) ends the line: anything listed after it is skipped with a warning.
## A piece that carries kit markers (marker_kit_*: tunnel_vault's furniture) is furnished as it is laid (BunkerKit.furnish).
## Then: TunnelLine.exit(pieces) (where the line ends, for the next run or a portal), TunnelLine.pylons(pieces) (an
## EmergencyPylon in every refuge niche and on every marker_pylon*), TunnelLine.batch(root, pieces) (one draw per mesh
## for the whole run, furniture included; batch before adding pylons, or the batch swallows their bodies and their glow).

const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const NEXT := "marker_next"
const REFUGE := "marker_refuge"
const PYLON := "marker_pylon"


static func lay(parent: Node3D, start: Transform3D, names: Array[StringName]) -> Array[Node3D]:
	var placed: Array[Node3D] = []
	if parent == null:
		return placed
	var at := start
	for i in names.size():
		var piece := O73Kit.spawn(names[i], parent, at)
		if piece == null:
			return placed
		piece.name = "%s_%02d" % [names[i], i]
		placed.append(piece)
		KitScript.furnish(piece)
		var next := piece.get_node_or_null(NEXT) as Node3D
		if next == null:
			if i < names.size() - 1:
				push_warning("TunnelLine: %s ends the line; %d piece(s) after it skipped" % [names[i], names.size() - 1 - i])
			return placed
		at = at * next.transform
	return placed


## Where the line ends (parent space): the last piece's marker_next, or its own transform if it has none.
static func exit(pieces: Array[Node3D]) -> Transform3D:
	if pieces.is_empty():
		return Transform3D.IDENTITY
	var last := pieces.back() as Node3D
	var next := last.get_node_or_null(NEXT) as Node3D
	return last.transform * next.transform if next else last.transform


## An EmergencyPylon in every tunnel_refuge's niche (at marker_refuge, facing the track) and on every marker_pylon* of a
## piece (tunnel_vault's dock and door), added under the piece.
static func pylons(pieces: Array[Node3D], state := EmergencyPylon.State.STANDBY) -> Array[EmergencyPylon]:
	var made: Array[EmergencyPylon] = []
	for piece in pieces:
		if piece == null:
			continue
		for child in piece.get_children():
			var marker_name := String(child.name)
			if not (child is Node3D and (marker_name == REFUGE or marker_name.begins_with(PYLON))):
				continue
			var pylon := EmergencyPylon.new()
			pylon.state = state
			pylon.transform = (child as Node3D).transform
			piece.add_child(pylon)
			made.append(pylon)
	return made


## Redraws the pieces' static meshes as MultiMeshes under `root` (KitBatch). Near runs only: a batch is culled as one box.
static func batch(root: Node3D, pieces: Array[Node3D]) -> Array[MultiMeshInstance3D]:
	var sources: Array[Node] = []
	sources.assign(pieces)
	return KitBatch.merge(root, sources)
