class_name SiloLift
extends Node3D
## Missile Silo 00's freight lift (model: tools/blender/props/silo_lift.py): launch control (level 09) down to the
## generator hall. One FSM: TOP, DOWN, BOTTOM, UP (+ CRASH). A trip closes all four gates (LiftGate), then eases the cage
## down or up over TRAVEL_TIME and opens the cage gate and the landing gate on the arrival side. The cage is an AnimatableBody3D,
## so the player rides it. [E] (SiloLiftControls): in the cage it goes to the other end; at a call panel it comes to you.
## MissileSilo owns it: mount(model) while building (it takes the cage + gate nodes into its own "silo_lift" node, which
## the hall's AbyssFog covers), update(player position) every physics frame while the player is near.
## doom() (night 4's ending, ForestNightDirector): the next trip down fails STALL_AT seconds in and the cage crashes to the
## hall floor (SiloLiftCrash); the lift is CRASH from then on and answers nothing. wreck() (the silo level after that
## night, SiloDepthsLevel): the crash has already happened, the cage lies at the foot with the walker in it and a
## SiloLiftWreck runs what is left (FORCE GATE, the dying lamp, sparks).

enum State { TOP, DOWN, BOTTOM, UP, CRASH }

const TRAVEL_TIME := 24.0           # s, eased: tops out near 5 m/s
const GATE_RISE := 2.3              # silo_lift.py GATE_RISE
const CAB_HALF := 1.55              # cage inside, from its centre (x and z, cage frame)
const GATE_Z := {"in": -1.55, "out": 1.55, "top": -2.05, "bottom": 2.05}   # gate planes, cage frame z
const MAX_DELTA := 0.1
const STALL_AT := 4.0               # s into a doomed trip down (~6 m below level 09) the cage seizes
const GROUP := &"silo_lift"
const KitLights = preload("res://scripts/props/kit_lights.gd")
const MOTOR := preload("res://audio/sci-fi/Audio/spaceEngineLow_002.ogg")
const CLANK := preload("res://audio/impacts/Audio/impactMetal_heavy_002.ogg")

var state := State.TOP
var drop := 0.0                     # m, top floor to bottom floor
var _t := 0.0                       # trip time; < 0 while the gates are still closing
var _top: Transform3D               # cage frame at the top (model space): x across, +z toward the hall, y up
var _body: AnimatableBody3D
var _gates := {}                    # name -> LiftGate
var call_top: Node3D               # where the player stands to call it (SiloLiftControls)
var call_bottom: Node3D
var _motor: AudioStreamPlayer3D
var _clank: AudioStreamPlayer3D
var _lamp: OmniLight3D
var crash: SiloLiftCrash            # set by doom(): the next trip down ends in it
var wrecked: SiloLiftWreck          # set by wreck(): the cage lies at the foot
var _debris: Array[Node3D] = []     # the crash's leavings (silo_lift_wreck + decals), hidden until wreck()


static func mount(model: Node3D) -> SiloLift:
	var top := model.get_node_or_null("marker_lift_top") as Node3D
	var bottom := model.get_node_or_null("marker_lift_bottom") as Node3D
	var cab := model.get_node_or_null("silo_lift_cab") as Node3D
	if top == null or bottom == null or cab == null:
		return null
	var lift := SiloLift.new()
	lift.name = "silo_lift"
	lift.add_to_group(GROUP)
	model.add_child(lift)
	lift._build(model, top.transform, top.position.y - bottom.position.y, cab)
	return lift


func _build(model: Node3D, top: Transform3D, drop_m: float, cab: Node3D) -> void:
	_top = top
	drop = drop_m
	_body = AnimatableBody3D.new()
	add_child(_body)
	for part in [cab, model.get_node_or_null("silo_lift_cab_art")]:   # the shell and the art laid inside it ride together
		if part:
			part.owner = null                                      # leaves the imported scene's ownership
			part.reparent(_body, false)
	_shape(_body, Vector3(CAB_HALF * 2.0 + 0.1, 0.25, CAB_HALF * 2.0 + 0.1), Vector3(0.0, -0.125, 0.0))
	for s in [-1.0, 1.0]:
		_shape(_body, Vector3(0.1, 2.5, CAB_HALF * 2.0), Vector3(s * CAB_HALF, 1.25, 0.0))
	var landings := StaticBody3D.new()
	add_child(landings)
	for gate_name in GATE_Z:
		var cage: bool = gate_name == "in" or gate_name == "out"
		var mesh := model.get_node_or_null("silo_lift_gate_" + gate_name) as Node3D
		var floor_y: float = 0.0 if gate_name != "bottom" else -drop
		var shape := _shape(_body if cage else landings, Vector3(2.8, 2.4, 0.1), Vector3(0.0, floor_y + 1.2, GATE_Z[gate_name]))
		if mesh:
			mesh.owner = null
			mesh.reparent(_body if cage else self, false)
		_gates[gate_name] = LiftGate.make(mesh, shape, GATE_RISE)
	for debris_name in ["silo_lift_wreck", "silo_lift_wreck_decals"]:
		var debris := model.get_node_or_null(debris_name) as Node3D
		if debris:
			debris.visible = false
			_debris.append(debris)
	call_top = model.get_node_or_null("marker_lift_call_top") as Node3D
	call_bottom = model.get_node_or_null("marker_lift_call_bottom") as Node3D
	var lamp := OmniLight3D.new()
	lamp.light_color = Color(1.0, 0.66, 0.2)
	lamp.light_energy = 2.2
	lamp.omni_range = 7.0
	KitLights.fade(lamp)
	lamp.transform = _top * Transform3D(Basis(), Vector3(0.0, 2.3, 0.0))
	_body.add_child(lamp)
	_lamp = lamp
	var loop := MOTOR.duplicate() as AudioStreamOggVorbis
	if loop:
		loop.loop = true
	_motor = _sound(loop if loop else MOTOR, -4.0, 0.55)
	_clank = _sound(CLANK, 0.0, 0.8)
	_gates["in"].snap_open()                                       # it starts at level 09, open
	_gates["top"].snap_open()


