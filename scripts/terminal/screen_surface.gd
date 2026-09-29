class_name ScreenSurface
extends RefCounted
## A flat screen quad on a mesh (a kit piece's kit_scr_* surface) as a frame in the world: where it is, how big, which
## way it faces, and the texture UV under any point on it (the affine map read from the quad's own vertices and UVs, so
## tilted and leaning screens work). TerminalStation frames the camera on it and turns mouse rays into screen pixels;
## reusable for any device the player should touch.
##   var s := ScreenSurface.find(piece)                  # the first kit_scr_* surface under piece
##   var s := ScreenSurface.find(piece, "kit_scr_nodes") # or a named one

const PREFIX := "kit_scr_"
const MISS := Vector2(-1.0, -1.0)

var mesh: MeshInstance3D
var surface := -1
var material_name := ""
var size := Vector2.ZERO             # metres along u and v (mesh units: kit pieces are unscaled)
var _p0 := Vector3.ZERO              # mesh-local point at _uv0
var _uv0 := Vector2.ZERO
var _du := Vector3.ZERO              # mesh-local metres per unit of u
var _dv := Vector3.ZERO              # ... per unit of v (texture v runs down the screen)
var _uv_mid := Vector2(0.5, 0.5)


## The screen surface named `material` (or the first kit_scr_* one) on any mesh under `root`. Null if there is none.
static func find(root: Node, material := "") -> ScreenSurface:
	if root == null:
		return null
	var meshes: Array = [root]
	meshes.append_array(root.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(i)
			var mat_name := mat.resource_name if mat else ""
			if (material == "" and mat_name.begins_with(PREFIX)) or (material != "" and mat_name == material):
				var s := ScreenSurface.new()
				if s._build(mi, i, mat_name):
					return s
	return null


func _build(mi: MeshInstance3D, i: int, mat_name: String) -> bool:
	var arrays := mi.mesh.surface_get_arrays(i)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	if verts.size() < 3 or uvs.size() != verts.size():
		return false
	var e1 := verts[1] - verts[0]
	var e2 := verts[2] - verts[0]
	var t1 := uvs[1] - uvs[0]
	var t2 := uvs[2] - uvs[0]
	var det := t1.x * t2.y - t2.x * t1.y
	if absf(det) < 0.000001:
		return false
	mesh = mi
	surface = i
	material_name = mat_name
	_p0 = verts[0]
	_uv0 = uvs[0]
	_du = (e1 * t2.y - e2 * t1.y) / det
	_dv = (e2 * t1.x - e1 * t2.x) / det
	var lo := uvs[0]
	var hi := uvs[0]
	for uv in uvs:
		lo = lo.min(uv)
		hi = hi.max(uv)
	_uv_mid = (lo + hi) * 0.5
	size = Vector2(_du.length() * (hi.x - lo.x), _dv.length() * (hi.y - lo.y))
	return true


## World frame at the screen's centre: x = texture right, y = texture up, z = out of the screen (the side the image
## reads correctly from).
func frame() -> Transform3D:
	var xf := mesh.global_transform
	var right := (xf.basis * _du).normalized()
	var up := -(xf.basis * _dv).normalized()
	return Transform3D(Basis(right, up, right.cross(up).normalized()), point_at(_uv_mid))


## World point at texture coordinate `uv`.
func point_at(uv: Vector2) -> Vector3:
	return mesh.global_transform * (_p0 + _du * (uv.x - _uv0.x) + _dv * (uv.y - _uv0.y))


## Texture UV where a world ray meets the screen's plane (0..1 on the screen, outside it beyond); MISS if it never does.
func ray_uv(origin: Vector3, dir: Vector3) -> Vector2:
	var f := frame()
	var along := dir.dot(f.basis.z)
	if absf(along) < 0.0001:
		return MISS
	var t := (f.origin - origin).dot(f.basis.z) / along
	if t < 0.0:
		return MISS
	return uv_at(origin + dir * t)


## Texture UV of a world point on (or projected onto) the screen's plane.
func uv_at(point: Vector3) -> Vector2:
	var d := mesh.global_transform.affine_inverse() * point - _p0
	var d00 := _du.dot(_du)
	var d01 := _du.dot(_dv)
	var d11 := _dv.dot(_dv)
	var x0 := d.dot(_du)
	var x1 := d.dot(_dv)
	var den := d00 * d11 - d01 * d01
	if absf(den) < 0.0000001:
		return MISS
	return _uv0 + Vector2((d11 * x0 - d01 * x1) / den, (d00 * x1 - d01 * x0) / den)


## A camera transform square on to the screen, far enough back that the screen fills the view at `fov_deg` (vertical,
## Camera3D.KEEP_HEIGHT) and `aspect` (width / height) with `margin` (1.1 = a tenth of room round it).
func view_from(fov_deg: float, aspect: float, margin: float) -> Transform3D:
	var f := frame()
	var t := tan(deg_to_rad(fov_deg) * 0.5)
	var d := maxf(size.y * 0.5 / t, size.x * 0.5 / (t * maxf(aspect, 0.1))) * margin
	var eye := f.origin + f.basis.z * d
	return Transform3D(Basis.looking_at(f.origin - eye, f.basis.y), eye)
