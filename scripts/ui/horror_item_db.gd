class_name HorrorItemDb
extends RefCounted

enum ItemType { WEAPON, ORDNANCE, DIAGNOSTIC, LIGHT, MEDICAL, AMMO, RELIC }

static func create_item(id: String, name: String, type: ItemType, model_path: String, icon_path: String, desc: String, qty: int = 1, heal_val: float = 0.0) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"model_path": model_path,
		"icon_path": icon_path,
		"desc": desc,
		"qty": qty,
		"heal_val": heal_val,
		"type_label": _get_type_label(type)
	}

static func _get_type_label(type: ItemType) -> String:
	match type:
		ItemType.WEAPON: return "SIDEARM"
		ItemType.ORDNANCE: return "ORDNANCE"
		ItemType.DIAGNOSTIC: return "DEVICE"
		ItemType.LIGHT: return "UTILITY"
		ItemType.MEDICAL: return "MEDICAL"
		ItemType.AMMO: return "MUNITIONS"
		ItemType.RELIC: return "ANOMALY"
	return "ITEM"

static func get_starter_inventory() -> Array[Dictionary]:
	return [
		create_item(
			"blaster", "MK-2 KINETIC BLASTER", ItemType.WEAPON,
			"res://models/kenney_blasters/blaster.glb", "res://textures/ui/icons/icon_blaster.png",
			"Standard issue kinetic sidearm. High-velocity plasma slugs penetrate light armor. Primary defense against anomalous threats."
		),
		create_item(
			"grenade", "PINE-FRAG GRENADE", ItemType.ORDNANCE,
			"res://models/kenney_blasters/grenade-a.glb", "res://textures/ui/icons/icon_grenade.png",
			"Concussive shrapnel explosive with a 3.5s pyrotechnic delay fuse. Highly effective for clearing hostile clusters.",
			3
		),
		create_item(
			"dosimeter", "FIELD DOSIMETER MK-IV", ItemType.DIAGNOSTIC,
			"res://models/finder_device.glb", "res://textures/ui/icons/icon_dosimeter.png",
			"Analog ionizing radiation tracker with electromechanical meter needle. Audio clicks increase exponentially near toxic amber sludge."
		),
		create_item(
			"torch", "CHEMICAL SURVIVAL TORCH", ItemType.LIGHT,
			"res://models/curated_cc0/FireTorch03_Art.glb", "res://textures/ui/icons/icon_torch.png",
			"High-intensity magnesium flare torch. Pierces dense subterranean mist and dark forest canopy with 360-degree illumination."
		),
		create_item(
			"med_injector", "COAGULANT AUTO-INJECTOR", ItemType.MEDICAL,
			"res://models/kenney_blasters/bullet-foam-thick.glb", "res://textures/ui/icons/icon_med_injector.png",
			"Pneumatic dermal syringe filled with synthetic coagulant and adrenaline. Instantly stabilizes vital signs and restores 45 HP.",
			2, 45.0
		),
		create_item(
			"ammo_cell", "DENSE ENERGY CELL", ItemType.AMMO,
			"res://models/kenney_blasters/clip-large.glb", "res://textures/ui/icons/icon_ammo_cell.png",
			"High-density tritium fuel cartridge. Supplies 60 rounds of pressurized plasma discharges for kinetic weaponry.",
			60
		),
		create_item(
			"needle_shard", "ANCIENT BASALT SHARD", ItemType.RELIC,
			"res://models/spikes/spike_tall_needle_4s.glb", "res://textures/ui/icons/icon_basalt_shard.png",
			"A chisel-carved fragment from the 1,000-year-old warning spikes. Faint radioactive warmth still emanates from its faceted core."
		),
		{}
	]
