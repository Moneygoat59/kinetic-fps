@tool
extends EditorScenePostImport
## Import hook for the apartment kit. The Blender builder (tools/blender/apt/apt_lib.py) writes it into each new
## models/generated/apt_kit/*.glb.import (and apartment.py into the shell's). Sets the material look by name prefix
## (glTF cannot carry Blender's specular / intent) and puts the AptProp runtime on the root, so a dropped-in piece is live
## (doors swing, clocks tick, lamps light, interaction points answer).

const AptLook = preload("res://scripts/apartment/apt_look.gd")
const AptPropScript = preload("res://scripts/apartment/apt_prop.gd")


func _post_import(scene: Node) -> Object:
	AptLook.apply(scene)
	scene.set_script(AptPropScript)
	return scene
