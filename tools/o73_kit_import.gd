@tool
extends EditorScenePostImport
## Import hook for the Outpost 73 prop kit. The Blender builder (tools/blender/kit/kit_lib.py) writes it into each new
## models/generated/o73_kit/*.glb.import. Makes every material dead matte like the bunker (glTF cannot carry Blender's
## specular = 0) and puts the KitProp runtime (screens, lamps, reels, lights) on the root, so a dropped-in prop is live.

const Fx = preload("res://scripts/bunker/bunker_fx.gd")
const KitPropScript = preload("res://scripts/props/kit_prop.gd")


func _post_import(scene: Node) -> Object:
	Fx.make_matte(scene)
	scene.set_script(KitPropScript)
	return scene
