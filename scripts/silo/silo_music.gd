class_name SiloMusic
extends Node
## Presenter for Missile Silo 00's music: a MusicZone playing the theme's four synchronised stems (tools/audio/silo_theme.py,
## audio/silo/silo_theme*.ogg). Inside ENTER the base replaces the forest's music (its intro is the discovery); the layers
## follow the walker in: DEEP comes up with depth below the rim (all of it by level 09), CORE over the last stretch down to
## level 09 and the launch control, ALARM once the override is engaged (and stays). Climbing back out calms it again.
## MissileSilo owns it: update(rim, player_pos) every frame, alarm() when the console engages.

const BASE = preload("res://audio/silo/silo_theme.ogg")
const DEEP = preload("res://audio/silo/silo_theme_deep.ogg")
const CORE = preload("res://audio/silo/silo_theme_core.ogg")
const ALARM = preload("res://audio/silo/silo_theme_alarm.ogg")
const LOUDNESS_DB := 0.0         # the stems carry the headroom: all four together peak at -1 dBFS
const ENTER := 124.0             # just inside the blast clearing: the trees open and the bore is in front of you
const EXIT := 150.0              # back in the trees before the forest's music returns
const LEVEL_09_DEPTH := 36.0     # metres below the rim: the deck and the launch control
const CORE_FROM := 22.0          # the core starts coming in this far down
enum Layer { BASE, DEEP, CORE, ALARM }
enum Mode { IDLE, ALARM }

var zone := MusicZone.make(BASE, LOUDNESS_DB, ENTER, EXIT, [DEEP, CORE, ALARM] as Array[AudioStream])
var _mode := Mode.IDLE


func _ready() -> void:
	add_child(zone)


## rim: the bore's centre at rim height (world).
func update(rim: Vector3, player_pos: Vector3) -> void:
	zone.update(rim.distance_to(player_pos))
	if zone.state != MusicZone.State.INSIDE:
		return
	var depth := rim.y - player_pos.y
	zone.set_layer(Layer.DEEP, clampf(depth / LEVEL_09_DEPTH, 0.0, 1.0))
	zone.set_layer(Layer.CORE, clampf((depth - CORE_FROM) / (LEVEL_09_DEPTH - CORE_FROM), 0.0, 1.0))
	zone.set_layer(Layer.ALARM, 1.0 if _mode == Mode.ALARM else 0.0)


func alarm() -> void:
	_mode = Mode.ALARM
