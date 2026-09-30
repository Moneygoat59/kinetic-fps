class_name SiloLiftWreck
extends Node
## The freight lift after the crash, lying at the foot of its shaft with the walker in it (the silo level after night 4,
## SiloDepthsLevel). SiloLift.wreck() makes it and hands over the cage, its lamp and the two hall-side gates (cage + landing).
## One FSM: JAMMED (the cage gate is buckled shut: FORCE GATE, [E] in the cage), FORCING (the walker heaves at it: it gives
## a little at each heave), OPEN (both gates grind up and stay up: the way out into the generator hall). All along the cage
## lamp stutters on a dying circuit, sparks spit off the brake shoes now and then and the wreck ticks and groans as it
## settles. SiloLift.update calls update(player position) every physics frame; forced is emitted once the gates go up.

signal forced()

enum State { JAMMED, FORCING, OPEN }

const TITLE := "FORCE GATE"
const SUB := "CAGE GATE  //  BUCKLED SHUT"
const HEAVES := 3                            # heaves before it gives
const HEAVE_GAP := 0.75                      # seconds between them
const MAX_DELTA := 0.1
const LAMP_LOW := 0.4                        # of the lamp's working energy
const SPARK_GAP := Vector2(2.5, 8.0)         # seconds between spark bursts
const SPARK_BURST := 0.25
const CREAK_GAP := Vector2(5.0, 13.0)
const HEAVE = preload("res://audio/impacts/Audio/impactMetal_heavy_001.ogg")
const GIVE = preload("res://audio/impacts/Audio/impactMetal_heavy_003.ogg")
const CREAKS: Array[AudioStream] = [preload("res://audio/rpg/Audio/creak1.ogg"), preload("res://audio/rpg/Audio/creak2.ogg"),
	preload("res://audio/rpg/Audio/creak3.ogg")]
const BUZZ = preload("res://audio/sci-fi/Audio/forceField_001.ogg")

var state := State.JAMMED
var lift: SiloLift
var _gates: Array[LiftGate] = []
var _lamp: OmniLight3D
var _lamp_energy := 0.0
var _sparks: Array[CPUParticles3D] = []
var _audio: AudioStreamPlayer3D
var _buzz: AudioStreamPlayer3D
var _heaves := 0
var _t_heave := 0.0
var _t_spark := 1.5
var _t_spark_off := 0.0
var _t_creak := 3.0


func _ready() -> void:
	set_physics_process(false)


## Takes over the wrecked cage. frame = the cage frame at the top (SiloLift._top), for the brake shoe and lamp points.
func begin(l: SiloLift, body: Node3D, lamp: OmniLight3D, gates: Array[LiftGate], frame: Transform3D) -> void:
	if lift != null or l == null or body == null:
		return
	lift = l
	_gates = gates
	_lamp = lamp
	_lamp_energy = lamp.light_energy if lamp else 0.0
	for side in [-1.0, 1.0]:
		_sparks.append(Sparks.make(body, frame * Vector3(side * 1.7, 0.3, 0.0)))
	_audio = _player(body, frame * Vector3(0.0, 1.2, 0.0), -4.0)
	_buzz = _player(body, frame * Vector3(0.0, 2.3, 0.0), -22.0)
	var loop := BUZZ.duplicate() as AudioStreamOggVorbis
	if loop:
		loop.loop = true
		_buzz.stream = loop
		_buzz.pitch_scale = 0.5
		_buzz.play()
	set_physics_process(true)


func _player(parent: Node3D, at: Vector3, db: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.position = at
	p.volume_db = db
	p.unit_size = 5.0
	parent.add_child(p)
	return p


## Every physics frame from SiloLift: the prompt and [E] while the walker is in the cage and the gate still holds.
func update(p_pos: Vector3) -> void:
	if state != State.JAMMED or lift == null or not lift.in_cage(p_pos):
		return
	InteractPrompt.offer(self, TITLE, SUB, 1.0)
	if Input.is_action_just_pressed("interact"):
		force()


## Starts forcing the gate (the walker's [E]; tests call it directly).
func force() -> void:
	if state != State.JAMMED:
		return
	state = State.FORCING
	_heaves = 0
	_t_heave = 0.0


func _physics_process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_flicker()
	_spit(dt)
	_t_creak -= dt
	if _t_creak <= 0.0:
		_t_creak = randf_range(CREAK_GAP.x, CREAK_GAP.y)
		_sound(CREAKS[randi() % CREAKS.size()], randf_range(0.5, 0.8))
	if state != State.FORCING:
		return
	_t_heave -= dt
	if _t_heave > 0.0:
		return
	_t_heave = HEAVE_GAP
	_heaves += 1
	if _heaves <= HEAVES:
		_sound(HEAVE, randf_range(0.7, 0.9))
		return
	state = State.OPEN
	_sound(GIVE, 0.6)
	for gate in _gates:
		gate.set_open(true)
	forced.emit()


func _sound(stream: AudioStream, pitch: float) -> void:
	if _audio == null:
		return
	_audio.stream = stream
	_audio.pitch_scale = pitch
	_audio.play()


## The cage lamp on a dying circuit: low, a slow waver, dropping out for a few frames now and then.
func _flicker() -> void:
	if _lamp == null:
		return
	var t := Time.get_ticks_msec() * 0.001
	var on := randf() > 0.04 and fmod(t * 0.37, 1.0) > 0.06
	_lamp.light_energy = _lamp_energy * LAMP_LOW * (0.75 + 0.25 * sin(t * 7.3)) if on else 0.0


func _spit(dt: float) -> void:
	_t_spark -= dt
	_t_spark_off -= dt
	if _t_spark <= 0.0:
		_t_spark = randf_range(SPARK_GAP.x, SPARK_GAP.y)
		_t_spark_off = SPARK_BURST
		_sparks[randi() % _sparks.size()].emitting = true
	elif _t_spark_off <= 0.0:
		for s in _sparks:
			s.emitting = false
