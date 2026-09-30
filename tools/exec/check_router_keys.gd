extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): spawns Relay Hub 00 (spawn_relay_hub.gd) and, once physics has
## run, casts the player's aim ray (areas included, like Player.AimRay) from a standing eye in front of the router at each
## route key: the ray must find that key's HubRouterKeys area before the console's own collision. Looking at the screen
## must not hit a key.

const EYE_BACK := 0.95       # m in front of the console's origin (its front face is at 0.45)
const EYE_UP := 1.62         # above the router's base


func run(scene: Node, tree: SceneTree) -> void:
	load("res://tools/exec/spawn_relay_hub.gd").new().run(scene, tree)
	var hub = scene.get_node("DeadForestEvent").get_children().filter(func(n): return n is RelayHub).back()
	scene.set_meta(&"check_router_keys", self)                    # capture drops the hook after run(): keep it for the probe
	tree.create_timer(0.5).timeout.connect(_probe.bind(hub, scene.get_viewport().world_3d.direct_space_state))


func _probe(hub: RelayHub, space: PhysicsDirectSpaceState3D) -> void:
	var router: Node3D = hub.keys._areas[0].get_parent()
	for r in HubRouterKeys.KEY_X.size():
		var x: float = HubRouterKeys.KEY_X[r]
		for side in [-0.4, 0.0, 0.4]:                                 # straight on and from either side
			var eye := router.to_global(Vector3(x + side, EYE_UP, EYE_BACK))
			var key := router.to_global(Vector3(x, 1.01, 0.118))     # the key cap on the deck (router.py)
			var hit := _ray(space, eye, key)
			var ok: bool = hit is HubRouterKeys.KeyArea and hit.route == r
			_check("key %d from %+.1f m -> %s" % [r, side, _name(hit)], ok)
	var screen := router.to_global(Vector3(0.0, 1.4, -0.16))
	var hit_scr := _ray(space, router.to_global(Vector3(0.0, EYE_UP, EYE_BACK)), screen)
	_check("screen look hits no key -> %s" % _name(hit_scr), not hit_scr is HubRouterKeys.KeyArea)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, at: Vector3) -> Object:
	var q := PhysicsRayQueryParameters3D.create(from, from + (at - from).normalized() * 4.0)
	q.collide_with_areas = true
	return space.intersect_ray(q).get("collider")


func _name(o: Object) -> String:
	return "nothing" if o == null else ("key %d" % o.route if o is HubRouterKeys.KeyArea else String(o.name))


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
