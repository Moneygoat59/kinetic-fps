class_name ForestNightDirector
extends Node
## Runs how a night in the forest ends (ForestNights): nights 1 and 2 count the walker's steps and trip them at `trip_at`
## metres (DreamTrip); night 3 is the wraith (WraithStalk: nothing, then "I don't think I am alone...", then glimpses that come
## nearer and nearer until it takes you); night 4 is Missile Silo 00's freight lift: every SiloLift that enters the tree is
## doomed (SiloLift.doom) and a LiftCrashView shakes the walker through the crash. Each way the walker wakes: a hard cut
## to black (the fall's impact, the grab, the cage hitting the hall floor), then LevelFlow to the apartment.
## DeadForestManager adds it with setup(); nights without an ending (the full forest) never process.

enum State { DREAMING, WAKING }

const TripScript = preload("res://scripts/world/dream_trip.gd")
const WAKE_TO := &"apartment"
const WAKE_HOLD := 1.8               # seconds of black before the apartment
const MAX_STEP := 5.0                # metres per frame; more is a teleport / respawn, not walking

var state := State.DREAMING
var night: Dictionary = {}
var player: Player
var terrain: Node3D
var walked := 0.0
var stalk: WraithStalk
var _last := Vector3.ZERO


func setup(p: Player, t: Node3D, night_spec: Dictionary) -> void:
	player = p
	terrain = t
	night = night_spec


func _ready() -> void:
	var ending: int = night.get("ending", ForestNights.Ending.NONE)
	if player:
		_last = player.global_position
	if player and ending == ForestNights.Ending.CAUGHT:
		stalk = WraithStalk.new()
		add_child(stalk)
		stalk.setup(player, terrain)
		stalk.caught.connect(_wake)
	if ending == ForestNights.Ending.CRASH:
		get_tree().node_added.connect(_on_node_added)                  # the silo is built later, when the walk reaches it
		for lift in get_tree().get_nodes_in_group(SiloLift.GROUP):
			_doom(lift as SiloLift)
	set_physics_process(player != null and (ending == ForestNights.Ending.TRIP or ending == ForestNights.Ending.CAUGHT))


func _physics_process(delta: float) -> void:
	if state != State.DREAMING or player == null:
		return
	var dt := clampf(delta, 0.0, 0.1)
	var p := player.global_position
	var step := Vector2(p.x - _last.x, p.z - _last.z).length()
	_last = p
	if step < MAX_STEP and player.is_on_floor() and player.is_physics_processing():   # not while carried (dev flycam)
		walked += step
	match night["ending"]:
		ForestNights.Ending.TRIP:
			if walked >= night["trip_at"]:
				_trip()
		ForestNights.Ending.CAUGHT:
			stalk.tick(walked, dt)


func _on_node_added(node: Node) -> void:
	if node is SiloLift:
		_doom(node)


func _doom(lift: SiloLift) -> void:
	if lift == null or lift.crash != null:
		return
	var crash := lift.doom()
	var view := LiftCrashView.new()
	view.name = "LiftCrashView"
	add_child(view)
	view.setup(player, lift, crash)
	crash.phase_changed.connect(_on_crash_phase)


func _on_crash_phase(phase: SiloLiftCrash.Phase) -> void:
	if phase == SiloLiftCrash.Phase.WRECK and state == State.DREAMING:
		_wake()


func _trip() -> void:
	state = State.WAKING
	var trip := TripScript.new()
	add_child(trip)
	trip.landed.connect(_wake)
	trip.start(player)


func _wake() -> void:
	state = State.WAKING
	set_physics_process(false)
	if player:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
	var flow := get_node_or_null(ForestNights.FLOW_PATH)
	if flow:
		flow.go(WAKE_TO, 0.0, WAKE_HOLD)
