extends RefCounted
## capture.ps1 -Exec hook: spawns Outpost 73 in the dead forest at (0, 0, -40), door facing +Z, the way DeadForestEvent does
## (cleared props, flat pad). Blender (x, y, z) -> Godot (x, z, -40 - y): e.g. the pump jack plane is Godot z = -45.6.
## The route terminal (front wall, right of the door) is at (1.74, 1.87, -38.15), facing -Z. Env ROUTE_TERMINAL=ready
## (dosimeter taken) or set (route programmed) shows its later screens; default: locked.

func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	scene.get_node("DeadForestProps").clear_area(Vector3(0.0, 0.0, -40.0), 16.0)
	terrain.add_flat_zone(0.0, -40.0, 20.0, 0.0, 9.0)
	terrain.update_player_pos(Vector3(0.0, 0.0, -40.0))
	var bunker = ev.BUNKER_SCRIPT.new()
	bunker.build_bunker(terrain, 0.0, -40.0)
	ev.add_child(bunker)
	var mode := OS.get_environment("ROUTE_TERMINAL")
	if bunker.terminal and mode in ["ready", "set"]:
		bunker.terminal.unlock()
		if mode == "set":
			bunker.terminal.show_route(true)
