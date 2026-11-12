class_name Borg
extends Node3D
## A cyborg with a headlamp. While the player watches its feed they possess
## it: WASD drives it, relative to the screen.

const SPEED := 2.2
const TURN_SPEED := 10.0

var display_name: String = "BORG-1"
var possessed: bool = false
var module_color: Color = Palette.BORG_ENGINEERING
## Callable(pos: Vector3) -> bool, provided by the station: can the borg's
## centre stand here? (The station leaves room for the borg's body.)
var walkable_check: Callable
## Screen "up" and "right" directions on the floor, set by the feed camera.
var screen_forward: Vector3 = Vector3(-1.0, 0.0, -1.0).normalized()
var screen_right: Vector3 = Vector3(1.0, 0.0, -1.0).normalized()

var _headlamp: SpotLight3D


func setup(color: Color) -> void:
	module_color = color
	var model := BorgModel.new()
	add_child(model)
	model.build(color)
	_headlamp = SpotLight3D.new()
	_headlamp.position = Vector3(0.0, 0.85, 0.2)
	# A SpotLight shines along -Z: turn it to face forward (+Z) and tilt it down.
	_headlamp.rotation = Vector3(deg_to_rad(-22.0), PI, 0.0)
	_headlamp.light_color = Palette.LIGHT_NORMAL
	_headlamp.light_energy = 6.0
	_headlamp.spot_range = 7.0
	_headlamp.spot_angle = 32.0
	_headlamp.shadow_enabled = true
	add_child(_headlamp)


func _process(delta: float) -> void:
	if not possessed:
		return
	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input.y += 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input.x += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input.x -= 1.0
	if input == Vector2.ZERO:
		return
	var direction: Vector3 = (screen_forward * input.y + screen_right * input.x).normalized()
	var step: Vector3 = direction * SPEED * delta
	# Try the full move, then each axis alone, so the borg slides along walls.
	for candidate: Vector3 in [step, Vector3(step.x, 0.0, 0.0), Vector3(0.0, 0.0, step.z)]:
		if _can_stand_at(position + candidate):
			position += candidate
			break
	var target_yaw: float = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1.0, TURN_SPEED * delta))


func _can_stand_at(pos: Vector3) -> bool:
	if not walkable_check.is_valid():
		return true
	# If a door closed on the borg, let it drive out instead of freezing.
	if not walkable_check.call(position):
		return true
	return walkable_check.call(pos)
