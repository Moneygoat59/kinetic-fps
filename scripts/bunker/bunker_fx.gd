extends RefCounted
## Set-dressing for the Outpost 73 bunker: materials, marker lights, ground contact-shadow decal, lamp flicker maths.
## The build-time helpers run once; `flicker` is a pure function called per frame (no allocations).

const AMBER := Color(1.0, 0.68, 0.15)
const WELL_AMBER := Color(1.0, 0.52, 0.10)
const GRIME_SIZE := 18.0
const ROOF_LIGHT := "light_roof"
## Lights whose energy breathes (the amber well is still pumping) and lamps that are failing (they flicker / drop out).
const PULSE_LIGHTS := ["light_well", "light_wellhead"]
const FLICKER_LIGHTS := ["light_ceiling", "light_front", "light_side_l", "light_side_r"]
## marker name -> [colour, energy, range, casts_shadow]
const LIGHTS := {
	"marker_light_ceiling": [Color(1.0, 0.68, 0.2), 3.6, 8.0, true],
	"marker_light_front": [AMBER, 1.8, 6.0, true],
	"marker_light_side_l": [AMBER, 1.2, 4.0, false],
	"marker_light_side_r": [AMBER, 1.2, 4.0, false],
	"marker_light_well": [WELL_AMBER, 1.7, 4.0, false],
	"marker_light_wellhead": [WELL_AMBER, 1.4, 5.0, false],
	"marker_light_roof": [AMBER, 4.0, 45.0, false],
}


## Obsidian concrete keeps a glassy sheen; everything else is matte (glTF cannot carry Blender's "specular = 0").
static func make_matte(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(i) as BaseMaterial3D
			if mat == null:
				continue
			if mat.resource_name.begins_with("bunker_concrete"):
				mat.metallic_specular = 0.7
				mat.roughness = 0.5
			else:
				mat.metallic_specular = 0.0
	for child in node.get_children():
		make_matte(child)


## Adds an omni light under every marker_light_* node (named "light_*"). Returns {name: OmniLight3D}.
static func add_lights(model: Node3D) -> Dictionary:
	var made := {}
	for marker_name in LIGHTS:
		var anchor := model.get_node_or_null(marker_name) as Node3D
		if anchor == null:
			continue
		var spec: Array = LIGHTS[marker_name]
		var light := OmniLight3D.new()
		light.name = marker_name.trim_prefix("marker_")
		light.light_color = spec[0]
		light.light_energy = spec[1]
		light.omni_range = spec[2]
		light.shadow_enabled = spec[3]
		light.shadow_bias = 0.05
		anchor.add_child(light)
		made[light.name] = light
	return made


## Picks the named lights out of `made` into parallel arrays (light + its base energy) for per-frame animation.
static func collect(made: Dictionary, names: Array, lights: Array[OmniLight3D], base: PackedFloat32Array) -> void:
	for n in names:
		if made.has(n):
			lights.append(made[n])
			base.append(made[n].light_energy)


## Failing-lamp multiplier in ~0.1..1.0: steady wobble with rare deep dips. t in seconds, phase de-syncs lamps.
static func flicker(t: float, phase: float) -> float:
	var wobble := 0.9 + 0.1 * sin(t * 3.1 + phase)
	var dip := smoothstep(0.9, 1.0, sin(t * 7.3 + phase * 3.0) * sin(t * 2.3 + phase))
	return wobble * (1.0 - 0.9 * dip)


## Soft dark contact-shadow decal projected onto the terrain (and the wall bases) around the foundation.
static func add_grime(parent: Node3D) -> void:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0.9), Color(0, 0, 0, 0.7), Color(0, 0, 0, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var decal := Decal.new()
	decal.texture_albedo = tex
	decal.size = Vector3(GRIME_SIZE, 1.6, GRIME_SIZE)
	decal.position = Vector3(0.0, 0.3, 0.0)
	parent.add_child(decal)
