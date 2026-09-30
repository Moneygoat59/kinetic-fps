class_name WraithRig
extends RefCounted
## The wraith's skeleton (models/generated/wraith.glb; its rest pose IS its hanging pose): turns bones about their own rest
## axes, never allocating per frame. head(euler) twitches / thrashes the head, jaw(0..1) drops the jaw open far too far,
## arm(i, 0..1) swings arm i (0 arm_l = its +X side, 1 arm_r) forward toward whoever it faces; hand(i, 0..1) bends that
## wrist down, fingers first (the grip: over a shoulder and down the front).

const JAW_OPEN := 0.95                  # radians at gape 1
const REACH := 1.35                     # radians of forward swing at reach 1
const BEND := 0.45                      # radians of wrist at grip 1

var skel: Skeleton3D
var head_bone := -1
var _jaw := -1
var _arms: Array[int] = []
var _hands: Array[int] = []
var _rest: Array[Quaternion] = []


func _init(s: Skeleton3D) -> void:
	skel = s
	if skel == null:
		return
	head_bone = skel.find_bone("head")
	_jaw = skel.find_bone("jaw")
	_arms = [skel.find_bone("arm_l"), skel.find_bone("arm_r")]
	_hands = [skel.find_bone("hand_l"), skel.find_bone("hand_r")]
	for i in skel.get_bone_count():
		_rest.append(skel.get_bone_rest(i).basis.get_rotation_quaternion())


func head(euler: Vector3) -> void:
	_turn(head_bone, Quaternion.from_euler(euler))


func jaw(gape: float) -> void:
	_turn(_jaw, Quaternion(Vector3.RIGHT, clampf(gape, 0.0, 1.2) * JAW_OPEN))


func arm(i: int, reach: float, sway := 0.0) -> void:
	if i < 0 or i >= _arms.size():
		return
	_turn(_arms[i], Quaternion(Vector3.RIGHT, -reach * REACH + sway))


func hand(i: int, grip: float) -> void:
	if i < 0 or i >= _hands.size():
		return
	_turn(_hands[i], Quaternion(Vector3.RIGHT, clampf(grip, 0.0, 1.0) * BEND))


## World position of hand i, a little way down toward the fingers.
func hand_point(i: int) -> Vector3:
	if i < 0 or i >= _hands.size():
		return skel.global_position
	var pose := skel.get_bone_global_pose(_hands[i])
	return skel.global_transform * (pose.origin + pose.basis.y * 0.1)


## A point in the model's space -> the head bone's rest space (things hung on a BoneAttachment3D of `head`).
func to_head(p: Vector3) -> Vector3:
	return skel.get_bone_global_rest(head_bone).affine_inverse() * p


## A direction in the model's space -> the head bone's rest space.
func dir_to_head(d: Vector3) -> Vector3:
	return (skel.get_bone_global_rest(head_bone).basis.inverse() * d).normalized()


func _turn(i: int, q: Quaternion) -> void:
	if i < 0:
		return
	skel.set_bone_pose_rotation(i, _rest[i] * q)
