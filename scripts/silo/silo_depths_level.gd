class_name SiloDepthsLevel
extends Node3D
## The silo depths (scenes/levels/silo_depths.tscn): the night after the lift crash. Sleeping in the flat gone to squalor
## comes here (ForestNights night 4 "sleep"): the walker comes to flat on the floor of the wrecked freight lift cage at the
## foot of Missile Silo 00's lift shaft, 120 m down (SiloLift.wreck, AptWake.come_to), forces its buckled gate
## (SiloLiftWreck), ears ringing and the world muffled until hearing comes back (HearingReturn), and has the generator hall: the machines, the blast door and stair down to the bore floor (SiloPit), and
## the open vent duct in the far end wall to crawl into (VentDuct). Nothing leads up: the lift is dead. The duct runs on
## into the underground line (TunnelNetwork, joined by SiloTunnels): a maze of tunnels and interchange halls.
## Builds a lone MissileSilo (no forest round it) and drives it as DeadForestEvent does: check_interaction every physics
## frame.

const STEP_L = preload("res://audio/impacts/Audio/footstep_concrete_000.ogg")
const STEP_R = preload("res://audio/impacts/Audio/footstep_concrete_002.ogg")
const FADE_IN := 3.2
const WAKE_HOLD := 6.5             # seconds flat on the cage floor before getting up
const EYE_UP := 0.22               # lying: eyes this far over the cage floor ...
const EYE_BACK := 0.85             # ... and this far back from its centre, feet toward the gate
const VENT_DROP := 1.4             # kit_dims.py VENT_Z - WALK_Z: the tunnel vent's duct floor over the walkway
const FALL_Y := -160.0             # below this (under the bore floor) the walker is put back where they came to

@export var player: Player

var silo: MissileSilo
var tunnels: TunnelNetwork
var wake: AptWake
var _spawn := Vector3.ZERO


func _ready() -> void:
	silo = MissileSilo.new()
	silo.name = "MissileSilo"
	silo.build_silo(null, 0.0, 0.0)
	add_child(silo)
	if player:
		player.enable_walk_mode()
		player.step_l = STEP_L
		player.step_r = STEP_R
	if silo.lift:
		silo.lift.wreck()
	tunnels = TunnelNetwork.new()
	tunnels.name = "Tunnels"
	add_child(tunnels)
	tunnels.build()
	tunnels.player = player
	SiloTunnels.attach(silo, tunnels)
	add_child(HearingReturn.new())                      # ears ringing, the world muffled, hearing coming back
	_come_to()
	_fade_in()


## Flat on the cage floor, feet toward the hall gate, staring up at the stuttering lamp; then the head comes up and they get up.
func _come_to() -> void:
	var cab := silo.model.get_node_or_null("marker_lift_bottom") as Node3D if silo.model else null
	if player == null or cab == null:
		return
	var fwd := cab.global_basis.z                       # marker +Z: toward the hall-side gate
	fwd.y = 0.0
	fwd = fwd.normalized()
	var eye := cab.global_position - fwd * EYE_BACK + Vector3.UP * EYE_UP
	var cam_rot := Vector3(deg_to_rad(78.0), 0.0, deg_to_rad(-9.0))
	wake = AptWake.come_to(player, cab.global_position, atan2(-fwd.x, -fwd.z), eye, cam_rot)
	_spawn = player.global_position
	if wake == null:
		return
	wake.name = "WakeInCage"
	wake.hold = WAKE_HOLD
	wake.lift_rot = Vector3(deg_to_rad(24.0), deg_to_rad(8.0), deg_to_rad(-14.0))
	add_child(wake)


func _physics_process(_delta: float) -> void:
	if player == null or silo == null or not player.is_physics_processing():
		return                                          # coming to (AptWake) or climbing (VentDuct): nothing to offer
	silo.check_interaction(player.global_position)
	if player.global_position.y < FALL_Y:
		player.global_position = _spawn
		player.velocity = Vector3.ZERO


func _fade_in() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(black)
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(black, "color:a", 0.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(canvas.queue_free)


## Dev menu GO TO places (DevPlaces): [label, feet position, point to face], read from the silo's markers.
func dev_places() -> Array:
	var out := []
	if silo == null or silo.model == null:
		return out
	for row in [["Wrecked lift", "marker_lift_bottom", "marker_lift_call_bottom"],
			["Pit door (hall side)", "marker_pit_door", "marker_kit_door_blast__pit"], ["Bore floor (stair foot)", "marker_pit_floor", "marker_center"],
			["Vent duct mouth", "marker_vent_mouth", "marker_kit_duct_mouth__vent0"]]:
		var at := silo.model.get_node_or_null(row[1]) as Node3D
		var look := silo.model.get_node_or_null(row[2]) as Node3D
		if at and look:
			out.append([row[0], at.global_position, look.global_position])
	if tunnels and tunnels.vent_mouth:
		var mouth := tunnels.vent_mouth.global_transform
		var below := mouth.origin + mouth.basis.z * 1.0 + Vector3.DOWN * VENT_DROP
		out.append(["Tunnels: under the vent", below, below + mouth.basis.x * 6.0])
		if tunnels.station:
			var st := tunnels.station
			out.append(["Tunnels: records station", st.to_global(Vector3(2.4, O73Kit.WALK_Z, -3.0)),
				st.to_global(Vector3(2.4, O73Kit.WALK_Z + 1.2, -20.0))])
		if tunnels.vault:
			var v := tunnels.vault
			out.append(["Tunnels: records vault", v.to_global(Vector3(0.0, O73Kit.WALK_Z, -13.0)),
				v.to_global(Vector3(0.0, O73Kit.WALK_Z + 1.0, -22.0))])
		for p in [Vector2i.ZERO, Vector2i(tunnels.cols - 1, tunnels.rows - 1)]:
			var hall: Node3D = tunnels.halls.get(p)
			if hall:
				out.append(["Tunnels: interchange %d-%d" % [p.x, p.y], hall.global_position + hall.global_basis.z * 7.0,
					hall.global_position])
	return out
