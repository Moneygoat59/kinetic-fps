class_name AptProp
extends KitProp
## Runtime for apartment kit pieces (models/generated/apt_kit/*.glb and the shell, models/generated/apartment.glb).
## Everything KitProp does (screens, blinking lamps, marker lights) plus the apartment node contract (tools/blender/apt/apt_lib.py):
##   glass, noshadow  never cast shadows (window light passes the panes; lamp shades do not swallow their bulb)
##   pivot_leaf       a swinging door leaf -> AptDoor
##   hand_h/m/s       clock hands -> AptClock
##   marker_use_<id>  an interaction point -> AptUse (prompt + behaviour from AptUses)
##   view*            window backdrop: unshaded, no shadows

const DoorScript = preload("res://scripts/apartment/apt_door.gd")
const ClockScript = preload("res://scripts/apartment/apt_clock.gd")
const UseScript = preload("res://scripts/apartment/apt_use.gd")


func _ready() -> void:
	super._ready()
	var hands := 0
	for child in get_children():
		var n := String(child.name)
		if (n == "glass" or n == "noshadow" or n.begins_with("view")) and child is GeometryInstance3D:
			(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif n == "pivot_leaf":
			DoorScript.mount(child as Node3D)
		elif n.begins_with("marker_use_"):
			UseScript.mount(child as Node3D, StringName(n.trim_prefix("marker_use_")))
		elif n.begins_with("hand_"):
			hands += 1
	if hands > 0:
		ClockScript.mount(self)
