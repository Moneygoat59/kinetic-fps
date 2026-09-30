class_name AptShadows
extends Node
## Interior shadow filtering, for as long as this node is in the tree (AptMood.apply adds one; any enclosed level can).
## The apartment's sun and lamps cast soft (PCSS) shadows through thin blind slats; the project's low filter quality leaves
## them grainy, medium smooths them for ~1 ms at 1080p. (8192 atlases and high quality looked the same and cost ~5 ms.)
## The setting is global, so leaving the tree puts the project's own value back and the forest keeps its budget.

const QUALITY := RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM
const DIR_KEY := "rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality"
const POS_KEY := "rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality"


func _enter_tree() -> void:
	RenderingServer.directional_soft_shadow_filter_set_quality(QUALITY)
	RenderingServer.positional_soft_shadow_filter_set_quality(QUALITY)


func _exit_tree() -> void:
	RenderingServer.directional_soft_shadow_filter_set_quality(ProjectSettings.get_setting(DIR_KEY, 2))
	RenderingServer.positional_soft_shadow_filter_set_quality(ProjectSettings.get_setting(POS_KEY, 2))
