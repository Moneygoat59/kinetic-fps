class_name MusicZone
extends Node
## A place's own music (the silo's theme, ...): while the player is inside, it replaces the background music, i.e. every
## AudioStreamPlayer in group MUSIC_GROUP (DeadForestManager's MusicPlayer) fades out and this fades in; leaving fades it
## out and hands back. Enter / exit radii differ so walking the edge does not flap. The first visit plays from the top
## (the stream's intro: the discovery); later visits start at the loop point (AudioStreamOggVorbis.loop_offset).
## Layers: stems of the same length and loop, started together so they stay in sync; the owner sets each one's weight
## (0..1, set_layer) and it eases there at LAYER_RATE. Layer 0 is the base, always 1. Owner calls update(distance) each
## frame. Not positional: it is the place's mood, not a sound source. Silo: SiloMusic (tools/audio/silo_theme.py).

signal entered()
signal exited()

const MUSIC_GROUP := &"music"
const SILENT := 0.0001           # -80 dB
const FADE_IN := 2.0
const FADE_OUT := 5.0
const HANDBACK := 6.0            # the background music eases back this slowly after leaving
const LAYER_RATE := 0.3          # weight per second: a layer takes ~3 s to come in fully
enum State { OUTSIDE, INSIDE }

var state := State.OUTSIDE
var enter_dist := 0.0
var exit_dist := 0.0
var loudness_db := 0.0
var presence := 0.0              # the zone's own fade, 0..1 (tweened), over every layer
var _players: Array[AudioStreamPlayer] = []
var _target := PackedFloat32Array()
var _weight := PackedFloat32Array()
var _visits := 0
var _background: Array[AudioStreamPlayer] = []
var _tween: Tween


static func make(theme: AudioStream, db: float, enter: float, exit: float, layers: Array[AudioStream] = []) -> MusicZone:
	var z := MusicZone.new()
	z.name = "MusicZone"
	z.loudness_db = db
	z.enter_dist = enter
	z.exit_dist = maxf(exit, enter)
	z._add_player(theme, 1.0)
	for layer in layers:
		z._add_player(layer, 0.0)
	return z


func _ready() -> void:
	set_process(false)


func update(distance: float) -> void:
	if _players.is_empty() or _players[0].stream == null:
		return
	if state == State.OUTSIDE and distance < enter_dist:
		_enter()
	elif state == State.INSIDE and distance > exit_dist:
		_exit()


## Layer i (1..) toward weight 0..1. The base (0) cannot be changed.
func set_layer(i: int, weight: float) -> void:
	if i <= 0 or i >= _target.size():
		return
	_target[i] = clampf(weight, 0.0, 1.0)


func _add_player(stream: AudioStream, weight: float) -> void:
	var p := AudioStreamPlayer.new()
	p.name = "Layer%d" % _players.size()
	p.stream = stream
	p.volume_db = linear_to_db(SILENT)
	add_child(p)
	_players.append(p)
	_target.append(weight)
	_weight.append(weight)


func _process(delta: float) -> void:
	var step := LAYER_RATE * clampf(delta, 0.0, 0.1)
	for i in _players.size():
		_weight[i] = move_toward(_weight[i], _target[i], step)
		_players[i].volume_db = loudness_db + linear_to_db(maxf(presence * _weight[i], SILENT))


func _enter() -> void:
	state = State.INSIDE
	_collect_background()
	var from := 0.0 if _visits == 0 else _loop_point()
	_visits += 1
	if from == 0.0:
		presence = 1.0                                   # the intro swells in by itself
	for i in _players.size():
		_weight[i] = _target[i]                          # arrive in the mix as it stands
		_players[i].play(from)
	_process(0.0)
	set_process(true)
	_fade(1.0, FADE_IN, linear_to_db(SILENT), FADE_OUT * 0.5)
	entered.emit()


func _exit() -> void:
	state = State.OUTSIDE
	_fade(0.0, FADE_OUT, 0.0, HANDBACK)
	_tween.tween_callback(_stopped)
	exited.emit()


func _stopped() -> void:
	for p in _players:
		p.stop()
	set_process(false)


## own: presence target; background_offset_db: added to each background player's own level (0 = back to normal).
func _fade(own: float, own_time: float, background_offset_db: float, background_time: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "presence", own, own_time)
	for music in _background:
		if is_instance_valid(music):
			var level := float(music.get_meta(&"zone_level_db")) + background_offset_db
			_tween.tween_property(music, "volume_db", level, background_time)
	_tween.chain()


func _collect_background() -> void:
	if not _background.is_empty():
		return
	for node in get_tree().get_nodes_in_group(MUSIC_GROUP):
		if node is AudioStreamPlayer:
			_background.append(node)
			node.set_meta(&"zone_level_db", node.volume_db)


func _loop_point() -> float:
	var ogg := _players[0].stream as AudioStreamOggVorbis
	return ogg.loop_offset if ogg else 0.0
