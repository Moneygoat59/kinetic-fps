class_name ApartmentLevel
extends Node3D
## The apartment (scenes/levels/apartment.tscn, the first level): builds the shell (models/generated/apartment.glb, plan in
## tools/blender/props/apartment.py), furnishes it with the apartment kit (marker_kit_* -> AptKit pieces, each live through
## AptProp), lights it with an AptMood picked by visit, stands the player at marker_spawn and fades in from black.
## Its uses (AptUse: CHECK LOCKS, CHECK STOVE, SLEEP...) report here; SLEEP hands over to `next_level` through LevelFlow
## (the forest, or where the night just ended says sleep leads: ForestNights "sleep"),
## LEAVE at the front door only ever gets the walker's thought (they cannot go). What they think (on waking, at a check the
## first time, at the door) is AptThoughts.
## Where the walker comes to follows the night just ended (ForestNights "wake"): the bed as usual, or the couch in the small
## hours with the TV showing static and the journal open on the coffee table (AptWake, AptTvStatic, AptJournal). What they
## come to follows it too (ForestNights "flat"): kept, or squalor after the lift crash (AptSqualor, mood squalor).

signal use_made(id: StringName, count: int)

const MODEL := "res://models/generated/apartment.glb"
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const STEP_L = preload("res://audio/impacts/Audio/footstep_wood_000.ogg")
const STEP_R = preload("res://audio/impacts/Audio/footstep_wood_002.ogg")
const ROOM_TONE = preload("res://audio/ambient/wind_long_loop.ogg")
const MOOD_BY_VISIT: Array[StringName] = [&"golden_hour", &"night"]
const FADE_IN := 2.4
const SLEEP_USE := &"sleep"
const FLOW_PATH := ^"/root/LevelFlow"      # autoload (scripts/level_flow.gd); absent in tool runs
const WAKE_COUCH := &"couch"
const WAKE_MOODS := {&"couch": &"small_hours"}   # where the walker comes to -> the light they come to in
const FLAT_SQUALOR := &"squalor"
const FLAT_MOODS := {&"squalor": &"squalor"}     # the state of the flat -> its light (a wake mood wins)
const SOFA_MARKER := "marker_kit_sofa__"
const TV_MARKER := "marker_kit_tv_console__"
const TABLE_MARKER := "marker_kit_coffee_table__"
const JOURNAL := &"journal_open"
## on the coffee table (its marker's space): the free strip between the remotes and the coasters, near edge, squared to the
## table and turned to face the end where the walker stands up
const JOURNAL_ON_TABLE := Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0.04, 0.42, 0.17))

@export var player: Player
@export var next_level: StringName = &"forest"
@export var mood: StringName = &""          # empty: pick by the wake, else by visit (MOOD_BY_VISIT)
@export var wake: StringName = &""          # empty: from the night just ended (ForestNights.woke_from); bed or couch
@export var flat: StringName = &""          # empty: from the night just ended (ForestNights "flat"); kept or squalor

var model: Node3D
var sun: DirectionalLight3D


func _ready() -> void:
	var scene := load(MODEL) as PackedScene
	if scene == null:
		push_error("ApartmentLevel: cannot load " + MODEL)
		return
	model = scene.instantiate() as Node3D
	add_child(model)
	var night := ForestNights.woke_from(get_tree())
	if wake == &"":
		wake = night.get("wake", &"bed")
	if flat == &"":
		flat = night.get("flat", &"kept")
	next_level = night.get("sleep", next_level)
	if flat == FLAT_SQUALOR:
		AptSqualor.prepare(model)
	KitScript.furnish(model, AptKit.DIR)
	if flat == FLAT_SQUALOR:
		AptSqualor.dress(self)
	sun = AptMood.apply(self, _pick_mood(), model)
	_room_tone()
	_place_player()
	_wake_up()
	AptThoughts.woke(self, flat)
	for use in get_tree().get_nodes_in_group(AptUse.GROUP):
		(use as AptUse).used.connect(_on_use)
	_fade_in()


func _pick_mood() -> StringName:
	if mood != &"":
		return mood
	if WAKE_MOODS.has(wake):
		return WAKE_MOODS[wake]
	if FLAT_MOODS.has(flat):
		return FLAT_MOODS[flat]
	var flow := get_node_or_null(FLOW_PATH)
	var visit: int = flow.visits(&"apartment") if flow else 0
	return MOOD_BY_VISIT[mini(visit, MOOD_BY_VISIT.size() - 1)]


func _place_player() -> void:
	if player == null:
		return
	player.enable_walk_mode()
	player.step_l = STEP_L
	player.step_r = STEP_R
	var spawn := model.get_node_or_null("marker_spawn") as Node3D
	if spawn:
		player.global_position = spawn.global_position + Vector3.UP * 0.95
		player.rotation.y = spawn.global_rotation.y
	player.velocity = Vector3.ZERO
	if player.health:
		player.health.spawn_position = player.global_position


func _wake_up() -> void:
	if wake != WAKE_COUCH:
		return
	AptTvStatic.mount(_marker(TV_MARKER))
	var journal := AptKit.spawn(JOURNAL, _marker(TABLE_MARKER), JOURNAL_ON_TABLE)
	AptJournal.mount(journal, player)
	var sequence := AptWake.couch(player, _marker(SOFA_MARKER), journal)
	if sequence:
		add_child(sequence)


func _marker(prefix: String) -> Node3D:
	for child in model.get_children():
		if String(child.name).begins_with(prefix):
			return child as Node3D
	return null


func _room_tone() -> void:
	var tone := AudioStreamPlayer.new()             # the city outside, through closed windows
	tone.stream = ROOM_TONE
	tone.volume_db = -30.0
	tone.pitch_scale = 0.8
	tone.autoplay = true
	add_child(tone)


func _on_use(id: StringName, count: int) -> void:
	use_made.emit(id, count)
	var flow := get_node_or_null(FLOW_PATH)
	if id == SLEEP_USE and flow:
		flow.go(next_level)
	else:
		AptThoughts.used(self, id, count)


func _fade_in() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_property(black, "color:a", 0.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(canvas.queue_free)
