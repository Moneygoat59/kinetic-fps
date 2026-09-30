class_name NuclearPylon
extends Node3D
## A relay mast of the old outpost network. DeadForestEvent lays a chain of them between buildings; the field dosimeter homes
## in on the active one. The player re-aligns it at its cabinet with [E]: a latch clunks, the lamp stutters while it syncs,
## then it holds a steady glow and the chain moves on. Once aligned it stays online, so later passes (return trips) clear
## it just by walking by. The mast's field always keeps stalkers out (BARRIER_RADIUS). Look: RelayView.
## API kept for DeadForestEvent / RadiationDosimeter / StalkerEnemy: build_pylon, set_station_active, check_player_proximity,
## is_active, is_cleared, is_barrier_active, BARRIER_RADIUS, station_reached. force_online: RelayHub's corner masts.

signal station_reached(pylon: NuclearPylon)

enum Relay { DARK, WAITING, SYNCING, ONLINE }

const BARRIER_RADIUS: float = 20.0
const PROMPT_REACH := 3.4                   # m from the mast: prompt shows, [E] works
const PASS_REACH := 7.0                     # already-aligned relays clear when you pass this close
const SYNC_TIME := 1.4
const SINK := 0.05                          # settle the footing into the ground
## GroundSeat contacts of the relay_pylon model (tools/blender/kit/relay.py): footing rim (0.5 m deep), guy anchors (0.8 m deep)
const FOOTPRINT: Array[Vector3] = [Vector3(0.85, 0.4, 0), Vector3(-0.85, 0.4, 0), Vector3(0, 0.4, 0.85), Vector3(0, 0.4, -0.85),
	Vector3(2.771, 0.6, 1.6), Vector3(-2.771, 0.6, 1.6), Vector3(0, 0.6, -3.2)]
const WAIT_SUB := "OUTPOST NET  //  CARRIER LOST"
const SYNC_SUB := "HOLD POSITION  //  SYNCING CARRIER"
const LATCH_SOUND = preload("res://audio/rpg/Audio/metalLatch.ogg")
const MAX_DELTA := 0.1

@export var station_id: int = 1
@export var pylon_color: Color = Color(1.0, 0.65, 0.12)
var is_active: bool = false                 # the chain's current target (set by the dosimeter)
var is_cleared: bool = false                # reached on the current track (the event resets it for return trips)
var relay: Relay = Relay.DARK
var _aligned_once := false                  # history, not state: the relay stays online for later passes
var _sync_t := 0.0
var _view := RelayView.new()
var _wait_title := ""                       # built once per relay: offered every frame without allocating
var _sync_title := ""
var _sfx: AudioStreamPlayer3D


func is_barrier_active() -> bool:
	return true


func _ready() -> void:
	set_process(relay == Relay.WAITING or relay == Relay.SYNCING)   # Godot enables _process at ready: settle it now


func build_pylon(terrain: Node3D, pos_x: float, pos_z: float) -> void:
	position = Vector3(pos_x, 0.0, pos_z)
	rotation.y = float(station_id) * 2.39996            # golden-angle turn: neighbours never face the same way
	settle(terrain)
	_view.build(self)
	_wait_title = "RE-ALIGN RELAY %02d" % station_id
	_sync_title = "ALIGNING RELAY %02d" % station_id
	_sfx = AudioStreamPlayer3D.new()
	_sfx.position = Vector3(0.0, 1.5, 0.3)
	_sfx.unit_size = 4.0
	_sfx.max_distance = 30.0
	add_child(_sfx)
	_apply()


func settle(terrain: Node3D) -> void:   # footing + guy anchors into the ground; again after it changes (flat zone laid late)
	if terrain:
		position.y = GroundSeat.base_y(terrain, position, rotation.y, FOOTPRINT, SINK)


func set_pylon_color(col: Color) -> void:
	pylon_color = col
	_apply()


func set_station_active(active: bool) -> void:
	is_active = active
	_apply()


## Called every frame by RadiationDosimeter for the active relay. True on the frame it comes online.
func check_player_proximity(p_pos: Vector3) -> bool:
	if not is_active or is_cleared:
		return false
	var dist := global_position.distance_to(p_pos)
	if _aligned_once:
		return dist < PASS_REACH and _complete()
	var strength := (PROMPT_REACH - dist) / 0.6
	if relay == Relay.SYNCING:
		InteractPrompt.offer(self, _sync_title, SYNC_SUB, strength)
		return _sync_t >= SYNC_TIME and _complete()
	InteractPrompt.offer(self, _wait_title, WAIT_SUB, strength)
	if dist < PROMPT_REACH and Input.is_action_just_pressed("interact"):
		relay = Relay.SYNCING
		_sync_t = 0.0
		_play(LATCH_SOUND, -3.0, 0.9)
	return false


## Brought online from elsewhere (Relay Hub 00's router): steady glow now, and later tracks clear it by walking past.
func force_online() -> void:
	_aligned_once = true
	is_cleared = true
	_apply()


func _complete() -> bool:
	is_cleared = true
	_aligned_once = true
	_apply()
	station_reached.emit(self)
	return true


func _play(stream: AudioStream, volume: float, pitch: float) -> void:
	_sfx.stream = stream
	_sfx.volume_db = volume
	_sfx.pitch_scale = pitch
	_sfx.play()


## Resolve the relay state from the dosimeter's flags and show it.
func _apply() -> void:
	if is_cleared or (_aligned_once and not is_active):
		relay = Relay.ONLINE
	elif is_active and relay != Relay.SYNCING:
		relay = Relay.WAITING
	elif not is_active:
		relay = Relay.DARK
	_view.color = pylon_color
	set_process(relay == Relay.WAITING or relay == Relay.SYNCING)
	if relay == Relay.ONLINE:
		_view.show_online()
	elif relay == Relay.DARK:
		_view.show_dark()


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	if relay == Relay.WAITING:
		_view.show_waiting(t)
	elif relay == Relay.SYNCING:
		_sync_t += clampf(delta, 0.0, MAX_DELTA)
		_view.show_syncing(t, clampf(_sync_t / SYNC_TIME, 0.0, 1.0))
