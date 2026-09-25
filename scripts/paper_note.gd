class_name PaperNote
extends Area3D

const OPEN_SOUND = preload("res://audio/rpg/Audio/bookFlip1.ogg")
const CLOSE_SOUND = preload("res://audio/rpg/Audio/bookClose.ogg")
const FONT_LIB = preload("res://scripts/ui/font_library.gd")

const NOTE_TEXT: String = "I have been out here for weeks, I can't seem to get any bearing on where exactly I am.  I'm not sure what I did to deserve this but I think I am going to die out here.  I am out of food and water, and the only thing there is out here is that stuff.  I don't know why or how but it hasn't killed me yet.  I don't even get hungry anymore after drinking it.  I am not sure what it is doing to my body but it can't be good.  I hope I find my way out soon"

static var note_tex: Texture2D

var is_open: bool = false
var canvas_layer: CanvasLayer
var audio_player: AudioStreamPlayer

static func get_note_texture() -> Texture2D:
	if note_tex: return note_tex
	var path = "res://textures/dirty_paper_note.png"
	if FileAccess.file_exists(path + ".import"):
		var res = load(path)
		if res is Texture2D:
			note_tex = res; return note_tex
	var img = Image.load_from_file(ProjectSettings.globalize_path(path))
	if img and not img.is_empty():
		note_tex = ImageTexture.create_from_image(img)
	return note_tex

func _ready() -> void:
	if canvas_layer != null: return
	_init_3d_mesh()
	_init_ui()
	audio_player = AudioStreamPlayer.new(); add_child(audio_player)

func _init_3d_mesh() -> void:
	var mi = MeshInstance3D.new()
	var plane = PlaneMesh.new(); plane.size = Vector2(0.24, 0.186); plane.orientation = PlaneMesh.FACE_Y; mi.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = get_note_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.95
	mi.material_override = mat; add_child(mi)

	var col = CollisionShape3D.new(); var shape = BoxShape3D.new()
	shape.size = Vector3(0.36, 0.22, 0.30); col.shape = shape; add_child(col)

func _init_ui() -> void:
	canvas_layer = CanvasLayer.new(); canvas_layer.layer = 25; canvas_layer.visible = false; add_child(canvas_layer)
	var backdrop = ColorRect.new(); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.02, 0.03, 0.82); backdrop.mouse_filter = Control.MOUSE_FILTER_STOP; canvas_layer.add_child(backdrop)

	var tex_rect = TextureRect.new(); tex_rect.texture = get_note_texture()
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.set_anchors_preset(Control.PRESET_CENTER)
	tex_rect.custom_minimum_size = Vector2(780, 604)
	tex_rect.offset_left = -390; tex_rect.offset_top = -315
	tex_rect.offset_right = 390; tex_rect.offset_bottom = 289
	canvas_layer.add_child(tex_rect)

	var margin = MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 85)
	margin.add_theme_constant_override("margin_top", 95)
	margin.add_theme_constant_override("margin_right", 130)
	margin.add_theme_constant_override("margin_bottom", 70)
	tex_rect.add_child(margin)

	var body_label = Label.new(); body_label.text = NOTE_TEXT; body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 23)
	body_label.add_theme_color_override("font_color", Color(0.12, 0.09, 0.06, 0.95))
	body_label.add_theme_constant_override("line_spacing", 6)
	var hand_font = FONT_LIB.handwriting_font()
	if hand_font: body_label.add_theme_font_override("font", hand_font)
	margin.add_child(body_label)

	var hint = Label.new(); hint.text = "[ Press E or ESC to put down ]"
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -200; hint.offset_right = 200; hint.offset_top = -36; hint.offset_bottom = -12
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.72, 0.70, 0.65, 0.85))
	var hint_font = FONT_LIB.kinetic_font()
	if hint_font: hint.add_theme_font_override("font", hint_font)
	canvas_layer.add_child(hint)

func get_interaction_prompt() -> String:
	return "" if is_open else "Read Note with E"

func get_interaction_font() -> Font:
	return FONT_LIB.kinetic_font()

func interact(_player: Node) -> void:
	if canvas_layer == null: _ready()
	if is_open: close_note()
	else: open_note()

func open_note() -> void:
	is_open = true; canvas_layer.visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if audio_player and is_inside_tree():
		audio_player.stream = OPEN_SOUND; audio_player.pitch_scale = randf_range(0.95, 1.05); audio_player.play()

func close_note() -> void:
	is_open = false; canvas_layer.visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if audio_player and is_inside_tree():
		audio_player.stream = CLOSE_SOUND; audio_player.pitch_scale = randf_range(0.95, 1.05); audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if not is_open: return
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_E]) or (event is InputEventMouseButton and event.pressed):
		close_note(); get_viewport().set_input_as_handled()
