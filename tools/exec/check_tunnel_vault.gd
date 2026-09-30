extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the records vault (tunnel_vault) at the end of its run in the silo
## depths' tunnel network. Switches to scenes/levels/silo_depths.tscn and checks: the vault was laid at vault_mouth and
## furnished (every kit marker has its piece, the tape cage console is a usable terminal); there is floor and a clear way
## (three rays, knee to head) from the walkway along the dock, through the round doorway, down the aisle, through the
## cage gate to the console, and into the stacks' open aisle; the hall is closed in (walls all round, ceiling over);
## the lamps are lit, two of them shadowed; an emergency pylon stands on the dock; the vault is inside the network's bounds.
## `SHOT` = $env:VAULT_SHOT: stands the walker at the vault (dev place) and holds, for a capture in the real level.

const LEVEL := "res://scenes/levels/silo_depths.tscn"
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")
const F := 0.7                                          # O73Kit.WALK_Z: the dock and hall floor
## the walk, piece space (Godot: -Z = deeper in): walkway, dock, doorway, hall, aisle, cage gate, the console's chair
const PATH: Array[Vector3] = [Vector3(2.4, F, -2.0), Vector3(2.4, F, -8.2), Vector3(0.0, F, -9.4), Vector3(0.0, F, -12.0),
	Vector3(0.0, F, -28.0), Vector3(0.0, F, -29.6), Vector3(-1.8, F, -31.2)]
const STACK_AISLE: Array[Vector3] = [Vector3(-1.5, F, -16.8), Vector3(-8.2, F, -16.8)]


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("tunnel_vault_check", self)
	tree.set_meta("capture_hold", true)
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	var net := level.tunnels if level else null
	var vault := net.vault if net else null
	_check("the vault ends the run out of vault_mouth %s" % (net.vault_mouth if net else Vector3i.ZERO),
		vault != null and String(vault.name).begins_with("tunnel_vault"))
	if vault == null:
		tree.set_meta("capture_hold", false)
		return
	var space := vault.get_world_3d().direct_space_state
	_furniture(vault)
	_walk(space, vault, PATH, "walkway, dock, door, aisle, cage gate, console")
	_walk(space, vault, STACK_AISLE, "into the stacks' open aisle")
	_enclosed(space, vault)
	var lamps := vault.find_children("*", "OmniLight3D", true, false)
	var shadowed := lamps.filter(func(l: OmniLight3D): return l.shadow_enabled and l.get_parent().name.begins_with("marker_light_vault"))
	_check("the vault's lamps burn (%d lights, %d shadowed)" % [lamps.size(), shadowed.size()], lamps.size() >= 10 and shadowed.size() == 2)
	var dock := net.pylons.filter(func(p: EmergencyPylon): return p.get_parent() == vault)
	_check("an emergency pylon stands on the dock (%d)" % dock.size(), dock.size() == 1)
	_check("the vault is inside the network's bounds (hall centre)", net.bounds.has_point(net.to_local(vault.to_global(Vector3(0, 2, -22)))))
	if OS.get_environment("VAULT_SHOT") != "":
		var place: Array = level.dev_places().filter(func(p: Array): return p[0] == "Tunnels: records vault").front()
		level.player.global_position = place[1]
		return                                          # hold for the capture
	tree.set_meta("capture_hold", false)


func _furniture(vault: Node3D) -> void:
	var markers := 0
	var empty := 0
	var terminal: TerminalStation = null
	for child in vault.get_children():
		if not String(child.name).begins_with(KitScript.PREFIX):
			continue
		markers += 1
		empty += 1 if child.get_child_count() == 0 else 0
		var found := child.find_children("*", "TerminalStation", true, false)
		if not found.is_empty():
			terminal = found[0]
	_check("every kit marker has its piece (%d markers, %d empty)" % [markers, empty], markers > 60 and empty == 0)
	_check("the tape cage console is a usable terminal (%s)" % (terminal.drive.name if terminal and terminal.drive else "none"),
		terminal != null and terminal.drive != null)


## Floor under every 0.5 m of the path and nothing across it at knee, chest and head height.
func _walk(space: PhysicsDirectSpaceState3D, vault: Node3D, path: Array[Vector3], label: String) -> void:
	var misses := 0
	var blocks := 0
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var steps := maxi(int(a.distance_to(b) / 0.5), 1)
		for j in steps + 1:
			var p := a.lerp(b, float(j) / steps)
			var from := vault.to_global(p + Vector3.UP * 1.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 1.6))
			if hit.is_empty() or absf(vault.to_local(hit.position).y - F) > 0.06:
				misses += 1
				print("CHECK FAIL no floor at %s (%s)" % [p, vault.to_local(hit.position) if hit else "nothing"])
		for h in [0.4, 1.0, 1.7]:
			var ray := PhysicsRayQueryParameters3D.create(vault.to_global(a + Vector3.UP * h), vault.to_global(b + Vector3.UP * h))
			var hit := space.intersect_ray(ray)
			if not hit.is_empty():
				blocks += 1
				print("CHECK FAIL blocked %s -> %s at %.1f m by %s" % [a, b, h, hit.collider.get_parent().name if hit.collider else "?"])
	_check("%s: floor all the way and clear (%d misses, %d blocks)" % [label, misses, blocks], misses == 0 and blocks == 0)


func _enclosed(space: PhysicsDirectSpaceState3D, vault: Node3D) -> void:
	var centre := Vector3(0.0, 3.5, -22.0)
	var open := 0
	for k in 8:
		var dir := Vector3(0, 0, -1).rotated(Vector3.UP, TAU * k / 8.0)
		var ray := PhysicsRayQueryParameters3D.create(vault.to_global(centre), vault.to_global(centre + dir * 16.0))
		open += 0 if not space.intersect_ray(ray).is_empty() else 1
	var up := PhysicsRayQueryParameters3D.create(vault.to_global(centre), vault.to_global(centre + Vector3.UP * 4.0))
	_check("the hall is closed in (%d of 8 ways open; ceiling %s)" % [open, "yes" if not space.intersect_ray(up).is_empty() else "no"],
		open == 0 and not space.intersect_ray(up).is_empty())


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
