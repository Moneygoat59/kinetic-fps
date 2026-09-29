class_name AptMood
extends RefCounted
## Lighting moods for an interior (the apartment first; any enclosed level can use them). A mood is data: the sun through the
## windows, the sky seen through them, the room fill, haze in the light shafts, grading. apply() builds the WorldEnvironment and
## the sun under `host` (with AptShadows for sharper, softer interior shadow maps), plus a box-projected ReflectionProbe for every marker_room_* of the shell (scale = half extents).
## Levels pick a mood per visit, so the same flat can feel different each time the walker comes back to it.

const MOODS := {
	# low sun from the south-west through the blinds: the first thing the player sees
	&"golden_hour": {"sun": Color(1.0, 0.7, 0.42), "sun_energy": 4.2, "azimuth": -48.0, "elevation": 13.0,
		"sky": Color(1.0, 0.8, 0.6), "ambient": Color(1.0, 0.82, 0.66), "ambient_energy": 0.5, "fog": Color(1.0, 0.78, 0.55),
		"fog_density": 0.018, "exposure": 1.0, "saturation": 1.08, "view_energy": 1.4},
	# after dark: only the lamps, blue window light
	&"night": {"sun": Color(0.55, 0.62, 0.9), "sun_energy": 0.25, "azimuth": 30.0, "elevation": 35.0,
		"sky": Color(0.1, 0.12, 0.2), "ambient": Color(0.35, 0.4, 0.6), "ambient_energy": 0.12, "fog": Color(0.3, 0.35, 0.5),
		"fog_density": 0.01, "exposure": 1.2, "saturation": 0.95, "view_energy": 0.25},
	# the middle of the night: every lamp off (practicals false), a little moonlight, the city asleep; the TV lights the room
	&"small_hours": {"sun": Color(0.5, 0.58, 0.85), "sun_energy": 0.08, "azimuth": 20.0, "elevation": 40.0,
		"sky": Color(0.04, 0.05, 0.09), "ambient": Color(0.3, 0.35, 0.55), "ambient_energy": 0.03, "fog": Color(0.25, 0.3, 0.45),
		"fog_density": 0.008, "exposure": 1.0, "saturation": 0.8, "view_energy": 0.12, "view_tint": Color(0.3, 0.38, 0.62),
		"practicals": false},
	# weeks shut in (the flat gone to squalor): daylight outside, the blinds turned shut; thin blades of it through the
	# slats into stale, dusty air; drained and dim, the bulbs weak
	&"squalor": {"sun": Color(1.0, 0.84, 0.62), "sun_energy": 3.4, "azimuth": -48.0, "elevation": 16.0,
		"sky": Color(0.5, 0.5, 0.46), "ambient": Color(0.62, 0.64, 0.56), "ambient_energy": 0.32, "fog": Color(0.7, 0.68, 0.56),
		"fog_density": 0.04, "exposure": 1.15, "saturation": 0.6, "view_energy": 0.45, "view_tint": Color(0.75, 0.76, 0.7),
		"practical_energy": 0.4},
}
const PROBE_PREFIX := "marker_room_"


## Lights `host` with `mood` (unknown names fall back to golden_hour). Returns the sun.
static func apply(host: Node3D, mood: StringName, shell: Node3D = null) -> DirectionalLight3D:
	var m: Dictionary = MOODS.get(mood, MOODS[&"golden_hour"])
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = _environment(m)
	host.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = m["sun"]
	sun.light_energy = m["sun_energy"]
	sun.light_volumetric_fog_energy = 2.5
	sun.shadow_enabled = true
	sun.shadow_bias = 0.015
	sun.shadow_normal_bias = 0.6
	sun.shadow_blur = 1.0
	sun.light_angular_distance = 0.6         # the sun's disc: blind stripes soften away from the slats (PCSS)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 14.0   # the flat is 10 m across: every texel stays indoors
	host.add_child(sun)
	var shadows := AptShadows.new()
	shadows.name = "Shadows"
	host.add_child(shadows)
	var az := deg_to_rad(m["azimuth"])
	var el := deg_to_rad(m["elevation"])
	var dir := Vector3(-sin(az) * cos(el), -sin(el), -cos(az) * cos(el))   # where the light travels (azimuth from -Z, +CW)
	sun.basis = Basis.looking_at(dir, Vector3.UP)
	if shell:
		_probes(shell)
		_views(shell, m["view_energy"], m.get("view_tint", Color.WHITE))
		if not m.get("practicals", true):
			AptPracticals.off(shell)
		elif m.has("practical_energy"):
			AptPracticals.dim(shell, m["practical_energy"])
	return sun


static func _environment(m: Dictionary) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = m["sky"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = m["ambient"]
	env.ambient_light_energy = m["ambient_energy"]
	env.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = m["exposure"]
	env.ssao_enabled = true
	env.ssao_radius = 0.8
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.ssil_radius = 3.0
	env.ssil_intensity = 1.2
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_min_cell_size = 0.1
	env.sdfgi_cascades = 3
	env.sdfgi_bounce_feedback = 0.6
	env.sdfgi_energy = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.1
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = m["fog_density"]
	env.volumetric_fog_albedo = m["fog"]
	env.volumetric_fog_length = 14.0          # froxel slices packed into the flat, not wasted past its walls
	env.volumetric_fog_anisotropy = 0.55
	env.adjustment_enabled = true
	env.adjustment_saturation = m["saturation"]
	env.adjustment_contrast = 1.04
	return env


## One interior, box-projected reflection probe per room (the mirror, porcelain and the TV pick them up).
static func _probes(shell: Node3D) -> void:
	for child in shell.get_children():
		if not String(child.name).begins_with(PROBE_PREFIX):
			continue
		var room := child as Node3D
		var probe := ReflectionProbe.new()
		probe.name = "probe_" + String(child.name).trim_prefix(PROBE_PREFIX)
		probe.size = room.scale.abs() * 2.0
		probe.box_projection = true
		probe.interior = true
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		probe.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
		shell.add_child(probe)
		probe.global_position = room.global_position


## The window backdrops glow with the mood (day sky or night city), tinted by it (the small hours: the city gone dark blue).
static func _views(shell: Node3D, energy: float, tint: Color) -> void:
	for child in shell.get_children():
		if not (String(child.name).begins_with("view") and child is MeshInstance3D):
			continue
		var mi := child as MeshInstance3D
		var mat := mi.get_active_material(0) as BaseMaterial3D
		if mat:
			var own := mat.duplicate() as BaseMaterial3D
			own.emission_energy_multiplier = energy
			own.albedo_color *= tint
			own.emission *= tint
			mi.material_override = own

