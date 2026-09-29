class_name NightmareFx
extends CanvasLayer
## What the finale of night 2 does to the picture. WraithGrab adds it; each frame it reads the grab's state and progress
## and drives shaders/nightmare_fx.gdshader over the whole screen:
##   HUSH    the colour drains, the edges close in, grain rises, the frame swells with every heartbeat, first glitches
##   GRIP    a white hit: the image tears and splits red / blue, then settles into a jittering, glitching stare
##   TURN    zoom blur and colour split as the view is wrenched round
##   GLARE   blood creeps in from the edges, the frame pinches in as it breathes in, red flickers as its eyes catch
##   SCREAM  all of it and worse: vibration, tearing, red pulses, negative frames, and the picture hitching (the world
##           frozen for a few frames at a time) until the cut to black
## Reds survive the desaturation, so its eyes and the blood burn. Hides the walker's HUD meanwhile.

const SHADER = preload("res://shaders/nightmare_fx.gdshader")
const LAYER := 90                    # under LevelFlow's black (100)
const HEART_HZ := 1.9
const GLITCH_FPS := 24.0             # tears and grain jump at this rate, like a failing signal
const HITCH := Vector2(0.05, 0.12)   # seconds a hitch holds the world still
const HITCHES := 2.5                 # per second while it screams
const NEGATIVES := 2.0               # negative frames per second while it screams
const RED := Color(0.8, 0.02, 0.0)

var _grab: WraithGrab
var _hud: CanvasLayer
var _mat := ShaderMaterial.new()
var _state := WraithGrab.State.IDLE
var _last := 0.0
var _hit := 0.0                      # the grip's jolt, decaying
var _hitch_until := 0.0
var _neg_until := 0.0


func _init(grab: WraithGrab, player: Player) -> void:
	_grab = grab
	_hud = player.hud if player else null
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS                                 # keeps running through the hitches
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat.shader = SHADER
	rect.material = _mat
	add_child(rect)


func _ready() -> void:
	_last = Time.get_ticks_msec() * 0.001
	if _hud:
		_hud.visible = false


func _exit_tree() -> void:
	Engine.time_scale = 1.0                                                # never leave the world frozen
	if _hud and is_instance_valid(_hud):
		_hud.visible = true


func _process(_delta: float) -> void:
	if _grab == null:
		return
	var now := Time.get_ticks_msec() * 0.001                             # real time: the hitches freeze delta
	var dt := clampf(now - _last, 0.0, 0.1)
	_last = now
	if _grab.state != _state:
		if _state < WraithGrab.State.GRIP and _grab.state >= WraithGrab.State.GRIP:
			_hit = 1.0                                                         # the hand lands
		_state = _grab.state
		if _state == WraithGrab.State.DONE:
			Engine.time_scale = 1.0
	_hit = maxf(_hit - dt * 1.8, 0.0)
	var k := _grab.progress()
	var beat := pow(maxf(sin(now * TAU * HEART_HZ), 0.0), 12.0)
	var frame := floorf(now * GLITCH_FPS)
	var burst := 0.6 if fposmod(sin(frame * 12.9898) * 43758.5, 1.0) < 0.12 else 0.0
	var warp := 0.03 * beat
	var tear := 0.0
	var blur := 0.0
	var ab := 0.002 + 0.004 * beat
	var desat := 0.65
	var red := 0.0
	var vig := 0.55
	var grain := 0.12
	var flash_red := 0.0
	match _state:
		WraithGrab.State.HUSH:
			desat = 0.6 * k
			vig = 0.25 + 0.3 * k
			grain = 0.04 + 0.08 * k
			tear = burst * 0.4 * smoothstep(0.6, 1.0, k)                         # the signal starting to fail
		WraithGrab.State.LOOK:
			tear = burst
		WraithGrab.State.TURN:
			blur = 0.12 * sin(PI * k)
			ab = 0.02
			tear = 0.3
		WraithGrab.State.GLARE:
			red = 0.7 * k
			desat = 0.85
			vig = 0.6 + 0.2 * k
			warp = -0.07 * k * k * (3.0 - 2.0 * k)                            # the frame draws in with its breath
			flash_red = 0.14 if k > 0.2 and k < 0.55 and randf() < 0.3 else 0.0
		WraithGrab.State.SCREAM:
			red = 0.85
			desat = 0.9
			vig = 0.8
			warp = 0.03 * sin(now * 55.0) + 0.04 * k
			ab = 0.015 + 0.02 * randf()
			tear = 0.45 + 0.5 * fposmod(frame * 0.618, 1.0)
			blur = 0.03
			grain = 0.28
			flash_red = 0.25 * pow(maxf(sin(now * 14.0), 0.0), 4.0)
			_scream_hitches(now, dt)
	tear = maxf(tear, _hit)
	ab += 0.035 * _hit
	var flash_white := 0.55 * _hit * _hit
	_mat.set_shader_parameter(&"warp", warp)
	_mat.set_shader_parameter(&"tear", tear)
	_mat.set_shader_parameter(&"blur", blur)
	_mat.set_shader_parameter(&"aberration", ab)
	_mat.set_shader_parameter(&"desat", desat)
	_mat.set_shader_parameter(&"red", red)
	_mat.set_shader_parameter(&"grain", grain)
	_mat.set_shader_parameter(&"vignette", vig)
	_mat.set_shader_parameter(&"flash", maxf(flash_white, flash_red))
	_mat.set_shader_parameter(&"flash_color", Color.WHITE if flash_white > flash_red else RED)
	_mat.set_shader_parameter(&"invert", 1.0 if now < _neg_until else 0.0)
	_mat.set_shader_parameter(&"seed", frame)


## The picture hitches (the world holds still for a few frames) and flips to a negative, at random, while it screams.
func _scream_hitches(now: float, dt: float) -> void:
	if Engine.time_scale == 0.0:
		if now >= _hitch_until:
			Engine.time_scale = 1.0
	elif randf() < dt * HITCHES:
		Engine.time_scale = 0.0
		_hitch_until = now + randf_range(HITCH.x, HITCH.y)
	if now >= _neg_until and randf() < dt * NEGATIVES:
		_neg_until = now + randf_range(0.03, 0.07)
