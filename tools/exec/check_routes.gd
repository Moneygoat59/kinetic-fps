extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): plays the relay network through DeadForestEvent without walking.
## Outpost 73's terminal is locked until the dosimeter is taken, then programs route 73 (lays it, raises the hub); the hub's
## router keys route back out, write routes 02 / 03 / 00 as keys unlock them, refuse locked ones; every outer terminal
## programs its route home; chains persist and the dosimeter drops the old target when the route changes.

func run(scene: Node, _tree: SceneTree) -> void:
	var ev = scene.get_node("DeadForestEvent")
	var R := HubRoutes.Route
	ev._spawn_bunker_1(Vector3.ZERO)
	var bunker = ev.bunker_instance
	_check("73 terminal mounted", bunker.terminal != null)
	_check("73 terminal locked before dosimeter", bunker.terminal.state == RouteTerminal.State.LOCKED)
	bunker.check_interaction(bunker.global_position, true)
	_check("dosimeter taken", ev.dosimeter != null and bunker.terminal.state == RouteTerminal.State.READY)
	_check("no route yet", ev.dosimeter.pylons.is_empty() and ev.hub_instance == null)
	bunker.terminal.update(bunker.global_position, true)
	var hub = ev.hub_instance
	_check("73 terminal raised the hub", hub != null and ev.net.has_route(R.W73))
	_check("track 73 ends at the hub mast", _last(ev) == hub.route_mast(R.W73))
	_check("73 terminal shows ROUTE SET", bunker.terminal.state == RouteTerminal.State.SET)
	var chain73: Array = ev.net._chains[R.W73].duplicate()
	_check("keys: 73 route / 02 write / 03 + 00 locked", _modes(hub) == [0, 1, 2, 2])
	_press(hub, R.W73)
	_check("hub routes back out to 73", _last(ev) == chain73[0] and bunker.terminal.state == RouteTerminal.State.READY)
	_check("old target released", not hub.route_mast(R.W73).is_active)
	_press(hub, R.W03)
	_check("locked key refused", ev.outpost_3_instance == null and hub.current_stage == 0)
	_press(hub, R.W02)
	var o2 = ev.outpost_2_instance
	_check("02 written: outpost raised, track out", o2 != null and _last(ev) == ev.net._chains[R.W02][0])
	_check("route 73 chain still standing", chain73.all(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion()))
	o2.terminal.update(o2.global_position, true)
	_check("02 terminal routes home", _last(ev) == hub.route_mast(R.W02) and o2.terminal.state == RouteTerminal.State.SET)
	o2.check_interaction(o2.global_position, true)
	_check("key 02 advances the hub only", hub.current_stage == 2 and _last(ev) == hub.route_mast(R.W02))
	_press(hub, R.W03)
	var o3 = ev.outpost_3_instance
	_check("03 written", o3 != null and ev.net.has_route(R.W03))
	_press(hub, R.W02)
	_check("existing route 02 selectable again", _last(ev) == ev.net._chains[R.W02][0])
	o3.check_interaction(o3.global_position, true)
	_press(hub, R.SILO)
	var silo = ev.silo_instance
	_check("silo written", silo != null and hub.current_stage == 5 and ev.net.has_route(R.SILO))
	_check("silo terminal mounted", silo.terminal != null and silo.terminal.state == RouteTerminal.State.READY)
	silo.terminal.update(silo.global_position, true)
	_check("silo terminal routes home", _last(ev) == hub.route_mast(R.SILO))
	_check("every key routes at the end", _modes(hub) == [0, 0, 0, 0])


func _press(hub: Node, r: int) -> void:
	hub.keys._press(r)
	hub.console.force_finish()


func _last(ev: Node) -> Node3D:
	var track: Array = ev.dosimeter.pylons
	return track.back() if not track.is_empty() else null


func _modes(hub: Node) -> Array:
	var out := []
	for r in 4:
		out.append(int(hub.keys.mode_of(r)))
	return out


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
