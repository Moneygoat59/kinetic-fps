extends RefCounted
## capture.ps1 -Exec hook for scenes/levels/silo_depths.tscn: stands the walker at one of the level's tunnel places (dev menu
## GO TO rows starting "Tunnels", $env:TUNNEL_PLACE = index, default 0: under the vent) so the tunnels' air is on for the
## shot. The capture camera still frames the shot (-Cam / -Look); the level's dev_places() prints where the places are.

func run(scene: Node, tree: SceneTree) -> void:
	scene.set_meta("spawn_tunnels", self)
	for i in 2:
		await tree.physics_frame
	var places: Array = scene.dev_places().filter(func(p: Array) -> bool: return String(p[0]).begins_with("Tunnels"))
	var i := clampi(int(OS.get_environment("TUNNEL_PLACE")) if OS.has_environment("TUNNEL_PLACE") else 0, 0, places.size() - 1)
	for p in places:
		print("TUNNEL PLACE ", p)
	if places.is_empty():
		return
	scene.player.global_position = places[i][1]
