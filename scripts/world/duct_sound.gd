class_name DuctSound
extends Node3D
## The sound of crawling through a vent duct (audio/silo/*.wav, tools/audio/silo_depths.py). Stands at the duct's far end.
## While someone crawls in it: their own breathing, calm at the mouth and short and ragged as the end gets close (two
## loops crossfaded by how far along they are), the sheet steel popping under them now and then while they move, and from
## past the end, every so often, something far off (a thud, a scrape, knocking). The draft through the end whistles all
## the time, placed at the end. VentDuct.climbed(inside, player) drives it (on_climbed); idle otherwise.
## make(end, mouth) with the end point and the mouth's position in the space of the node it is added under.

enum State { IDLE, CRAWLING }

const BREATH_CALM = preload("res://audio/silo/breath_calm.wav")
const BREATH_FAST = preload("res://audio/silo/breath_fast.wav")
const DRAFT = preload("res://audio/silo/duct_draft.wav")
const FLEX: Array[AudioStream] = [preload("res://audio/silo/duct_flex_1.wav"), preload("res://audio/silo/duct_flex_2.wav"),
	preload("res://audio/silo/duct_flex_3.wav")]
const BEYOND: Array[AudioStream] = [preload("res://audio/silo/beyond_1.wav"), preload("res://audio/silo/beyond_2.wav"),
	preload("res://audio/silo/beyond_3.wav")]
const BREATH_DB := -10.0
const SILENT_DB := -60.0
const FADE := 1.5                     # seconds for the breathing to come in / go
const FLEX_DB := -8.0
const FLEX_GAP := Vector2(1.6, 4.5)   # seconds between pops while moving
const MOVING := 0.3                   # m/s
const BEYOND_DB := -4.0
const BEYOND_GAP := Vector2(9.0, 20.0)
const DRAFT_DB := -12.0
const MAX_DELTA := 0.1

var state := State.IDLE
var crawler: Player
var _length := 1.0                    # mouth to end (m): how far along the crawler is
var _mouth := Vector3.ZERO           # parent space
var _calm: AudioStreamPlayer
var _fast: AudioStreamPlayer
var _flex: AudioStreamPlayer
var _beyond: AudioStreamPlayer3D
var _presence := 0.0                  # 0..1: the breathing faded in
var _t_flex := 2.0
var _t_beyond := 6.0


static func make(end: Vector3, mouth: Vector3) -> DuctSound:
	var s := DuctSound.new()
	s.name = "DuctSound"
	s.position = end
	s._mouth = mouth
	s._length = maxf(end.distance_to(mouth), 1.0)
	return s


## The duct was made longer (a new far end, same parent space): the breathing now builds toward there.
func set_end(end: Vector3) -> void:
	position = end
	_length = maxf(end.distance_to(_mouth), 1.0)


func _ready() -> void:
	_calm = _flat(SiloGeneratorSound.looped(BREATH_CALM))
	_fast = _flat(SiloGeneratorSound.looped(BREATH_FAST))
	_flex = _flat(FLEX[0])
	_flex.volume_db = FLEX_DB
	_beyond = AudioStreamPlayer3D.new()
	_beyond.volume_db = BEYOND_DB
	_beyond.unit_size = 6.0
	_beyond.max_distance = 30.0
	add_child(_beyond)
	var draft := AudioStreamPlayer3D.new()
	draft.stream = SiloGeneratorSound.looped(DRAFT)
	draft.volume_db = DRAFT_DB
	draft.unit_size = 2.0
	draft.max_distance = 16.0
	draft.autoplay = true
	add_child(draft)
	set_physics_process(false)


func _flat(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = SILENT_DB
	add_child(p)
	return p


## VentDuct.climbed: someone is in the duct now (inside) or has climbed out.
func on_climbed(inside: bool, player: Player) -> void:
	if inside and player:
		crawler = player
		if state == State.IDLE:
			state = State.CRAWLING
			_calm.play()
			_fast.play()
			set_physics_process(true)
	elif state == State.CRAWLING:
		crawler = null                 # the breathing fades out below, then it goes idle


func _physics_process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var in_duct := crawler != null and is_instance_valid(crawler)
	_presence = move_toward(_presence, 1.0 if in_duct else 0.0, dt / FADE)
	var along := 0.0
	if in_duct:
		var at := (get_parent() as Node3D).to_local(crawler.global_position)
		along = clampf(at.distance_to(_mouth) / _length, 0.0, 1.0)
	_calm.volume_db = BREATH_DB + linear_to_db(maxf(_presence * (1.0 - along), 0.001))
	_fast.volume_db = BREATH_DB + linear_to_db(maxf(_presence * along, 0.001))
	if not in_duct:
		if _presence <= 0.0:
			_stop()
		return
	var moving := Vector2(crawler.velocity.x, crawler.velocity.z).length() > MOVING
	if moving:
		_t_flex -= dt
	if _t_flex <= 0.0:
		_t_flex = randf_range(FLEX_GAP.x, FLEX_GAP.y)
		_flex.stream = FLEX[randi() % FLEX.size()]
		_flex.pitch_scale = randf_range(0.85, 1.2)
		_flex.play()
	_t_beyond -= dt
	if _t_beyond <= 0.0:
		_t_beyond = randf_range(BEYOND_GAP.x, BEYOND_GAP.y)
		_beyond.stream = BEYOND[randi() % BEYOND.size()]
		_beyond.pitch_scale = randf_range(0.8, 1.0)
		_beyond.play()


func _stop() -> void:
	state = State.IDLE
	_calm.stop()
	_fast.stop()
	set_physics_process(false)
