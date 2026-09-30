class_name SiloHallEar
extends RefCounted
## How much of the generator hall's sound the walker can hear from where they stand (0 sealed .. 1 in the room), so the
## machines respect walls: SiloGeneratorSound feeds it to its MuffleBus. In the hall (and the lift shaft to it) the room is
## open; the vent duct opens onto the hall, so a fraction gets down it; the pit behind the blast door is shut off, and only
## a door that is open lets much through (`pit_door` = its BunkerDoor.factor, 0 shut .. 1 open); under the rock outside the
## hall's walls, and in the tunnels (`sealed`, set by TunnelNetwork while the walker is inside it), nothing gets through.
## Anywhere else (up the lift shaft, the forest) the sound keeps its plain distance fall-off.

const VENT := 0.5
const PIT_SHUT := 0.08
const PIT_OPEN := 0.55


## local: the walker in silo space.
static func openness(local: Vector3, pit_door: float, sealed: bool) -> float:
	if sealed:
		return 0.0
	if SiloPit.in_pit(local):
		return lerpf(PIT_SHUT, PIT_OPEN, clampf(pit_door, 0.0, 1.0))
	if SiloGenerators.in_hall(local):
		return 1.0
	if SiloGenerators.in_vent(local):
		return VENT
	if local.y < SiloGenerators.HALL_TOP and Vector2(local.x, local.z).length() > SiloGenerators.HALL_RADII.y:
		return 0.0
	return 1.0
