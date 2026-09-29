class_name HubRoutes
extends Node
## The four amber routes of Relay Hub 00 (model: tools/blender/props/relay_hub.py). Per route: the handwheel on its riser
## (valve_<key>), its sight glasses (hub_flow_<key>, inside and at the corner main), the status lamp over its plate
## (hub_glow_lamp_<key>), a light at marker_route_light_<key>, and the corner relay mast at marker_route_<key> (a
## NuclearPylon, so the dosimeter and the event treat it like any relay). One Flow state per route: DRY -> OPENING (the
## valve wheel spins, amber sputters into the glass) -> ONLINE (flowing, lamp lit, corner mast online in the route colour).
## Animates only while the player is near (set_active).

enum Route { W73, W02, W03, SILO }
enum Flow { DRY, OPENING, ONLINE }

const KitLights = preload("res://scripts/props/kit_lights.gd")
const KEYS: Array[String] = ["73", "02", "03", "00"]
const NAMES: Array[String] = ["OUTPOST 73", "OUTPOST 02", "OUTPOST 03", "MISSILE SILO"]
const COLORS: Array[Color] = [Color(1.0, 0.65, 0.12), Color(0.15, 0.8, 1.0), Color(0.2, 0.95, 0.35), Color(1.0, 0.15, 0.1)]
const LIGHT_COLOR := Color(1.0, 0.52, 0.10)
const OPEN_TIME := 2.2
const VALVE_TURNS := 2.5
const FLOW_SPEED := 0.35
const GLASS_DRY := 0.02
const GLASS_ON := 1.5
const LAMP_OFF := 0.0
const LAMP_ON := 2.4
const LIGHT_ON := 0.8
const MAX_DELTA := 0.1
const CREAK_SOUND = preload("res://audio/rpg/Audio/creak2.ogg")
const LATCH_SOUND = preload("res://audio/rpg/Audio/metalLatch.ogg")

var flow: Array[Flow] = [Flow.DRY, Flow.DRY, Flow.DRY, Flow.DRY]
var masts: Array[NuclearPylon] = []
var _valves: Array[Node3D] = []
var _glass: Array[BaseMaterial3D] = []
var _lamps: Array[BaseMaterial3D] = []
var _lights: Array[OmniLight3D] = []
var _open_t := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _header: BaseMaterial3D
var _pool: BaseMaterial3D
var _sfx: AudioStreamPlayer3D


## Claims the route parts of `model` (a child of `hub` at identity) and raises the four corner masts on the terrain.
func setup(model: Node3D, hub: Node3D, terrain: Node3D) -> void:
	set_process(false)
	var liquid := model.get_node_or_null("hub_liquid")
	var shell := model.get_node_or_null("hub_shell")
	_header = O73Kit.own_material(liquid, "hub_amber_liquid")
	_pool = O73Kit.own_material(liquid, "hub_amber_pool")
	for r in KEYS.size():
		_valves.append(model.get_node_or_null("valve_" + KEYS[r]) as Node3D)
		_glass.append(O73Kit.own_material(liquid, "hub_flow_" + KEYS[r]))
		_lamps.append(O73Kit.own_material(shell, "hub_glow_lamp_" + KEYS[r]))
		var light := OmniLight3D.new()
		light.light_color = LIGHT_COLOR
		light.omni_range = 3.2
		KitLights.fade(light)
		var anchor := model.get_node_or_null("marker_route_light_" + KEYS[r]) as Node3D
		(anchor if anchor else model).add_child(light)
		_lights.append(light)
		masts.append(_raise_mast(r, model.get_node_or_null("marker_route_" + KEYS[r]) as Node3D, hub, terrain))
	_sfx = AudioStreamPlayer3D.new()
	_sfx.position = Vector3(0.0, 1.5, -3.2)
	model.add_child(_sfx)
	for r in KEYS.size():
		_show(r, 0.0)


func _raise_mast(r: int, anchor: Node3D, hub: Node3D, terrain: Node3D) -> NuclearPylon:
	var mast := NuclearPylon.new()
	mast.station_id = int(KEYS[r])
	mast.pylon_color = COLORS[r]
	var local := anchor.position if anchor else Vector3.ZERO
	mast.build_pylon(null, local.x, local.z)
	var world := hub.transform * local
	var ground: float = terrain.get_height(world.x, world.z) if terrain else hub.position.y
	mast.position.y = ground - hub.position.y - NuclearPylon.SINK
	mast.rotation.y = atan2(local.x, local.z)                 # cabinet faces out along the route
	hub.add_child(mast)
	return mast


## Start opening a route: the valve turns and amber comes through. Ignored if it is already opening or online.
func open(r: int) -> void:
	if r < 0 or r >= KEYS.size() or flow[r] != Flow.DRY:
		return
	flow[r] = Flow.OPENING
	_open_t[r] = 0.0
	_play(CREAK_SOUND, -2.0)
	set_process(true)


## Jump a route straight to online (progress restored or skipped by dev tools). with_mast = false leaves the corner mast
## to the player (route 73: amber already flows from the well, but its mast is the last relay of the arrival track).
func set_online(r: int, with_mast: bool = true) -> void:
	if r < 0 or r >= KEYS.size() or flow[r] == Flow.ONLINE:
		return
	flow[r] = Flow.ONLINE
	_show(r, 1.0)
	if with_mast:
		masts[r].set_pylon_color(COLORS[r])
		masts[r].force_online()


## Called every physics frame by the hub with "is the player near". An opening valve finishes even if they walk off.
func set_active(near: bool) -> void:
	set_process(near or flow.has(Flow.OPENING))


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	var t := Time.get_ticks_msec() * 0.001
	for r in KEYS.size():
		if flow[r] == Flow.OPENING:
			_open_t[r] += dt
			var k := clampf(_open_t[r] / OPEN_TIME, 0.0, 1.0)
			if _valves[r]:
				_valves[r].rotation.z = -TAU * VALVE_TURNS * ease(k, -2.0)
			_show(r, k * (0.6 + 0.4 * sin(t * 23.0 + r)) if k < 1.0 else 1.0)
			if k >= 1.0:
				_play(LATCH_SOUND, 0.0)
				set_online(r)
		elif flow[r] == Flow.ONLINE and _glass[r]:
			_scroll(_glass[r], dt, GLASS_ON + 0.3 * sin(t * 1.7 + r))
	if _header:
		_scroll(_header, dt, GLASS_ON + 0.4 * sin(t * 1.7))
	if _pool:
		_pool.emission_energy_multiplier = 1.0 + 0.3 * sin(t * 1.3 + 1.0)


## level 0 = dry and dark, 1 = flowing and lit.
func _show(r: int, level: float) -> void:
	if _glass[r]:
		_glass[r].emission_energy_multiplier = lerpf(GLASS_DRY, GLASS_ON, level)
	if _lamps[r]:
		_lamps[r].emission = COLORS[r]
		_lamps[r].emission_energy_multiplier = lerpf(LAMP_OFF, LAMP_ON, level)
	_lights[r].light_energy = LIGHT_ON * level
	_lights[r].visible = level > 0.01


func _scroll(mat: BaseMaterial3D, dt: float, energy: float) -> void:
	var offset := mat.uv1_offset
	offset.y = fposmod(offset.y - dt * FLOW_SPEED, 1.0)
	mat.uv1_offset = offset
	mat.emission_energy_multiplier = energy


func _play(stream: AudioStream, volume: float) -> void:
	_sfx.stream = stream; _sfx.volume_db = volume; _sfx.unit_size = 6.0
	_sfx.play()
