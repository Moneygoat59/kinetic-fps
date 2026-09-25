extends SceneTree
func _init():
    var scn = load('res://models/prop_alien_creature_colossus.glb')
    var inst = scn.instantiate()
    root.add_child(inst)
    for m in inst.find_children('*', 'MeshInstance3D'):
        print(m.name, 'AABB:', m.get_aabb(), 'global_pos:', m.global_position, 'scale:', m.scale)
        if m.mesh:
            print('  surfaces:', m.mesh.get_surface_count())
            for s in range(m.mesh.get_surface_count()):
                var mat = m.get_surface_override_material(s)
                if not mat: mat = m.mesh.surface_get_material(s)
                print('  mat:', mat)
    inst.queue_free()
    quit(0)
