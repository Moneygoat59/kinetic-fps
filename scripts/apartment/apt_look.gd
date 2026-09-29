extends RefCounted
## Material look of the apartment kit, chosen by material-name prefix (set once at import, see tools/apt_kit_import.gd):
##   apt_mirror*  polished mirror (metallic, near-zero roughness; the bathroom ReflectionProbe gives it something to show)
##   apt_glass*   clear glass (alpha from the glTF, a little specular)
##   apt_gloss_*  porcelain, pharmacy plastic, chrome, the TV: soft sheen
##   apt_sheen_*  bin-bag plastic, foil, can metal, a wet spill: tight, bright highlights
##   apt_hi_*     hi-res art (book spines and covers): trilinear + anisotropic filtering instead of the kit's nearest pixels
##   kit_glow_* / kit_scr_*  emissive, left alone
##   anything else dead matte, like the rest of the game (roughness 1, specular 0)


static func apply(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var mat := node.mesh.surface_get_material(i) as BaseMaterial3D
			if mat:
				look(mat)
	for child in node.get_children():
		apply(child)


static func look(mat: BaseMaterial3D) -> void:
	var n := mat.resource_name
	mat.metallic = 0.0
	if n.begins_with("apt_mirror"):
		mat.metallic = 1.0
		mat.roughness = 0.03
		mat.metallic_specular = 0.5
	elif n.begins_with("apt_glass"):
		mat.roughness = 0.06
		mat.metallic_specular = 0.6
	elif n.begins_with("apt_sheen"):
		mat.roughness = 0.2
		mat.metallic_specular = 0.65
	elif n.begins_with("apt_gloss"):
		mat.roughness = 0.38
		mat.metallic_specular = 0.4
	elif n.begins_with("apt_hi"):
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		mat.roughness = 0.85
		mat.metallic_specular = 0.2
	elif not (n.begins_with("kit_glow") or n.begins_with("kit_scr")):
		mat.roughness = 1.0
		mat.metallic_specular = 0.0
