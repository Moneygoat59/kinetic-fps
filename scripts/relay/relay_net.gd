class_name RelayNet
extends RefCounted
## The relay network as the player uses it: one chain of masts per hub route (HubRoutes.Route), kept in walking order from
## its outer site (Outpost 73 / 02 / 03, the silo) toward Relay Hub 00. Chains stay standing once laid, so any route that
## exists can be followed either way from the terminal at either end (RouteTerminal, the hub's router keys) whatever the
## progress, the way a working network would. track() hands RadiationDosimeter the masts to follow.

var _chains: Array = [[], [], [], []]        # per route: Array[Node3D], outer site -> hub (the hub's corner mast not included)


## Stores a laid chain. from_hub = it was laid outward from the hub (reversed to outer -> hub).
func add_route(route: int, chain: Array[Node3D], from_hub: bool) -> void:
	if route < 0 or route >= _chains.size():
		return
	var ordered: Array[Node3D] = chain.duplicate()
	if from_hub:
		ordered.reverse()
	_chains[route] = ordered


func has_route(route: int) -> bool:
	return route >= 0 and route < _chains.size() and not (_chains[route] as Array).is_empty()


## The masts to follow along `route`, uncleared: toward the hub it ends at the hub's corner mast `hub_mast`; outward it
## starts at the first mast past the corner and ends at the outer site.
func track(route: int, to_hub: bool, hub_mast: Node3D) -> Array[Node3D]:
	var out: Array[Node3D] = []
	if not has_route(route):
		return out
	for p in _chains[route]:
		if is_instance_valid(p):
			out.append(p)
	if to_hub and hub_mast:
		out.append(hub_mast)
	elif not to_hub:
		out.reverse()
	for p in out:
		p.is_cleared = false
	return out
