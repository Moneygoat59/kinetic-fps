class_name AptPracticals
extends RefCounted
## The kit's practical lights (KitLights marker_light_<kind> omnis: lamps, bulbs, vanity, strips) switched off in bulk, lamp
## shades and all. AptMood uses it for moods with "practicals": false (the small hours); anything that cuts the power can too.
## dim() turns them down instead (moods with "practical_energy": the squalor's weak bulbs).

const SHADE_MAT := "kit_glow_shade"                    # the lit lamp shades (tools/blender/apt/apt_lib.py)
const STAYS_ON: Array[String] = ["marker_light_fridge"]  # anchors left alone (the fridge is lit only when it is open)


## Every practical under `root` goes dark and its shade stops glowing. Load-time only (walks the tree). Returns lights off.
static func off(root: Node) -> int:
	if root == null:
		return 0
	var count := 0
	for light in _lights(root):
		light.visible = false
		count += 1
	_shades(root, 0.0)
	return count


## Every practical under `root` at `factor` of its energy (load-time only). Returns how many.
static func dim(root: Node, factor: float) -> int:
	if root == null:
		return 0
	var lights := _lights(root)
	for light in lights:
		light.light_energy *= maxf(factor, 0.0)
	_shades(root, factor)
	return lights.size()


## Every lit lamp shade under `root` glows at `factor` (0 = not at all), through one shared override material.
static func _shades(root: Node, factor: float) -> void:
	var own: BaseMaterial3D = null
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if mat == null or mat.resource_name != SHADE_MAT:
				continue
			if own == null:
				own = mat.duplicate() as BaseMaterial3D
				own.emission_enabled = factor > 0.0
				own.emission_energy_multiplier *= maxf(factor, 0.0)
			mi.set_surface_override_material(i, own)


static func _lights(root: Node) -> Array[Light3D]:
	var out: Array[Light3D] = []
	for light in root.find_children("*", "Light3D", true, false):
		var anchor := String(light.get_parent().name)
		if anchor.begins_with("marker_light_") and not STAYS_ON.any(func(s: String) -> bool: return anchor.begins_with(s)):
			out.append(light as Light3D)
	return out
