extends RefCounted
## Dev hook (godot MCP game_eval / capture -Exec): starts night 2's finale (WraithGrab) on the scene's player, frozen, and
## steps it to `at` seconds so each phase can be screenshotted. Usage from game_eval:
##   load("res://tools/exec/wraith_grab_test.gd").new().step(get_tree(), 3.0)   (the walker is moved to `where` first)

func step(tree: SceneTree, at: float, where := Vector3(30.0, 0.0, 30.0)) -> Array:
	Engine.time_scale = 0.0
	var scene := tree.current_scene
	var old := scene.get_node_or_null("GrabTest")
	if old:
		old.wraith.free()
		old.free()
	var p: Player = null
	for n in scene.find_children("*", "CharacterBody3D", true, false):
		if n is Player:
			p = n
	var terrain := scene.get_node_or_null("DeadForestTerrain")
	p.global_position = Vector3(where.x, terrain.get_height(where.x, where.z) if terrain else where.y, where.z)
	p.camera.rotation = Vector3.ZERO
	p.camera.fov = 85.0
	p.head.rotation = Vector3.ZERO
	var st := WraithStalk.new()
	st.name = "GrabTest"
	scene.add_child(st)
	st.setup(p, terrain)
	st._finale()
	var g: WraithGrab = st.get_child(0)
	st.wraith.view.set_presence(1.0)
	st.wraith._enter(Wraith.State.PRESENT)
	var t := 0.0
	while t < at and g.state != WraithGrab.State.DONE:
		st.wraith.view._process(0.02)                                   # as the frames would
		g._process(0.02)
		t += 0.02
	return [g.state, g._t, g._side]
