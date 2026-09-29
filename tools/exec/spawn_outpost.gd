extends RefCounted
## capture.ps1 -Exec hook: spawns Outpost 02 or 03 ($env:OUTPOST = 2 | 3, default 2) in the dead forest at (0, 0, -40),
## door facing +Z, the way DeadForestEvent does (cleared props, flat pad, route colour). Same frame as spawn_outpost73.gd:
## Blender (x, y, z) -> Godot (x, z, -40 - y). $env:OUTPOST_TAKE = 1 takes the key (empty case, dim lamp).

func run(scene: Node, _tree: SceneTree) -> void:
	var id := int(OS.get_environment("OUTPOST")) if OS.has_environment("OUTPOST") else 2
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	scene.get_node("DeadForestProps").clear_area(Vector3(0.0, 0.0, -40.0), 24.0)
	terrain.add_flat_zone(0.0, -40.0, 20.0, 0.0, 10.0)
	terrain.update_player_pos(Vector3(0.0, 0.0, -40.0))
	var outpost = ev.OUTPOST_SCRIPT.new()
	outpost.build_outpost(terrain, 0.0, -40.0, id, HubRoutes.COLORS[HubRoutes.Route.W02 if id == 2 else HubRoutes.Route.W03])
	ev.add_child(outpost)
	if OS.get_environment("OUTPOST_TAKE") == "1":
		outpost.pickup.update_proximity(outpost.global_position, true)
