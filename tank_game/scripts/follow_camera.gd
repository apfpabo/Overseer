class_name FollowCamera
extends Camera3D
## Bird's-eye camera straight above the player's tank. It glides after the
## tank, stays over the map, and snaps to whole screen pixels so the pixel-art
## picture doesn't shimmer while it moves.

const HEIGHT: float = 15.5
const VIEW_FOV: float = 40.0
const FOLLOW_SPEED: float = 6.0
const EDGE_MARGIN: float = 2.0  # how far past the map edge the view may show

static var _current: FollowCamera = null

var _shake: float = 0.0
var target: Node3D = null:
	set(value):
		target = value
		if value != null:
			_focus = value.position  # start right over it instead of gliding in
var map_size: Vector2 = Vector2(40.0, 22.5)
var _focus: Vector3 = Vector3.ZERO


## Shakes the camera (explosions, cannon fire). 1.0 is a big jolt.
static func shake(amount: float) -> void:
	if _current != null and is_instance_valid(_current):
		_current._shake = minf(_current._shake + amount, 1.2)


func _ready() -> void:
	_current = self
	fov = VIEW_FOV
	rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_place()


func _process(delta: float) -> void:
	if target != null and is_instance_valid(target):
		_focus = _focus.lerp(target.global_position, 1.0 - exp(-FOLLOW_SPEED * delta))
	_shake = move_toward(_shake, 0.0, delta * 2.5)
	_place()


## How many meters of ground one screen pixel covers.
func ground_pixel_size() -> float:
	var view_height: float = 2.0 * HEIGHT * tan(deg_to_rad(VIEW_FOV) * 0.5)
	return view_height / float(get_viewport().get_visible_rect().size.y)


func _place() -> void:
	var view := get_viewport().get_visible_rect().size
	var view_h: float = 2.0 * HEIGHT * tan(deg_to_rad(VIEW_FOV) * 0.5)
	var view_w: float = view_h * view.x / view.y
	var x: float = clampf(_focus.x, view_w * 0.5 - EDGE_MARGIN, map_size.x - view_w * 0.5 + EDGE_MARGIN)
	var z: float = clampf(_focus.z, view_h * 0.5 - EDGE_MARGIN, map_size.y - view_h * 0.5 + EDGE_MARGIN)
	var px: float = ground_pixel_size()
	# Shake: random jolt that fades out (squared, so small shakes stay subtle).
	var jolt: float = _shake * _shake * 0.6
	x += randf_range(-jolt, jolt)
	z += randf_range(-jolt, jolt)
	global_position = Vector3(snappedf(x, px), HEIGHT, snappedf(z, px))
