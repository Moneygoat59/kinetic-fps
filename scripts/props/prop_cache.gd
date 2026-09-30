extends RefCounted
## Shared resources for scattered props, so streaming chunks reuse them instead of building copies on every rebuild:
##   PropCache.tinted(tex, tint)   one Lambert-wrap StandardMaterial3D per (texture, tint): trees of a tint batch together
##   PropCache.convex(mesh)        one convex collision hull per mesh (hull generation is the slow part of a chunk rebuild)
## Both caches are small and bounded by the number of distinct prop meshes / tints.

static var _tinted := {}
static var _convex := {}


static func tinted(tex: Texture2D, tint: Color) -> StandardMaterial3D:
	var key := [tex, tint]
	if _tinted.has(key):
		return _tinted[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT_WRAP
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_BACK
	_tinted[key] = m
	return m


static func convex(mesh: Mesh) -> Shape3D:
	if mesh == null:
		return null
	if not _convex.has(mesh):
		_convex[mesh] = mesh.create_convex_shape()
	return _convex[mesh]
