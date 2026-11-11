class_name CrewModel
extends Node3D
## A crew member made of boxes (~1.2 m tall), facing +Z. Proportions follow
## the art test (tools/blender/render3d_lit.py). The suit color shows the job.

const HIP_HEIGHT := 0.47
const SHOULDER_HEIGHT := 0.86
const SWING_DEGREES := 28.0

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D


## Builds the model. Call once, right after creating it.
func build(suit: Color) -> void:
	var suit_dark: Color = suit.darkened(0.45)
	_left_leg = _limb(Vector3(-0.09, HIP_HEIGHT, 0.0))
	_right_leg = _limb(Vector3(0.09, HIP_HEIGHT, 0.0))
	for leg: Node3D in [_left_leg, _right_leg]:
		BoxBuilder.box(leg, Vector3(0.13, 0.36, 0.15), Vector3(0.0, -0.20, 0.0), suit_dark)
		BoxBuilder.box(leg, Vector3(0.14, 0.11, 0.18), Vector3(0.0, -0.42, 0.02), Palette.BOOTS)

	_left_arm = _limb(Vector3(-0.25, SHOULDER_HEIGHT, 0.0))
	_right_arm = _limb(Vector3(0.25, SHOULDER_HEIGHT, 0.0))
	for arm: Node3D in [_left_arm, _right_arm]:
		BoxBuilder.box(arm, Vector3(0.10, 0.34, 0.11), Vector3(0.0, -0.17, 0.0), suit)
		BoxBuilder.box(arm, Vector3(0.09, 0.08, 0.09), Vector3(0.0, -0.38, 0.0), Palette.SKIN)

	BoxBuilder.box(self, Vector3(0.38, 0.42, 0.26), Vector3(0.0, 0.68, 0.0), suit)
	BoxBuilder.box(self, Vector3(0.39, 0.06, 0.27), Vector3(0.0, 0.49, 0.0), suit_dark)
	BoxBuilder.box(self, Vector3(0.26, 0.24, 0.24), Vector3(0.0, 1.03, 0.0), Palette.SKIN)
	BoxBuilder.box(self, Vector3(0.28, 0.08, 0.26), Vector3(0.0, 1.17, -0.01), Palette.HAIR)
	BoxBuilder.box(self, Vector3(0.28, 0.14, 0.08), Vector3(0.0, 1.08, -0.10), Palette.HAIR)
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.05, 0.06, 0.03), Vector3(side * 0.06, 1.04, 0.125), Palette.EYES)


## Poses the limbs. `phase` is in radians and advances while walking;
## `amount` is 0 when standing still and 1 at full stride.
func set_walk_pose(phase: float, amount: float) -> void:
	var swing: float = deg_to_rad(SWING_DEGREES) * sin(phase) * amount
	_left_leg.rotation.x = swing
	_right_leg.rotation.x = -swing
	_left_arm.rotation.x = -swing * 0.8
	_right_arm.rotation.x = swing * 0.8


func _limb(pivot: Vector3) -> Node3D:
	var limb := Node3D.new()
	limb.position = pivot
	add_child(limb)
	return limb
