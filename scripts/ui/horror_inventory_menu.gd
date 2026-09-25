class_name HorrorInventoryMenu
extends CanvasLayer

signal item_equipped(item_id: String, slot_idx: int)
signal item_used(item_id: String, slot_idx: int)
signal inventory_toggled(is_open: bool)

const SOUND_OPEN = preload("res://audio/ui/Audio/open_001.ogg")
const SOUND_CLOSE = preload("res://audio/ui/Audio/close_001.ogg")
const SOUND_SELECT = preload("res://audio/ui/Audio/select_001.ogg")
const SOUND_EQUIP = preload("res://audio/ui/Audio/switch_001.ogg")
const SOUND_USE = preload("res://audio/ui/Audio/confirmation_001.ogg")
const TURNTABLE_SCRIPT = preload("res://scripts/ui/item_turntable_3d.gd")
const ITEM_DB = preload("res://scripts/ui/horror_item_db.gd")
const THEME = preload("res://scripts/ui/horror_ui_theme.gd")

var is_open: bool = false
var slots: Array[Dictionary] = []
var selected_idx: int = 0
var equipped_idx: int = 0

var panel: TextureRect
var body_rect: TextureRect
var turntable: Control
var slot_bgs: Array[TextureRect] = []
var slot_icons: Array[TextureRect] = []
var slot_badges: Array[TextureRect] = []
var sfx: AudioStreamPlayer

const POSITIONS: Array[Vector2] = [
	Vector2(20, 95),   # 0: Right Hand (Blaster)
	Vector2(250, 95),  # 1: Left Hand (Torch)
	Vector2(20, 30),   # 2: Chest Rig (Grenades)
	Vector2(250, 30),  # 3: Waist Belt (Dosimeter)
	Vector2(20, 160),  # 4: Thigh Med (Injector)
	Vector2(250, 160), # 5: Leg Ammo (Cell)
	Vector2(139, 4),   # 6: Cranium Relic (Basalt)
	Vector2(139, 205)  # 7: Pouch Reserve
]

func _ready() -> void:
	layer = 120
	visible = false
	sfx = AudioStreamPlayer.new(); sfx.volume_db = -4.0; add_child(sfx)
	slots = ITEM_DB.get_starter_inventory()
	_build_ui()
	_select_slot(0)

func toggle() -> void:
	if is_open: close()
	else: open()

func open() -> void:
	is_open = true; visible = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_play_sfx(SOUND_OPEN); emit_signal("inventory_toggled", true); _select_slot(selected_idx)

func close() -> void:
	is_open = false; visible = false; Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_play_sfx(SOUND_CLOSE); emit_signal("inventory_toggled", false)

func update_health(_hp: float) -> void:
	pass

func _play_sfx(stream: AudioStream) -> void:
	if sfx and stream: sfx.stream = stream; sfx.play()

func _build_ui() -> void:
	panel = TextureRect.new()
	panel.texture = THEME.get_window_bg()
	panel.position = Vector2(50, 45); panel.size = Vector2(540, 270)
	add_child(panel)

	body_rect = TextureRect.new()
	body_rect.texture = THEME.get_body_silhouette()
	body_rect.position = Vector2(95, 20); body_rect.size = Vector2(140, 220)
	body_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	body_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	panel.add_child(body_rect)

	for i in range(POSITIONS.size()):
		var slot_ctrl = Control.new()
		slot_ctrl.position = POSITIONS[i]; slot_ctrl.size = Vector2(54, 54)
		var bg = TextureRect.new(); bg.texture = THEME.get_slot_default(); bg.size = Vector2(54, 54)
		slot_ctrl.add_child(bg); slot_bgs.append(bg)

		var ic = TextureRect.new(); ic.position = Vector2(5, 5); ic.size = Vector2(44, 44)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_ctrl.add_child(ic); slot_icons.append(ic)

		var badge = TextureRect.new(); badge.texture = THEME.get_slot_equipped_badge()
		badge.position = Vector2(34, 2); badge.size = Vector2(18, 18); badge.visible = false
		slot_ctrl.add_child(badge); slot_badges.append(badge)

		var click_btn = TextureButton.new(); click_btn.size = Vector2(54, 54)
		var idx = i; click_btn.pressed.connect(func(): _select_slot(idx))
		slot_ctrl.add_child(click_btn)
		panel.add_child(slot_ctrl)

	var btn_box = HBoxContainer.new(); btn_box.position = Vector2(350, 210)
	btn_box.add_theme_constant_override("separation", 15); panel.add_child(btn_box)

	var btn_eq = TextureButton.new(); btn_eq.texture_normal = THEME.get_btn_equip()
	btn_eq.pressed.connect(_on_equip_pressed); btn_box.add_child(btn_eq)

	var btn_act = TextureButton.new(); btn_act.texture_normal = THEME.get_btn_action()
	btn_act.pressed.connect(_on_use_pressed); btn_box.add_child(btn_act)

	var btn_cl = TextureButton.new(); btn_cl.texture_normal = THEME.get_btn_close()
	btn_cl.pressed.connect(close); btn_box.add_child(btn_cl)

	var tt_frame = TextureRect.new(); tt_frame.texture = THEME.get_turntable_frame()
	tt_frame.position = Vector2(335, 20); tt_frame.size = Vector2(180, 180); panel.add_child(tt_frame)

	turntable = TURNTABLE_SCRIPT.new(); turntable.position = Vector2(335, 20)
	turntable.size = Vector2(180, 180); panel.add_child(turntable)
	_refresh_slots()

func _refresh_slots() -> void:
	for i in range(slots.size()):
		var it = slots[i]
		slot_icons[i].texture = null if it.is_empty() else THEME.load_icon(it["icon_path"])
		slot_badges[i].visible = (i == equipped_idx)
		slot_bgs[i].texture = THEME.get_slot_selected() if i == selected_idx else THEME.get_slot_default()

func _select_slot(idx: int) -> void:
	if idx < 0 or idx >= slots.size(): return
	selected_idx = idx
	_refresh_slots()
	_play_sfx(SOUND_SELECT)
	if turntable and not slots[idx].is_empty():
		turntable.load_model(slots[idx].get("model_path", ""))

func _on_equip_pressed() -> void:
	if slots[selected_idx].is_empty(): return
	equipped_idx = selected_idx
	_refresh_slots()
	_play_sfx(SOUND_EQUIP)
	emit_signal("item_equipped", slots[selected_idx]["id"], selected_idx)

func _on_use_pressed() -> void:
	if slots[selected_idx].is_empty(): return
	_play_sfx(SOUND_USE)
	emit_signal("item_used", slots[selected_idx]["id"], selected_idx)
