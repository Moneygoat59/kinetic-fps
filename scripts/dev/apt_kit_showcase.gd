extends Node3D
## Dev showroom for the apartment kit (scenes/dev/apt_kit_showcase.tscn): every piece of AptKit.GROUPS on a warm floor, one
## row per group, in soft window light. Capture:
##   tools\capture.ps1 -Scene res://scenes/dev/apt_kit_showcase.tscn -Cam 6,5,9 -Look 6,0.5,0 -NoUi

const ROW_GAP := 3.0
const COL_GAP := 1.6
const SMALL_GAP := 0.35


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.18, 0.16)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.82, 0.72)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	(floor_mesh.mesh as PlaneMesh).size = Vector2(60.0, 40.0)
	add_child(floor_mesh)
	for row in AptKit.GROUPS.size():
		var group: Array = AptKit.GROUPS[row]
		var small := group == AptKit.SMALLS
		for i in group.size():
			var x := i * (SMALL_GAP if small else COL_GAP)
			AptKit.spawn(group[i], self, Transform3D(Basis(), Vector3(x, 0.0, -row * ROW_GAP)))
