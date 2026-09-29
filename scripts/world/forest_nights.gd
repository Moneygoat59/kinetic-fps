class_name ForestNights
extends RefCounted
## What each night in the dead forest holds. Night n = the n-th time the walker fell asleep in the apartment
## (LevelFlow.visits(&"forest")); later nights repeat the last one. A run that opens the forest directly (editor, tools)
## gets the full forest (FULL), so development is unchanged.
##   wind / music   the manager's ambience          event    buildings, relay chains, campsite (DeadForestEvent)
##   monster        the wraith stalks the walker (WraithStalk)   ending   how the dream lets go (ForestNightDirector):
##                  TRIP after trip_at metres, CAUGHT by the wraith, CRASH in the silo's freight lift (SiloLiftCrash)
##   drink          whether the amber pools can be drunk (AmberPool)
##   wake           where the walker comes to in the apartment afterwards (ApartmentLevel: bed, or couch = the small hours,
##                  slumped in front of a TV showing static)
##   flat           the state of the apartment they wake to (optional, default kept; squalor = AptSqualor: weeks of not
##                  leaving, rubbish everywhere, blinds shut)
##   sleep          where sleeping in the apartment after this night leads (optional, default the forest's next night;
##                  silo = SiloDepthsLevel: coming to in the wrecked lift at the foot of the silo)

enum Ending { NONE, TRIP, CAUGHT, CRASH }

const NIGHTS := {
	# first night: silence, just the trees; after trip_at metres of walking the walker trips, hits the ground and wakes
	# the walker will not touch the amber yet
	1: {"wind": false, "music": false, "event": false, "monster": false, "ending": Ending.TRIP, "trip_at": 50.0, "drink": false, "wake": &"bed"},
	# second night: the wind is up and the walk goes further; the amber can be drunk now; the walker trips again at trip_at
	2: {"wind": true, "music": false, "event": false, "monster": false, "ending": Ending.TRIP, "trip_at": 150.0, "drink": true, "wake": &"bed"},
	# third night: nothing built out here, only something that follows, nearer each time; being taken wakes the walker, on
	# the couch in the middle of the night with the TV showing static
	3: {"wind": true, "music": false, "event": false, "monster": true, "ending": Ending.CAUGHT, "trip_at": 0.0, "drink": true,
		"wake": &"couch"},
	# fourth night: the forest as it is, all of it, down to Missile Silo 00; riding its freight lift down from launch control
	# is the end: the cage seizes, snaps, catches on its brakes and falls the rest of the shaft, and the walker wakes in bed;
	# the next sleep does not go back to the forest: they come to in the wrecked cage at the bottom of the silo
	4: {"wind": true, "music": true, "event": true, "monster": false, "ending": Ending.CRASH, "trip_at": 0.0, "drink": true,
		"wake": &"bed", "flat": &"squalor", "sleep": &"silo"},
	# fifth night on: the whole forest again, with no way out of the dream
	5: {"wind": true, "music": true, "event": true, "monster": false, "ending": Ending.NONE, "trip_at": 0.0, "drink": true, "wake": &"bed",
		"flat": &"squalor"},
}
const FULL := 5
const FLOW_PATH := ^"/root/LevelFlow"


static func current(tree: SceneTree) -> int:
	var flow := tree.root.get_node_or_null(FLOW_PATH) if tree else null
	var visits: int = flow.visits(&"forest") if flow else 0
	return FULL if visits <= 0 else mini(visits, FULL)


## The night the walker has just come back from (its spec), or {} if they have not been to the forest yet.
static func woke_from(tree: SceneTree) -> Dictionary:
	var flow := tree.root.get_node_or_null(FLOW_PATH) if tree else null
	var visits: int = flow.visits(&"forest") if flow else 0
	return {} if visits <= 0 else spec(visits)


static func spec(night: int) -> Dictionary:
	return NIGHTS.get(clampi(night, 1, FULL), NIGHTS[FULL])
