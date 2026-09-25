class_name HorrorUiTheme
extends RefCounted

static var _cache: Dictionary = {}

static func get_tex(res_path: String) -> Texture2D:
	if _cache.has(res_path):
		return _cache[res_path]
	var global_p = ProjectSettings.globalize_path(res_path)
	var img = Image.load_from_file(global_p)
	if img and not img.is_empty():
		var itex = ImageTexture.create_from_image(img)
		_cache[res_path] = itex
		return itex
	return null

static func get_window_bg() -> Texture2D:
	return get_tex("res://textures/ui/bloody_autopsy_bg.png")

static func get_body_silhouette() -> Texture2D:
	return get_tex("res://textures/ui/body_silhouette.png")

static func get_slot_default() -> Texture2D:
	return get_tex("res://textures/ui/bloody_slot_default.png")

static func get_slot_selected() -> Texture2D:
	return get_tex("res://textures/ui/bloody_slot_selected.png")

static func get_slot_equipped_badge() -> Texture2D:
	return get_tex("res://textures/ui/bloody_slot_equipped.png")

static func get_btn_equip() -> Texture2D:
	return get_tex("res://textures/ui/bloody_btn_equip.png")

static func get_btn_action() -> Texture2D:
	return get_tex("res://textures/ui/bloody_btn_action.png")

static func get_btn_close() -> Texture2D:
	return get_tex("res://textures/ui/bloody_btn_close.png")

static func get_turntable_frame() -> Texture2D:
	return get_tex("res://textures/ui/bloody_turntable_frame.png")

static func get_hud_dock() -> Texture2D:
	return get_tex("res://textures/ui/bloody_hud_dock.png")

static func get_hud_pip_active() -> Texture2D:
	return get_tex("res://textures/ui/bloody_pip_lit.png")

static func get_hud_pip_inactive() -> Texture2D:
	return get_tex("res://textures/ui/bloody_pip_unlit.png")

static func load_icon(path: String) -> Texture2D:
	return get_tex(path)
