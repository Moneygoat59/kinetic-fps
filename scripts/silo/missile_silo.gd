class_name MissileSilo
extends Node3D
## Missile Silo 00: the bore at the end of relay route 00 (model: tools/blender/props/missile_silo.py). Something impossibly
## large launched from it: a 112 m shaft with no visible floor, six cap petals blown open round the rim. Instances the model,
## furnishes the level 09 launch control and the data room beside it (SiloServers) with kit props, darkens the bore with AbyssFog, lays the blast-flattened forest
## (SiloBlast) and wires the lights (SiloAmbience), the launch desk (SiloConsole), the generator hall below launch
## control, reached by its freight lift (SiloGenerators, SiloLift), and below that the bore floor and the hall's open vent
## (SiloPit). API for DeadForestEvent / SiloDepthsLevel / dev tools:
##   build_silo(terrain, x, z[, props]), check_interaction(player_pos[, force]) every physics frame, silo_activated,
##   route_programmed(route) from the launch control's wall terminal (RouteTerminal: route 00 home to the hub).
## Front (stair head, approach) = local +Z: DeadForestEvent turns it toward the arriving relay chain.

signal silo_activated()
signal route_programmed(route: int)

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const MODEL_PATH := "res://models/generated/missile_silo.glb"
const BORE_NODES: Array[String] = ["silo_bore", "silo_bore_decals", "silo_liquid"]
const RIM_Y := 0.05
## Footprint for DeadForestEvent / spawn hooks (metres from the bore centre).
const BORE_RADIUS := 56.0
const APPROACH := 92.0          # the last relay mast stands this far out in front of the stair head
const CLEAR_RADIUS := 128.0     # standing trees removed; SiloBlast lays flattened ones in the outer ring
const FLAT_RADIUS := 118.0
const FLAT_INNER := 82.0
const HOLE_RADIUS := 78.4       # the apron (to 78 m) replaces the terrain; its skirt (78..82 m) slopes under the dirt
const HOLE_SINK := 0.12         # the dirt's edge dips this far, just under the skirt, so no seam shows
const PIT_DEPTH := 146.0        # walkable to the bore floor (-136 m, under the generator hall): falls reset only below this
const ACTIVE_DIST := 160.0      # lights / screens / console animate inside this range
const DOOR_BLOCKER := Vector3(2.0, 2.4, 0.3)   # launch control blast door (kit door_blast opening)
const DOOR_REACH := 4.0         # a kit blast door (launch control, the pit) slides open when the player is this close
const LEVEL_09_Y := -36.0       # launch control level (deck lamp, room light cast shadows there)
const SHADOW_BAND := 6.0        # kit pieces this close to the rim or level 09 cast shadows; the dark shaft between does not
## Looking down the bore is the silo's reveal: it stays black only near the floor and the camera sees all of it (ViewZone).
const ABYSS_LOOK := {"abyss_depth": 45.0, "abyss_end": 450.0, "ambient_floor": 0.5}
const VIEW_FAR := 400.0         # rim to the bore floor's far edge is ~250 m
const VIEW_EXIT := 170.0

var model: Node3D
var ambience := SiloAmbience.new()
var console := SiloConsole.new()
var music := SiloMusic.new()   # the silo's theme: replaces the forest's music, builds as the walker goes down
var view := ViewZone.make(VIEW_FAR, ACTIVE_DIST, VIEW_EXIT)
var generators: SiloGenerators
var lift: SiloLift
var terminal: RouteTerminal
var vents: Array[VentDuct] = []   # the hall's open vent duct (SiloPit)
var _terrain: Node3D
var _props: Node3D
var _structure: Array[Node] = []   # walkway kit markers in the bore (stairs, landings, bridge, gate, door): AbyssFog
var _doors: Array[BunkerDoor] = []
var _door_centers: Array[Node3D] = []
var _pit_door: BunkerDoor          # the kit door_blast placed `__pit`: the hall's sound goes through it (SiloHallEar)


static func preload_models() -> void:
	load(MODEL_PATH)