func _shape(parent: Node3D, size: Vector3, at: Vector3) -> CollisionShape3D:
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	col.transform = _top * Transform3D(Basis(), at)
	parent.add_child(col)
	return col


func _sound(stream: AudioStream, db: float, pitch: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	p.unit_size = 6.0
	p.transform = _top * Transform3D(Basis(), Vector3(0.0, 2.8, 0.0))
	_body.add_child(p)
	return p


## Called every physics frame by MissileSilo with the player's position: prompts and [E] (SiloLiftControls).
func update(p_pos: Vector3) -> void:
	if wrecked:
		wrecked.update(p_pos)
		return
	SiloLiftControls.update(self, p_pos)


## True when p_pos (global) is inside the cage, wherever it is.
func in_cage(p_pos: Vector3) -> bool:
	var parent := get_parent() as Node3D
	if parent == null:
		return false
	var q := _top.affine_inverse() * parent.to_local(p_pos)
	var cab_y := _body.position.y
	return absf(q.x) < CAB_HALF and absf(q.z) < CAB_HALF and q.y > cab_y - 0.5 and q.y < cab_y + 2.5


func is_moving() -> bool:
	return state == State.DOWN or state == State.UP


## Dooms the next trip down: it seizes STALL_AT s in and crashes (SiloLiftCrash). Returns the crash so the caller can
## listen to its phases. Safe before the lift is built or in the tree; repeat calls return the same crash.
func doom() -> SiloLiftCrash:
	if crash == null:
		crash = SiloLiftCrash.new()
		crash.name = "crash"
		add_child(crash)
	return crash


## The crash has already happened: the cage lies on the hall floor, every gate shut, its debris round it, and a
## SiloLiftWreck takes over (the way out: forcing the hall-side gates). Returns it; repeat calls return the same one.
## Null before the lift is built or once a crash is under way.
func wreck() -> SiloLiftWreck:
	if wrecked:
		return wrecked
	if _body == null or crash != null:
		return null
	state = State.CRASH
	_body.position.y = -drop
	for gate_name in _gates:
		_gates[gate_name].snap_shut()
	for debris in _debris:
		debris.visible = true
	wrecked = SiloLiftWreck.new()
	wrecked.name = "wreck"
	add_child(wrecked)
	wrecked.begin(self, _body, _lamp, [_gates["out"], _gates["bottom"]] as Array[LiftGate], _top)
	return wrecked


## Starts a trip (DOWN from TOP, UP from BOTTOM): the gates close first. Dev tools and tests call it directly.
func depart(trip: State) -> void:
	if not ((trip == State.DOWN and state == State.TOP) or (trip == State.UP and state == State.BOTTOM)):
		return
	state = trip
	_t = -1.0
	_open_for(trip)


func _open_for(s: State) -> void:
	_gates["in"].set_open(s == State.TOP)
	_gates["top"].set_open(s == State.TOP)
	_gates["out"].set_open(s == State.BOTTOM)
	_gates["bottom"].set_open(s == State.BOTTOM)


func _physics_process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	for gate_name in _gates:
		if _gates[gate_name].step(dt):
			_clank.play()
	if state != State.DOWN and state != State.UP:
		return
	if crash and state == State.DOWN and _t >= STALL_AT:
		state = State.CRASH
		crash.begin(_body, _lamp, _motor, drop, _top)
		return
	if _t < 0.0:
		for gate_name in _gates:
			if not _gates[gate_name].is_shut():
				return
		_t = 0.0
		_motor.play()
	_t = minf(_t + dt, TRAVEL_TIME)
	var f := smoothstep(0.0, 1.0, _t / TRAVEL_TIME)
	_body.position.y = -drop * (f if state == State.DOWN else 1.0 - f)
	if _t >= TRAVEL_TIME:
		state = State.BOTTOM if state == State.DOWN else State.TOP
		_motor.stop()
		_clank.play()
		_open_for(state)
