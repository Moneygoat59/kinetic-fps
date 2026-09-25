class_name StartBed
extends Node3D

const BED_SCENE = preload("res://models/kaykit_dungeon/bed_frame.glb")

func build_bed(terrain: Node3D, pos_x: float = 0.0, pos_z: float = 0.0) -> void:
	var gy = terrain.get_height(pos_x, pos_z) if terrain else 0.0
	position = Vector3(pos_x, gy - 0.02, pos_z)

	var inst = BED_SCENE.instantiate() as Node3D
	add_child(inst)

	var mis = inst.find_children("*", "MeshInstance3D")
	for mi in mis:
		if mi is MeshInstance3D:
			mi.create_trimesh_collision()
			var mat = mi.get_active_material(0)
			if mat is StandardMaterial3D:
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