func _ready() -> void:
	if model == null:
		build_silo(null, position.x, position.z)          # placed directly in a scene (colossal_missile_silo.tscn)
	if model == null:
		return
	var world := get_world_3d()
	var env := world.environment if world else null
	for node_name in BORE_NODES:
		AbyssFog.apply(model.get_node_or_null(node_name), global_position.y + RIM_Y, env, ABYSS_LOOK)
	var bore_kit := generators.fog(self, model, _structure, global_position.y + RIM_Y, env)   # the hall's own look
	var top: Array[Node] = []                                       # shadowed lights: apron floods + top lamp ...
	var low: Array[Node] = []                                       # ... deck lamp + room light at level 09
	var dark: Array[Node] = []                                      # the shaft between: no shadows fall there
	for marker in bore_kit:
		var y := (marker as Node3D).position.y
		(top if y > -SHADOW_BAND else low if absf(y - LEVEL_09_Y) < SHADOW_BAND else dark).append(marker)
	var fogged: Array[Node] = bore_kit.duplicate()               # live parts left in the pieces (door leaves) ...
	fogged.append_array(KitBatch.merge(self, top))                  # ... and the batched static meshes
	fogged.append_array(KitBatch.merge(self, low))
	fogged.append_array(KitBatch.merge(self, dark, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF))
	AbyssFog.apply_many(fogged, global_position.y + RIM_Y, env, ABYSS_LOOK)
	SiloServers.dress(self, model, global_position.y + RIM_Y, env, ABYSS_LOOK)   # the data room: batch + fog its kit
	ambience.bind_fog(model)
	SiloBlast.lay(self, _terrain, _props)


## Places the silo at (pos_x, pos_z) on the terrain. Set rotation before adding it to the tree (the blast ring is laid then).
func build_silo(terrain: Node3D, pos_x: float, pos_z: float, props: Node3D = null) -> void:
	if model != null:
		return
	var scene := load(MODEL_PATH) as PackedScene
	if scene == null:
		push_error("MissileSilo: cannot load " + MODEL_PATH)
		return
	_terrain = terrain
	_props = props
	position = Vector3(pos_x, terrain.get_height(pos_x, pos_z) if terrain else 0.0, pos_z)
	model = scene.instantiate() as Node3D
	add_child(model)
	Fx.make_matte(model)
	KitScript.furnish(model)
	RemnantSmalls.dress(model)
	_mount_kit()
	terminal = RouteTerminal.mount(self, model, HubRoutes.Route.SILO, false)
	if terminal:
		terminal.programmed.connect(route_programmed.emit)
	add_child(ambience)
	ambience.setup(model)
	add_child(console)
	console.setup(model)
	console.engaged.connect(_on_engaged)
	generators = SiloGenerators.mount(self, model)
	generators.pit_door = _pit_door
	lift = SiloLift.mount(model)
	vents = SiloPit.mount(model)
	add_child(music)
	add_child(view)


## The stair tower, bridge, gate, the pit stair and the doors are walkway kit pieces, the vent is duct kit (silo_tower.py,
## silo_room.py, silo_pit.py, silo_vent.py markers): collect them for AbyssFog and wire each blast door (BunkerDoor,
## opened by proximity in check_interaction).
func _mount_kit() -> void:
	for child in model.get_children():
		var marker_name := String(child.name)
		if not marker_name.begins_with(KitScript.PREFIX) or child.get_child_count() == 0:
			continue
		var prop := StringName(marker_name.trim_prefix(KitScript.PREFIX).get_slice("__", 0))
		if prop in O73Kit.STRUCTURE or prop in O73Kit.DUCTS:
			_structure.append(child)
		if prop == &"door_blast":
			var piece := child.get_child(0) as Node3D
			var center := piece.get_node_or_null("marker_door_center") as Node3D
			var door := BunkerDoor.mount(self, piece, DOOR_BLOCKER)
			if door and center:
				_doors.append(door)
				_door_centers.append(center)
				if marker_name.ends_with("__pit"):
					_pit_door = door


func _on_engaged() -> void:
	ambience.alarm()
	music.alarm()
	silo_activated.emit()


## Called every physics frame by DeadForestEvent. force = engage the launch override now (dev tools). True on that frame.
func check_interaction(player_pos: Vector3, force: bool = false) -> bool:
	if model == null:
		return false
	var dist := global_position.distance_to(player_pos)
	var near := dist < ACTIVE_DIST
	music.update(global_position + Vector3(0.0, RIM_Y, 0.0), player_pos)
	view.update(dist)
	ambience.set_active(near)
	console.set_active(near)
	generators.update(to_local(player_pos), near)
	if lift and near:
		lift.update(player_pos)
	for i in _doors.size():
		_doors[i].request_open(_door_centers[i].global_position.distance_squared_to(player_pos) < DOOR_REACH * DOOR_REACH)
	if terminal and near:
		terminal.update(player_pos)
	var before := console.state
	console.update(player_pos, force)
	return console.state != before
