extends RefCounted
## The apartment's interaction points (AptUse), keyed by the id in a kit piece's marker_use_<id> empty.
## id -> [title, sub (IDENTITY // STATE), sound path, trigger box size (m, Godot axes, centred on the marker),
##        optional repeat sub format (default REPEAT_SUB)]
## Checks repeat forever and remember how often they were made (the sub line shows it after the first); what a use leads to
## (sleep -> the forest) is up to whoever listens to AptUse.used (ApartmentLevel).

const SPECS := {
	&"locks": ["CHECK LOCKS", "FRONT DOOR  //  LOCKED", "res://audio/rpg/Audio/metalLatch.ogg", Vector3(0.5, 0.9, 0.2)],
	&"stove": ["CHECK STOVE", "RANGE  //  ALL OFF", "res://audio/ui/Audio/switch_003.ogg", Vector3(0.7, 0.2, 0.25)],
	&"tap": ["CHECK TAP", "KITCHEN SINK  //  OFF", "res://audio/rpg/Audio/metalClick.ogg", Vector3(0.3, 0.3, 0.3)],
	&"plugs": ["CHECK PLUGS", "TOASTER, KETTLE  //  UNPLUGGED", "res://audio/ui/Audio/click_002.ogg", Vector3(0.6, 0.3, 0.3)],
	&"pills": ["CHECK PILLS", "THURSDAY  //  TAKEN", "res://audio/rpg/Audio/handleSmallLeather.ogg", Vector3(0.3, 0.12, 0.2)],
	&"window": ["CHECK WINDOW", "LATCH  //  SHUT", "res://audio/rpg/Audio/metalClick.ogg", Vector3(0.5, 0.25, 0.25)],
	&"sleep": ["SLEEP", "BED  //  MADE", "res://audio/rpg/Audio/cloth2.ogg", Vector3(1.2, 0.5, 1.6)],
	# the front door's leaf beside the locks box: the walker never goes (AptThoughts.ALWAYS: their thought)
	&"leave": ["LEAVE", "FRONT DOOR  //  LOCKED", "res://audio/rpg/Audio/metalClick.ogg", Vector3(0.5, 1.7, 0.2),
		"%s  (TRIED %d)"],
	# the open journal (journal_open, set out by the couch wake): AptJournal lifts it and writes a line each time
	&"journal": ["REASSURE YOURSELF", "JOURNAL  //  OPEN", "res://audio/rpg/Audio/bookFlip2.ogg", Vector3(0.27, 0.08, 0.2),
		"%s  (WRITTEN %d)"],
}
const REPEAT_SUB := "%s  (CHECKED %d)"


static func spec(id: StringName) -> Array:
	return SPECS.get(id, [])
