extends Node3D
## Dev showroom for the rail tunnel kit (scenes/dev/tunnel_showcase.tscn): an interchange hall (its north mouth open) and
## one run of every tunnel piece out of it in the dark, as a level would lay it (TunnelLine), emergency pylons standing in the refuges, a duct mouth in the vent piece with its grille
## on the walkway, a buffer stop before the cave-in. The line starts at the origin and runs along -Z. Out of the hall's
## east mouth a short line runs through the station (tunnel_station) to the records vault (tunnel_vault, both furnished as
## they are laid): _vault_line() prints their places for -Cam / -Look.
## Capture: tools\capture.ps1 -Scene res://scenes/dev/tunnel_showcase.tscn -Cam -0.6,1.7,-2 -Look -0.6,1.5,-20 -NoUi
## ($env:TUNNEL_LIT=1: flat work light, no fog, to judge the geometry rather than the mood)

const LINE: Array[StringName] = [&"tunnel_bulkhead", &"tunnel_straight", &"tunnel_refuge", &"tunnel_straight",
	&"tunnel_curve_r", &"tunnel_curve_r", &"tunnel_curve_r", &"tunnel_vent", &"tunnel_straight", &"tunnel_curve_l",
	&"tunnel_curve_l", &"tunnel_refuge", &"tunnel_straight", &"tunnel_collapse"]
const VAULT_LINE: Array[StringName] = [&"tunnel_straight", &"tunnel_station", &"tunnel_vault"]
const BUFFER_AT := Vector3(-0.6, 0.0, -1.6)        # in the collapse piece: on the track, 1.6 m in
const KitScript = preload("res://scripts/bunker/bunker_kit.gd")

var pieces: Array[Node3D] = []
var pylons: Array[EmergencyPylon] = []
var vault: Node3D


func _ready() -> void:
	_environment()
	var hall := O73Kit.spawn(&"tunnel_junction", self, Transform3D(Basis(), Vector3(0.0, 0.0, O73Kit.JUNC_R)))
	KitScript.drop_part(hall, "seal_0")
	for k in 4:
		var at := hall.get_node_or_null("marker_pylon_%d" % k) as Node3D
		if at:
			var pylon := EmergencyPylon.new()
			pylon.cast_shadows = false
			pylon.transform = at.transform
			hall.add_child(pylon)
	pieces = TunnelLine.lay(self, Transform3D.IDENTITY, LINE)
	TunnelLine.batch(self, pieces)
	pylons = TunnelLine.pylons(pieces)
	for piece in pieces:
		var vent := piece.get_node_or_null("marker_vent") as Node3D
		if vent:
			var mouth := O73Kit.spawn(&"duct_mouth", piece, vent.transform)
			VentDuct.mount(mouth)
			var grille := Transform3D(Basis(Vector3.UP, 0.35), Vector3(2.2, O73Kit.WALK_Z + 0.005, vent.position.z + 1.4))
			O73Kit.spawn(&"duct_grille", piece, grille)
	var end := pieces.back() as Node3D
	if end and String(end.name).begins_with("tunnel_collapse"):
		O73Kit.spawn(&"rail_buffer", end, Transform3D(Basis(), BUFFER_AT))
	_vault_line(hall)


func _vault_line(hall: Node3D) -> void:
	KitScript.drop_part(hall, "seal_1")
	var mouth := hall.transform * (hall.get_node("marker_mouth_1") as Node3D).transform
	var run := TunnelLine.lay(self, mouth, VAULT_LINE)
	TunnelLine.batch(self, run)
	pylons.append_array(TunnelLine.pylons(run))
	vault = run.back() if run.size() == VAULT_LINE.size() else null
	var station: Node3D = run[1] if run.size() > 1 else null
	if station:
		for p in [["entry", Vector3(2.4, 1.6, -0.5)], ["platform", Vector3(4.5, 1.9, -3.0)], ["edge", Vector3(1.4, 1.8, -12.0)],
				["far", Vector3(3.0, 2.2, -23.0)], ["across", Vector3(5.8, 1.9, -12.0)]]:
			print("STATION ", p[0], " ", station.to_global(p[1]))
	if vault:
		for p in [["dock", Vector3(1.5, 1.4, -6.0)], ["door", Vector3(0.0, 1.4, -9.2)], ["hall", Vector3(0.0, 2.3, -12.5)],
				["aisle", Vector3(0.0, 1.9, -20.0)], ["cage", Vector3(0.0, 1.9, -27.0)], ["far", Vector3(0.0, 1.9, -30.0)]]:
			print("VAULT ", p[0], " ", vault.to_global(p[1]))


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.18, 0.26)
	env.ambient_light_energy = 0.3
	if OS.get_environment("TUNNEL_LIT") != "":
		env.ambient_light_color = Color(0.8, 0.78, 0.85)
		env.ambient_light_energy = 3.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.fog_enabled = OS.get_environment("TUNNEL_LIT") == ""
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color.BLACK
	env.fog_depth_begin = 6.0
	env.fog_depth_end = 48.0
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
