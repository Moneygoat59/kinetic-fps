class_name AptUse
extends StaticBody3D
## One interaction point in the apartment (marker_use_<id> in a kit piece; the text and sound come from AptUses.SPECS).
## The player's aim ray finds it (get_interaction_prompt / get_interaction_detail / interact). Emits `used(id, count)`;
## ApartmentLevel listens (all uses are in the "apt_use" group). Strings are built once per use, not per frame.
## A use with a row in apt_check_moves.gd is acted out first (AptCheck: lean in, work the piece) and reports when done.

signal used(id: StringName, count: int)

const Uses = preload("res://scripts/apartment/apt_uses.gd")
const GROUP := &"apt_use"
const COOLDOWN_MS := 450             # a held or double-tapped key is one check

var id: StringName
var count := 0
var _title := ""
var _base_sub := ""
var _repeat := ""
var enabled := true                  # false: no prompt, no use (the player's aim skips it: can_interact)
var _sub := ""
var _audio: AudioStreamPlayer3D
var _check: AptCheck
var _last_ms := -100000


static func mount(marker: Node3D, use_id: StringName) -> AptUse:
	var spec := Uses.spec(use_id)
	if marker == null or spec.is_empty():
		push_warning("AptUse: no spec for '%s'" % use_id)
		return null
	var use := AptUse.new()
	use.name = "use_" + String(use_id)
	use.id = use_id
	use._title = spec[0]
	use._base_sub = spec[1]
	use._sub = spec[1]
	use._repeat = spec[4] if spec.size() > 4 else Uses.REPEAT_SUB
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = spec[3]
	use.add_child(shape)
	use._audio = AudioStreamPlayer3D.new()
	use._audio.stream = load(spec[2])
	use._audio.unit_size = 2.0
	use._audio.max_distance = 12.0
	use.add_child(use._audio)
	marker.add_child(use)
	use.add_to_group(GROUP)
	use._check = AptCheck.mount(use)
	return use


func can_interact() -> bool:
	return enabled


func get_interaction_prompt() -> String:
	return _title


func get_interaction_detail() -> String:
	return _sub


func interact(player: Node) -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	if now - _last_ms < COOLDOWN_MS:
		return
	_last_ms = now
	count += 1
	_sub = _repeat % [_base_sub, count]
	if _check and player is Player and _check.perform(player as Player):
		return                                         # AptCheck plays the sound on each move and calls report()
	play_sound()
	report()


func play_sound() -> void:
	if _audio.stream:
		_audio.pitch_scale = randf_range(0.94, 1.06)
		_audio.play()


## Tells the listeners this use was made (at once, or when AptCheck has acted it out).
func report() -> void:
	used.emit(id, count)
