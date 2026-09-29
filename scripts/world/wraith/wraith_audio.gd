class_name WraithAudio
extends Node
## Everything the wraith sounds like, driven by one number: dread (0 nothing near .. 1 it is on you), set by WraithStalk.
## Beds (smoothly faded each frame, no allocation): the drone rises from nothing, the heartbeat comes in past HEART_AT and
## quickens, its breathing (the old stalker's, dragged down an octave) plays from its body while it is present and close.
## Cues: sting (it is really there), vanish (from where it was), whisper(side) just beside the listener's head (one of the
## recorded whispers, audio/wraith/, never the same twice running), and for the finale (WraithGrab): grip, inhale, scream.
## mix: STALK (as above), HUSH (the drone gone at once, only the heart and its breath), SILENT (every bed cut dead).

enum Mix { STALK, HUSH, SILENT }

const BREATH = preload("res://audio/stalker/breathing.mp3")
const WHISPERS := [preload("res://audio/wraith/whisper_1.wav"), preload("res://audio/wraith/whisper_2.wav"),
	preload("res://audio/wraith/whisper_3.wav"), preload("res://audio/wraith/whisper_4.wav"),
	preload("res://audio/wraith/whisper_5.wav")]
const WHISPER_MANY = preload("res://audio/wraith/whisper_many.wav")
const INHALE = preload("res://audio/wraith/inhale.wav")
const GRIP := [preload("res://audio/rpg/Audio/cloth3.ogg"), preload("res://audio/impacts/Audio/impactPunch_heavy_001.ogg")]
const HEART_AT := 0.35
const SILENT := -60.0
const FADE := 1.6                  # bed volume follows its target at this rate (per second)

var dread := 0.0
var breathing := false             # the wraith is present close enough to hear
var mix := Mix.STALK
var _last_whisper := -1
var _scream: WraithScream
var _drone: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _cue: AudioStreamPlayer
var _whisper: AudioStreamPlayer3D
var _vanish: AudioStreamPlayer3D
var _breath: AudioStreamPlayer3D


## `body` = the wraith (its breath and vanish come from it); `listener` = the player (whispers are placed round them).
func setup(body: Node3D) -> void:
	_drone = _bed(WraithSfx.drone())
	_heart = _bed(WraithSfx.heartbeat())
	_cue = AudioStreamPlayer.new()
	add_child(_cue)
	_whisper = _spatial(WHISPERS[0], 3.0, 14.0, self)
	_vanish = _spatial(WraithSfx.vanish(), 6.0, 60.0, body)
	_breath = _spatial(BREATH, 4.0, 22.0, body)
	_breath.pitch_scale = 0.55
	_breath.volume_db = SILENT
	_scream = WraithScream.new()
	add_child(_scream)


func _bed(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = SILENT
	add_child(p)
	p.play()
	return p


func _spatial(stream: AudioStream, unit: float, reach: float, host: Node) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.unit_size = unit
	p.max_distance = reach
	host.add_child(p)
	return p


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, 0.1)
	var k := 1.0 - exp(-dt * FADE)
	if mix == Mix.SILENT:
		return
	var drone_db := SILENT if dread <= 0.0 else lerpf(-34.0, -8.0, dread)
	_drone.volume_db = SILENT if mix == Mix.HUSH else lerpf(_drone.volume_db, drone_db, k)
	_drone.pitch_scale = 1.0 - 0.08 * dread
	var heart_db := SILENT if dread < HEART_AT else lerpf(-26.0, -4.0, (dread - HEART_AT) / (1.0 - HEART_AT))
	_heart.volume_db = lerpf(_heart.volume_db, heart_db, k)
	_heart.pitch_scale = 0.85 + 0.9 * maxf(dread - HEART_AT, 0.0)
	_breath.volume_db = lerpf(_breath.volume_db, 2.0 if breathing else SILENT, k)
	if breathing and not _breath.playing:
		_breath.play()


## `bus`: the finale's stings go through the scream's limiter (they are far too loud for the master on their own).
func sting(loudness_db := 0.0, bus := &"Master") -> void:
	_cue.bus = bus
	_cue.stream = WraithSfx.sting()
	_cue.volume_db = loudness_db
	_cue.pitch_scale = randf_range(0.92, 1.05)
	_cue.play()


func vanish() -> void:
	_vanish.pitch_scale = randf_range(0.85, 1.1)
	_vanish.play()


## A whisper beside the listener's head, on the side of `toward` (a world direction); louder the closer it has come.
## `many` = the overlapping voices, `near` = metres from the head (the finale puts it right at the ear).
func whisper(listener: Node3D, toward: Vector3, many := false, near := 1.2) -> void:
	if listener == null:
		return
	var side := toward.normalized() if toward.length_squared() > 0.01 else Vector3.RIGHT
	var pick := (_last_whisper + randi_range(1, WHISPERS.size() - 1)) % WHISPERS.size()
	_last_whisper = pick
	_whisper.stream = WHISPER_MANY if many else WHISPERS[pick]
	_whisper.global_position = listener.global_position + Vector3.UP * 1.4 + side * near
	_whisper.volume_db = lerpf(-12.0, 6.0, dread)
	_whisper.pitch_scale = randf_range(0.88, 1.02)
	_whisper.play()


func set_mix(next: Mix) -> void:
	mix = next
	if mix == Mix.SILENT:
		for p in [_drone, _heart, _breath]:
			p.volume_db = SILENT
		_whisper.stop()


## The hand closing on a shoulder: cloth, a heavy hit, the sting at full.
func grip() -> void:
	for s in GRIP:
		SoundManager.play(s, 4.0, 0.03)
	sting(0.0, WraithScream.BUS)


func inhale() -> void:
	SoundManager.play(INHALE, 6.0, 0.0)


func scream() -> void:
	sting(2.0, WraithScream.BUS)
	_scream.play()


func cut() -> void:
	set_mix(Mix.SILENT)
	_scream.stop()
	_cue.stop()
