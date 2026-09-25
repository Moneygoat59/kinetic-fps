class_name GalleryCatalog
extends RefCounted

const CATEGORY_NAMES: Dictionary = {
	"root": "Speculative Machinery & Props",
	"spikes": "Ancient Needle Spikes",
	"dead_forest": "Dead Forest Biome",
	"foliage": "Foliage & Wilderness",
	"kenney_blasters": "Kenney Blasters & Weapons",
	"kenney_fps": "Kenney FPS Prototypes",
	"kenney_platformer": "Kenney Platformer Kit",
	"curated_cc0": "Curated CC0 Relics",
	"cc0_tree": "CC0 Modular Trees",
	"kaykit_space_base": "KayKit Space Base",
	"industrial": "Industrial Kit",
	"kaykit_dungeon": "KayKit Dungeon Remastered",
	"kaykit_hexagons": "KayKit Hexagons"
}

static func build_catalog() -> Array[Dictionary]:
	var raw_files: Array[String] = []
	_scan_dir("res://models", raw_files)
	raw_files.sort()

	var cat_map: Dictionary = {}
	for key in CATEGORY_NAMES:
		cat_map[key] = []

	for path in raw_files:
		var rel = path.trim_prefix("res://models/")
		var parts = rel.split("/")
		var cat_key = parts[0] if parts.size() > 1 else "root"
		if not cat_map.has(cat_key):
			cat_map[cat_key] = []
		cat_map[cat_key].append(path)

	var catalog: Array[Dictionary] = []
	for key in CATEGORY_NAMES:
		var list = cat_map.get(key, [])
		if list.size() > 0:
			catalog.append({
				"id": key,
				"name": CATEGORY_NAMES[key],
				"count": list.size(),
				"models": list
			})
	return catalog

static func _scan_dir(path: String, out_list: Array[String]) -> void:
	var dir = DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path = path + "/" + file_name
		if dir.current_is_dir():
			_scan_dir(full_path, out_list)
		else:
			var ext = file_name.get_extension().to_lower()
			if ext in ["glb", "gltf", "fbx", "obj"]:
				out_list.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
