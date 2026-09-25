extends RefCounted
## Set-dressing for the Outpost 73 bunker: matte materials, marker lights, ground contact-shadow decal.
## All static; each runs once at build time (nothing here touches the per-frame path).

const AMBER := Color(1.0, 0.68, 0.15)
const GRIME_SIZE := 18.0
const ROOF_LIGHT := "marker_light_roof"
## marker name -> [colour, energy, range, casts_shadow]
const LIGHTS := {
	"marker_light_ceiling": [Color(1.0, 0.68, 0.2), 4.0, 8.0, true],
	"marker_light_front": [AMBER, 3.8, 7.5, true],
	"marker_light_side_l": [AMBER, 2.5, 5.0, false],
	"marker_light_side_r": [AMBER, 2.5, 5.0, false],
	ROOF_LIGHT: [AMBER, 4.0, 45.0, false],
}


## glTF cannot carry Blender's "specular = 0", so strip glints here (PS1 matte look).
static func make_matte(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(i) as BaseMaterial3D
			if mat:
				mat.metallic_specular = 0.0
	for child in node.get_children():
		make_matte(child)


## Adds an omni light under every marker_light_* node. Returns the roof beacon light (pulsed by the caller) or null.
static func add_lights(model: Node3D) -> OmniLight3D:
	var roof: OmniLight3D = null
	for marker_name in LIGHTS:
		var anchor := model.get_node_or_null(marker_name) as Node3D
		if anchor == null:
			continue
		var spec: Array = LIGHTS[marker_name]
		var light := OmniLight3D.new()
		light.light_color = spec[0]
		light.light_energy = spec[1]
		light.omni_range = spec[2]
		light.shadow_enabled = spec[3]
		light.shadow_bias = 0.05
		anchor.add_child(light)
		if marker_name == ROOF_LIGHT:
			roof = light
	return roof


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
