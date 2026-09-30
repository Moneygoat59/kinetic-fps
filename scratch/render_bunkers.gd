extends SceneTree

func _init() -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(960, 540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var world = Node3D.new()
	viewport.add_child(world)

	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.14, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.5)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	world.add_child(env_node)

	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 45, 0)
	light.light_energy = 1.2
	world.add_child(light)

	var cam = Camera3D.new()
	cam.current = true
	world.add_child(cam)

	# 1. Render SmallBunker
	var b1 = SmallBunker.new()
	b1.build_bunker(null, 0, 0)
	world.add_child(b1)
	cam.position = Vector3(8.0, 5.0, 9.0)
	cam.look_at(Vector3(0.0, 1.5, 0.0))
	_capture(viewport, "scratch/render_bunker_1.png")
	b1.queue_free()

	# 2. Render HubBuilding
	var hub = HubBuilding.new()
	hub.build_hub(null, 0, 0)
	world.add_child(hub)
	cam.position = Vector3(10.0, 6.0, 12.0)
	cam.look_at(Vector3(0.0, 2.0, 0.0))
	_capture(viewport, "scratch/render_hub.png")
	hub.queue_free()

	# 3. Render OutpostBuilding
	var op = OutpostBuilding.new()
	op.build_outpost(null, 0, 0, 2, Color(0.15, 0.8, 1.0))
	world.add_child(op)
	cam.position = Vector3(9.0, 5.5, 10.0)
	cam.look_at(Vector3(0.0, 1.8, 0.0))
	_capture(viewport, "scratch/render_outpost.png")
	op.queue_free()

	# 4. Render Missile Silo
	var silo = MissileSilo.new()
	silo.build_silo(null, 0, 0)
	world.add_child(silo)
	cam.position = Vector3(75.0, 45.0, 75.0)
	cam.look_at(Vector3(0.0, 10.0, 0.0))
	_capture(viewport, "scratch/render_silo.png")
	silo.queue_free()

	print("ALL BUNKER RENDERS COMPLETE")
	quit()

func _capture(vp: SubViewport, path: String) -> void:
	# Give viewport frames to render
	RenderingServer.frame_post_draw.emit()
	var img = vp.get_texture().get_image()
	if img:
		img.save_png(ProjectSettings.globalize_path(path))
		print("Saved: ", path)
