extends RefCounted
## capture.ps1 -Exec hook: spawns Missile Silo 00 in the dead forest at (0, 0, -400) the way DeadForestEvent does (cleared
## props, flat apron, terrain hole over the bore), turned so its front (stair head, approach) faces +Z.
## Blender (x, y, z) -> Godot (x, z, -400 - y) (far from the spawn clearing at the origin). The player is moved to the
## approach point (terrain streams round the player). SILO_NOFOG=1 turns the level fog off (layout shots); SILO_ENGAGE=1
## completes the launch override (alarm state); SILO_HALL=1 stands the player on the generator hall floor instead (the
## hall's SkyZone hides the moon, as in game); SILO_LIFT=<0..1> parks the lift cage that far down its travel.

const CENTER := Vector3(0.0, 0.0, -400.0)
const HALL_SPOT := Vector3(-50.6, -119.4, 42.4)    # silo space (Godot local): hall floor between generators 0 and 1


func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var terrain = scene.get_node("DeadForestTerrain")
	var s = ev.SILO_SCRIPT
	scene.get_node("DeadForestProps").clear_area(CENTER, s.CLEAR_RADIUS)
	terrain.add_flat_zone(CENTER.x, CENTER.z, s.FLAT_RADIUS, 0.0, s.FLAT_INNER)
	terrain.add_hole(CENTER.x, CENTER.z, s.HOLE_RADIUS, s.HOLE_SINK, s.PIT_DEPTH)
	terrain.update_player_pos(CENTER + Vector3(0.0, 0.0, s.APPROACH))
	var silo = s.new()
	silo.build_silo(terrain, CENTER.x, CENTER.z, scene.get_node("DeadForestProps"))
	ev.add_child(silo)
	if OS.has_environment("SILO_NOFOG"):
		scene.get_node("WorldEnvironment").environment.fog_enabled = false
	var at: Vector3 = silo.to_global(HALL_SPOT) if OS.has_environment("SILO_HALL") else CENTER
	silo.check_interaction(at, OS.has_environment("SILO_ENGAGE"))
	print("SILO lights=%d spots=%d kit=%d" % [silo.find_children("*", "OmniLight3D", true, false).size(),
		silo.find_children("*", "SpotLight3D", true, false).size(), silo.find_children("marker_kit_*", "", true, false).size()])
	if OS.has_environment("SILO_LIFT") and silo.lift:
		silo.lift._body.position.y = -silo.lift.drop * clampf(float(OS.get_environment("SILO_LIFT")), 0.0, 1.0)
	if ev.player:
		ev.player.global_position = CENTER + Vector3(0.0, 0.5, s.APPROACH)
		if OS.has_environment("SILO_HALL"):
			ev.player.global_position = silo.to_global(HALL_SPOT)
