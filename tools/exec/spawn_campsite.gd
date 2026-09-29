extends RefCounted
## capture.ps1 -Exec hook: builds the abandoned campsite (AbandonedCampsite) in the dead forest at (30, 0, -30).
##   tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_campsite.gd -Cam 30,2.2,-21 -Look 30,0.5,-30 -Wait 4 -NoUi

const CENTER := Vector3(30.0, 0.0, -30.0)


func run(scene: Node, _tree: SceneTree) -> void:
	var terrain = scene.get_node("DeadForestTerrain")
	terrain.update_player_pos(CENTER)
	var props = scene.get_node("DeadForestProps")
	var gy: float = terrain.get_height(CENTER.x, CENTER.z)
	props.clear_area(Vector3(CENTER.x, gy, CENTER.z), 14.0)
	terrain.add_flat_zone(CENTER.x, CENTER.z, 18.0, gy, 9.5)
	var camp := AbandonedCampsite.new()
	camp.build_campsite(terrain, CENTER.x, CENTER.z)
	scene.add_child(camp)
