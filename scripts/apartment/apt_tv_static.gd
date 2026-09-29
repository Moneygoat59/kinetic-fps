class_name AptTvStatic
extends Node3D
## A TV left on with no signal: static on the screen (shaders/tv_static.gdshader on the piece's `panels` mesh, this one
## instance only: the kit material is shared with the oven window), a cold flickering light thrown into the room, and the
## hiss. mount() it on a tv_console kit piece, or anything with a `panels` screen mesh facing +Z.

const SHADER = preload("res://shaders/tv_static.gdshader")
const SCREEN_NODE := "panels"
const GLOW_COLOR := Color(0.7, 0.78, 1.0)
const GLOW_ENERGY := 0.55
const GLOW_RANGE := 6.0
const GLOW_FALLOFF := 1.8          # attenuation: bright on the sofa and the table, the far corners dark
const GLOW_OUT := 0.35              # metres in front of the screen
const FLICKER_STEP := 0.05          # seconds between flicker levels (the snow re-rolls faster than the room can show)
const HISS_DB := -14.0
const HISS_RATE := 22050
const HISS_SECONDS := 1.5

static var _hiss_stream: AudioStreamWAV

var _glow: OmniLight3D
var _step := 0.0
var _level := 1.0


## Puts static on `tv`'s screen. Returns the node (a child of the screen mesh), or null if there is no screen.
static func mount(tv: Node) -> AptTvStatic:
	if tv == null:
		return null
	var screen := tv.find_child(SCREEN_NODE, true, false) as MeshInstance3D
	if screen == null or screen.mesh == null:
		push_warning("AptTvStatic: no '%s' mesh under %s" % [SCREEN_NODE, tv.name])
		return null
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	screen.material_override = mat
	var fx := AptTvStatic.new()
	fx.name = "TvStatic"
	fx.position = screen.mesh.get_aabb().get_center() + Vector3(0.0, 0.0, GLOW_OUT)
	screen.add_child(fx)
	return fx


func _ready() -> void:
	_glow = OmniLight3D.new()
	_glow.light_color = GLOW_COLOR
	_glow.light_energy = GLOW_ENERGY
	_glow.omni_range = GLOW_RANGE
	_glow.omni_attenuation = GLOW_FALLOFF
	_glow.shadow_enabled = true           # the furniture throws long shadows away from the set
	_glow.shadow_bias = 0.03
	_glow.light_size = 0.3                # a screen, not a bulb: soft edges
	_glow.light_specular = 0.0            # an omni highlight is a round blob, not a screen: it blew the window glass white
	add_child(_glow)
	var hiss := AudioStreamPlayer3D.new()
	hiss.stream = _hiss()
	hiss.volume_db = HISS_DB
	hiss.unit_size = 2.5
	hiss.max_distance = 14.0
	hiss.autoplay = true
	add_child(hiss)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_step -= minf(delta, 0.1)
	if _step <= 0.0:
		_step = FLICKER_STEP
		_level = randf_range(0.7, 1.05)
	_glow.light_energy = lerpf(_glow.light_energy, GLOW_ENERGY * _level, minf(delta * 30.0, 1.0))


## White noise, a little low-passed (a set's hiss, not a jet), made once and looped.
static func _hiss() -> AudioStreamWAV:
	if _hiss_stream:
		return _hiss_stream
	var n := int(HISS_RATE * HISS_SECONDS)
	var data := PackedByteArray()
	data.resize(n * 2)
	var s := 0.0
	for i in n:
		s = lerpf(s, randf_range(-1.0, 1.0), 0.6)
		data.encode_s16(i * 2, int(s * 11000.0))
	_hiss_stream = AudioStreamWAV.new()
	_hiss_stream.format = AudioStreamWAV.FORMAT_16_BITS
	_hiss_stream.mix_rate = HISS_RATE
	_hiss_stream.data = data
	_hiss_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_hiss_stream.loop_end = n
	return _hiss_stream
