class_name TunnelRuns
extends RefCounted
## What each run of a tunnel network is made of: lists of tunnel kit piece names (8 m slots) for TunnelLine.lay. Runs are
## built from 4-slot blocks so the emergency pylons (in the refuges) light the way at a steady spacing:
##   PLAIN  straight, refuge, straight, straight          (a pylon 12 m into the block)
##   WIGGLE curve r, l, l, r  (or l, r, r, l)             (32 m on, back on line, no refuge: never two in a row)
## An open link is PLAIN, then PLAIN or a WIGGLE, then PLAIN ... ending in PLAIN; a caved link is two halves that meet at
## back-to-back cave-ins; a spur is a few slots and a cave-in; the vault run is one PLAIN block, the station and the
## records vault.
## Deterministic from the rng it is given.

const S := &"tunnel_straight"
const R := &"tunnel_refuge"
const CL := &"tunnel_curve_l"
const CR := &"tunnel_curve_r"
const V := &"tunnel_vent"
const C := &"tunnel_collapse"
const VAULT := &"tunnel_vault"
const STATION := &"tunnel_station"
const PLAIN: Array[StringName] = [S, R, S, S]
const WIGGLES: Array = [[CR, CL, CL, CR], [CL, CR, CR, CL]]
const WIGGLE_CHANCE := 0.6


## An open tunnel of `slots` 8 m slots (a multiple of 4) between two halls.
static func open(slots: int, rng: RandomNumberGenerator) -> Array[StringName]:
	var out: Array[StringName] = []
	var blocks := maxi(slots / 4, 1)
	var wiggled := true                       # the first block is always PLAIN
	for b in blocks:
		var last := b == blocks - 1
		if not wiggled and not last and rng.randf() < WIGGLE_CHANCE:
			out.append_array(WIGGLES[rng.randi_range(0, 1)])
			wiggled = true
		else:
			out.append_array(PLAIN)
			wiggled = false
	return out


## One half of a caved-in link: `slots` is the whole link, each hall lays half of it, ending in rubble at the middle.
static func caved_half(slots: int) -> Array[StringName]:
	return spur(slots / 2 - 1)


## `n` slots of tunnel and then the cave-in (n + 1 slots in all).
static func spur(n: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for i in n:
		out.append(PLAIN[i % PLAIN.size()])
	out.append(C)
	return out


## The run the vent drops into: from the first hall's entry mouth out to the vent piece, a refuge past it (its pylon
## lights where the walker lands), then rubble.
## Returns [pieces, index of the vent piece].
static func entry(before_vent: int) -> Array:
	var out: Array[StringName] = []
	for i in before_vent:
		out.append(PLAIN[i % PLAIN.size()])
	var at := out.size()
	out.append_array([V, R, C])
	return [out, at]


## The run out to the records vault: a PLAIN block, the station (its platform runs on into the vault's approach), then
## tunnel_vault (its own 10 m approach, buffer stop, dock and door; it ends the line).
static func vault() -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(PLAIN)
	out.append(STATION)
	out.append(VAULT)
	return out
