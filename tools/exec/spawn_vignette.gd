extends RefCounted
## capture.ps1 -Exec hook: builds one KitVignettes scene (VIGNETTE) in the dead forest at (30, 0, -30).
##   tools\capture.ps1 -Scene res://scenes/levels/dead_forest.tscn -Exec res://tools/exec/spawn_vignette.gd -Cam 30,2.2,-22 -Look 30,0.6,-30 -Wait 4 -NoUi

const CENTER := Vector3(30.0, 0.0, -30.0)
const VIGNETTE := "drum_dump"


func run(scene: Node, _tree: SceneTree) -> void:
	var terrain = scene.get_node("DeadForestTerrain")
	terrain.update_player_pos(CENTER)
	KitVignettes.build(VIGNETTE, scene, terrain, scene.get_node("DeadForestProps"), CENTER, 0.0)
