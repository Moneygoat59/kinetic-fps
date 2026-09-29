class_name AptThoughts
extends RefCounted
## What the walker thinks in the apartment (FieldHud.speak, their own voice), as data. ApartmentLevel calls:
##   woke(host, flat)          on arrival: the flat's thought (WAKE), WAKE_DELAY s in, once the room has faded up
##   used(host, id, count)     after every AptUse: a check's thought the first time it is ever made (FIRST_CHECK, remembered
##                             across visits by LevelFlow.first_time; without LevelFlow, the first time this visit), and the
##                             thoughts that come every time (ALWAYS: trying the front door)

const WAKE := {
	&"squalor": "I'm not sure if I have any food left...or money",
}
const FIRST_CHECK := {
	&"locks": "Locked. I heard it click. ...Did I hear it click?",
	&"stove": "All off. One left on and the whole building goes up. I'll check again later.",
	&"tap": "It's off. I can't hear it dripping. I don't think I can.",
	&"plugs": "Unplugged. Things catch fire when they're left plugged in. It happens.",
	&"pills": "Thursday's empty. Did I take it, or did I only open it?",
	&"window": "Latched. Nobody's getting in that way.",
}
const ALWAYS := {
	&"leave": "I shouldn't leave, something bad might happen",
}
const WAKE_DELAY := 3.2                      # s after arrival: the fade up (ApartmentLevel.FADE_IN) and a breath
const FLOW_PATH := ^"/root/LevelFlow"


static func woke(host: Node, flat: StringName) -> void:
	if host == null or not WAKE.has(flat) or not host.is_inside_tree():
		return
	host.get_tree().create_timer(WAKE_DELAY).timeout.connect(FieldHud.speak.bind(WAKE[flat]))


static func used(host: Node, id: StringName, count: int) -> void:
	if host == null:
		return
	if ALWAYS.has(id):
		FieldHud.speak(ALWAYS[id])
	elif FIRST_CHECK.has(id) and _first(host, id, count):
		FieldHud.speak(FIRST_CHECK[id])


static func _first(host: Node, id: StringName, count: int) -> bool:
	var flow := host.get_node_or_null(FLOW_PATH)
	if flow:
		return flow.first_time(StringName("check_" + String(id)))
	return count == 1
