class_name TunnelMusic
extends Node
## Presenter for the underground line's music: a MusicZone playing the theme's three synchronised stems
## (tools/audio/tunnel_theme.py, audio/tunnel/tunnel_theme*.ogg). While the walker is inside the network it plays (the first
## visit hears the intro: the hum rising and one lone B); the layers follow them down the line by how far they are from the
## entry vent: DEEP (a low voice answers the motif) then STRAIN (a wrong copy of it). Placeholder rule until the route is
## planned: later it should follow the route (the cave-in, a pylon ALERT). TunnelNetwork owns it: update() every physics frame.

const BASE = preload("res://audio/tunnel/tunnel_theme.ogg")
const DEEP = preload("res://audio/tunnel/tunnel_theme_deep.ogg")
const STRAIN = preload("res://audio/tunnel/tunnel_theme_strain.ogg")
const LOUDNESS_DB := 0.0         # the stems carry the headroom: all three together peak at -1 dBFS
const DEEP_FROM := 60.0          # metres from the entry vent
const DEEP_FULL := 220.0
const STRAIN_FROM := 220.0
const STRAIN_FULL := 420.0
enum Layer { BASE, DEEP, STRAIN }

var zone := MusicZone.make(BASE, LOUDNESS_DB, 0.5, 1.0, [DEEP, STRAIN] as Array[AudioStream])


func _ready() -> void:
	add_child(zone)


## inside: the walker is within the network's bounds; from_entry: metres from the entry vent.
func update(inside: bool, from_entry: float) -> void:
	zone.update(0.0 if inside else INF)
	if zone.state != MusicZone.State.INSIDE:
		return
	zone.set_layer(Layer.DEEP, clampf(inverse_lerp(DEEP_FROM, DEEP_FULL, from_entry), 0.0, 1.0))
	zone.set_layer(Layer.STRAIN, clampf(inverse_lerp(STRAIN_FROM, STRAIN_FULL, from_entry), 0.0, 1.0))
