class_name WalkerShoulder
extends MeshInstance3D
## The walker has no body in first person. When the view drops to their own shoulder (WraithGrab's LOOK: the hand closing
## on it) there has to be one to grip: a dark coat shoulder, from the neck out to `side`, just under where the hand lands.
## make() adds it to the scene; free it once the view leaves.

const WIDTH := 0.3                 # neck to the point of the shoulder
const THICK := 0.09
const DROP := 0.38                 # below the eyes


static func make(parent: Node, eye: Vector3, right: Vector3, fwd: Vector3, side: float) -> WalkerShoulder:
	var s := WalkerShoulder.new()
	var cap := CapsuleMesh.new()
	cap.radius = THICK
	cap.height = WIDTH
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.045, 0.045, 0.05)
	m.roughness = 0.95
	cap.material = m
	s.mesh = cap
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(s)
	var out := right * side
	var along := (out + Vector3.DOWN * 0.25).normalized()                  # the shoulder slopes down to its point
	s.global_basis = Basis(fwd.cross(along).normalized(), along, fwd).orthonormalized()
	s.global_position = eye + Vector3.DOWN * DROP + out * (WIDTH * 0.5) + fwd * 0.06
	return s
