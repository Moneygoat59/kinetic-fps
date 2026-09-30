extends RefCounted
## capture.ps1 -Exec hook: puts the night-2 wraith (Wraith) in the forest, fully present, facing +Z.
##   tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_wraith.gd -Cam 0,1.6,6 -Look 0,1.8,0 -Wait 4 -NoUi
## Env WRAITH_POS=x,z (default 0,0), WRAITH_REACH=0..1 (arms), WRAITH_PRESENCE=0..1.

func run(scene: Node, tree: SceneTree) -> void:
	var terrain := scene.get_node_or_null("DeadForestTerrain") as Node3D
	var xz := Vector2.ZERO
	if OS.has_environment("WRAITH_POS"):
		var p := OS.get_environment("WRAITH_POS").split(",")
		xz = Vector2(float(p[0]), float(p[1]))
	var w := Wraith.new()
	w.terrain = terrain
	scene.add_child(w)
	w.appear(Vector3(xz.x, 0.0, xz.y), Vector3(xz.x, 0.0, xz.y + 10.0), 0.05)   # faces +Z (put the camera there)
	await tree.process_frame
	await tree.create_timer(0.2).timeout
	w.view.set_presence(float(OS.get_environment("WRAITH_PRESENCE")) if OS.has_environment("WRAITH_PRESENCE") else 1.0)
	w.view.reach = float(OS.get_environment("WRAITH_REACH")) if OS.has_environment("WRAITH_REACH") else 0.0
