extends Node
## Outpost 73 pump jack: it has pulled amber out of the ground unattended for 200 years. Turns the crank and solves the
## four-bar linkage exactly each frame (crank pin -> pitman -> tail pin on the walking beam), then moves the polished rod by
## the horsehead arc length and stretches the bridle cables. No allocations; transforms only.
## Nodes come from tools/blender/props/o73_exterior.py: pump_* origins sit on their pivots, geometry is built at rest.

const CRANK_R := 0.35                    # crank pin radius (o73_exterior.py CRANK_R)
const PERIOD := 10.0                     # seconds per stroke (6 SPM, matches the terminal readout)
const MAX_STEP := 0.1                    # clamp dt spikes (hitches) so the crank never jumps a whole stroke
const HUM := preload("res://audio/sci-fi/Audio/spaceEngineLow_001.ogg")
const KNOCK := preload("res://audio/impacts/Audio/impactMetal_heavy_002.ogg")
const CREAKS: Array[AudioStream] = [preload("res://audio/rpg/Audio/creak1.ogg"), preload("res://audio/rpg/Audio/creak2.ogg"),
	preload("res://audio/rpg/Audio/creak3.ogg")]
## The pump jack is the lure to the bunker: its knock and bearing groan carry through the silent forest, muffled with
## distance (low-pass), faint at the 60-70 m the bunker spawns from, clear only close up. [volume dB, unit size, reach m]
const CARRY := [-7.0, 7.0, 115.0]
const MUFFLE_HZ := 1400.0                # distance low-pass: far away only the thud and the low groan remain
const MUFFLE_DB := -18.0

var _beam: Node3D
var _crank: Node3D
var _pitman: Node3D
var _rod: Node3D
var _bridle: Node3D
var _clank: AudioStreamPlayer3D
var _creak: AudioStreamPlayer3D
var _pivot := Vector2.ZERO               # walking-beam bearing (model x, y)
var _crank_c := Vector2.ZERO
var _tail_len := 0.0
var _tail_rest := 0.0
var _pitman_len := 0.0
var _pitman_rest := 0.0
var _branch := 1.0                       # which of the two linkage solutions is the assembled one
var _rod_rest := Vector3.ZERO
var _bridle_top := 0.0
var _bridle_len := 1.0
var _head_r := 0.0
var _angle := 0.0
var _last_phi := 0.0
var _rising := true
var _tail := Vector2.ZERO


func setup(model: Node3D) -> void:
	set_process(false)
	_beam = model.get_node_or_null("pump_beam") as Node3D
	_crank = model.get_node_or_null("pump_crank") as Node3D
	_pitman = model.get_node_or_null("pump_pitman") as Node3D
	_rod = model.get_node_or_null("pump_rod") as Node3D
	_bridle = model.get_node_or_null("pump_bridle") as Node3D
	if not (_beam and _crank and _pitman and _rod and _bridle):
		push_warning("BunkerPump: pump_* nodes missing from model")
		return
	_pivot = Vector2(_beam.position.x, _beam.position.y)
	_crank_c = Vector2(_crank.position.x, _crank.position.y)
	_tail = Vector2(_pitman.position.x, _pitman.position.y)
	var pin := _crank_c + Vector2(CRANK_R, 0.0)
	_tail_len = _tail.distance_to(_pivot)
	_tail_rest = (_tail - _pivot).angle()
	_pitman_len = _tail.distance_to(pin)
	_pitman_rest = (pin - _tail).angle()
	_branch = signf((pin - _pivot).cross(_tail - _pivot))
	_rod_rest = _rod.position
	_bridle_top = _bridle.position.y
	_bridle_len = maxf(_bridle_top - _rod_rest.y, 0.01)
	_head_r = _rod_rest.x - _pivot.x
	_setup_audio(model)
	set_process(true)


func _setup_audio(model: Node3D) -> void:
	var anchor := model.get_node_or_null("marker_pump") as Node3D
	var hum := AudioStreamPlayer3D.new()
	var loop := HUM.duplicate() as AudioStreamOggVorbis
	if loop:
		loop.loop = true
	hum.stream = loop
	hum.volume_db = -16.0
	hum.pitch_scale = 0.5
	hum.unit_size = 5.0
	hum.max_distance = 38.0
	hum.autoplay = true                     # the bunker is built before it enters the tree; start when it does
	_clank = _carrying_player(KNOCK)
	_creak = _carrying_player(CREAKS[0])
	var parent: Node3D = anchor if anchor else model
	parent.add_child(hum)
	parent.add_child(_clank)
	parent.add_child(_creak)


func _carrying_player(stream: AudioStream) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = CARRY[0]
	p.unit_size = CARRY[1]
	p.max_distance = CARRY[2]
	p.attenuation_filter_cutoff_hz = MUFFLE_HZ
	p.attenuation_filter_db = MUFFLE_DB
	return p


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_angle = fposmod(_angle + minf(delta, MAX_STEP) * TAU / PERIOD, TAU)
	var pin := _crank_c + Vector2(cos(_angle), sin(_angle)) * CRANK_R
	_tail = _solve_tail(pin)
	var phi := (_tail - _pivot).angle() - _tail_rest
	_beam.basis = Basis(Vector3.BACK, phi)
	_crank.basis = Basis(Vector3.BACK, _angle)
	_pitman.position = Vector3(_tail.x, _tail.y, _pitman.position.z)
	_pitman.basis = Basis(Vector3.BACK, (pin - _tail).angle() - _pitman_rest)
	_rod.position = _rod_rest + Vector3(0.0, _head_r * phi, 0.0)
	_bridle.scale = Vector3(1.0, maxf(_bridle_top - _rod.position.y, 0.01) / _bridle_len, 1.0)
	var rising := phi > _last_phi
	if rising != _rising and not rising:            # top of the stroke: the worn linkage knocks
		_clank.pitch_scale = randf_range(0.55, 0.68)
		_clank.play()
	elif rising != _rising and rising:              # bottom of the stroke: the dry walking-beam bearing groans
		_creak.stream = CREAKS[randi() % CREAKS.size()]
		_creak.pitch_scale = randf_range(0.42, 0.52)
		_creak.play()
	_rising = rising
	_last_phi = phi


## Tail pin = intersection of the circle it swings on (about the beam pivot) and the pitman circle (about the crank pin).
func _solve_tail(pin: Vector2) -> Vector2:
	var d_vec := pin - _pivot
	var d := d_vec.length()
	if d < 0.0001:
		return _tail
	var l := (_tail_len * _tail_len - _pitman_len * _pitman_len + d * d) / (2.0 * d)
	var h := sqrt(maxf(_tail_len * _tail_len - l * l, 0.0))
	var dir := d_vec / d
	var foot := _pivot + dir * l
	var perp := Vector2(-dir.y, dir.x) * h
	var t1 := foot + perp
	return t1 if signf(d_vec.cross(t1 - _pivot)) == _branch else foot - perp
