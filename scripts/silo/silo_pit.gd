class_name SiloPit
extends RefCounted
## Missile Silo 00 below the generator hall (models: tools/blender/props/silo_pit.py, silo_vent.py): lights for the bore
## floor, the pit stair and the tunnel out to it, and a VentDuct on every duct_mouth kit piece (the open vent in the
## hall's far end wall, with a DuctSound at its far end: breathing, popping steel, the draft, something beyond). The pit's door is a kit door_blast, run by MissileSilo like the launch control's; the pit stair
## and the duct are walkway / duct kit that MissileSilo batches and fogs with the rest. mount(model) once the kit is
## furnished; in_pit(local) is true down on the floor, on the stair and in the tunnel (SiloGenerators hides the moon there).

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const LAMP := Color(1.0, 0.66, 0.2)
## marker name -> [colour, energy, range, casts_shadow]
const LIGHTS := {
	"marker_light_pit_tunnel": [LAMP, 2.0, 7.0, false],
	"marker_light_pit_stair_0": [LAMP, 3.0, 11.0, true],
	"marker_light_pit_stair_1": [LAMP, 2.6, 10.0, false],
	"marker_light_pit_stair_2": [LAMP, 2.6, 10.0, false],
	"marker_light_pit_stair_3": [LAMP, 2.8, 11.0, false],
	"marker_light_pit_pool": [Fx.WELL_AMBER, 8.0, 26.0, false],
	"marker_light_pit_cone": [Fx.WELL_AMBER, 6.0, 28.0, false],
	"marker_light_vent_mouth": [LAMP, 2.4, 9.0, true],
	"marker_light_vent_bend": [Fx.WELL_AMBER, 0.5, 4.5, false],
}
const MOUTH := "duct_mouth"
const END := "marker_vent_end"           # silo_vent.py: in front of the duct's cap
const PIT_TOP := -100.0          # silo space: below this and inside PIT_RADIUS is the pit
const PIT_RADIUS := 60.5         # out to the hall face of the inner wall (the tunnel)


## Lights the pit and mounts the vents. Returns the VentDucts made.
static func mount(model: Node3D) -> Array[VentDuct]:
	var vents: Array[VentDuct] = []
	if model == null:
		return vents
	Fx.add_lights(model, LIGHTS)
	for child in model.get_children():
		if not String(child.name).begins_with(KitScript.PREFIX + MOUTH) or child.get_child_count() == 0:
			continue
		var vent := VentDuct.mount(child.get_child(0) as Node3D)
		if vent:
			vents.append(vent)
			_add_sound(model, vent, child as Node3D)
	return vents


## model space (the silo is built before it is in the tree): the end marker and the mouth's kit marker are its children.
static func _add_sound(model: Node3D, vent: VentDuct, mouth: Node3D) -> void:
	var end := model.get_node_or_null(END) as Node3D
	if end == null:
		return
	var sound := DuctSound.make(end.position, mouth.position)
	model.add_child(sound)
	vent.climbed.connect(sound.on_climbed)


## True on the bore floor, the pit stair or in the tunnel to it (silo space: Godot local, the model's front = +Z).
static func in_pit(local: Vector3) -> bool:
	return local.y < PIT_TOP and Vector2(local.x, local.z).length() < PIT_RADIUS
