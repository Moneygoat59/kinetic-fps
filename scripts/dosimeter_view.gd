class_name DosimeterView
extends Node3D
## Presenter for the carried field dosimeter (kit piece `dosimeter`) in first person: the analog needle swings with the
## signal, the amber display is a pure bar graph (PixelScreen: ten rising bars, no text), the click LED flashes on every
## click and the channel lamp, bars and hand light take the channel colour. Named "HeldFieldTracker" under the camera (HeldItemController
## shows it on slot 3). Driven by RadiationDosimeter; holds no tracking logic itself.

const NODE_NAME := "HeldFieldTracker"
const HOLD_POS := Vector3(0.135, -0.18, -0.3)
const HOLD_ROT := Vector3(-24.0, -16.0, 3.0)           # degrees: face tipped up toward the eye, turned toward centre
const SCREEN_MAT := "kit_scr_dosi"
const LED_MAT := "kit_glow_dosi_led"
const LAMP_MAT := "kit_glow_dosi_lamp"
const SCREEN_PX := Vector2i(160, 80)
const SEGMENTS := 10
## bar graph on the 160 x 80 display: rising bars, bottom-aligned (kit_textures.screen_dosi draws the same layout unlit)
const BAR_X0 := 6
const BAR_W := 12
const BAR_GAP := 3
const BAR_BOTTOM := 70
const BAR_MIN_H := 18.0
const BAR_MAX_H := 60.0
const BAR_DIM := 0.16                                   # alpha of an unlit bar
const NEEDLE_SWING := 50.0                              # degrees either side of centre (kit_dims.NEEDLE_SWING)
const NEEDLE_RATE := 7.0                                # 1/s: meter damping
const LED_ON := 6.0
const LED_OFF := 0.15
const LED_DECAY := 7.0
const LIGHT_IDLE := 0.2
const MAX_DELTA := 0.1

var _needle: Node3D
var _led: BaseMaterial3D
var _lamp: BaseMaterial3D
var _light: OmniLight3D
var _segs: Array[ColorRect] = []
var _color := Color(1.0, 0.65, 0.12)
var _needle_val := 0.0
var _needle_target := 0.0
var _led_level := 0.0
var _lit_segs := -1


func build(cam: Camera3D) -> void:
	name = NODE_NAME
	position = HOLD_POS
	rotation_degrees = HOLD_ROT
	cam.add_child(self)
	var device := O73Kit.spawn(&"dosimeter", self)
	if device == null:
		return
	for mi in device.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF   # viewmodel: no self-shadow
	_needle = device.get_node_or_null("needle") as Node3D
	_led = O73Kit.own_material(device, LED_MAT)
	_lamp = O73Kit.own_material(device, LAMP_MAT)
	var screen := PixelScreen.make(SCREEN_PX)
	add_child(screen)
	screen.attach(device.get_node_or_null("screens") as MeshInstance3D, SCREEN_MAT)
	for i in SEGMENTS:
		var h := lerpf(BAR_MIN_H, BAR_MAX_H, float(i) / float(SEGMENTS - 1))
		_segs.append(screen.block(Rect2(BAR_X0 + i * (BAR_W + BAR_GAP), BAR_BOTTOM - h, BAR_W, h), Color(_color, BAR_DIM)))
	_light = OmniLight3D.new()
	_light.position = Vector3(0.0, 0.1, 0.2)                 # the display's spill on the hand, not a lamp on the body
	_light.light_energy = LIGHT_IDLE
	_light.omni_range = 0.8
	add_child(_light)


func set_channel(color: Color) -> void:
	_color = color
	if _lamp:
		_lamp.emission = color
	if _light:
		_light.light_color = color
	_lit_segs = -1


## signal: 0..1 (noisy), bars: lit bars 0..10.
func show_reading(signal_level: float, bars: int) -> void:
	_needle_target = clampf(signal_level, 0.0, 1.0)
	_set_bars(bars)


## Destination reached: needle pinned, the whole graph blinks.
func show_arrived(blink_on: bool) -> void:
	_needle_target = 1.0
	_set_bars(SEGMENTS if blink_on else 0)


## One Geiger click: flash the LED and knock the needle.
func click(strength: float) -> void:
	_led_level = 1.0
	_needle_val = minf(_needle_val + 0.03, 1.0)
	if _light:
		_light.light_energy = lerpf(LIGHT_IDLE, LIGHT_IDLE * 3.0, strength)


func _set_bars(bars: int) -> void:
	if bars == _lit_segs:
		return
	_lit_segs = bars
	for i in _segs.size():
		_segs[i].color = _color if i < bars else Color(_color, BAR_DIM)


func _process(delta: float) -> void:
	var dt := clampf(delta, 0.0, MAX_DELTA)
	_needle_val = lerpf(_needle_val, _needle_target, 1.0 - exp(-NEEDLE_RATE * dt))
	if _needle:
		_needle.rotation.z = deg_to_rad(NEEDLE_SWING * (1.0 - 2.0 * _needle_val))
	_led_level = maxf(_led_level - dt * LED_DECAY, 0.0)
	if _led:
		_led.emission_energy_multiplier = lerpf(LED_OFF, LED_ON, _led_level)
	if _light:
		_light.light_energy = lerpf(_light.light_energy, LIGHT_IDLE, dt * 3.0)
	position.y = HOLD_POS.y + sin(Time.get_ticks_msec() * 0.003) * 0.004
