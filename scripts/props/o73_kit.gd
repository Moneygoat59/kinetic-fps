class_name O73Kit
extends RefCounted
## Outpost 73 prop kit catalog: model paths and the placement constants the Blender builder uses
## (tools/blender/kit/kit_lib.py). Every prop's origin is its base centre and its front faces +Z.
##   O73Kit.spawn(&"terminal_crt", table, Transform3D(Basis(), Vector3(0, O73Kit.TABLE_TOP, 0)))

const DIR := "res://models/generated/o73_kit/"
const TABLE_TOP := 0.78      # tabletop props (terminal_crt, amber_cell) go on table_steel at this height
const GRID := 2.0            # pipes and barriers: 2 m cells, origin at the cell centre
const PIPE_Z := 0.5          # pipe centreline height
const DOSIMETER_HANG := 0.159  # dosimeter: grip underside above its base (it hangs from a hook there; kit_dims.py)
const TERMINALS: Array[StringName] = [&"terminal_crt", &"terminal_console", &"terminal_wall", &"terminal_mainframe",
	&"terminal_router"]
const FURNITURE: Array[StringName] = [&"table_steel", &"chair_steel", &"locker", &"shelf_rack", &"dosimeter_rack"]
const STORAGE: Array[StringName] = [&"crate_large", &"crate_small", &"drum_amber", &"amber_cell"]
const EQUIPMENT: Array[StringName] = [&"dosimeter", &"route_key"]   # carried items (no collision)
const INFRASTRUCTURE: Array[StringName] = [&"pipe_straight", &"pipe_elbow", &"pipe_valve", &"pipe_riser",
	&"barrier_concrete", &"barrier_concrete_broken", &"floodlight", &"relay_pylon"]
## Walkways (tools/blender/kit/walkways.py): stairs, landings, catwalks, gates, doors on a 2 m grid. opt_<part> nodes (rails)
## are dropped per placement with a __no_<part> marker suffix (bunker_kit.gd). door_blast runs on BunkerDoor.mount.
const STRUCTURE: Array[StringName] = [&"stair_flight", &"stair_flight_broken", &"stair_landing", &"catwalk_2m",
	&"gate_barred", &"door_blast"]
## Vent ducts (tools/blender/kit/ducts.py): crawl-through sheet-steel ducts on the same grid, crawling surface at y 0, runs
## along local Z; duct_mouth sits on a wall face (front +Z into the room) and carries marker_crawl (VentDuct.mount).
const DUCTS: Array[StringName] = [&"duct_straight", &"duct_bend", &"duct_mouth", &"duct_grille", &"duct_cap"]
## Server room (tools/blender/kit/servers.py): racks (0.6 x 1.0 m, optional part `risers` = cables up into a cable_tray),
## the operator console, a cooling unit and 2 m ceiling cable trays (origin = tray underside, hangers reach 0.8 m up).
## Indoor only.
const SERVERS: Array[StringName] = [&"server_rack", &"server_rack_open", &"terminal_server", &"crac_unit", &"cable_tray"]
## Rail tunnels (tools/blender/kit/tunnels.py, rail_props.py): the underground line. Each tunnel piece runs along its local -Z
## from its origin (entry face, tunnel centre, invert level) and carries marker_next at its exit: TunnelLine chains them.
## emergency_pylon stands in a tunnel_refuge's marker_refuge (EmergencyPylon drives it); rail_buffer sits on the track.
const TUNNELS: Array[StringName] = [&"tunnel_straight", &"tunnel_curve_l", &"tunnel_curve_r", &"tunnel_refuge",
	&"tunnel_vent", &"tunnel_bulkhead", &"tunnel_collapse", &"tunnel_junction", &"tunnel_vault", &"tunnel_station"]
const RAIL: Array[StringName] = [&"emergency_pylon", &"rail_buffer", &"platform_bench"]
## Records vault furniture (tools/blender/kit/archive.py, drawings.py; placed by tunnel_vault's kit markers). Indoor only.
## archive_stack = a mobile shelving carriage: front = the end panel with the crank, long axis along its local Z.
const ARCHIVE: Array[StringName] = [&"archive_stack", &"file_cabinet", &"file_cabinet_open", &"card_catalog", &"plan_chest",
	&"plan_chest_open", &"drafting_table", &"tube_rack"]
const TUN_LEN := 8.0         # kit_dims.py TUN_LEN: straight / curve / refuge / vent / collapse length (bulkhead: 2)
const TUN_CURVE_DEG := 15.0  # kit_dims.py TUN_CURVE_DEG: each curve piece turns this much
const TRACK_X := -0.6        # kit_dims.py TRACK_X: track centreline, left of the tunnel centre
const WALK_X0 := 1.75        # kit_dims.py WALK_X0 / WALK_Z: the raised walkway from here to the right wall
const WALK_Z := 0.7
const JUNC_R := 12.0         # kit_dims.py JUNC_R: tunnel_junction centre to each mouth plane
const DUCT_W := 1.2         # clear inside (kit_dims.py DUCT_W / DUCT_H): PlayerCrawl's stance fits in it
const DUCT_H := 1.0
const DUCT_MOUTH := 1.2      # kit_dims.py DUCT_MOUTH: duct_mouth's stub behind the wall face
const FLIGHT_RISE := 4.0     # stair_flight: 4 m up over an 8 m run, origin at its foot, climbing toward -Z
const FLIGHT_RUN := 8.0
## Wall props: back on their local z = 0 plane; place flush against a wall with +Z pointing into the room.
const WALL_PROPS: Array[StringName] = [&"terminal_wall", &"dosimeter_rack"]


static func path(prop: StringName, dir := DIR) -> String:
	return dir + String(prop) + ".glb"


## Instances `prop` under `parent` at `xform` (parent space). Returns null (with an error) for an unknown prop.
## `dir` picks the kit (another kit's folder, e.g. AptKit.DIR, uses the same placement contract).
static func spawn(prop: StringName, parent: Node, xform := Transform3D.IDENTITY, dir := DIR) -> Node3D:
	if parent == null:
		return null
	var scene := load(path(prop, dir)) as PackedScene
	if scene == null:
		push_error("O73Kit: no prop '%s' at %s" % [prop, path(prop, dir)])
		return null
	var node := scene.instantiate() as Node3D
	node.transform = xform
	parent.add_child(node)
	return node


## Per-instance copy of the first surface material named `mat_name` under `root` (set as that surface's override), so one
## prop's lamp or screen can change without touching every other instance. Returns null if no surface uses it.
static func own_material(root: Node, mat_name: String) -> BaseMaterial3D:
	if root == null:
		return null
	for node in [root] + root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat and mat.resource_name == mat_name:
				var own := mat.duplicate() as BaseMaterial3D
				mi.set_surface_override_material(i, own)
				return own
	return null
