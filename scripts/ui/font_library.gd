class_name FontLibrary
extends RefCounted

static var _cache: Dictionary = {}

static func get_font(filename: String) -> Font:
	if _cache.has(filename):
		return _cache[filename]
	var path = "res://fonts/" + filename
	var f = FontFile.new()
	if f.load_dynamic_font(path) == OK:
		_cache[filename] = f
		return f
	if FileAccess.file_exists(path + ".import"):
		var res = load(path)
		if res is Font:
			_cache[filename] = res
			return res
	return null

# Weathered vintage typewriter - ideal for dream monologues, lore notes, journals
static func dream_font() -> Font:
	return get_font("SpecialElite-Regular.ttf")

# Authentic CRT phosphor terminal - ideal for computer consoles & bio-kinetic logs
static func terminal_font() -> Font:
	return get_font("VT323-Regular.ttf")

# Military/industrial technical HUD - ideal for dosimeters, radiation readings, diagnostics
static func tech_font() -> Font:
	return get_font("ShareTechMono-Regular.ttf")

# Crisp 8-bit retro pixel font - ideal for survival inventory, quick-slots, badges
static func pixel_font() -> Font:
	return get_font("Silkscreen-Regular.ttf")

# Brutalist high-velocity sci-fi - ideal for speedometer, sector banners, speed milestones
static func kinetic_font() -> Font:
	return get_font("Oxanium-SemiBold.ttf")

# Off-kilter surrealist monospace - ideal for Cruelty Squad / weird anomaly flavor
static func surreal_font() -> Font:
	return get_font("SyneMono-Regular.ttf")

# Classic retro 80s arcade - ideal for arcade scoreboards and retro pickups
static func arcade_font() -> Font:
	return get_font("PressStart2P-Regular.ttf")

# Authentic survivor handwriting - desperate, messy pen scrawl
static func handwriting_font() -> Font:
	var f = get_font("NothingYouCouldDo.ttf")
	if f: return f
	f = get_font("CoveredByYourGrace.ttf")
	if f: return f
	f = get_font("ReenieBeanie.ttf")
	return f if f else get_font("WalterTurncoat.ttf")
