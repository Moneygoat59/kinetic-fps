class_name SiloGeneratorSound
extends Node
## Presenter for the sound of Missile Silo 00's generators (audio/silo/gen_*.wav, tools/audio/silo_generator.py). Per
## machine: the running drone (a loop that breathes with the machine's throb, a touch louder and higher as its glow
## swells), its own bowed note swelling with the glow (E, B, G: together an E minor chord over the drones' E, rolling
## round the hall as the machines breathe out of step; heard close to), the amber pouring into its crown pool, and once a
## breath a heavy pulse, fired at the bottom of the breath so
## the glow swells up after it; now and then an arc cracks off one of them. Heard through the whole hall and faintly up the
## lift shaft. Every player goes through one MuffleBus (BUS), so the hall can be shut off from the listener behind walls:
## set_open(0..1), from SiloHallEar. SiloGenerators owns it: setup(model, count) once, update(t, rate, spread, delta) every
## frame it runs, with its own throb (machine i's breath = sin(t * rate + i * spread)).

const DRONE = preload("res://audio/silo/gen_drone.wav")
const PULSE = preload("res://audio/silo/gen_pulse.wav")
const BOWS: Array[AudioStream] = [preload("res://audio/silo/gen_bow_e2.wav"), preload("res://audio/silo/gen_bow_b2.wav"),
	preload("res://audio/silo/gen_bow_g3.wav")]
const POUR = preload("res://audio/silo/gen_pour.wav")
const ARCS: Array[AudioStream] = [preload("res://audio/silo/gen_arc_1.wav"), preload("res://audio/silo/gen_arc_2.wav"),
	preload("res://audio/silo/gen_arc_3.wav")]
const BUS := &"SiloHall"
const DRONE_DB := -3.0
const DRONE_REACH := 80.0
const BREATH_DB := Vector2(-3.0, 1.5)       # drone level at the bottom / top of a breath (added to DRONE_DB)
const BREATH_PITCH := Vector2(0.96, 1.03)
const PULSE_DB := 0.0
const PULSE_REACH := 130.0
const PULSE_PHASE := PI * 1.5               # the bottom of a breath
const BOW_DB := -5.0                        # at the top of a breath; silent at the bottom
const BOW_REACH := 32.0
const BOW_CURVE := 2.0                      # breath ^ this: the note blooms late in the swell, like the glow
const POUR_DB := -9.0
const POUR_REACH := 34.0
const ARC_DB := -4.0
const ARC_GAP := Vector2(5.0, 14.0)         # seconds between arcs, somewhere in the hall
const MAX_DELTA := 0.1

var muffle := MuffleBus.make(BUS)
var _drones: Array[AudioStreamPlayer3D] = []
var _bows: Array[AudioStreamPlayer3D] = []
var _pulses: Array[AudioStreamPlayer3D] = []
var _arcs: Array[AudioStreamPlayer3D] = []
var _beats := PackedInt32Array()            # breaths counted per machine (a pulse on each new one)
var _t_arc := 6.0


## Builds the players on the model's markers (marker_gen_<i>: the machine, marker_light_gen_pool_<i>: its crown pool).
func setup(model: Node3D, count: int) -> void:
	if model == null:
		return
	add_child(muffle)
	var drone := looped(DRONE)
	var pour := looped(POUR)
	for i in count:
		var anchor := model.get_node_or_null("marker_gen_%d" % i) as Node3D
		if anchor == null:
			continue
		_drones.append(_player(anchor, drone, DRONE_DB, 16.0, DRONE_REACH, true))
		_bows.append(_player(anchor, looped(BOWS[i % BOWS.size()]), BOW_DB, 8.0, BOW_REACH, true))
		_pulses.append(_player(anchor, PULSE, PULSE_DB, 24.0, PULSE_REACH, false))
		_arcs.append(_player(anchor, ARCS[0], ARC_DB, 10.0, 70.0, false))
		_beats.append(-1)
		var pool := model.get_node_or_null("marker_light_gen_pool_%d" % i) as Node3D
		if pool:
			_player(pool, pour, POUR_DB, 8.0, POUR_REACH, true)


func _player(anchor: Node3D, stream: AudioStream, db: float, unit: float, reach: float, play: bool) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = db
	p.unit_size = unit
	p.max_distance = reach
	p.autoplay = play
	p.bus = BUS
	p.max_polyphony = 2                        # a pulse's tail (5.5 s) outlasts a breath: let the next one overlap it
	anchor.add_child(p)
	return p


## 1 = the listener is in the hall, 0 = shut off from it (see SiloHallEar).
func set_open(value: float) -> void:
	muffle.set_open(value)


## A looping copy of a WAV (the files carry no loop points).
static func looped(stream: AudioStream) -> AudioStream:
	var wav := stream.duplicate() as AudioStreamWAV
	if wav == null:
		return stream
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = int(wav.get_length() * wav.mix_rate)
	return wav


func update(t: float, rate: float, spread: float, delta: float) -> void:
	for i in _drones.size():
		var phase := t * rate + i * spread
		var breath := (sin(phase) + 1.0) * 0.5
		_drones[i].volume_db = DRONE_DB + lerpf(BREATH_DB.x, BREATH_DB.y, breath)
		_drones[i].pitch_scale = lerpf(BREATH_PITCH.x, BREATH_PITCH.y, breath)
		_bows[i].volume_db = BOW_DB + linear_to_db(maxf(pow(breath, BOW_CURVE), 0.001))
		var beat := floori((phase - PULSE_PHASE) / TAU)
		if beat != _beats[i]:
			if _beats[i] >= 0:                  # not on the first frame: only real breaths
				_pulses[i].pitch_scale = randf_range(0.94, 1.04)
				_pulses[i].play()
			_beats[i] = beat
	_t_arc -= clampf(delta, 0.0, MAX_DELTA)
	if _t_arc <= 0.0 and not _arcs.is_empty():
		_t_arc = randf_range(ARC_GAP.x, ARC_GAP.y)
		var arc := _arcs[randi() % _arcs.size()]
		arc.stream = ARCS[randi() % ARCS.size()]
		arc.pitch_scale = randf_range(0.85, 1.15)
		arc.play()
