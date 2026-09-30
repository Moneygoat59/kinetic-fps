class_name AptJournal
extends Node
## The open journal (kit piece journal_open, its AptUse "journal": REASSURE YOURSELF). Each use: the walker picks it up to
## their face, writes LINE with the pen (the ink appears as the nib moves, scratching), holds it a moment and puts it back.
## Every use adds a new line (JournalPage turns the spread when it fills). The pages are a SubViewport drawn by JournalPage,
## on the piece's `panels` mesh, faintly self-lit so the ink reads by the light of the TV. The player is frozen while holding.

enum State { RESTING, LIFTING, WRITING, LOWERING }

const LINE := "I am not a bad person"
const HELD := Vector3(0.0, -0.03, -0.22)      # camera-space: where the line being written is held
const HELD_TILT := 70.0              # degrees the book is tipped up toward the eyes
const FOCUS_FOV := 55.0              # the view narrows onto the page while holding it (the presenter eases it back)
const LIFT := 0.7
const CHAR_TIME := 0.075
const LOOK := 0.6                    # seconds holding it, reading it back, before it goes down
const GLOW_REST := 0.1
const GLOW_HELD := 0.55
const SND_SCRATCH := [preload("res://audio/ui/Audio/scratch_001.ogg"), preload("res://audio/ui/Audio/scratch_002.ogg"),
	preload("res://audio/ui/Audio/scratch_003.ogg")]
const SND_PLACE = preload("res://audio/rpg/Audio/bookPlace1.ogg")
const SND_TURN = preload("res://audio/rpg/Audio/bookFlip1.ogg")

var state := State.RESTING
var player: Player
var book: Node3D
var pen: JournalPen
var use: AptUse
var page: JournalPage
var _panels: MeshInstance3D
var _pen_node: Node3D
var _mat: StandardMaterial3D
var _rest: Transform3D
var _held: Transform3D
var _written := -1
var _fov := 75.0


## Makes `piece` a live journal for `p`. Returns it (added under the piece), or null if the piece is not a journal.
static func mount(piece: Node3D, p: Player) -> AptJournal:
	if piece == null or p == null:
		return null
	var journal := AptJournal.new()
	journal.name = "AptJournal"
	journal.player = p
	journal.book = piece
	journal._panels = piece.find_child("panels", true, false) as MeshInstance3D
	journal._pen_node = piece.find_child("pen", true, false) as Node3D
	journal.use = piece.find_child("use_journal", true, false) as AptUse
	if journal._panels == null or journal._pen_node == null or journal.use == null:
		push_warning("AptJournal: %s lacks panels / pen / use_journal" % piece.name)
		journal.free()
		return null
	piece.add_child(journal)
	return journal


func _ready() -> void:
	page = JournalPage.in_viewport(self)
	_mat = StandardMaterial3D.new()
	_mat.albedo_texture = page.texture()
	_mat.emission_enabled = true
	_mat.emission_texture = _mat.albedo_texture
	_mat.emission_energy_multiplier = GLOW_REST
	_mat.roughness = 1.0
	_mat.metallic_specular = 0.2
	_panels.material_override = _mat
	pen = JournalPen.new(_pen_node, page)
	use.used.connect(_on_used)


func _on_used(_id: StringName, _count: int) -> void:
	if state != State.RESTING or not is_instance_valid(player) or player.camera == null:
		return
	state = State.LIFTING
	use.enabled = false
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.velocity = Vector3.ZERO
	_rest = book.global_transform
	var turn := page.spread()
	page.lines.append(LINE)
	var v := page.uv_of(page.line_origin(page.lines.size() - 1)).y            # held so the new line sits at HELD
	var cam := player.camera.global_transform
	_held = cam * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(HELD_TILT)), HELD) 		* Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, -(v - 0.5) * JournalPen.PAGE_H))
	page.shown = 0
	pen.start_line(LINE)
	_written = 0
	page.refresh()
	if page.spread() != turn and page.lines.size() > 1:
		SoundManager.play(SND_TURN, -6.0, 0.05)
	_fov = player.camera.fov
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player.camera, "fov", FOCUS_FOV, LIFT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_carry, 0.0, 1.0, LIFT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_mat, "emission_energy_multiplier", GLOW_HELD, LIFT)
	tw.tween_property(pen.node, "transform", pen.at(0.0), LIFT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.chain().tween_callback(_write)


func _write() -> void:
	state = State.WRITING
	var tw := create_tween()
	tw.tween_method(_ink, 0.0, float(LINE.length()), LINE.length() * CHAR_TIME)
	tw.tween_interval(LOOK)
	tw.tween_callback(_lower)


func _lower() -> void:
	state = State.LOWERING
	page.shown = -1
	page.refresh()
	var tw := create_tween().set_parallel(true)
	if is_instance_valid(player):
		tw.tween_property(player.camera, "fov", _fov, LIFT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_carry, 1.0, 0.0, LIFT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_mat, "emission_energy_multiplier", GLOW_REST, LIFT)
	tw.tween_property(pen.node, "transform", pen.rest, LIFT * 0.8)
	tw.chain().tween_callback(_put_down)


func _put_down() -> void:
	state = State.RESTING
	SoundManager.play(SND_PLACE, -4.0, 0.05)
	use.enabled = true
	if is_instance_valid(player):
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)


func _carry(w: float) -> void:
	book.global_transform = _rest.interpolate_with(_held, w)


## Tween step while writing: `chars` characters of ink so far (fractional: the nib is between letters).
func _ink(chars: float) -> void:
	var whole := mini(int(chars), LINE.length())
	if whole != _written:
		_written = whole
		page.shown = whole
		page.refresh()
		if whole % 3 == 1:
			SoundManager.play(SND_SCRATCH[whole % SND_SCRATCH.size()], -14.0, 0.15)
	pen.node.transform = pen.at(chars)

