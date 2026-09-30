class_name Remnant
extends RefCounted
## Shared helpers for apartment kit pieces left in the forest levels (RemnantSmalls in the buildings, BuriedRemnants in the
## ground). A remnant is scenery: its apartment interactions (marker_use_* -> AptUse) are taken off, so a pill organizer in a
## bunker or a front door in the ash offers no CHECK and nothing out here listens for one.

const GRIME := preload("res://scripts/world/remnants/remnant_grime.tres")
const USE_PREFIX := "marker_use_"
const COLLISION_TAG := "col"
const WEATHER_SPECULAR := 0.2        # weathered materials: dull, faded toward grey, darker
const WEATHER_GREY := 0.45
const WEATHER_DIM := 0.7

## Loaded scenes kept by piece, so a piece streamed in with a forest chunk does not hit the disk each time.
static var _held := {}
## source material -> its weathered copy
static var _weathered := {}


## Instances apartment kit piece `piece` under `parent` at `xform`, inert (see above). Null for an unknown piece.
static func spawn(piece: StringName, parent: Node, xform := Transform3D.IDENTITY) -> Node3D:
	if parent == null:
		return null
	if not _held.has(piece):
		_held[piece] = load(O73Kit.path(piece, AptKit.DIR))
	var node := AptKit.spawn(piece, parent, xform)
	if node:
		inert(node)
	return node


## Frees the piece's interaction markers (and the AptUse mounted on them if it has already entered the tree).
static func inert(piece: Node) -> int:
	if piece == null:
		return 0
	var freed := 0
	for child in piece.get_children():
		if String(child.name).begins_with(USE_PREFIX):
			piece.remove_child(child)
			child.free()
			freed += 1
	return freed


## The visible meshes' bounds in the piece's own space (collision meshes left out).
static func bounds(piece: Node3D) -> AABB:
	var box := AABB()
	if piece == null:
		return box
	for node in piece.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or String(mi.name).contains(COLLISION_TAG):
			continue
		var xf := mi.transform
		var up := mi.get_parent()
		while up != piece and up is Node3D:
			xf = (up as Node3D).transform * xf
			up = up.get_parent()
		box = box.merge(xf * mi.mesh.get_aabb()) if box.has_volume() else xf * mi.mesh.get_aabb()
	return box


## Soils every mesh of the piece: its materials swapped for weathered copies (weathered()) under the shared grime overlay
## (remnant_grime.gdshader: mud climbing from `ground_y`, ash on what faces up, a general film; ground line per instance).
static func grime(piece: Node3D, ground_y: float) -> void:
	if piece == null:
		return
	for node in piece.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				var mat := weathered(mi.mesh.surface_get_material(i) as BaseMaterial3D)
				if mat:
					mi.set_surface_override_material(i, mat)
		mi.material_overlay = GRIME
		mi.set_instance_shader_parameter(&"ground_y", ground_y)


## A matte, faded copy of an apartment material (no gloss: a glossy fridge mirrors the bright fog through any film on it),
## made once per source material and shared by every remnant.
static func weathered(src: BaseMaterial3D) -> BaseMaterial3D:
	if src == null:
		return null
	if not _weathered.has(src):
		var mat := src.duplicate() as BaseMaterial3D
		mat.roughness = 1.0
		mat.metallic = 0.0
		mat.metallic_specular = WEATHER_SPECULAR
		mat.clearcoat_enabled = false
		var c := mat.albedo_color
		mat.albedo_color = c.lerp(Color(c.get_luminance(), c.get_luminance(), c.get_luminance(), c.a), WEATHER_GREY) * WEATHER_DIM
		mat.emission_enabled = false
		_weathered[src] = mat
	return _weathered[src]
