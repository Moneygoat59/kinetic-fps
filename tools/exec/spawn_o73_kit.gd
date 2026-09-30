extends RefCounted
## capture.ps1 -Exec hook: sets up an abandoned relay post from the Outpost 73 prop kit in the dead forest around (30, 0, -30)
## (cleared props, flat pad): a pipe run into the ground, barriers, crates, a leaking drum, a field desk under a floodlight.
##   tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_o73_kit.gd -Cam 30,2.2,-19 -Look 30,0.8,-30 -Wait 4 -NoUi

const CENTER := Vector3(30.0, 0.0, -30.0)  # outside chunk (0,0): its spawn-clearing tree ring ignores exclusion zones
## [prop, offset from CENTER (x, z), yaw degrees, stacked height]
const SITE := [
	[&"pipe_elbow", Vector2(-5, -2), 180.0, 0.0], [&"pipe_straight", Vector2(-3, -2), 0.0, 0.0],
	[&"pipe_valve", Vector2(-1, -2), 0.0, 0.0], [&"pipe_straight", Vector2(1, -2), 0.0, 0.0],
	[&"pipe_riser", Vector2(3, -2), 0.0, 0.0],
	[&"barrier_concrete", Vector2(-3, 3), 0.0, 0.0], [&"barrier_concrete", Vector2(-1, 3), 0.0, 0.0],
	[&"barrier_concrete_broken", Vector2(1, 3), 0.0, 0.0],
	[&"crate_large", Vector2(-5.6, 2.2), 20.0, 0.0], [&"crate_small", Vector2(-5.6, 2.2), 35.0, 0.6],
	[&"drum_amber", Vector2(-6.8, 3.4), 60.0, 0.0], [&"amber_cell", Vector2(-4.6, 3.2), 0.0, 0.0],
	[&"table_steel", Vector2(5.2, 0.6), -70.0, 0.0], [&"chair_steel", Vector2(4.2, 1.2), 110.0, 0.0],
	[&"floodlight", Vector2(4.6, 4.2), 200.0, 0.0],
]


func run(scene: Node, _tree: SceneTree) -> void:
	var terrain = scene.get_node("DeadForestTerrain")
	var ground: float = terrain.get_height(CENTER.x, CENTER.z)
	scene.get_node("DeadForestProps").clear_area(CENTER, 11.0)
	terrain.add_flat_zone(CENTER.x, CENTER.z, 14.0, ground, 9.0)
	terrain.update_player_pos(CENTER)
	var site := Node3D.new()
	site.name = "O73KitSite"
	site.position = Vector3(CENTER.x, ground, CENTER.z)
	scene.add_child(site)
	var table: Node3D
	for row in SITE:
		var off: Vector2 = row[1]
		var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(row[2])), Vector3(off.x, row[3], off.y))
		var node := O73Kit.spawn(row[0], site, xf)
		if row[0] == &"table_steel":
			table = node
	if table:
		O73Kit.spawn(&"terminal_crt", table, Transform3D(Basis(), Vector3(0.05, O73Kit.TABLE_TOP, -0.03)))
