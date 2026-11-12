class_name CrewModel
extends Node3D
## A crew member made of boxes (~1.2 m tall), facing +Z. Chunky, readable
## proportions: big head, short legs, blocky hands. The suit color shows the
## job, and each job adds one detail (hard hat, helmet, red cross).

const HIP_HEIGHT := 0.38
const SHOULDER_HEIGHT := 0.72
const SWING_DEGREES := 30.0

const JOB_ENGINEERING := &"engineering"
const JOB_SECURITY := &"security"
const JOB_MEDICAL := &"medical"

var _left_leg: Node3D
var _right_leg: Node3D
var _left_arm: Node3D
var _right_arm: Node3D


## Builds the model. Call once, right after creating it.
## `job` is one of the JOB_* constants (anything else: no job detail).
func build(suit: Color, job: StringName = &"") -> void:
	var suit_dark: Color = suit.darkened(0.45)
	_left_leg = _limb(Vector3(-0.1, HIP_HEIGHT, 0.0))
	_right_leg = _limb(Vector3(0.1, HIP_HEIGHT, 0.0))
	for leg: Node3D in [_left_leg, _right_leg]:
		BoxBuilder.box(leg, Vector3(0.15, 0.28, 0.16), Vector3(0.0, -0.15, 0.0), suit_dark)
		BoxBuilder.box(leg, Vector3(0.17, 0.11, 0.22), Vector3(0.0, -0.325, 0.03), Palette.BOOTS)

	_left_arm = _limb(Vector3(-0.28, SHOULDER_HEIGHT, 0.0))
	_right_arm = _limb(Vector3(0.28, SHOULDER_HEIGHT, 0.0))
	for arm: Node3D in [_left_arm, _right_arm]:
		BoxBuilder.box(arm, Vector3(0.12, 0.26, 0.13), Vector3(0.0, -0.13, 0.0), suit)
		BoxBuilder.box(arm, Vector3(0.13, 0.12, 0.13), Vector3(0.0, -0.31, 0.0), Palette.SKIN)

	BoxBuilder.box(self, Vector3(0.44, 0.36, 0.28), Vector3(0.0, 0.56, 0.0), suit)
	BoxBuilder.box(self, Vector3(0.45, 0.07, 0.29), Vector3(0.0, 0.41, 0.0), suit_dark)
	# Big head: reads at 640x360 and gives the characters charm.
	BoxBuilder.box(self, Vector3(0.34, 0.32, 0.32), Vector3(0.0, 0.92, 0.0), Palette.SKIN)
	for side: float in [-1.0, 1.0]:
		BoxBuilder.box(self, Vector3(0.06, 0.08, 0.03), Vector3(side * 0.08, 0.92, 0.165), Palette.EYES)
	BoxBuilder.box(self, Vector3(0.36, 0.18, 0.1), Vector3(0.0, 0.99, -0.13), Palette.HAIR)

	match job:
		JOB_ENGINEERING:
			BoxBuilder.box(self, Vector3(0.38, 0.12, 0.36), Vector3(0.0, 1.13, 0.0), Palette.HARD_HAT)
			BoxBuilder.box(self, Vector3(0.42, 0.04, 0.46), Vector3(0.0, 1.08, 0.04), Palette.HARD_HAT)
		JOB_SECURITY:
			var helmet: Color = suit.darkened(0.3)
			BoxBuilder.box(self, Vector3(0.38, 0.16, 0.36), Vector3(0.0, 1.14, 0.0), helmet)
			BoxBuilder.box(self, Vector3(0.38, 0.07, 0.04), Vector3(0.0, 1.03, 0.17), Palette.VISOR)
		JOB_MEDICAL:
			BoxBuilder.box(self, Vector3(0.36, 0.08, 0.34), Vector3(0.0, 1.11, -0.01), Palette.HAIR)
			BoxBuilder.box(self, Vector3(0.16, 0.06, 0.03), Vector3(0.0, 0.6, 0.145), Palette.MED_CROSS)
			BoxBuilder.box(self, Vector3(0.06, 0.16, 0.03), Vector3(0.0, 0.6, 0.145), Palette.MED_CROSS)
		_:
			BoxBuilder.box(self, Vector3(0.36, 0.08, 0.34), Vector3(0.0, 1.11, -0.01), Palette.HAIR)


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
