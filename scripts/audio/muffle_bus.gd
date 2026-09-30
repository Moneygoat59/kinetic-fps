class_name MuffleBus
extends Node
## A runtime audio bus that can be shut behind walls. AudioStreamPlayer3D only knows distance, so a machine behind rock or a
## closed door sounds as loud as one in the room: route its players through this bus (`player.bus = bus_name`) and drive
## set_open(0..1) from where the listener stands (1 = the same room, 0 = sealed behind rock). It eases there at RATE per
## second: the volume from CLOSED_DB up to 0 and a low-pass (lows carry through walls, highs do not) from CLOSED_HZ up to
## OPEN_HZ in log steps. It sends to Master, or wherever `send` says (HearingReturn moves it into its daze). make() creates
## the bus (one per name, shared by every MuffleBus of that name); the last one freed removes it. Add the node to the tree:
## it eases in _process, and only while it still has somewhere to go.

const MASTER := &"Master"
const CLOSED_DB := -40.0
const CLOSED_HZ := 180.0
const OPEN_HZ := 20000.0
const RATE := 0.6                # openness per second: a full swing takes ~1.7 s

static var _users := {}          # bus name -> how many MuffleBus nodes use it

var bus_name := &""
var send := MASTER:
	set(value):
		send = value
		var i := AudioServer.get_bus_index(bus_name)
		if i != -1:
			AudioServer.set_bus_send(i, send)
var openness := 1.0
var _target := 1.0
var _lpf: AudioEffectLowPassFilter


static func make(bus: StringName) -> MuffleBus:
	var muffle := MuffleBus.new()
	muffle.name = bus
	muffle.bus_name = bus
	_users[bus] = int(_users.get(bus, 0)) + 1
	if AudioServer.get_bus_index(bus) == -1:
		var i := AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, bus)
		AudioServer.set_bus_send(i, MASTER)
		AudioServer.add_bus_effect(i, AudioEffectLowPassFilter.new())
	muffle._lpf = AudioServer.get_bus_effect(AudioServer.get_bus_index(bus), 0) as AudioEffectLowPassFilter
	muffle.set_process(false)
	return muffle


func _ready() -> void:
	_apply()


## 1 = open, 0 = sealed. Cheap to call every frame.
func set_open(value: float) -> void:
	_target = clampf(value, 0.0, 1.0)
	if not is_equal_approx(openness, _target):
		set_process(true)


func _process(delta: float) -> void:
	openness = move_toward(openness, _target, RATE * clampf(delta, 0.0, 0.1))
	_apply()
	if is_equal_approx(openness, _target):
		set_process(false)


func _apply() -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1 or _lpf == null:
		return
	AudioServer.set_bus_volume_db(i, lerpf(CLOSED_DB, 0.0, openness))
	_lpf.cutoff_hz = CLOSED_HZ * pow(OPEN_HZ / CLOSED_HZ, openness)


func _notification(what: int) -> void:
	if what != NOTIFICATION_PREDELETE or bus_name == &"":
		return
	var left := int(_users.get(bus_name, 1)) - 1
	_users[bus_name] = left
	if left <= 0:
		var i := AudioServer.get_bus_index(bus_name)
		if i != -1:
			AudioServer.remove_bus(i)
