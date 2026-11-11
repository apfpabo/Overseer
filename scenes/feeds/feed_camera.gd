class_name FeedCamera
extends Camera3D
## The one camera that renders the game. "Switching feeds" moves it to a
## station camera's view, or makes it follow a borg. Borg feeds move, so the
## camera is snapped to whole screen pixels to avoid shimmer.

const PITCH_DEGREES := -30.0
const YAW_DEGREES := 45.0
## How far back the camera sits. Large enough that the stress-test overview
## doesn't clip; orthographic, so distance doesn't change the image.
const DISTANCE := 40.0
const PIXEL_ROWS := 360

## Node being followed (a borg), or null for a fixed station view.
var follow_target: Node3D

var _iso_basis: Basis


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	near = 0.1
	far = 200.0
	_iso_basis = Basis.from_euler(Vector3(deg_to_rad(PITCH_DEGREES), deg_to_rad(YAW_DEGREES), 0.0))
	add_child(OutlinePass.new())


func _process(_delta: float) -> void:
	if follow_target != null:
		_look_at_point(follow_target.global_position + Vector3(0.0, 0.5, 0.0), true)


## Fixed view centred on `target`, showing `view_height` meters top to bottom.
func show_fixed(target: Vector3, view_height: float) -> void:
	follow_target = null
	size = view_height
	_look_at_point(target, false)


## Follows `target` every frame, pixel-snapped.
func show_following(target: Node3D, view_height: float) -> void:
	follow_target = target
	size = view_height
	_look_at_point(target.global_position + Vector3(0.0, 0.5, 0.0), true)


## Screen "up" projected on the floor: where W should drive a borg.
func screen_forward_on_floor() -> Vector3:
	var forward: Vector3 = -_iso_basis.z
	return Vector3(forward.x, 0.0, forward.z).normalized()


func screen_right_on_floor() -> Vector3:
	var right: Vector3 = _iso_basis.x
	return Vector3(right.x, 0.0, right.z).normalized()


func _look_at_point(point: Vector3, snap_to_pixels: bool) -> void:
	var center: Vector3 = point
	if snap_to_pixels:
		center = PixelSnap.snap(point, _iso_basis, PixelSnap.pixel_size_for(size, PIXEL_ROWS))
	global_transform = Transform3D(_iso_basis, center + _iso_basis.z * DISTANCE)
