class_name PlayerState
extends RefCounted

enum State {
	GROUND,
	AIR,
	SLIDE,
	GRAPPLE,
	DEAD
}

static func to_string_name(state: int) -> String:
	match state:
		0: return "GROUND"
		1: return "AIR"
		2: return "SLIDE"
		3: return "GRAPPLE"
		4: return "DEAD"
		_: return "UNKNOWN"
