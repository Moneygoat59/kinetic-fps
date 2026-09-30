extends RefCounted
## capture.ps1 -Exec hook: spawns Relay Hub 00 in the dead forest at (0, 0, -40) the way DeadForestEvent does (cleared props,
## flat pad), turned so its door faces +Z. Blender (x, y, z) -> Godot (x, z, -40 - y): the router console is at (0, 0, -41.45),
## the routing wall at z = -43.5, the door at z = -35.1, corner masts at (+-12.2, 0, -40 -+ 10).
## Env HUB_STAGE=n (0..5) shows a later stage (routes online); the door is held open and the console/valves run.

func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	scene.get_node("DeadForestProps").clear_area(Vector3(0.0, 0.0, -40.0), 34.0)
	terrain.add_flat_zone(0.0, -40.0, 30.0, 0.0, 17.0)
	terrain.update_player_pos(Vector3(0.0, 0.0, -40.0))
	var hub = ev.HUB_SCRIPT.new()
	hub.build_hub(terrain, 0.0, -40.0, Vector3(-12.2, 0.0, -30.0))   # route 73 corner local (-12.2, 10): yaw 0
	ev.add_child(hub)
	var stage := int(OS.get_environment("HUB_STAGE")) if OS.has_environment("HUB_STAGE") else 0
	if stage > 0:
		hub.set_stage(stage)
	hub.routes.set_active(true)
	hub.console.set_active(true)
	hub.get("_door").request_open(true)
