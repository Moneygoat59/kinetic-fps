class_name DevWarps
extends RefCounted
## The dev menu's JUMP list: points in the story to arrive at, each a level plus the visit history it is built from
## (LevelFlow.warp). The forest reads its night from visits(forest) (ForestNights.current); the apartment reads its mood
## from visits(apartment) (ApartmentLevel.MOOD_BY_VISIT) and where the walker wakes from the night just ended (visits(forest)).
## Add a jump = one row: [label, level, {level: visits}].

const WARPS := [
	["Apartment  -  first day", &"apartment", {&"apartment": 0, &"forest": 0}],
	["Apartment  -  evening", &"apartment", {&"apartment": 1, &"forest": 1}],
	["Apartment  -  couch, small hours", &"apartment", {&"apartment": 3, &"forest": 3}],
	["Apartment  -  after the crash, squalor", &"apartment", {&"apartment": 5, &"forest": 4}],
	["Night 1  -  silent, trip 50 m", &"forest", {&"apartment": 1, &"forest": 1}],
	["Night 2  -  wind, trip 150 m", &"forest", {&"apartment": 2, &"forest": 2}],
	["Night 3  -  the wraith", &"forest", {&"apartment": 3, &"forest": 3}],
	["Night 4  -  full forest, the lift crash", &"forest", {&"apartment": 4, &"forest": 4}],
	["Night 5  -  full forest", &"forest", {&"apartment": 5, &"forest": 5}],
	["Silo depths  -  woke in the wrecked lift", &"silo", {&"apartment": 5, &"forest": 4, &"silo": 1}],
]
const FLOW_PATH := ^"/root/LevelFlow"


static func count() -> int:
	return WARPS.size()


static func label(i: int) -> String:
	return WARPS[i][0] if i >= 0 and i < WARPS.size() else ""


## Starts the jump; false if the index is bad, LevelFlow is missing or a transition is already running.
static func jump(tree: SceneTree, i: int) -> bool:
	if tree == null or i < 0 or i >= WARPS.size():
		return false
	var flow := tree.root.get_node_or_null(FLOW_PATH)
	if flow == null:
		return false
	return flow.warp(WARPS[i][1], WARPS[i][2])


## One line on where the walker is: "FOREST  night 3" / "APARTMENT  visit 2, woke on the couch".
static func status(tree: SceneTree) -> String:
	if tree == null or tree.current_scene == null:
		return "-"
	var flow := tree.root.get_node_or_null(FLOW_PATH)
	var level := _level_of(tree, flow)
	if level == &"forest":
		var night := ForestNights.current(tree)
		return "FOREST  night %d%s" % [night, "" if flow and flow.visits(&"forest") > 0 else " (direct run)"]
	if level == &"apartment":
		var visit: int = flow.visits(&"apartment") if flow else 0
		var wake: StringName = ForestNights.woke_from(tree).get("wake", &"bed")
		return "APARTMENT  visit %d, woke in %s" % [visit, "bed" if wake == &"bed" else "the " + String(wake)]
	if level == &"silo":
		return "SILO DEPTHS  visit %d" % (flow.visits(&"silo") if flow else 0)
	return tree.current_scene.scene_file_path.get_file().get_basename().to_upper()


## The level the running scene is (LevelFlow.current when it got there by go/warp, else matched by file).
static func _level_of(tree: SceneTree, flow: Node) -> StringName:
	var path := tree.current_scene.scene_file_path
	if flow:
		for level in flow.LEVELS:
			if flow.LEVELS[level] == path:
				return level
	return &""
