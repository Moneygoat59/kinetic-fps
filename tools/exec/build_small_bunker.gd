extends RefCounted
## capture.ps1 -Exec hook: builds the procedural SmallBunker at the origin so it can be photographed.

func run(scene: Node, _tree: SceneTree) -> void:
	if scene.has_method("build_bunker"):
		scene.build_bunker(null, 0.0, 0.0)
