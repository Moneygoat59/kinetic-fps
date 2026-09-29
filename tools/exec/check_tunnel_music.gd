extends RefCounted
## capture.ps1 -Exec hook (a test, prints CHECK lines): the underground line's music (TunnelMusic). Switches to
## scenes/levels/silo_depths.tscn and checks: silent in the silo's hall; stepping out into the tunnels starts the base
## stem (the intro) and no layer; far down the line the deep and strain layers are in; back in the hall it hands back and
## stops; the stems are the same length and loop from the same point.

const LEVEL := "res://scenes/levels/silo_depths.tscn"


func run(_scene: Node, tree: SceneTree) -> void:
	tree.set_meta("tunnel_music_check", self)
	tree.set_meta("capture_hold", true)
	tree.change_scene_to_file(LEVEL)
	for i in 5:
		await tree.physics_frame
	var level := tree.current_scene as SiloDepthsLevel
	var net := level.tunnels if level else null
	if net == null or net.music == null:
		_check("the tunnel network has its music", false)
		tree.set_meta("capture_hold", false)
		return
	var zone := net.music.zone
	var player := level.player
	player.set_physics_process(false)
	_check("silent while the walker is still in the hall", zone.state == MusicZone.State.OUTSIDE and not zone._players[0].playing)
	player.global_position = net.vent_mouth.global_position + net.vent_mouth.global_basis.z * 2.0 + Vector3.DOWN * 1.4
	await tree.create_timer(0.5).timeout
	_check("stepping out into the tunnels starts the theme", zone.state == MusicZone.State.INSIDE and zone._players[0].playing)
	_check("near the vent only the base is in the mix (deep %.2f, strain %.2f)" % [zone._weight[1], zone._weight[2]],
		zone._weight[1] < 0.05 and zone._weight[2] < 0.05)
	var far: Node3D = net.halls.get(Vector2i(net.cols - 1, net.rows - 1))
	player.global_position = far.global_position + far.global_basis.z * 7.0
	await tree.create_timer(4.0).timeout
	_check("far down the line the deep and strain layers are in (deep %.2f, strain %.2f)" % [zone._weight[1], zone._weight[2]],
		zone._weight[1] > 0.95 and zone._weight[2] > 0.95)
	player.global_position = level.silo.model.get_node("marker_vent_mouth").global_position
	await tree.physics_frame
	await tree.physics_frame
	_check("back in the hall the theme lets go", zone.state == MusicZone.State.OUTSIDE)
	var waited := 0.0
	while zone._players[0].playing and waited < 2.0 * MusicZone.FADE_OUT:     # the tween runs a little behind the wall clock here
		await tree.create_timer(0.25).timeout
		waited += 0.25
	_check("and stops once it has faded (%.1f s)" % waited, not zone._players[0].playing)
	var lengths := {}
	var loops := {}
	for stem in [TunnelMusic.BASE, TunnelMusic.DEEP, TunnelMusic.STRAIN]:
		lengths[snappedf(stem.get_length(), 0.01)] = true
		loops[(stem as AudioStreamOggVorbis).loop_offset] = true
	_check("the stems share one length and one loop point (%s s, offset %s)" % [lengths.keys(), loops.keys()],
		lengths.size() == 1 and loops.size() == 1 and loops.keys()[0] > 100.0)
	tree.set_meta("capture_hold", false)


func _check(what: String, ok: bool) -> void:
	print("CHECK %s %s" % ["ok  " if ok else "FAIL", what])
