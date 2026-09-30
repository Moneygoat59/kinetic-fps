class_name SiloGenerators
extends Node
## Presenter for Missile Silo 00's generator hall (model: tools/blender/props/silo_generator.py): the generators' lights
## (a shadowed one in each amber waist, so the fins throw their shadows round the hall, one over each pool for the
## crown, the blades and the drop, low ones over the floor channel between the machines, amber uplights on the plinths),
## their sound (SiloGeneratorSound: drones breathing with the throb, a heavy pulse each breath, arcs, the pour; shut off
## behind walls by SiloHallEar), the amber pouring down the streams and through the glass (silo_gen_amber scrolls) and the
## glyph slits throbbing (silo_glow_gen). Runs only while the player is near; in the tunnel, the hall, its vent duct and
## down in the pit (SiloPit.in_pit) the moon is hidden (SkyZone). MissileSilo owns it: mount(host, model) once the model is built, fog(...) once in the tree (the hall
## gets its own AbyssFog look), update(player position in silo space, near) every frame.

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const LIQUID_NODE := "silo_gen_liquid"
const HALL_NODES: Array[String] = ["silo_hall", "silo_hall_decals", "silo_gen", LIQUID_NODE, "silo_lift", "silo_lift_wreck",
	"silo_lift_wreck_decals"]
## Underground: fully deep from the top (black fog, no sky ambient), and far parts of the hall fade to black.
const HALL_LOOK := {"abyss_depth": 1.0, "abyss_end": 140.0, "ambient_floor": 0.0}
const LIQUID_MAT := "silo_gen_amber"
const GLOW_MAT := "silo_glow_gen"
const GENS := 3
const GAPS := 4                    # low lights over the floor channel between the machines
const CORE := Color(1.0, 0.5, 0.12)
const UPLIGHT_PREFIX := "marker_uplight_"   # the floods on the plinth steps (silo_generator.py)
const UPLIGHT := Color(1.0, 0.56, 0.2)
const UPLIGHT_ENERGY := 11.0
const UPLIGHT_ANGLE := 32.0
const FLOW_SPEED := 0.6             # uv / s down the streams
const THROB_RATE := 1.3             # rad / s: one slow breath every ~5 s
const CORE_SPREAD := 2.1            # rad: each machine breathes this far out of step with the one before
const GLOW_MIN := 0.9
const GLOW_MAX := 2.6
## The tunnel, lift shaft + hall in silo space (silo_hall.py, Blender angles: atan2(-z, x)): angle range (deg), radius range, below.
const HALL_ANGLES := Vector2(-172.0, -112.5)
const HALL_RADII := Vector2(59.5, 78.5)
const HALL_TOP := -33.0
## The vent duct out of the far end wall (silo_vent.py) in the same terms, and its height band.
const VENT_ANGLES := Vector2(-178.0, -169.0)
const VENT_RADII := Vector2(70.0, 80.0)
const VENT_Y := Vector2(-121.0, -117.0)

var _cores: Array[OmniLight3D] = []
var _core_base := PackedFloat32Array()
var _liquid: ShaderMaterial
var _glow: ShaderMaterial
var pit_door: BunkerDoor                # the blast door to the pit (MissileSilo sets it): open lets the hall's sound through
var sealed := false                     # the walker is in the tunnels, behind rock (TunnelNetwork, via SiloTunnels)
var _sky := SkyZone.make()
var _sound := SiloGeneratorSound.new()


static func mount(host: Node, model: Node3D) -> SiloGenerators:
	var gens := SiloGenerators.new()
	host.add_child(gens)
	gens.setup(model)
	return gens


