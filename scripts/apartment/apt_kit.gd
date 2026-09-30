class_name AptKit
extends RefCounted
## Apartment kit catalog (models/generated/apt_kit/*.glb, built by tools/blender/props/apt_kit.py; conventions in
## tools/blender/apt/apt_lib.py, shared sizes in tools/blender/apt/apt_dims.py - mirror them here).
## Same placement contract as the Outpost 73 kit: origin at the base centre, front faces +Z; wall pieces have their back on z = 0.
##   AptKit.spawn(&"pill_bottle", nightstand, Transform3D(Basis(), Vector3(0.1, AptKit.NIGHT_H, -0.1)))
## Shells place pieces with marker_kit_<piece>__<n>[__open][__no_<part>] empties; BunkerKit.furnish(model, AptKit.DIR) spawns them.

const DIR := "res://models/generated/apt_kit/"
const COUNTER_H := 0.92      # tabletop heights (tabletop pieces go here)
const TABLE_H := 0.75
const COFFEE_H := 0.42
const NIGHT_H := 0.56
const DRESSER_H := 0.86
const VANITY_H := 0.84
const SIDE_H := 0.55
const CEILING := 2.7

const FIXTURES: Array[StringName] = [&"door_interior", &"door_front", &"window_blinds", &"window_blinds_raised", &"radiator",
	&"light_switch", &"outlet", &"ceiling_pendant", &"smoke_detector"]
const LIVING: Array[StringName] = [&"sofa", &"armchair", &"coffee_table", &"tv_console", &"bookshelf", &"floor_lamp",
	&"table_lamp", &"side_table", &"plant_snake", &"rug_living", &"picture_frame_a", &"picture_frame_b", &"picture_frame_c",
	&"picture_frame_d", &"wall_clock"]
const KITCHEN: Array[StringName] = [&"counter_base", &"counter_drawers", &"counter_sink", &"stove", &"fridge", &"wall_cabinet",
	&"wall_shelf_pantry", &"dining_table", &"chair_wood", &"toaster", &"kettle", &"dish_rack", &"canisters", &"fruit_bowl",
	&"trash_bin"]
const BATH: Array[StringName] = [&"toilet", &"vanity", &"medicine_cabinet", &"vanity_light", &"bathtub", &"towel_rack", &"bath_mat"]
const BEDROOM: Array[StringName] = [&"bed_double", &"nightstand", &"dresser", &"wardrobe_open"]
const SMALLS: Array[StringName] = [&"pill_bottle", &"pill_bottle_tall", &"pill_bottle_wide", &"pill_bottle_small",
	&"pill_organizer", &"blister_pack", &"water_glass", &"alarm_clock", &"shoes_pair", &"shoes_pair_b", &"shoe_tray",
	&"cleaning_row", &"soap_stack", &"tp_pyramid", &"book_stack"]
## The flat gone to squalor (AptSqualor): rubbish and neglect, placed only on the nights that ask for it.
const MESS: Array[StringName] = [&"trash_bag", &"trash_bag_slump", &"trash_bag_white", &"trash_bin_full", &"pizza_box",
	&"pizza_box_open", &"pizza_stack", &"takeout", &"cans_litter", &"bottles_litter", &"paper_litter", &"chip_bag", &"mail_pile",
	&"parcel_boxes", &"clothes_pile", &"clothes_pile_small", &"dish_pile", &"mug_mould", &"fruit_bowl_rotten", &"bed_unmade",
	&"towel_floor", &"window_blinds_shut", &"window_blinds_shut_check", &"trash_heap", &"trash_heap_small", &"litter_spread_a",
	&"litter_spread_b", &"litter_spread_c", &"pizza_tower", &"pot_crusted", &"counter_clutter", &"paper_cup"]
const GROUPS := [FIXTURES, LIVING, KITCHEN, BATH, BEDROOM, SMALLS, MESS]

## Kept loaded so building a flat does not hit the disk for each piece.
static var _held: Array[PackedScene] = []


static func spawn(piece: StringName, parent: Node, xform := Transform3D.IDENTITY) -> Node3D:
	return O73Kit.spawn(piece, parent, xform, DIR)


static func preload_all() -> void:
	if not _held.is_empty():
		return
	for group in GROUPS:
		for piece in group:
			var scene := load(O73Kit.path(piece, DIR)) as PackedScene
			if scene:
				_held.append(scene)
