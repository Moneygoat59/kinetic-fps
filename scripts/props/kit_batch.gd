class_name KitBatch
extends RefCounted
## Draws many placed kit pieces cheaply: every static kit mesh (node contract: body, panels, decals, opt_*) under `sources`
## is gathered by mesh and redrawn as one MultiMeshInstance3D per mesh under `root`, so 30 stair pieces cost a handful of
## draw calls instead of hundreds. Moving parts (door leaves, spin_*), screens, lights and collision stay where they are.
## Call once the pieces are in the tree and their optional parts are dropped:
##   KitBatch.merge(self, structure_markers)      # returns the MultiMeshInstance3D nodes it made
## A batch is culled as one (its box spans every instance), so a tall batch lands in every shadow map near it: batch far
## groups separately and pass `shadow` (a GeometryInstance3D.ShadowCastingSetting) to switch shadows off where none fall.
## Decals (flat quads on a surface) never cast shadows.

const STATIC_NAMES: Array[String] = ["body", "panels", "decals"]


static func merge(root: Node3D, sources: Array[Node], shadow: int = -1) -> Array[MultiMeshInstance3D]:
	var made: Array[MultiMeshInstance3D] = []
	if root == null or not root.is_inside_tree():
		return made
	var groups := {}                                 # Mesh -> Array of Transform3D (root space)
	var shadows := {}                                # Mesh -> cast_shadow of its first source
	var to_root := root.global_transform.affine_inverse()
	for source in sources:
		if source == null:
			continue
		for node in source.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if mi.mesh == null or not _is_static(String(mi.name)):
				continue
			if not groups.has(mi.mesh):
				groups[mi.mesh] = []
				shadows[mi.mesh] = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if mi.name == &"decals" else mi.cast_shadow
			groups[mi.mesh].append(to_root * mi.global_transform)
			mi.get_parent().remove_child(mi)
			mi.queue_free()
	for mesh in groups:
		var xforms: Array = groups[mesh]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "kit_batch_%s%s" % [mesh.resource_name if mesh.resource_name != "" else str(made.size()),
			"_noshadow" if shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else ""]
		mmi.multimesh = mm
		mmi.cast_shadow = shadows[mesh] if shadow < 0 else mini(shadow, shadows[mesh])
		root.add_child(mmi, true)                   # readable unique names across several merges
		made.append(mmi)
	return made


static func _is_static(node_name: String) -> bool:
	return node_name in STATIC_NAMES or node_name.begins_with("opt_")
