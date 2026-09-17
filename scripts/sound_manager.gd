class_name SoundManager
extends Node

static var instance: SoundManager

const POOL_SIZE_2D: int = 12
const POOL_SIZE_3D: int = 8

var _players_2d: Array[AudioStreamPlayer] = []
var _players_3d: Array[AudioStreamPlayer3D] = []
var _index_2d: int = 0
var _index_3d: int = 0

func _init() -> void:
	if not instance:
		instance = self

func _ready() -> void:
	if instance == null:
		instance = self
	for i in range(POOL_SIZE_2D):
		var p = AudioStreamPlayer.new()
		p.name = "Pool2D_%d" % i
		p.bus = "Master"
		add_child(p)
		_players_2d.append(p)
	for i in range(POOL_SIZE_3D):
		var p3 = AudioStreamPlayer3D.new()
		p3.name = "Pool3D_%d" % i
		p3.max_distance = 65.0
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.bus = "Master"
		add_child(p3)
		_players_3d.append(p3)

static func play(stream: AudioStream, volume_db: float = 0.0, pitch_variance: float = 0.04) -> void:
	if not instance or not stream or instance._players_2d.is_empty():
		return
	var p = instance._players_2d[instance._index_2d]
	instance._index_2d = (instance._index_2d + 1) % instance._players_2d.size()
	p.stop()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + (randf_range(-pitch_variance, pitch_variance) if pitch_variance > 0.0 else 0.0)
	p.play()

static func play_spatial(stream: AudioStream, pos: Vector3, volume_db: float = 0.0, pitch_variance: float = 0.04) -> void:
	if not instance or not stream or instance._players_3d.is_empty():
		return
	var p = instance._players_3d[instance._index_3d]
	instance._index_3d = (instance._index_3d + 1) % instance._players_3d.size()
	p.stop()
	p.global_position = pos
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + (randf_range(-pitch_variance, pitch_variance) if pitch_variance > 0.0 else 0.0)
	p.play()
