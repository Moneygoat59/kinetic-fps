class_name HearingReturn
extends Node
## Coming to after a blow (the silo depths, after the lift crash): the ears ring (audio/silo/ears_ring.wav,
## tools/audio/silo_depths.py) and the world is muffled and far off, then hearing comes back over DURATION.
## Godot's Master bus cannot be renamed or bypassed, so the world is moved instead: a DAZED bus (low-pass + volume duck,
## sending to Master) is made, and every sound player on Master, now and any added while it runs, is switched onto it;
## the ringing stays on Master, unmuffled. The cutoff opens exponentially (lows first: the machines' roar comes back
## before the detail) while the duck lifts. Everything is switched back and the bus removed when done or freed early.
## One state: DAZED, DONE. Add it as a child; it starts at once.

enum State { DAZED, DONE }

const RING = preload("res://audio/silo/ears_ring.wav")
const DAZED := &"Dazed"
const MASTER := &"Master"
const DURATION := 20.0
const CUTOFF := Vector2(180.0, 20000.0)     # Hz: at first, then once hearing is back
const DUCK_DB := -16.0
const RING_DB := -6.0

var state := State.DONE
var _lpf: AudioEffectLowPassFilter
var _ring: AudioStreamPlayer
var _moved: Array[Node] = []


func _ready() -> void:
	if AudioServer.get_bus_index(DAZED) != -1:    # another one is running: leave the buses to it
		queue_free()
		return
	AudioServer.add_bus(1)                        # right after Master: a bus can only send to one before it (MuffleBus feeds it)
	AudioServer.set_bus_name(1, DAZED)
	AudioServer.set_bus_send(1, MASTER)
	_lpf = AudioEffectLowPassFilter.new()
	AudioServer.add_bus_effect(1, _lpf)
	state = State.DAZED
	_set_hearing(0.0)
	var root := get_tree().root
	for type in ["AudioStreamPlayer", "AudioStreamPlayer3D", "MuffleBus"]:
		for node in root.find_children("*", type, true, false):
			_move(node)
	get_tree().node_added.connect(_move)
	_ring = AudioStreamPlayer.new()
	_ring.stream = RING
	_ring.volume_db = RING_DB
	_ring.bus = MASTER
	_ring.set_meta(&"hearing_keep", true)
	add_child(_ring)
	_ring.play()
	var tw := create_tween()
	tw.tween_method(_set_hearing, 0.0, 1.0, DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_restore)


## A sound player on Master goes through the daze (not the ringing); so does a MuffleBus (its own bus sends into the daze).
func _move(node: Node) -> void:
	if state != State.DAZED or node.has_meta(&"hearing_keep"):
		return
	if node is MuffleBus and node.send == MASTER:
		node.send = DAZED
		_moved.append(node)
	elif (node is AudioStreamPlayer or node is AudioStreamPlayer3D) and node.get("bus") == MASTER:
		node.set("bus", DAZED)
		_moved.append(node)


## 0 = dazed, 1 = hearing back.
func _set_hearing(u: float) -> void:
	var i := AudioServer.get_bus_index(DAZED)
	if state != State.DAZED or i <= 0:
		return
	_lpf.cutoff_hz = CUTOFF.x * pow(CUTOFF.y / CUTOFF.x, u)
	AudioServer.set_bus_volume_db(i, lerpf(DUCK_DB, 0.0, u))


func _restore() -> void:
	if state != State.DAZED:
		return
	state = State.DONE
	if get_tree() and get_tree().node_added.is_connected(_move):
		get_tree().node_added.disconnect(_move)
	for node in _moved:
		if not is_instance_valid(node):
			continue
		if node is MuffleBus:
			if node.send == DAZED:
				node.send = MASTER
		elif node.get("bus") == DAZED:
			node.set("bus", MASTER)
	_moved.clear()
	if _ring:
		_ring.stop()
	var i := AudioServer.get_bus_index(DAZED)
	if i > 0:
		AudioServer.remove_bus(i)
	queue_free()


func _exit_tree() -> void:
	_restore()