func setup(model: Node3D) -> void:
	var specs := {}
	for i in GENS:
		specs["marker_light_gen_%d" % i] = [CORE, 12.0, 28.0, true]
		specs["marker_light_gen_pool_%d" % i] = [Fx.WELL_AMBER, 5.0, 13.0, false]
	for k in GAPS:
		specs["marker_light_gen_gap_%d" % k] = [Fx.WELL_AMBER, 3.0, 9.0, false]
	specs["marker_light_lift_top"] = [Fx.AMBER, 1.8, 6.0, false]
	specs["marker_light_lift_bottom"] = [Fx.AMBER, 2.4, 9.0, false]
	add_child(_sky)
	add_child(_sound)
	_sound.setup(model, GENS)
	var made := Fx.add_lights(model, specs)
	SiloAmbience.add_spots(model, UPLIGHT_PREFIX, UPLIGHT, UPLIGHT_ENERGY, UPLIGHT_ANGLE)
	for i in GENS:
		Fx.collect(made, ["light_gen_%d" % i], _cores, _core_base)
	var liquid := model.get_node_or_null(LIQUID_NODE) as GeometryInstance3D
	if liquid:
		liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # the core lights sit inside the glass
	set_process(false)


## Fogs the hall with HALL_LOOK: its nodes and its kit (the markers in `structure` inside the hall or its vent, batched here).
## Returns the rest of `structure` (the bore's kit). Then picks up the materials animated here.
func fog(host: Node3D, model: Node3D, structure: Array[Node], rim_y: float, env: Environment) -> Array[Node]:
	var rest: Array[Node] = []
	var kit: Array[Node] = []
	for marker in structure:
		var at := (marker as Node3D).position
		(kit if in_hall(at) or in_vent(at) else rest).append(marker)
	var fogged: Array[Node] = kit.duplicate()
	fogged.append_array(KitBatch.merge(host, kit, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF))
	for node_name in HALL_NODES:
		fogged.append(model.get_node_or_null(node_name))
	AbyssFog.apply_many(fogged, rim_y, env, HALL_LOOK)
	_liquid = AbyssFog.find(model.get_node_or_null(LIQUID_NODE), LIQUID_MAT)
	_glow = AbyssFog.find(model.get_node_or_null("silo_gen"), GLOW_MAT)
	return rest


func update(local: Vector3, near: bool) -> void:
	set_process(near)
	_sky.update(near and (in_hall(local) or in_vent(local) or SiloPit.in_pit(local)))
	_sound.set_open(SiloHallEar.openness(local, pit_door.factor if pit_door else 0.0, sealed))


func set_sealed(value: bool) -> void:
	sealed = value


## True in the tunnel or the hall (silo space: Godot local, the model's front = +Z).
static func in_hall(local: Vector3) -> bool:
	var r := Vector2(local.x, local.z).length()
	var a := rad_to_deg(atan2(-local.z, local.x))
	return local.y < HALL_TOP and r > HALL_RADII.x and r < HALL_RADII.y and a > HALL_ANGLES.x and a < HALL_ANGLES.y


## True in the vent duct behind the hall's far end wall (silo space).
static func in_vent(local: Vector3) -> bool:
	var r := Vector2(local.x, local.z).length()
	var a := rad_to_deg(atan2(-local.z, local.x))
	return local.y > VENT_Y.x and local.y < VENT_Y.y and r > VENT_RADII.x and r < VENT_RADII.y and a > VENT_ANGLES.x \
		and a < VENT_ANGLES.y


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	_sound.update(t, THROB_RATE, CORE_SPREAD, delta)
	var breath := (sin(t * THROB_RATE) + 1.0) * 0.5
	if _liquid:
		_liquid.set_shader_parameter("uv_offset", Vector2(0.0, fmod(t * FLOW_SPEED, 1.0)))
	if _glow:
		_glow.set_shader_parameter("emission_energy", lerpf(GLOW_MIN, GLOW_MAX, breath))
	for i in _cores.size():                          # each machine breathes a little out of step with the others
		var b := (sin(t * THROB_RATE + i * CORE_SPREAD) + 1.0) * 0.5
		_cores[i].light_energy = _core_base[i] * lerpf(0.8, 1.1, b)
