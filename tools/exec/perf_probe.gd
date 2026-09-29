extends RefCounted
## capture.ps1 -Exec hook: waits 120 frames, then prints one PERF line (fps, process / physics ms, draw calls,
## primitives) for whatever the capture camera sees. Env PROBE_SPAWN=res://tools/exec/<hook>.gd runs that spawn hook
## first, so the same view can be compared with and without a building.

func run(scene: Node, tree: SceneTree) -> void:
	if OS.has_environment("PROBE_SPAWN"):
		(load(OS.get_environment("PROBE_SPAWN")) as GDScript).new().run(scene, tree)
	scene.set_meta("perf_probe", self)             # capture.gd drops its reference to this hook; stay alive while awaiting
	var vp := tree.root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	for i in 120:
		await tree.process_frame
	print("PERF fps=%d gpu=%.2fms process=%.2fms physics=%.2fms draws=%d prims=%d" % [Engine.get_frames_per_second(),
		RenderingServer.viewport_get_measured_render_time_gpu(vp),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
