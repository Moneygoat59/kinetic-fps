class_name AptGrime
extends RefCounted
## Grime projected onto the flat (Godot Decals; textures from tools/blender/apt_mess_textures.py): spill, rings, smudge, mould,
## water, dust, crumbs, streaks. Any surface, any kit piece in the box takes it. Build-time only:
##   AptGrime.make(parent, &"spill", Vector3(x, 0, z), Vector2(w, d), Vector3.UP)     # on the floor
##   AptGrime.make(parent, &"mould", Vector3(x, 2.69, z), Vector2(w, d), Vector3.DOWN) # on the ceiling
## normal = the surface's normal (the decal projects against it); yaw turns it about that normal (degrees); depth = how far
## either side of `at` it reaches (default DEPTH; deeper to reach into a bath).

const DIR := "res://models/generated/tex/apt_grime_%s.png"
const KINDS: Array[StringName] = [&"spill", &"rings", &"smudge", &"mould", &"water", &"dust", &"crumbs", &"streaks"]
const DEPTH := 0.12                          # m either side of the surface the decal reaches

static var _matte: ImageTexture             # ORM for every grime decal: full roughness, so dirt kills the floor's shine


static func make(parent: Node3D, kind: StringName, at: Vector3, size: Vector2, normal: Vector3, yaw := 0.0,
		opacity := 1.0, depth := DEPTH) -> Decal:
	if parent == null or not KINDS.has(kind) or normal.length_squared() < 0.001:
		return null
	var tex := load(DIR % kind) as Texture2D
	if tex == null:
		return null
	var d := Decal.new()
	d.name = "grime_" + String(kind)
	d.texture_albedo = tex
	d.texture_orm = _orm()
	d.size = Vector3(size.x, maxf(depth, 0.01) * 2.0, size.y)
	d.modulate = Color(1, 1, 1, opacity)
	d.upper_fade = 0.2
	d.lower_fade = 0.2
	d.normal_fade = 0.3                      # not onto the sides of things standing in it
	var n := normal.normalized()                                        # the decal's +Y: it projects along -Y, into the surface
	var side := Vector3.RIGHT if absf(n.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var x := (side - n * side.dot(n)).normalized()
	var turn := Basis(n, deg_to_rad(yaw))
	parent.add_child(d)
	d.global_transform = Transform3D(turn * Basis(x, n, x.cross(n)), at)
	return d


static func _orm() -> ImageTexture:
	if _matte == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
		img.fill(Color(1.0, 1.0, 0.0))                                   # occlusion 1, roughness 1, metal 0
		_matte = ImageTexture.create_from_image(img)
	return _matte
