class_name OutpostBuilding
extends OutpostBunker
## Outposts 02 and 03: the amber wells at the far ends of hub routes 02 and 03. The same bunker as Outpost 73 (door,
## lights, screens, kit furniture) built from its variant models (tools/blender/props/outpost_variants.py):
##   02  NO CARRIER: a tree came down over the roof and took the dish; interior mirrored.
##   03  SEIZED: the pump jack stalled and the well overflowed (crystal growth, storage tanks); its pump stays still.
## The item on the desk is the well's route key (bunker_key.gd) instead of the field dosimeter; the roof beacon and the
## pump cabinet lamp burn in the route's channel colour. API for DeadForestEvent / dev tools: build_outpost,
## check_interaction (inherited), key_acquired(outpost_id).

signal key_acquired(outpost_id: int)

const KeyScript = preload("res://scripts/bunker/bunker_key.gd")
const MODEL_FMT := "res://models/generated/outpost%02d_bunker.glb"
const IDS: Array[int] = [2, 3]
const SEIZED: Array[int] = [3]            # wells whose pump jack has stalled: no pump animation or sound

var outpost_id: int = 2
var theme_color: Color = Color(0.15, 0.8, 1.0)


## Keeps the variant models and the key case loaded so an outpost built mid-game does not hit the disk.
static func preload_variants() -> void:
	for id in IDS:
		load(MODEL_FMT % id)
	load(O73Kit.path(KeyScript.DEVICE))


func build_outpost(terrain: Node3D, pos_x: float, pos_z: float, id: int, col: Color) -> void:
	if id not in IDS:
		push_error("OutpostBuilding: no outpost %d" % id)
		return
	outpost_id = id
	theme_color = col
	build_bunker(terrain, pos_x, pos_z)
	if _roof_light:
		_roof_light.light_color = col
	if _beacon:
		_beacon.emission = col


func _model_path() -> String:
	return MODEL_FMT % outpost_id


func _route() -> int:
	return HubRoutes.Route.W02 if outpost_id == 2 else HubRoutes.Route.W03


func _setup_pump() -> void:
	if outpost_id not in SEIZED:
		super._setup_pump()


func _setup_pickup() -> void:
	var anchor := _marker("marker_pickup")
	if anchor == null:
		push_warning("OutpostBuilding: marker_pickup missing from " + _model_path())
		return
	pickup = KeyScript.new()
	anchor.add_child(pickup)
	pickup.setup("%02d" % outpost_id, theme_color)
	pickup.claimed.connect(func() -> void: key_acquired.emit(outpost_id))
