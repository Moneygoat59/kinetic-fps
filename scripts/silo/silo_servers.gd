class_name SiloServers
extends RefCounted
## Missile Silo 00's data room (tools/blender/props/silo_servers.py), through the doorway in launch control's left wall at
## level 09: two rows of server racks, cable trays over them, the operator console (kit terminal_server) at the far end.
## The racks and trays are many copies of three kit pieces, so their static meshes are redrawn as a few batches (KitBatch);
## each rack keeps its own face (kit_scr_rack, animated by KitProp) and collision. The room is 20 m deep, past where the
## forest's pale depth fog starts (8 m), so its kit takes the bore's AbyssFog like the walls round it; live surfaces
## (screens, blinking lamps) keep their KitProp materials and ignore fog instead. The lamps are SiloAmbience's
## (marker_light_srv_*). Call once the silo is in the tree: SiloServers.dress(silo, model, rim_y, env, look).

const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const BATCHED: Array[StringName] = [&"server_rack", &"server_rack_open", &"cable_tray"]
const MARKER_TAG := "__srv"          # silo_servers.py names its kit markers marker_kit_<prop>__srv<n>


## Batches the racks and trays under `host`, then fogs the room's kit with `look` (MissileSilo.ABYSS_LOOK).
## Returns the MultiMeshInstance3D nodes it made.
static func dress(host: Node3D, model: Node3D, rim_y: float, env: Environment, look: Dictionary) -> Array[MultiMeshInstance3D]:
	if host == null or model == null:
		return []
	var pieces: Array[Node] = []
	var batched: Array[Node] = []
	for child in model.get_children():
		var marker_name := String(child.name)
		if not marker_name.begins_with(KitScript.PREFIX) or not marker_name.contains(MARKER_TAG):
			continue
		pieces.append(child)
		if StringName(marker_name.trim_prefix(KitScript.PREFIX).get_slice("__", 0)) in BATCHED:
			batched.append(child)
	var made := KitBatch.merge(host, batched)
	var fogged: Array[Node] = pieces.duplicate()
	fogged.append_array(made)
	AbyssFog.apply_many(fogged, rim_y, env, look, true)
	for piece in pieces:
		_unfog_live(piece)
	return made


## The surfaces AbyssFog left live (per-instance overrides) glow through the dark instead of greying in the forest's fog.
static func _unfog_live(piece: Node) -> void:
	for node in piece.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			var mat := mi.get_surface_override_material(i) as BaseMaterial3D
			if mat:
				mat.disable_fog = true
