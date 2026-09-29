class_name SiloTunnels
extends RefCounted
## Joins Missile Silo 00's open vent to the underground line (the silo depths level): the duct's blanking cap comes off,
## the duct runs on EXTRA more 2 m lengths outward, and the TunnelNetwork is moved so its entry vent's duct mouth takes the
## end of that run; the crawl then drops out through the tunnel wall onto the walkway. The duct's sound builds toward the
## new end and stops once the walker climbs out into the tunnel. While the walker is inside the network the generator
## hall is sealed off from their ears (SiloHallEar). The forest's silo keeps its cap (only this level joins).

const CAP := "marker_kit_duct_cap__vent"
const EXTRA := 3


static func attach(silo: MissileSilo, network: TunnelNetwork) -> bool:
	var marker := _cap_marker(silo)
	if marker == null or network == null or network.vent_mouth == null:
		push_warning("SiloTunnels: no duct cap or no tunnel vent to join")
		return false
	var cap := marker.global_transform
	var out := -cap.basis.z
	out.y = 0.0
	out = out.normalized()
	_remove_cap(silo, marker)
	for i in EXTRA:
		var length := O73Kit.spawn(&"duct_straight", silo)
		length.name = "duct_extra_%d" % i
		length.global_transform = Transform3D(cap.basis, cap.origin + out * (2.0 * i + 1.0))
	var mouth_at := cap.origin + out * (2.0 * EXTRA + O73Kit.DUCT_MOUTH)
	network.place_by_mouth(Transform3D(Basis.looking_at(-out, Vector3.UP), mouth_at))
	var sound := silo.model.get_node_or_null("DuctSound") as DuctSound
	if sound:
		sound.set_end(silo.model.to_local(mouth_at))
		if network.vent:
			network.vent.climbed.connect(sound.on_climbed)
	if silo.generators:
		network.inside_changed.connect(silo.generators.set_sealed)     # the hall's machines cannot be heard through the rock
	return true


static func _cap_marker(silo: MissileSilo) -> Node3D:
	if silo == null or silo.model == null:
		return null
	for child in silo.model.get_children():
		if String(child.name).begins_with(CAP):
			return child as Node3D
	return null


## The cap piece goes, and so does its share of the silo's kit batches (its meshes are drawn there, not by the piece).
static func _remove_cap(silo: MissileSilo, marker: Node3D) -> void:
	var meshes := {}
	var sample := (load(O73Kit.path(&"duct_cap")) as PackedScene).instantiate()
	for node in sample.find_children("*", "MeshInstance3D", true, false):
		meshes[(node as MeshInstance3D).mesh] = true
	sample.free()
	for node in silo.find_children("kit_batch_*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if mmi.multimesh and meshes.has(mmi.multimesh.mesh) and mmi.multimesh.instance_count == 1:
			mmi.visible = false
	for child in marker.get_children():
		child.queue_free()
